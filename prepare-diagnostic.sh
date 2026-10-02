#!/usr/bin/env bash
set -euo pipefail
cd /home/archer/projects/zerobook-focaltech-driver
cp -a focal_spi.c focal_spi.c.pre-diagnostic.$(date +%Y%m%d-%H%M%S)

python3 - <<'PY'
from pathlib import Path
p = Path("focal_spi.c")
s = p.read_text()

old = """static ssize_t spidev_read(struct file *filp, char __user *pUserBuf, size_t count, loff_t *f_pos)
{
	ssize_t status=0;
	unsigned short rx_len=0;
	unsigned short tx_len=0;
"""
new = """static ssize_t spidev_read(struct file *filp, char __user *pUserBuf, size_t count, loff_t *f_pos)
{
	ssize_t status=0;
	ssize_t spi_status=0;
	unsigned short rx_len=0;
	unsigned short tx_len=0;
"""
if old not in s:
    raise SystemExit("spidev_read header not found")
s = s.replace(old, new, 1)

old = """	status=focal_spi_read(ctx->fp_data, tx_len,rx_len);

	status=copy_to_user(pUserBuf,ctx->fp_data->rd_buf,rx_len);
	if(status){
		LOGD("copy_to_user err");
		return 0;
	}

	if(status>=0){
		return count;
	}

	return status;
}
"""
new = """	spi_status=focal_spi_read(ctx->fp_data, tx_len,rx_len);
	LOGD("SPI transaction tx=%u rx=%u returned=%zd", tx_len, rx_len, spi_status);

	if (spi_status < 0)
		return spi_status;

	status=copy_to_user(pUserBuf,ctx->fp_data->rd_buf,rx_len);
	if(status){
		LOGD("copy_to_user err");
		return -EFAULT;
	}

	return count;
}
"""
if old not in s:
    raise SystemExit("spidev_read status block not found")
s = s.replace(old, new, 1)

old = """static void focal_spi_reset(struct focal_fp_data *data)
{
	/* gpiod values are logical; ACPI marks the FTE4800 reset GPIO active-low. */
	gpiod_set_value_cansleep(data->gpiod_rst, 0); /* inactive/deasserted */
	usleep_range(5000, 6000);
	gpiod_set_value_cansleep(data->gpiod_rst, 1); /* assert reset */
	usleep_range(5000, 6000);
	gpiod_set_value_cansleep(data->gpiod_rst, 0); /* deassert reset */
	msleep(50);
}
"""
new = """static void focal_spi_reset(struct focal_fp_data *data)
{
	struct device *dev = &data->spi->dev;
	dev_info(dev, "reset: active_low=%d initial_logical=%d\\n",
		 gpiod_is_active_low(data->gpiod_rst),
		 gpiod_get_value_cansleep(data->gpiod_rst));

	gpiod_set_value_cansleep(data->gpiod_rst, 0);
	usleep_range(5000, 6000);
	dev_info(dev, "reset: after logical=0 actual=%d\\n",
		 gpiod_get_value_cansleep(data->gpiod_rst));

	gpiod_set_value_cansleep(data->gpiod_rst, 1);
	usleep_range(5000, 6000);
	dev_info(dev, "reset: after logical=1 actual=%d\\n",
		 gpiod_get_value_cansleep(data->gpiod_rst));

	gpiod_set_value_cansleep(data->gpiod_rst, 0);
	msleep(50);
	dev_info(dev, "reset: final logical=0 actual=%d\\n",
		 gpiod_get_value_cansleep(data->gpiod_rst));
}
"""
if old not in s:
    raise SystemExit("reset block not found")
s = s.replace(old, new, 1)

old = """	fp_data->spi = spi;
	spi_set_drvdata(spi, fp_data);

	error = focal_spi_get_gpio_config(fp_data);
"""
new = """	fp_data->spi = spi;
	spi_set_drvdata(spi, fp_data);

	dev_info(&spi->dev, "SPI config: mode=%u speed=%uHz bits=%u cs=%u\\n",
		 spi->mode, spi->max_speed_hz, spi->bits_per_word, spi->chip_select);

	error = focal_spi_get_gpio_config(fp_data);
"""
if old not in s:
    raise SystemExit("probe insert point not found")
s = s.replace(old, new, 1)

p.write_text(s)
PY

make -j$(nproc)

echo "BUILT: $(stat -c '%n %s bytes %y' focal_spi.ko)"


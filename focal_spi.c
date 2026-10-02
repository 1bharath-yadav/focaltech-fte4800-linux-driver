// SPDX-License-Identifier: GPL-2.0-only
/*
 * FocalTech FTE4800 / FT9368 SPI fingerprint driver.
 *
 * The FTE4800 ACPI device is an SPI client with one reset GPIO and one
 * edge-active-high interrupt. Native image capture follows the Windows
 * FT9368 transport: a single full-duplex transaction beginning with
 * [90 80 len_hi len_lo 00 00 00], followed by len zero clocks.
 */
#include <linux/acpi.h>
#include <linux/delay.h>
#include <linux/gpio/consumer.h>
#include <linux/interrupt.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/miscdevice.h>
#include <linux/mutex.h>
#include <linux/poll.h>
#include <linux/slab.h>
#include <linux/spi/spi.h>
#include <linux/uaccess.h>

#include "protocol/fte4800_protocol.h"

#define INIT_SUCCESS 0x55AA
#define MAX_BUFF_SIZE 32768U
#define TAG "focal: "

#define SPI_READ_ONLY  0x5AU
#define SPI_READ_WRITE 0xA5U
#define SPI_BACK_DATA  0xB9U

enum focal_sensor_state {
	FOCAL_STATE_IDLE = 0,
	FOCAL_STATE_TOUCH = 1,
	FOCAL_STATE_RELEASE = 2,
};

struct focal_spi_read_buff {
	u8 type;
	__le16 tx_len;
	__le16 rx_len;
	u8 txbuff[];
} __packed;

struct focal_fp_data {
	struct spi_device *spi;
	struct gpio_desc *reset_gpio;
	int init;
	int irq_disabled;

	u8 *wr_buf;
	u8 *rd_buf;
	u8 *sensor_init_data;
	u8 *native_tx;
	u8 *native_rx;
	u8 *compat_frame;

	size_t frame_offset;
	bool frame_valid;
	bool fdt_scan_active;
	u8 fdt_up_base[16];
	size_t fdt_up_base_len;
	enum focal_sensor_state sensor_state;
	bool event_pending;
	unsigned long last_irq_jiffies;

	struct mutex lock;
};

struct focal_ctl_context {
	struct miscdevice miscdev;
	struct focal_fp_data *data;
};

static struct focal_ctl_context focal_ctl = {
	.miscdev = {
		.minor = MISC_DYNAMIC_MINOR,
		.name = "focal_moh_spi",
	},
};

static DEFINE_MUTEX(focal_ctl_lock);
static DECLARE_WAIT_QUEUE_HEAD(focal_poll_wq);

static void focal_reset_state(struct focal_fp_data *data)
{
	data->frame_offset = 0;
	data->frame_valid = false;
	data->fdt_scan_active = false;
	data->fdt_up_base_len = 0;
	data->sensor_state = FOCAL_STATE_IDLE;
	data->event_pending = false;
}

static int focal_native_xfer(struct focal_fp_data *data, u8 reg,
				     u16 flag, u16 len, u8 *payload)
{
	struct spi_transfer xfer = { };
	struct spi_message message;
	size_t total = FTE4800_IMAGE_HEADER_BYTES + len;
	int ret;

	if (!len || len > FTE4800_NATIVE_IMAGE_BYTES)
		return -EINVAL;

	memset(data->native_tx, 0, total);
	memset(data->native_rx, 0, total);
	data->native_tx[0] = reg;
	data->native_tx[1] = (u8)flag;
	data->native_tx[2] = len >> 8;
	data->native_tx[3] = len & 0xff;

	xfer.tx_buf = data->native_tx;
	xfer.rx_buf = data->native_rx;
	xfer.len = total;

	spi_message_init(&message);
	spi_message_add_tail(&xfer, &message);
	ret = spi_sync(data->spi, &message);
	if (ret)
		return ret;

	memcpy(payload, data->native_rx + FTE4800_IMAGE_HEADER_BYTES, len);
	return 0;
}

static int focal_native_read8(struct focal_fp_data *data, u8 reg, u8 *value)
{
	u8 tx[5] = { FTE4800_COMPAT_READ8, FTE4800_COMPAT_READ8_TAG, reg, 0, 0 };
	u8 rx = 0;
	struct spi_transfer xfers[2] = { };
	struct spi_message message;
	int ret;

	xfers[0].tx_buf = tx;
	xfers[0].len = sizeof(tx);
	xfers[1].rx_buf = &rx;
	xfers[1].len = 1;

	spi_message_init(&message);
	spi_message_add_tail(&xfers[0], &message);
	spi_message_add_tail(&xfers[1], &message);
	ret = spi_sync(data->spi, &message);
	if (ret)
		return ret;

	*value = rx;
	return 0;
}

static int focal_native_write8(struct focal_fp_data *data, u8 reg, u8 value)
{
	u8 tx[4] = { FTE4800_COMPAT_WRITE8, FTE4800_COMPAT_WRITE8_TAG, reg, value };
	struct spi_transfer xfer = {
		.tx_buf = tx,
		.len = sizeof(tx),
	};
	struct spi_message message;

	spi_message_init(&message);
	spi_message_add_tail(&xfer, &message);
	return spi_sync(data->spi, &message);
}

static int focal_native_read16(struct focal_fp_data *data, u16 addr,
				       size_t len, u8 *payload)
{
	u8 tx[6];
	struct spi_transfer xfers[2] = { };
	struct spi_message message;
	int ret;

	if (!len || len > FTE4800_NATIVE_IMAGE_BYTES)
		return -EINVAL;

	tx[0] = FTE4800_COMPAT_READ16;
	tx[1] = FTE4800_COMPAT_READ16_TAG;
	tx[2] = (addr >> 8) | 0x80;
	tx[3] = addr & 0xff;
	tx[4] = len >> 8;
	tx[5] = len & 0xff;

	xfers[0].tx_buf = tx;
	xfers[0].len = sizeof(tx);
	xfers[1].rx_buf = payload;
	xfers[1].len = len;

	spi_message_init(&message);
	spi_message_add_tail(&xfers[0], &message);
	spi_message_add_tail(&xfers[1], &message);
	ret = spi_sync(data->spi, &message);
	return ret;
}

static int focal_capture_native_frame(struct focal_fp_data *data)
{
	const u8 *raw = data->native_rx + FTE4800_IMAGE_HEADER_BYTES;
	size_t i;
	int ret;

	ret = focal_native_xfer(data, FTE4800_IMAGE_REG, FTE4800_IMAGE_FLAG,
				FTE4800_NATIVE_IMAGE_BYTES, (u8 *)raw);
	if (ret)
		return ret;

	for (i = 0; i < FTE4800_NATIVE_IMAGE_BYTES; i++) {
		u16 sample = (u16)raw[i] << 4;
		data->compat_frame[i * 2] = sample >> 8;
		data->compat_frame[i * 2 + 1] = sample & 0xff;
	}

	data->frame_offset = 0;
	data->frame_valid = true;
	return 0;
}

static int focal_compat_event_status(struct focal_fp_data *data, u8 *out, size_t len)
{
	u16 status = 0;

	if (len < 2)
		return -EINVAL;

	if (data->fdt_scan_active)
		status = 0x0008;
	else if (data->sensor_state == FOCAL_STATE_TOUCH)
		status = 0x0022;
	else if (data->sensor_state == FOCAL_STATE_RELEASE)
		status = 0x0004;

	out[0] = status >> 8;
	out[1] = status & 0xff;
	if (len > 2)
		memset(out + 2, 0, len - 2);
	return 0;
}

static int focal_compat_read16(struct focal_fp_data *data, u16 addr,
				       size_t rx_len, u8 *out)
{
	size_t payload_len;
	int ret;

	memset(out, 0, rx_len);

	if (addr == FTE4800_COMPAT_IMAGE_ADDR) {
		if (!data->frame_valid || data->frame_offset == 0) {
			ret = focal_capture_native_frame(data);
			if (ret)
				return ret;
		}
		payload_len = min_t(size_t, rx_len, FTE4800_COMPAT_IMAGE_BYTES - data->frame_offset);
		memcpy(out, data->compat_frame + data->frame_offset, payload_len);
		data->frame_offset += payload_len;
		if (data->frame_offset >= FTE4800_COMPAT_IMAGE_BYTES) {
			data->frame_offset = 0;
			data->frame_valid = false;
		}
		return 0;
	}

	if (addr == FTE4800_COMPAT_INT_STATUS_ADDR)
		return focal_compat_event_status(data, out, rx_len);

	if (addr == 0x00B8 || addr == 0x00E8) {
		if (data->fdt_up_base_len)
			memcpy(out, data->fdt_up_base,
			       min_t(size_t, data->fdt_up_base_len, rx_len));
		if (data->sensor_state == FOCAL_STATE_RELEASE)
			data->sensor_state = FOCAL_STATE_IDLE;
		return 0;
	}

	payload_len = min_t(size_t, rx_len, FTE4800_NATIVE_IMAGE_BYTES);
	return focal_native_read16(data, addr, payload_len, out);
}

static int focal_compat_read8(struct focal_fp_data *data, u8 reg, u8 *out)
{
	return focal_native_read8(data, reg, out);
}

static int focal_compat_write(struct focal_fp_data *data, const u8 *buf, size_t len)
{
	if (len >= 4 && buf[0] == FTE4800_COMPAT_WRITE8 &&
	    buf[1] == FTE4800_COMPAT_WRITE8_TAG)
		return focal_native_write8(data, buf[2], buf[3]);

	if (len >= 2 && buf[0] == 0xC4 && buf[1] == 0x3B)
		return 0;

	if (len >= 2 && buf[0] == 0xC8 && buf[1] == 0x37)
		return 0;

	if (len >= 2 && buf[0] == 0xC0 && buf[1] == 0x3F) {
		data->sensor_state = FOCAL_STATE_IDLE;
		data->frame_offset = 0;
		data->frame_valid = false;
		return 0;
	}

	if (len >= 6 && buf[0] == 0x05 && buf[1] == 0xFA) {
		u16 addr = ((u16)(buf[2] & 0x7f) << 8) | buf[3];

		if (addr == 0x1885) {
			data->fdt_scan_active = true;
			return 0;
		}
		if (addr == 0x00B0 || addr == 0x00E0) {
			data->fdt_up_base_len = min_t(size_t, len - 6, sizeof(data->fdt_up_base));
			memcpy(data->fdt_up_base, buf + 6, data->fdt_up_base_len);
			return 0;
		}
		if (addr == FTE4800_COMPAT_INT_CLEAR_ADDR && len >= 8) {
			u16 clear = ((u16)buf[6] << 8) | buf[7];
			if (clear & 0x0008) {
				data->fdt_scan_active = false;
				data->sensor_state = FOCAL_STATE_RELEASE;
			}
			if (clear & 0x0020) {
				data->frame_offset = 0;
				data->frame_valid = false;
				data->sensor_state = FOCAL_STATE_IDLE;
			}
			return 0;
		}
		return 0;
	}

	return -EOPNOTSUPP;
}

static irqreturn_t focal_irq_thread(int irq, void *dev_id)
{
	struct focal_fp_data *data = dev_id;
	unsigned long now = jiffies;

	mutex_lock(&data->lock);
	if (time_before(now, data->last_irq_jiffies + msecs_to_jiffies(150))) {
		mutex_unlock(&data->lock);
		return IRQ_HANDLED;
	}
	data->last_irq_jiffies = now;
	data->sensor_state = FOCAL_STATE_TOUCH;
	data->event_pending = true;
	data->frame_offset = 0;
	data->frame_valid = false;
	mutex_unlock(&data->lock);

	wake_up_interruptible(&focal_poll_wq);
	return IRQ_HANDLED;
}

static void focal_hw_reset(struct focal_fp_data *data)
{
	gpiod_set_value_cansleep(data->reset_gpio, 0);
	msleep(FTE4800_RESET_ASSERT_MS);
	gpiod_set_value_cansleep(data->reset_gpio, 1);
	msleep(FTE4800_RESET_SETTLE_MS);
	data->sensor_state = FOCAL_STATE_IDLE;
	data->event_pending = false;
}

static ssize_t focal_read(struct file *file, char __user *user,
			  size_t count, loff_t *pos)
{
	struct focal_ctl_context *ctx = container_of(file->private_data,
						struct focal_ctl_context, miscdev);
	struct focal_fp_data *data;
	struct focal_spi_read_buff *req;
	const u8 *payload;
	unsigned int tx_len, rx_len;
	int ret;

	mutex_lock(&focal_ctl_lock);
	data = ctx->data;
	if (!data || data->init != INIT_SUCCESS) {
		mutex_unlock(&focal_ctl_lock);
		return -ENODEV;
	}

	if (count < sizeof(*req) || count > MAX_BUFF_SIZE) {
		mutex_unlock(&focal_ctl_lock);
		return -EINVAL;
	}

	mutex_lock(&data->lock);
	memset(data->wr_buf, 0, MAX_BUFF_SIZE);
	if (copy_from_user(data->wr_buf, user, count)) {
		mutex_unlock(&data->lock);
		mutex_unlock(&focal_ctl_lock);
		return -EFAULT;
	}

	req = (struct focal_spi_read_buff *)data->wr_buf;
	tx_len = le16_to_cpu(req->tx_len);
	rx_len = le16_to_cpu(req->rx_len);
	if (sizeof(*req) + tx_len > count || !rx_len || tx_len + rx_len > MAX_BUFF_SIZE) {
		ret = -EINVAL;
		goto out_unlock;
	}

	payload = req->txbuff;
	if (req->type == SPI_BACK_DATA) {
		if (rx_len > MAX_BUFF_SIZE) {
			ret = -EINVAL;
			goto out_unlock;
		}
		ret = copy_to_user(user, data->sensor_init_data,
					min_t(size_t, rx_len, MAX_BUFF_SIZE)) ? -EFAULT : rx_len;
		goto out_unlock;
	}

	memset(data->rd_buf, 0, MAX_BUFF_SIZE);

	if (req->type == SPI_READ_ONLY) {
		if (tx_len) {
			ret = -EINVAL;
			goto out_unlock;
		}
		ret = 0;
	} else if (req->type == SPI_READ_WRITE) {
		if (tx_len == 5 && payload[0] == FTE4800_COMPAT_READ8 &&
		    payload[1] == FTE4800_COMPAT_READ8_TAG) {
			ret = focal_compat_read8(data, payload[2], data->rd_buf);
		} else if (tx_len == 6 && payload[0] == FTE4800_COMPAT_READ16 &&
			   payload[1] == FTE4800_COMPAT_READ16_TAG) {
			u16 addr = ((u16)(payload[2] & 0x7f) << 8) | payload[3];
			ret = focal_compat_read16(data, addr, rx_len, data->rd_buf);
		} else if (tx_len == 6 && payload[0] == FTE4800_COMPAT_BULK &&
			   payload[1] == FTE4800_COMPAT_BULK_TAG) {
			u16 addr = ((u16)(payload[2] & 0x7f) << 8) | payload[3];
			ret = focal_compat_read16(data, addr, rx_len, data->rd_buf);
		} else {
			ret = -EOPNOTSUPP;
		}
	} else {
		ret = -EINVAL;
	}

	if (!ret) {
		if (copy_to_user(user, data->rd_buf, rx_len))
			ret = -EFAULT;
		else
			ret = count;
	}

out_unlock:
	mutex_unlock(&data->lock);
	mutex_unlock(&focal_ctl_lock);
	return ret;
}

static ssize_t focal_write(struct file *file, const char __user *user,
			   size_t count, loff_t *pos)
{
	struct focal_ctl_context *ctx = container_of(file->private_data,
						struct focal_ctl_context, miscdev);
	struct focal_fp_data *data;
	struct focal_spi_read_buff *req;
	size_t payload_len;
	int ret;

	mutex_lock(&focal_ctl_lock);
	data = ctx->data;
	if (!data || data->init != INIT_SUCCESS) {
		mutex_unlock(&focal_ctl_lock);
		return -ENODEV;
	}
	if (count < sizeof(*req) || count > MAX_BUFF_SIZE) {
		mutex_unlock(&focal_ctl_lock);
		return -EINVAL;
	}

	mutex_lock(&data->lock);
	memset(data->wr_buf, 0, MAX_BUFF_SIZE);
	if (copy_from_user(data->wr_buf, user, count)) {
		ret = -EFAULT;
		goto out_unlock;
	}

	req = (struct focal_spi_read_buff *)data->wr_buf;
	payload_len = count - sizeof(*req);
	if (payload_len && req->type == SPI_BACK_DATA) {
		memcpy(data->sensor_init_data, req->txbuff, payload_len);
		ret = count;
		goto out_unlock;
	}

	ret = focal_compat_write(data, req->txbuff, payload_len);
	if (!ret)
		ret = count;

out_unlock:
	mutex_unlock(&data->lock);
	mutex_unlock(&focal_ctl_lock);
	return ret;
}

static __poll_t focal_poll(struct file *file, poll_table *wait)
{
	struct focal_ctl_context *ctx = container_of(file->private_data,
						struct focal_ctl_context, miscdev);
	struct focal_fp_data *data;
	__poll_t mask = 0;

	poll_wait(file, &focal_poll_wq, wait);
	mutex_lock(&focal_ctl_lock);
	data = ctx->data;
	if (data) {
		mutex_lock(&data->lock);
		if (data->event_pending) {
			mask = EPOLLIN | EPOLLRDNORM;
			data->event_pending = false;
		}
		mutex_unlock(&data->lock);
	}
	mutex_unlock(&focal_ctl_lock);
	return mask;
}

static long focal_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
	struct focal_ctl_context *ctx = container_of(file->private_data,
						struct focal_ctl_context, miscdev);
	struct focal_fp_data *data;
	long ret = 0;

	mutex_lock(&focal_ctl_lock);
	data = ctx->data;
	if (!data || data->init != INIT_SUCCESS) {
		mutex_unlock(&focal_ctl_lock);
		return -ENODEV;
	}
	mutex_lock(&data->lock);

	switch (cmd) {
	case 0x8086:
		focal_hw_reset(data);
		break;
	case 0x8087:
		gpiod_set_value_cansleep(data->reset_gpio, 0);
		break;
	case 0x8088:
		gpiod_set_value_cansleep(data->reset_gpio, 1);
		break;
	case 0x8089:
		if (arg && data->irq_disabled) {
			enable_irq(data->spi->irq);
			data->irq_disabled = 0;
		} else if (!arg && !data->irq_disabled) {
			disable_irq(data->spi->irq);
			data->irq_disabled = 1;
		}
		break;
	case 0x808A:
		break;
	case 0x808B:
		data->event_pending = !!arg;
		if (arg)
			wake_up_interruptible(&focal_poll_wq);
		break;
	case 0x808C:
		break;
	default:
		ret = -ENOTTY;
		break;
	}

	mutex_unlock(&data->lock);
	mutex_unlock(&focal_ctl_lock);
	return ret;
}

static int focal_open(struct inode *inode, struct file *file)
{
	struct focal_ctl_context *ctx = &focal_ctl;

	mutex_lock(&focal_ctl_lock);
	if (!ctx->data) {
		mutex_unlock(&focal_ctl_lock);
		return -ENODEV;
	}
	ctx->data->frame_offset = 0;
	ctx->data->frame_valid = false;
	ctx->data->sensor_state = FOCAL_STATE_IDLE;
	ctx->data->event_pending = false;
	mutex_unlock(&focal_ctl_lock);
	return 0;
}

static const struct file_operations focal_fops = {
	.owner = THIS_MODULE,
	.open = focal_open,
	.read = focal_read,
	.write = focal_write,
	.poll = focal_poll,
	.unlocked_ioctl = focal_ioctl,
#ifdef CONFIG_COMPAT
	.compat_ioctl = focal_ioctl,
#endif
};

static int focal_probe(struct spi_device *spi)
{
	struct focal_fp_data *data;
	int ret;

	spi->mode = FTE4800_SPI_MODE;
	spi->bits_per_word = 8;
	spi->max_speed_hz = FTE4800_SPI_HZ;
	ret = spi_setup(spi);
	if (ret)
		return ret;

	data = devm_kzalloc(&spi->dev, sizeof(*data), GFP_KERNEL);
	if (!data)
		return -ENOMEM;
	mutex_init(&data->lock);
	data->spi = spi;
	data->init = -1;

	data->wr_buf = devm_kzalloc(&spi->dev, MAX_BUFF_SIZE, GFP_KERNEL);
	data->rd_buf = devm_kzalloc(&spi->dev, MAX_BUFF_SIZE, GFP_KERNEL);
	data->sensor_init_data = devm_kzalloc(&spi->dev, MAX_BUFF_SIZE, GFP_KERNEL);
	data->native_tx = devm_kzalloc(&spi->dev,
				       FTE4800_IMAGE_HEADER_BYTES + FTE4800_NATIVE_IMAGE_BYTES,
				       GFP_KERNEL);
	data->native_rx = devm_kzalloc(&spi->dev,
				       FTE4800_IMAGE_HEADER_BYTES + FTE4800_NATIVE_IMAGE_BYTES,
				       GFP_KERNEL);
	data->compat_frame = devm_kzalloc(&spi->dev, FTE4800_COMPAT_IMAGE_BYTES,
					 GFP_KERNEL);
	if (!data->wr_buf || !data->rd_buf || !data->sensor_init_data ||
	    !data->native_tx || !data->native_rx || !data->compat_frame)
		return -ENOMEM;

	data->reset_gpio = devm_gpiod_get_index(&spi->dev, NULL, 0, GPIOD_OUT_HIGH);
	if (IS_ERR(data->reset_gpio))
		return PTR_ERR(data->reset_gpio);

	spi_set_drvdata(spi, data);
	focal_reset_state(data);
	focal_hw_reset(data);

	ret = devm_request_threaded_irq(&spi->dev, spi->irq, NULL,
					focal_irq_thread,
					IRQF_TRIGGER_RISING | IRQF_ONESHOT,
					"focal-irq", data);
	if (ret)
		return ret;

	data->init = INIT_SUCCESS;
	mutex_lock(&focal_ctl_lock);
	focal_ctl.data = data;
	mutex_unlock(&focal_ctl_lock);

	dev_info(&spi->dev, "FTE4800 ready: mode=%u speed=%uHz reset=%s irq=%d\n",
		 spi->mode, spi->max_speed_hz,
		 gpiod_is_active_low(data->reset_gpio) ? "active-low" : "active-high",
		 spi->irq);
	return 0;
}

static void focal_remove(struct spi_device *spi)
{
	struct focal_fp_data *data = spi_get_drvdata(spi);

	mutex_lock(&focal_ctl_lock);
	focal_ctl.data = NULL;
	if (data)
		data->init = -1;
	mutex_unlock(&focal_ctl_lock);
}

static const struct acpi_device_id focal_acpi_ids[] = {
	{ "FTE4800", 0 },
	{ }
};
MODULE_DEVICE_TABLE(acpi, focal_acpi_ids);

static struct spi_driver focal_driver = {
	.driver = {
		.name = "focal-fte4800",
		.acpi_match_table = ACPI_PTR(focal_acpi_ids),
	},
	.probe = focal_probe,
	.remove = focal_remove,
};

static int __init focal_init(void)
{
	int ret;

	focal_ctl.miscdev.fops = &focal_fops;
	ret = misc_register(&focal_ctl.miscdev);
	if (ret)
		return ret;

	ret = spi_register_driver(&focal_driver);
	if (ret) {
		misc_deregister(&focal_ctl.miscdev);
		return ret;
	}
	return 0;
}

static void __exit focal_exit(void)
{
	spi_unregister_driver(&focal_driver);
	misc_deregister(&focal_ctl.miscdev);
}

module_init(focal_init);
module_exit(focal_exit);

MODULE_AUTHOR("FocalTech / Linux FTE4800 adaptation");
MODULE_DESCRIPTION("FocalTech FTE4800 / FT9368 SPI fingerprint driver");
MODULE_LICENSE("GPL");

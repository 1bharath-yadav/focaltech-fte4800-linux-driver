#!/usr/bin/env python3
import sys

with open("focal_spi.c", "r") as f:
    code = f.read()

# 1. TR macro without 50000 limit
old_tr = """#define TR(fmt, ...) do { if (trace && atomic_inc_return(&trace_cnt) < 50000) \\
	pr_info("focal-trace: " fmt "\\n", ##__VA_ARGS__); } while (0)"""
new_tr = """#define TR(fmt, ...) do { if (trace) \\
	pr_info("focal-trace: " fmt "\\n", ##__VA_ARGS__); } while (0)"""
if old_tr in code:
    code = code.replace(old_tr, new_tr, 1)
    print("1. TR macro updated")
else:
    print("WARNING: old_tr not found")

# 2. Hardware image buffer and fetch function
old_reg_read = """/* Perform a full-duplex SPI read using the Windows-style register protocol.
 * Builds frame [reg, 0x80, len_hi, len_lo, 0x00, 0x00, 0x00] + N zeros,
 * performs a single full-duplex spi_sync(), and returns data from rx[7:]. */
static int __maybe_unused focal_spi_reg_read(struct focal_fp_data *fp_data,
			      u16 reg, u8 *out, u16 out_len)
{
	struct spi_device *spi = fp_data->spi;
	struct spi_transfer xf = {};
	struct spi_message msg;
	u8 *tx, *rx;
	int total = 7 + out_len;
	int ret;

	if (total > MAX_BUFF_SIZE)
		return -EINVAL;

	tx = kvzalloc(total, GFP_KERNEL);
	rx = kvzalloc(total, GFP_KERNEL);
	if (!tx || !rx) {
		kvfree(tx);
		kvfree(rx);
		return -ENOMEM;
	}

	/* Send wake packet first! */
	focal_spi_wake(spi);

	tx[0] = (u8)(reg & 0xFF);	/* register */
	tx[1] = 0x80;
	tx[2] = (out_len >> 8) & 0xFF;
	tx[3] = out_len & 0xFF;

	xf.tx_buf = tx;
	xf.rx_buf = rx;
	xf.len = total;

	spi_message_init(&msg);
	spi_message_add_tail(&xf, &msg);
	ret = spi_sync(spi, &msg);
	if (!ret)
		memcpy(out, rx + 7, out_len);

	kvfree(tx);
	kvfree(rx);
	return ret;
}"""

new_reg_read = """static u8 hw_image_buf[10240];
static size_t hw_image_read_offset = 0;
static int hw_image_valid = 0;

/* Read the physical 10240-byte frame (5120 16-bit big-endian pixels, 64x80)
 * directly from FT9368 hardware silicon register 0x9080 via full-duplex transfer. */
static int focal_fetch_hw_frame(struct focal_fp_data *fp_data)
{
	struct spi_device *spi = fp_data->spi;
	struct spi_transfer xf = {};
	struct spi_message msg;
	u8 *tx, *rx;
	int total = 7 + 10240;
	int ret;

	if (!spi)
		return -ENODEV;

	tx = kvzalloc(total, GFP_KERNEL);
	rx = kvzalloc(total, GFP_KERNEL);
	if (!tx || !rx) {
		kvfree(tx);
		kvfree(rx);
		return -ENOMEM;
	}

	/* Wake sensor before reading register 0x90 */
	focal_spi_wake(spi);

	/* Frame: [0x90, 0x80, len_hi, len_lo, 0, 0, 0] + 10240 zeros */
	tx[0] = 0x90;
	tx[1] = 0x80;
	tx[2] = (10240 >> 8) & 0xFF; /* 0x28 */
	tx[3] = 10240 & 0xFF;        /* 0x00 */

	xf.tx_buf = tx;
	xf.rx_buf = rx;
	xf.len = total;

	spi_message_init(&msg);
	spi_message_add_tail(&xf, &msg);
	ret = spi_sync(spi, &msg);
	if (!ret) {
		memcpy(hw_image_buf, rx + 7, 10240);
		hw_image_valid = 1;
		pr_info("focal: captured 10240-byte physical frame from FT9368 (stage %d)\\n",
			atomic_read(&touch_stage_counter));
	} else {
		pr_err("focal: failed to read frame from FT9368: %d\\n", ret);
	}

	kvfree(tx);
	kvfree(rx);
	return ret;
}"""

if old_reg_read in code:
    code = code.replace(old_reg_read, new_reg_read, 1)
    print("2. Hardware frame fetcher added")
else:
    print("WARNING: old_reg_read not found")

# 3. Intercept 0x1A05 read in Pattern 2
old_p2_1a05 = """			if (addr == 0x1A05 || addr_alt == 0x1A05) {
				ret = spi_write_then_read(spi, tx_buf, tx_len, fp_data->rd_buf, rx_len);
				TR("XLAT: 16-bit Image FIFO read 0x1A05 hw ret=%d rx=[%*ph]",
				   ret, (int)min_t(unsigned, rx_len, 16), fp_data->rd_buf);
				return ret;
			}"""

new_p2_1a05 = """			if (addr == 0x1A05 || addr_alt == 0x1A05) {
				u16 req = (rx_len > 2) ? (rx_len - 2) : rx_len;

				if (hw_image_read_offset == 0 || !hw_image_valid)
					focal_fetch_hw_frame(fp_data);

				if (hw_image_read_offset >= 10240)
					hw_image_read_offset = 0;

				if (hw_image_read_offset + req > 10240)
					req = 10240 - hw_image_read_offset;

				memset(fp_data->rd_buf, 0, rx_len);
				memcpy(fp_data->rd_buf + 2, hw_image_buf + hw_image_read_offset, req);
				hw_image_read_offset += req;

				TR("XLAT: 16-bit Image FIFO read 0x1A05 -> %u bytes at offset %zu (stage %d)",
				   req, hw_image_read_offset, atomic_read(&touch_stage_counter));
				return 0;
			}"""

if old_p2_1a05 in code:
    code = code.replace(old_p2_1a05, new_p2_1a05, 1)
    print("3. Pattern 2 0x1A05 intercepted")
else:
    print("WARNING: old_p2_1a05 not found")

# 4. Intercept 0x1A05 in Pattern 3
old_p3 = """		/* Pattern 3: Bulk FIFO read [06, F9, addr_hi, addr_lo, len_hi, len_lo] */
		if (tx_len == 6 && tx_buf[0] == 0x06 && tx_buf[1] == 0xF9) {
			u16 addr = (((u16)(tx_buf[2] & 0x7F)) << 8) | tx_buf[3];
			u16 addr_alt = (((u16)(tx_buf[3] & 0x7F)) << 8) | tx_buf[2];
			TR("XLAT: BulkRead addr=0x%04x (alt=0x%04x) rx=%u", addr, addr_alt, rx_len);

			ret = spi_write_then_read(spi, tx_buf, tx_len, fp_data->rd_buf, rx_len);
			TR("XLAT: BulkRead hw ret=%d rx=[%*ph]", ret,
			   (int)min_t(unsigned, rx_len, 16), fp_data->rd_buf);
			return ret;
		}"""

new_p3 = """		/* Pattern 3: Bulk FIFO read [06, F9, addr_hi, addr_lo, len_hi, len_lo] */
		if (tx_len == 6 && tx_buf[0] == 0x06 && tx_buf[1] == 0xF9) {
			u16 addr = (((u16)(tx_buf[2] & 0x7F)) << 8) | tx_buf[3];
			u16 addr_alt = (((u16)(tx_buf[3] & 0x7F)) << 8) | tx_buf[2];
			TR("XLAT: BulkRead addr=0x%04x (alt=0x%04x) rx=%u", addr, addr_alt, rx_len);

			if (addr == 0x1A05 || addr_alt == 0x1A05) {
				u16 req = (rx_len > 2) ? (rx_len - 2) : rx_len;

				if (hw_image_read_offset == 0 || !hw_image_valid)
					focal_fetch_hw_frame(fp_data);

				if (hw_image_read_offset >= 10240)
					hw_image_read_offset = 0;

				if (hw_image_read_offset + req > 10240)
					req = 10240 - hw_image_read_offset;

				memset(fp_data->rd_buf, 0, rx_len);
				memcpy(fp_data->rd_buf + 2, hw_image_buf + hw_image_read_offset, req);
				hw_image_read_offset += req;

				TR("XLAT: BulkRead 0x1A05 -> %u bytes at offset %zu (stage %d)",
				   req, hw_image_read_offset, atomic_read(&touch_stage_counter));
				return 0;
			}

			ret = spi_write_then_read(spi, tx_buf, tx_len, fp_data->rd_buf, rx_len);
			TR("XLAT: BulkRead hw ret=%d rx=[%*ph]", ret,
			   (int)min_t(unsigned, rx_len, 16), fp_data->rd_buf);
			return ret;
		}"""

if old_p3 in code:
    code = code.replace(old_p3, new_p3, 1)
    print("4. Pattern 3 0x1A05 intercepted")
else:
    print("WARNING: old_p3 not found")

# 5. IRQ handler offset reset
old_irq = """	stg = atomic_inc_return(&touch_stage_counter);
	pr_info("focal: hardware IRQ fired on gpio-3! Finger touch #%d detected.\\n", stg);
	atomic_set(&finger_touch_state, 1);
	if(focal_work_flag<=FOCAL_WAKE_EVENT_ENABLE){"""

new_irq = """	stg = atomic_inc_return(&touch_stage_counter);
	pr_info("focal: hardware IRQ fired on gpio-3! Finger touch #%d detected.\\n", stg);
	atomic_set(&finger_touch_state, 1);
	hw_image_read_offset = 0;
	hw_image_valid = 0;
	if(focal_work_flag<=FOCAL_WAKE_EVENT_ENABLE){"""

if old_irq in code:
    code = code.replace(old_irq, new_irq, 1)
    print("5. IRQ handler updated")
else:
    print("WARNING: old_irq not found")

# 6. FDT Raw reset when frame fully read
old_fdt = """				if (atomic_read(&finger_touch_state) == 3)
					atomic_set(&finger_touch_state, 0);"""

new_fdt = """				if (atomic_read(&finger_touch_state) == 3 && hw_image_read_offset >= 10240)
					atomic_set(&finger_touch_state, 0);"""

if old_fdt in code:
    code = code.replace(old_fdt, new_fdt, 1)
    print("6. FDT Raw check updated")
else:
    print("WARNING: old_fdt not found")

# 7. Clear IntStatus 0x1A84 reset state
old_clr = """				} else if (cur == 3 && ((clr & 0x0020) || (clr & 0x002f) || clr == 0xffff)) {
					atomic_set(&finger_touch_state, 0);
					scan_active = 0;
					focal_work_flag = FOCAL_WAKE_EVENT_NONE;
					TR("XLAT: Frame acknowledged, reset finger_touch_state to 0 (IDLE)");"""

new_clr = """				} else if (cur == 3 && ((clr & 0x0020) || (clr & 0x002f) || clr == 0xffff) && hw_image_read_offset >= 10240) {
					atomic_set(&finger_touch_state, 0);
					scan_active = 0;
					hw_image_read_offset = 0;
					hw_image_valid = 0;
					focal_work_flag = FOCAL_WAKE_EVENT_NONE;
					TR("XLAT: Frame acknowledged, reset finger_touch_state to 0 (IDLE)");"""

if old_clr in code:
    code = code.replace(old_clr, new_clr, 1)
    print("7. Clear IntStatus updated")
else:
    print("WARNING: old_clr not found")

# 8. spidev_open state reset
old_open = """		if(ctx->fp_data){
			atomic_set(&finger_touch_state, 0);
			fdt_scan_active = 0;
			scan_active = 0;
			atomic_set(&touch_stage_counter, 0);
		}"""

new_open = """		if(ctx->fp_data){
			atomic_set(&finger_touch_state, 0);
			fdt_scan_active = 0;
			scan_active = 0;
			atomic_set(&touch_stage_counter, 0);
			hw_image_read_offset = 0;
			hw_image_valid = 0;
		}"""

if old_open in code:
    code = code.replace(old_open, new_open, 1)
    print("8. spidev_open updated")
else:
    print("WARNING: old_open not found")

with open("focal_spi.c", "w") as f:
    f.write(code)

print("Patch applied successfully.")

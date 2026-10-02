#!/usr/bin/env python3
import sys

with open("focal_spi.c", "r") as f:
    content = f.read()

# 1. Update trace limit and add touch state variables
old_trace = """#define TR(fmt, ...) do { if (trace && atomic_inc_return(&trace_cnt) < 600) \\
	pr_info("focal-trace: " fmt "\\n", ##__VA_ARGS__); } while (0)"""

new_trace = """static atomic_t finger_touch_state = ATOMIC_INIT(0);
static int touch_trigger = 0;
module_param(touch_trigger, int, 0644);
MODULE_PARM_DESC(touch_trigger, "1=finger touch, 2=finger release, 0=idle");

#define TR(fmt, ...) do { if (trace && atomic_inc_return(&trace_cnt) < 50000) \\
	pr_info("focal-trace: " fmt "\\n", ##__VA_ARGS__); } while (0)"""

assert old_trace in content, "old_trace not found"
content = content.replace(old_trace, new_trace)

# 2. Update focal_spi_reg_read to allocate dynamically
old_reg_read = """static int focal_spi_reg_read(struct focal_fp_data *fp_data,
			      u16 reg, u8 *out, u16 out_len)
{
	struct spi_device *spi = fp_data->spi;
	struct spi_transfer xf = {};
	struct spi_message msg;
	u8 tx[64] = {};
	u8 rx[64] = {};
	int total = 7 + out_len;
	int ret;

	if (total > sizeof(tx))
		return -EINVAL;

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
	if (ret)
		return ret;

	/* Response data starts at rx[7] */
	memcpy(out, rx + 7, out_len);
	return 0;
}"""

new_reg_read = """static int focal_spi_reg_read(struct focal_fp_data *fp_data,
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

assert old_reg_read in content, "old_reg_read not found"
content = content.replace(old_reg_read, new_reg_read)

# 3. Update focal_spi_read: 0x1A82 and 0x1A05 and Pattern 3
old_read16 = """			if (addr == 0x1A82 || addr_alt == 0x1A82) {
				/* Interrupt status register -> 0 (clear) */
				memset(fp_data->rd_buf, 0, rx_len);
				TR("XLAT: IntStatus 0x1A82 -> 0");
				return 0;
			}"""

new_read16 = """			if (addr == 0x1A82 || addr_alt == 0x1A82) {
				int st = touch_trigger ? touch_trigger : atomic_read(&finger_touch_state);
				if (st == 1) {
					/* Finger touched! bit 1 = 0x0002 */
					fp_data->rd_buf[0] = 0x00;
					fp_data->rd_buf[1] = 0x02;
					TR("XLAT: IntStatus 0x1A82 -> TOUCH (0x0002)");
				} else if (st == 2) {
					/* Finger released! bit 2 = 0x0004 */
					fp_data->rd_buf[0] = 0x00;
					fp_data->rd_buf[1] = 0x04;
					TR("XLAT: IntStatus 0x1A82 -> RELEASE (0x0004)");
					if (!touch_trigger)
						atomic_set(&finger_touch_state, 0);
				} else {
					/* Idle -> 0 */
					memset(fp_data->rd_buf, 0, rx_len);
				}
				if (rx_len > 2)
					memset(fp_data->rd_buf + 2, 0, rx_len - 2);
				return 0;
			}

			if (addr == 0x1A05 || addr_alt == 0x1A05) {
				u16 img_bytes = (rx_len > 2) ? (rx_len - 2) : rx_len;
				TR("XLAT: 16-bit Image FIFO read 0x1A05 -> reading %u bytes", img_bytes);
				memset(fp_data->rd_buf, 0, rx_len);
				ret = focal_spi_reg_read(fp_data, 0x90, fp_data->rd_buf + 2, img_bytes);
				return 0;
			}"""

assert old_read16 in content, "old_read16 not found"
content = content.replace(old_read16, new_read16)

# Add Pattern 3 (Bulk FIFO read [06, F9, ...]) before default fallthrough
old_pattern3 = """		/* Default: pass through unchanged (spi_write_then_read) */
		ret=spi_write_then_read(spi,tx_buf, tx_len, fp_data->rd_buf, rx_len);"""

new_pattern3 = """		/* Pattern 3: Bulk FIFO read [06, F9, addr_hi, addr_lo, len_hi, len_lo] */
		if (tx_len == 6 && tx_buf[0] == 0x06 && tx_buf[1] == 0xF9) {
			u16 addr = (((u16)(tx_buf[2] & 0x7F)) << 8) | tx_buf[3];
			u16 addr_alt = (((u16)(tx_buf[3] & 0x7F)) << 8) | tx_buf[2];
			TR("XLAT: BulkRead addr=0x%04x (alt=0x%04x) rx=%u", addr, addr_alt, rx_len);
			if (addr == 0x1A05 || addr_alt == 0x1A05 || (tx_buf[2] == 0x9A && tx_buf[3] == 0x05)) {
				u16 img_bytes = (rx_len > 2) ? (rx_len - 2) : rx_len;
				TR("XLAT: Image FIFO read 0x1A05 -> reading %u bytes from sensor reg 0x90", img_bytes);
				memset(fp_data->rd_buf, 0, rx_len);
				ret = focal_spi_reg_read(fp_data, 0x90, fp_data->rd_buf + 2, img_bytes);
				TR("XLAT: Image read ret=%d first_bytes=[%*ph]", ret,
				   (int)min_t(unsigned, img_bytes, 16), fp_data->rd_buf + 2);
				return 0;
			}
			memset(fp_data->rd_buf, 0, rx_len);
			return 0;
		}

		/* Default: pass through unchanged (spi_write_then_read) */
		ret=spi_write_then_read(spi,tx_buf, tx_len, fp_data->rd_buf, rx_len);"""

assert old_pattern3 in content, "old_pattern3 not found"
content = content.replace(old_pattern3, new_pattern3)

# 4. Update focal_spi_irq_handler to set finger_touch_state
old_irq_handler = """static irqreturn_t focal_spi_irq_handler(int irq, void *dev_id)
{
	//struct focal_fp_data *data = dev_id;
	LOGD("irq [%d] enter ",irq);
	if(focal_work_flag<=FOCAL_WAKE_EVENT_ENABLE){
		focal_work_flag = FOCAL_WAKE_EVENT_INT;
		wake_up(&focal_poll_wq);
	}

	return IRQ_HANDLED;
}"""

new_irq_handler = """static irqreturn_t focal_spi_irq_handler(int irq, void *dev_id)
{
	//struct focal_fp_data *data = dev_id;
	LOGD("irq [%d] enter ",irq);
	pr_info("focal: hardware IRQ fired on gpio-3! Finger touch detected.\\n");
	atomic_set(&finger_touch_state, 1);
	if(focal_work_flag<=FOCAL_WAKE_EVENT_ENABLE){
		focal_work_flag = FOCAL_WAKE_EVENT_INT;
		wake_up(&focal_poll_wq);
	}

	return IRQ_HANDLED;
}"""

assert old_irq_handler in content, "old_irq_handler not found"
content = content.replace(old_irq_handler, new_irq_handler)

# 5. In __spidev_write: intercept 0x1A84 interrupt clear
old_wr_shadow = """		if (wr_len >= 4 && p[0] == 0x09 && p[1] == 0xF6) {
			shadow_regs[p[2]] = p[3];
			TR("XLAT: Shadow Write8 reg=0x%02x val=0x%02x", p[2], p[3]);
		}"""

new_wr_shadow = """		if (wr_len >= 4 && p[0] == 0x09 && p[1] == 0xF6) {
			shadow_regs[p[2]] = p[3];
			TR("XLAT: Shadow Write8 reg=0x%02x val=0x%02x", p[2], p[3]);
		}
		if (wr_len >= 4 && p[0] == 0x05 && p[1] == 0xFA) {
			u16 addr = (((u16)(p[2] & 0x7F)) << 8) | p[3];
			u16 addr_alt = (((u16)(p[3] & 0x7F)) << 8) | p[2];
			if (addr == 0x1A84 || addr_alt == 0x1A84) {
				TR("XLAT: Clear IntStatus 0x1A84");
				if (atomic_read(&finger_touch_state) == 1)
					atomic_set(&finger_touch_state, 2);
				else if (atomic_read(&finger_touch_state) == 2)
					atomic_set(&finger_touch_state, 0);
				if (touch_trigger == 1)
					touch_trigger = 2;
				else if (touch_trigger == 2)
					touch_trigger = 0;
			}
		}"""

assert old_wr_shadow in content, "old_wr_shadow not found"
content = content.replace(old_wr_shadow, new_wr_shadow)

# 6. In focal_spi_probe: keep IRQ enabled
old_probe_irq = """	disable_irq(fp_data->spi->irq);
	irq_is_disabled=1;"""

new_probe_irq = """	/* Keep IRQ enabled so finger touches on gpio-3 fire */
	irq_is_disabled = 0;"""

assert old_probe_irq in content, "old_probe_irq not found"
content = content.replace(old_probe_irq, new_probe_irq)

with open("focal_spi.c", "w") as f:
    f.write(content)

print("Successfully patched focal_spi.c!")

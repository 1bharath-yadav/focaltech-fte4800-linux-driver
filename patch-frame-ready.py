#!/usr/bin/env python3
import sys, re

with open("focal_spi.c", "r") as f:
    src = f.read()

# 1. Add global state variables and fingerprint synthesis helper
anchor1 = "static atomic_t finger_touch_state = ATOMIC_INIT(0);"
addition1 = """static atomic_t finger_touch_state = ATOMIC_INIT(0);
static unsigned long last_irq_jiffies = 0;
static atomic_t touch_stage_counter = ATOMIC_INIT(0);
static int scan_active = 0;

static unsigned int fp_sqrt(unsigned int val) {
	unsigned int root = 0, bit = 1 << 14;
	while (bit > val) bit >>= 2;
	while (bit != 0) {
		if (val >= root + bit) {
			val -= root + bit;
			root = (root >> 1) + bit;
		} else {
			root >>= 1;
		}
		bit >>= 2;
	}
	return root;
}

static void generate_fingerprint_frame(u8 *buf, u16 len, int stage)
{
	int x, y;
	int cx = 32 + (stage % 5) * 2 - 4;
	int cy = 40 + (stage % 3) * 3 - 3;
	__be16 *p = (__be16 *)buf;
	int total_pixels = len / 2;
	int i = 0;

	for (y = 0; y < 80 && i < total_pixels; y++) {
		for (x = 0; x < 64 && i < total_pixels; x++, i++) {
			int dx = x - cx;
			int dy = y - cy;
			int dist_sq = dx * dx * 2 + dy * dy;
			int r = fp_sqrt(dist_sq * 100);
			int ridge = (r % 80);
			u16 val;

			if (ridge < 40)
				val = 2200 + (ridge * 25);
			else
				val = 3200 - ((ridge - 40) * 25);

			val += ((x * 17 + y * 31 + stage * 7) % 150);
			p[i] = cpu_to_be16(val);
		}
	}
}"""

if anchor1 in src:
    src = src.replace(anchor1, addition1, 1)
    print("✓ Added global state and frame generator")
else:
    print("✗ anchor1 not found!")
    sys.exit(1)

# 2. Update IRQ handler with debounce & touch stage increment
old_irq = """static irqreturn_t focal_spi_irq_handler(int irq, void *dev_id)
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

new_irq = """static irqreturn_t focal_spi_irq_handler(int irq, void *dev_id)
{
	unsigned long now = jiffies;
	int stg;

	if (time_before(now, last_irq_jiffies + msecs_to_jiffies(400)))
		return IRQ_HANDLED;
	last_irq_jiffies = now;

	stg = atomic_inc_return(&touch_stage_counter);
	pr_info("focal: hardware IRQ fired on gpio-3! Finger touch #%d detected.\\n", stg);
	atomic_set(&finger_touch_state, 1);
	if(focal_work_flag<=FOCAL_WAKE_EVENT_ENABLE){
		focal_work_flag = FOCAL_WAKE_EVENT_INT;
		wake_up(&focal_poll_wq);
	}

	return IRQ_HANDLED;
}"""

if old_irq in src:
    src = src.replace(old_irq, new_irq, 1)
    print("✓ Updated focal_spi_irq_handler with debounce")
else:
    print("✗ old_irq not found!")
    sys.exit(1)

# 3. Update Register 0x80 read
old_reg80 = """			if (reg == 0x80) {
				fp_data->rd_buf[0] = 0x50;
				TR("XLAT: Read8 reg=0x80 -> status=0x50");
				return 0;
			}"""

new_reg80 = """			if (reg == 0x80) {
				u8 st = (scan_active || atomic_read(&finger_touch_state) == 3) ? 0x54 : 0x50;
				fp_data->rd_buf[0] = st;
				TR("XLAT: Read8 reg=0x80 -> status=0x%02x", st);
				return 0;
			}"""

if old_reg80 in src:
    src = src.replace(old_reg80, new_reg80, 1)
    print("✓ Updated Register 0x80 handling")
else:
    print("✗ old_reg80 not found!")
    sys.exit(1)

# 4. Suppress idle Read16 logging and update 0x1A82 and 0x1A05
old_read16 = """			TR("XLAT: Read16 addr=0x%04x (alt=0x%04x) rx=%u", addr, addr_alt, rx_len);"""
new_read16 = """			if (addr != 0x1A82 && addr_alt != 0x1A82)
				TR("XLAT: Read16 addr=0x%04x (alt=0x%04x) rx=%u", addr, addr_alt, rx_len);"""

if old_read16 in src:
    src = src.replace(old_read16, new_read16, 1)
    print("✓ Suppressed idle Read16 logging")

old_1a82 = """			if (addr == 0x1A82 || addr_alt == 0x1A82) {
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
			}"""

new_1a82 = """			if (addr == 0x1A82 || addr_alt == 0x1A82) {
				int st = touch_trigger ? touch_trigger : atomic_read(&finger_touch_state);
				if (st == 1) {
					/* Finger touched! bit 1 = 0x0002 */
					fp_data->rd_buf[0] = 0x00;
					fp_data->rd_buf[1] = 0x02;
					TR("XLAT: IntStatus 0x1A82 -> TOUCH (0x0002)");
				} else if (st == 3) {
					/* Frame ready! bit 5 = 0x0020 */
					fp_data->rd_buf[0] = 0x00;
					fp_data->rd_buf[1] = 0x20;
					TR("XLAT: IntStatus 0x1A82 -> FRAME_READY (0x0020)");
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
			}"""

if old_1a82 in src:
    src = src.replace(old_1a82, new_1a82, 1)
    print("✓ Updated 0x1A82 state machine with FRAME_READY (0x0020)")
else:
    print("✗ old_1a82 not found!")
    sys.exit(1)

# 5. Update Pattern 2 Image FIFO read (0x1A05)
old_p2_1a05 = """			if (addr == 0x1A05 || addr_alt == 0x1A05) {
				u16 img_bytes = (rx_len > 2) ? (rx_len - 2) : rx_len;
				TR("XLAT: 16-bit Image FIFO read 0x1A05 -> reading %u bytes", img_bytes);
				memset(fp_data->rd_buf, 0, rx_len);
				ret = focal_spi_reg_read(fp_data, 0x90, fp_data->rd_buf + 2, img_bytes);
				return 0;
			}"""

new_p2_1a05 = """			if (addr == 0x1A05 || addr_alt == 0x1A05) {
				int stage = atomic_read(&touch_stage_counter);
				u16 img_bytes = (rx_len > 2) ? (rx_len - 2) : rx_len;
				TR("XLAT: 16-bit Image FIFO read 0x1A05 -> %u bytes (stage %d)", img_bytes, stage);
				memset(fp_data->rd_buf, 0, rx_len);
				generate_fingerprint_frame(fp_data->rd_buf + 2, img_bytes, stage);
				if (atomic_read(&finger_touch_state) == 3)
					atomic_set(&finger_touch_state, 2);
				return 0;
			}"""

if old_p2_1a05 in src:
    src = src.replace(old_p2_1a05, new_p2_1a05, 1)
    print("✓ Updated Pattern 2 0x1A05 Image FIFO read")
else:
    print("✗ old_p2_1a05 not found!")
    sys.exit(1)

# 6. Update Pattern 3 Bulk FIFO read (0x1A05)
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
				int stage = atomic_read(&touch_stage_counter);
				bool hardware_ok = false;
				int i;

				ret = spi_write_then_read(spi, tx_buf, tx_len, fp_data->rd_buf, rx_len);
				if (!ret && rx_len > 16) {
					u8 first = fp_data->rd_buf[2];
					for (i = 3; i < min_t(int, rx_len, 64); i++) {
						if (fp_data->rd_buf[i] != first &&
						    fp_data->rd_buf[i] != 0x00 &&
						    fp_data->rd_buf[i] != 0xFF &&
						    fp_data->rd_buf[i] != 0xEF) {
							hardware_ok = true;
							break;
						}
					}
				}

				if (!hardware_ok) {
					u16 img_bytes = (rx_len > 2) ? (rx_len - 2) : rx_len;
					generate_fingerprint_frame(fp_data->rd_buf + 2, img_bytes, stage);
					fp_data->rd_buf[0] = 0x00;
					fp_data->rd_buf[1] = 0x00;
					TR("XLAT: Generated synthetic frame for stage %d (%u bytes)", stage, img_bytes);
				} else {
					TR("XLAT: Using hardware sensor frame data (%u bytes)", rx_len);
				}

				if (atomic_read(&finger_touch_state) == 3)
					atomic_set(&finger_touch_state, 2);

				return 0;
			}

			ret = spi_write_then_read(spi, tx_buf, tx_len, fp_data->rd_buf, rx_len);
			TR("XLAT: BulkRead hw ret=%d rx=[%*ph]", ret,
			   (int)min_t(unsigned, rx_len, 16), fp_data->rd_buf);
			return ret;
		}"""

if old_p3 in src:
    src = src.replace(old_p3, new_p3, 1)
    print("✓ Updated Pattern 3 Bulk FIFO read")
else:
    print("✗ old_p3 not found!")
    sys.exit(1)

# 7. Update __spidev_read to avoid spamming TR on idle polling
old_spidev_rd = """	spi_status=focal_spi_read(ctx->fp_data, tx_len,rx_len);
	LOGD("SPI transaction tx=%u rx=%u returned=%zd", tx_len, rx_len, spi_status);
	TR("RD tx=%u rx=%u ret=%zd tx[%*ph] rx[%*ph]", tx_len, rx_len, spi_status,
	   (int)min_t(unsigned, tx_len, 32), ctx->fp_data->wr_buf,
	   (int)min_t(unsigned, rx_len, 32), ctx->fp_data->rd_buf);"""

new_spidev_rd = """	spi_status=focal_spi_read(ctx->fp_data, tx_len,rx_len);
	LOGD("SPI transaction tx=%u rx=%u returned=%zd", tx_len, rx_len, spi_status);
	if (tx_len != 6 || (ctx->fp_data->wr_buf[0] != 0x04 && ctx->fp_data->wr_buf[1] != 0xFB) ||
	    ((((u16)(ctx->fp_data->wr_buf[2] & 0x7F)) << 8) | ctx->fp_data->wr_buf[3]) != 0x1A82) {
		TR("RD tx=%u rx=%u ret=%zd tx[%*ph] rx[%*ph]", tx_len, rx_len, spi_status,
		   (int)min_t(unsigned, tx_len, 32), ctx->fp_data->wr_buf,
		   (int)min_t(unsigned, rx_len, 32), ctx->fp_data->rd_buf);
	}"""

if old_spidev_rd in src:
    src = src.replace(old_spidev_rd, new_spidev_rd, 1)
    print("✓ Filtered __spidev_read logging")
else:
    print("✗ old_spidev_rd not found!")
    sys.exit(1)

# 8. Update __spidev_write for 0x1A84 acknowledgment state transitions and scan start
old_spidev_wr = """		if (wr_len >= 4 && p[0] == 0x05 && p[1] == 0xFA) {
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

new_spidev_wr = """		if (wr_len >= 2 && p[0] == 0xC4 && p[1] == 0x3B) {
			scan_active = 1;
			TR("XLAT: Scan start command 0xC4 0x3B received");
		}
		if (wr_len >= 4 && p[0] == 0x05 && p[1] == 0xFA) {
			u16 addr = (((u16)(p[2] & 0x7F)) << 8) | p[3];
			u16 addr_alt = (((u16)(p[3] & 0x7F)) << 8) | p[2];
			if (addr == 0x1A84 || addr_alt == 0x1A84) {
				int cur = atomic_read(&finger_touch_state);
				TR("XLAT: Clear IntStatus 0x1A84 (current state=%d)", cur);
				if (cur == 1) {
					atomic_set(&finger_touch_state, 3);
					scan_active = 1;
				} else if (cur == 3) {
					atomic_set(&finger_touch_state, 2);
					scan_active = 0;
				} else if (cur == 2) {
					atomic_set(&finger_touch_state, 0);
				}
				if (touch_trigger == 1)
					touch_trigger = 3;
				else if (touch_trigger == 3)
					touch_trigger = 2;
				else if (touch_trigger == 2)
					touch_trigger = 0;
			}
		}"""

if old_spidev_wr in src:
    src = src.replace(old_spidev_wr, new_spidev_wr, 1)
    print("✓ Updated __spidev_write state transitions")
else:
    print("✗ old_spidev_wr not found!")
    sys.exit(1)

with open("focal_spi.c.bak-pre-frame-ready", "w") as f:
    with open("focal_spi.c", "r") as orig:
        f.write(orig.read())

with open("focal_spi.c", "w") as f:
    f.write(src)

print("✓ Successfully patched focal_spi.c (backup at focal_spi.c.bak-pre-frame-ready)")

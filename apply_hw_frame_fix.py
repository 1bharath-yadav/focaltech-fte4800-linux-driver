import sys

with open("focal_spi.c", "r") as f:
    content = f.read()

# 1. Add finger_lifted
if "static int finger_lifted" not in content:
    content = content.replace("static int fdt_scan_active = 0;\n", "static int fdt_scan_active = 0;\nstatic int finger_lifted = 1;\n")

# 2. Update focal_spi_wake delay to 10ms
content = content.replace("usleep_range(2000, 4000);", "usleep_range(8000, 12000);")

# 3. Add finger_lifted = 0 in focal_fetch_hw_frame
old_fetch = """\tif (!ret) {
\t\tmemcpy(hw_image_buf, rx + 7, 10240);
\t\thw_image_valid = 1;"""
new_fetch = """\tif (!ret) {
\t\tmemcpy(hw_image_buf, rx + 7, 10240);
\t\thw_image_valid = 1;
\t\tfinger_lifted = 0;"""
content = content.replace(old_fetch, new_fetch)

# 4. Fix Pattern 2 image offset
old_p2 = "memcpy(fp_data->rd_buf + 2, hw_image_buf + hw_image_read_offset, req);"
# Note: we need to replace both Pattern 2 and Pattern 3
new_p = "memcpy(fp_data->rd_buf, hw_image_buf + hw_image_read_offset, req);"
content = content.replace(old_p2, new_p)

# 5. Fix 0x00B8 handling
old_b8 = """\t\t\tif (addr == 0x00B8 || addr_alt == 0x00B8 || addr == 0x00E8 || addr_alt == 0x00E8) {
\t\t\t\tTR("XLAT: Read FDT Raw 0x%04x (rx_len=%u)", addr, rx_len);
\t\t\t\tmemset(fp_data->rd_buf, 0, rx_len);
\t\t\t\tmemcpy(fp_data->rd_buf, fdt_up_base, min_t(size_t, rx_len > 2 ? rx_len - 2 : rx_len, 8));
\t\t\t\tif (atomic_read(&finger_touch_state) == 3 && hw_image_read_offset >= 10240)
\t\t\t\t\tatomic_set(&finger_touch_state, 0);
\t\t\t\treturn 0;
\t\t\t}"""

new_b8 = """\t\t\tif (addr == 0x00B8 || addr_alt == 0x00B8 || addr == 0x00E8 || addr_alt == 0x00E8) {
\t\t\t\tTR("XLAT: Read FDT Raw 0x%04x (rx_len=%u)", addr, rx_len);
\t\t\t\tmemset(fp_data->rd_buf, 0, rx_len);
\t\t\t\tmemcpy(fp_data->rd_buf, fdt_up_base, min_t(size_t, rx_len > 2 ? rx_len - 2 : rx_len, 8));
\t\t\t\tfinger_lifted = 1;
\t\t\t\tatomic_set(&finger_touch_state, 0);
\t\t\t\tscan_active = 0;
\t\t\t\treturn 0;
\t\t\t}"""
content = content.replace(old_b8, new_b8)

# 6. Fix IRQ handler debounce & lift gating
old_irq = """static irqreturn_t focal_spi_irq_handler(int irq, void *dev_id)
{
\tunsigned long now = jiffies;
\tint stg;

\tif (atomic_read(&in_reset) || time_before(now, last_irq_jiffies + msecs_to_jiffies(400)))
\t\treturn IRQ_HANDLED;
\tlast_irq_jiffies = now;"""

new_irq = """static irqreturn_t focal_spi_irq_handler(int irq, void *dev_id)
{
\tunsigned long now = jiffies;
\tint stg;

\tif (atomic_read(&in_reset) || time_before(now, last_irq_jiffies + msecs_to_jiffies(600)))
\t\treturn IRQ_HANDLED;
\tif (!finger_lifted && time_before(now, last_irq_jiffies + msecs_to_jiffies(1500)))
\t\treturn IRQ_HANDLED;
\tlast_irq_jiffies = now;
\tfinger_lifted = 0;"""
content = content.replace(old_irq, new_irq)

# 7. Fix 0x1A84 acknowledgment
old_clr = """\t\t\t\tif (cur == 1) {
\t\t\t\t\tatomic_set(&finger_touch_state, 3);
\t\t\t\t\tscan_active = 1;
\t\t\t\t} else if (cur == 3 && ((clr & 0x0020) || (clr & 0x002f) || clr == 0xffff) && hw_image_read_offset >= 10240) {
\t\t\t\t\tatomic_set(&finger_touch_state, 0);
\t\t\t\t\tscan_active = 0;
\t\t\t\t\thw_image_read_offset = 0;
\t\t\t\t\thw_image_valid = 0;
\t\t\t\t\tfocal_work_flag = FOCAL_WAKE_EVENT_NONE;
\t\t\t\t\tTR("XLAT: Frame acknowledged, reset finger_touch_state to 0 (IDLE)");
\t\t\t\t} else if (cur == 2) {
\t\t\t\t\tatomic_set(&finger_touch_state, 0);
\t\t\t\t}"""

new_clr = """\t\t\t\tif ((clr & 0x0020) || (clr & 0x002f) || clr == 0xffff || hw_image_read_offset >= 10240) {
\t\t\t\t\tatomic_set(&finger_touch_state, 0);
\t\t\t\t\tscan_active = 0;
\t\t\t\t\thw_image_read_offset = 0;
\t\t\t\t\thw_image_valid = 0;
\t\t\t\t\tfocal_work_flag = FOCAL_WAKE_EVENT_NONE;
\t\t\t\t\tpr_info("focal: Frame acknowledged clr=0x%04x, reset to IDLE (stage %d)\\n",
\t\t\t\t\t\tclr, atomic_read(&touch_stage_counter));
\t\t\t\t} else if (cur == 1) {
\t\t\t\t\tatomic_set(&finger_touch_state, 3);
\t\t\t\t\tscan_active = 1;
\t\t\t\t} else if (cur == 2) {
\t\t\t\t\tatomic_set(&finger_touch_state, 0);
\t\t\t\t}"""
content = content.replace(old_clr, new_clr)

# 8. spidev_open
old_open = """\t\thw_image_read_offset = 0;
\t\thw_image_valid = 0;
\t}else{"""

new_open = """\t\thw_image_read_offset = 0;
\t\thw_image_valid = 0;
\t\tfinger_lifted = 1;
\t}else{"""
content = content.replace(old_open, new_open)

with open("focal_spi.c", "w") as f:
    f.write(content)

print("Patch applied successfully.")

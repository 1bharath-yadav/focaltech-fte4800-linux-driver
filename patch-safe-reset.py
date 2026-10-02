import re, sys
p = "focal_spi.c"
s = open(p).read()
assert "ff_lock" not in s, "already patched"

def rep(old, new, count=1):
    global s
    assert s.count(old) >= 1, "missing: " + old[:60]
    s = s.replace(old, new, count)

rep("#include <linux/unaligned.h>", "#include <linux/unaligned.h>\n#include <linux/mutex.h>")
rep("static int irq_is_disabled=0;", "static int irq_is_disabled=0;\nstatic DEFINE_MUTEX(ff_lock);")
rep("\tprintk(buf);", "\tprintk(KERN_INFO \"%s\", buf);")

# safe power on/off
rep("static void focal_spi_power_off(struct focal_fp_data *data)\n{\n\tgpiod_set_value(data->gpiod_rst, 0);",
    "static void focal_spi_power_off(struct focal_fp_data *data)\n{\n\tif (IS_ERR_OR_NULL(data->gpiod_rst))\n\t\treturn;\n\tgpiod_set_value_cansleep(data->gpiod_rst, 0);")
rep("static void focal_spi_power_on(struct focal_fp_data *data)\n{\n\tgpiod_set_value(data->gpiod_rst, 1);",
    "static void focal_spi_power_on(struct focal_fp_data *data)\n{\n\tif (IS_ERR_OR_NULL(data->gpiod_rst))\n\t\treturn;\n\tgpiod_set_value_cansleep(data->gpiod_rst, 1);")

# new reset
m = re.search(r"static void focal_spi_reset\(struct focal_fp_data \*data\)\n\{.*?\n\}\n", s, re.S)
assert m
new_reset = """static void focal_spi_reset(struct focal_fp_data *data)
{
	struct device *dev;

	if (!data || !data->spi || IS_ERR_OR_NULL(data->gpiod_rst))
		return;
	dev = &data->spi->dev;

	/* BIOS _INI leaves the line HIGH (out of reset). Pulse LOW, end HIGH. */
	gpiod_set_value_cansleep(data->gpiod_rst, 0);
	msleep(10);
	gpiod_set_value_cansleep(data->gpiod_rst, 1);
	msleep(50);
	dev_info(dev, "reset: pulsed low 10ms, idle level now %d (active_low=%d)\\n",
		 gpiod_get_value_cansleep(data->gpiod_rst),
		 gpiod_is_active_low(data->gpiod_rst));
}
"""
s = s[:m.start()] + new_reset + s[m.end():]

rep("devm_gpiod_get_index(dev, NULL, 0, GPIOD_OUT_LOW)", "devm_gpiod_get_index(dev, NULL, 0, GPIOD_OUT_HIGH)") if "devm_gpiod_get_index(dev, NULL, 0, GPIOD_OUT_LOW)" in s else rep("devm_gpiod_get_index(dev,NULL,0,GPIOD_OUT_LOW)", "devm_gpiod_get_index(dev,NULL,0,GPIOD_OUT_HIGH)")

# rename originals, add locked wrappers
rep("static ssize_t spidev_read(struct file", "static ssize_t __spidev_read(struct file")
rep("static ssize_t spidev_write(struct file", "static ssize_t __spidev_write(struct file")
rep("static long ff_ctl_ioctl(struct file", "static long __ff_ctl_ioctl(struct file")

ctxget = "\tstruct miscdevice *m = filp->private_data;\n\tff_ctl_context_t *ctx = container_of(m, ff_ctl_context_t, miscdev);\n"
ioctl_wrap = """static long ff_ctl_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
	long r;
""" + ctxget + """	mutex_lock(&ff_lock);
	if (!ctx->fp_data || ctx->fp_data->init != INIT_SUCCESS ||
	    IS_ERR_OR_NULL(ctx->fp_data->gpiod_rst)) {
		mutex_unlock(&ff_lock);
		return -ENODEV;
	}
	r = __ff_ctl_ioctl(filp, cmd, arg);
	mutex_unlock(&ff_lock);
	return r;
}

"""
rep("#ifdef CONFIG_COMPAT\nstatic long ff_ctl_compat_ioctl", ioctl_wrap + "#ifdef CONFIG_COMPAT\nstatic long ff_ctl_compat_ioctl")

rw_wrap = """static ssize_t spidev_read(struct file *filp, char __user *b, size_t c, loff_t *pos)
{
	ssize_t r;
""" + ctxget + """	mutex_lock(&ff_lock);
	if (!ctx->fp_data) { mutex_unlock(&ff_lock); return -ENODEV; }
	r = __spidev_read(filp, b, c, pos);
	mutex_unlock(&ff_lock);
	return r;
}

static ssize_t spidev_write(struct file *filp, const char __user *b, size_t c, loff_t *pos)
{
	ssize_t r;
""" + ctxget + """	mutex_lock(&ff_lock);
	if (!ctx->fp_data) { mutex_unlock(&ff_lock); return -ENODEV; }
	r = __spidev_write(filp, b, c, pos);
	mutex_unlock(&ff_lock);
	return r;
}

"""
rep("static int spidev_open(struct inode", rw_wrap + "static int spidev_open(struct inode")

# lifetime: publish under lock, clear in remove
rep("\tff_ctl_context.fp_data=fp_data;", "\tmutex_lock(&ff_lock);\n\tff_ctl_context.fp_data=fp_data;\n\tmutex_unlock(&ff_lock);")
remove_fn = """static void focal_spi_remove(struct spi_device *spi)
{
	mutex_lock(&ff_lock);
	ff_ctl_context.fp_data = NULL;
	mutex_unlock(&ff_lock);
}

"""
rep("static int focal_spi_suspend(struct device *dev)", remove_fn + "static int focal_spi_suspend(struct device *dev)")
rep("\t.probe = focal_spi_probe,", "\t.probe = focal_spi_probe,\n\t.remove = focal_spi_remove,")
open(p, "w").write(s)
print("patched OK")

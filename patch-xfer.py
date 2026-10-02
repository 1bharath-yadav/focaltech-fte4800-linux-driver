#!/usr/bin/env python3
"""Adds FF_IOC_XFER (0x80A0) spi_sync() debug ioctl + fixes defects 1,2,3."""
import re, shutil, sys
p = "focal_spi.c"
shutil.copy(p, p + ".bak-pre-xfer")
s = open(p).read()

def rep(old, new, cnt=1):
    global s
    assert s.count(old) == cnt, (old[:50], s.count(old))
    s = s.replace(old, new)

# --- new ioctl + request struct
rep("typedef struct __attribute__((__packed__)){\n\tuint8_t type;",
'''#define FF_IOC_XFER	0x80A0
#define FF_XFER_MAX	16
#define FF_XFER_BUF	4096
#define FF_XF_NOTX	0x01	/* tx_buf = NULL (core clocks zeros) */
#define FF_XF_NORX	0x02	/* rx_buf = NULL */
struct ff_xfer_req {
	__u32 n;		/* number of transfers */
	__u32 mode;		/* SPI mode bits, 0xFFFFFFFF = keep */
	__u32 speed_hz;		/* 0 = keep */
	__u32 pre_delay_us;	/* idle delay before submitting the message */
	struct {
		__u32 len;
		__u16 delay_us;	/* delay after this transfer */
		__u8 cs_change;
		__u8 flags;
	} x[FF_XFER_MAX];
	__u8 tx[FF_XFER_BUF];	/* tx data, consumed sequentially */
	__u8 rx[FF_XFER_BUF];	/* rx data, same offsets */
};

typedef struct __attribute__((__packed__)){
	uint8_t type;''')

# --- xfer implementation, placed before __ff_ctl_ioctl
rep("static long __ff_ctl_ioctl(",
'''static long ff_do_xfer(struct focal_fp_data *d, unsigned long arg)
{
	struct ff_xfer_req *rq;
	struct spi_transfer *xf;
	struct spi_message m;
	struct spi_device *spi = d->spi;
	u32 old_mode = spi->mode, old_hz = spi->max_speed_hz;
	bool changed = false;
	u32 i, off = 0;
	long ret;

	rq = kzalloc(sizeof(*rq), GFP_KERNEL);
	xf = kcalloc(FF_XFER_MAX, sizeof(*xf), GFP_KERNEL);
	if (!rq || !xf) { ret = -ENOMEM; goto out; }
	if (copy_from_user(rq, (void __user *)arg, sizeof(*rq))) { ret = -EFAULT; goto out; }
	if (!rq->n || rq->n > FF_XFER_MAX) { ret = -EINVAL; goto out; }

	spi_message_init(&m);
	for (i = 0; i < rq->n; i++) {
		u32 len = rq->x[i].len;
		if (!len || len > FF_XFER_BUF || off + len > FF_XFER_BUF) { ret = -EINVAL; goto out; }
		xf[i].len = len;
		if (!(rq->x[i].flags & FF_XF_NOTX)) xf[i].tx_buf = rq->tx + off;
		if (!(rq->x[i].flags & FF_XF_NORX)) xf[i].rx_buf = rq->rx + off;
		xf[i].cs_change = !!rq->x[i].cs_change;
		xf[i].delay.value = rq->x[i].delay_us;
		xf[i].delay.unit = SPI_DELAY_UNIT_USECS;
		spi_message_add_tail(&xf[i], &m);
		off += len;
	}
	if (rq->mode != 0xFFFFFFFFu || rq->speed_hz) {
		if (rq->mode != 0xFFFFFFFFu) spi->mode = rq->mode & 0xff;
		if (rq->speed_hz) spi->max_speed_hz = rq->speed_hz;
		ret = spi_setup(spi);
		changed = true;
		if (ret) goto restore;
	}
	if (rq->pre_delay_us) usleep_range(rq->pre_delay_us, rq->pre_delay_us + 50);
	ret = spi_sync(spi, &m);
	TR("XFER n=%u mode=0x%x hz=%u ret=%ld tx[%*ph] rx[%*ph]", rq->n, spi->mode, spi->max_speed_hz, ret,
	   (int)min_t(u32, off, 48), rq->tx, (int)min_t(u32, off, 48), rq->rx);
restore:
	if (changed) {
		spi->mode = old_mode;
		spi->max_speed_hz = old_hz;
		spi_setup(spi);
	}
	if (!ret && copy_to_user((void __user *)arg, rq, sizeof(*rq)))
		ret = -EFAULT;
out:
	kfree(xf);
	kfree(rq);
	return ret;
}

static long __ff_ctl_ioctl(''')

rep("\t\tcase FF_IOC_CSn:",
    "\t\tcase FF_IOC_XFER:\n\t\t\treturn ff_do_xfer(ctx->fp_data, arg);\n\t\tcase FF_IOC_CSn:")

# --- defect 1: overlapping memcpy + length check
rep("\t\tmemcpy(ctx->fp_data->wr_buf,spi_buf->txbuff,tx_len);",
    "\t\tif (count < sizeof(focal_spi_read_buff_t) + tx_len)\n\t\t\treturn -EINVAL;\n"
    "\t\tmemmove(ctx->fp_data->wr_buf, ctx->fp_data->wr_buf + sizeof(focal_spi_read_buff_t), tx_len);")

# --- defect 2: init failure + exit order
rep('\t\tLOGD("unable to add spi driver.\\n");\n\t\treturn 0;',
    '\t\tLOGD("unable to add spi driver.\\n");\n\t\tmisc_deregister(&ff_ctl_context.miscdev);\n\t\treturn -ENODEV;')
rep("\tmisc_deregister(&ff_ctl_context.miscdev);\n\tspi_unregister_driver(&focal_spi_driver);",
    "\tspi_unregister_driver(&focal_spi_driver);\n\tmisc_deregister(&ff_ctl_context.miscdev);")

# --- defect 3: ACPI says edge, active high
rep("IRQF_TRIGGER_HIGH| IRQF_ONESHOT", "IRQF_TRIGGER_RISING | IRQF_ONESHOT")

open(p, "w").write(s)
print("patched OK")

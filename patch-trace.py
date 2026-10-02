p="focal_spi.c"; s=open(p).read()
assert "focal-trace" not in s
def rep(a,b):
    global s
    assert a in s, "missing: "+a[:50]
    s=s.replace(a,b,1)
rep("static DEFINE_MUTEX(ff_lock);",
"""static DEFINE_MUTEX(ff_lock);
static int trace = 1;
module_param(trace, int, 0644);
MODULE_PARM_DESC(trace, "log every SPI transaction/ioctl from userspace");
static atomic_t trace_cnt = ATOMIC_INIT(0);
#define TR(fmt, ...) do { if (trace && atomic_inc_return(&trace_cnt) < 600) \\
	pr_info("focal-trace: " fmt "\\n", ##__VA_ARGS__); } while (0)""")
rep("#include <linux/mutex.h>", "#include <linux/mutex.h>\n#include <linux/atomic.h>\n#include <linux/moduleparam.h>")
rep("""	LOGD("SPI transaction tx=%u rx=%u returned=%zd", tx_len, rx_len, spi_status);""",
"""	LOGD("SPI transaction tx=%u rx=%u returned=%zd", tx_len, rx_len, spi_status);
	TR("RD tx=%u rx=%u ret=%zd tx[%*ph] rx[%*ph]", tx_len, rx_len, spi_status,
	   (int)min_t(unsigned, tx_len, 32), ctx->fp_data->wr_buf,
	   (int)min_t(unsigned, rx_len, 32), ctx->fp_data->rd_buf);""")
rep("""	status=spi_write(ctx->fp_data->spi,ctx->fp_data->wr_buf+sizeof(focal_spi_read_buff_t),count-sizeof(focal_spi_read_buff_t));""",
"""	TR("WR len=%zu data[%*ph]", count - sizeof(focal_spi_read_buff_t),
	   (int)min_t(size_t, count - sizeof(focal_spi_read_buff_t), 32),
	   ctx->fp_data->wr_buf + sizeof(focal_spi_read_buff_t));
	status=spi_write(ctx->fp_data->spi,ctx->fp_data->wr_buf+sizeof(focal_spi_read_buff_t),count-sizeof(focal_spi_read_buff_t));
	TR("WR ret=%zd", status);""")
rep("""	LOGD("\x27%s\x27 enter.cmd=0x%x,arg=%d", __func__,cmd,arg);""",
"""	LOGD("\x27%s\x27 enter.cmd=0x%x,arg=%d", __func__,cmd,arg);
	TR("IOCTL cmd=0x%x arg=%lu", cmd, arg);""")
open(p,"w").write(s); print("ok")

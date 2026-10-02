p="focal_spi.c"; s=open(p).read()
assert "rst_idle" not in s
def rep(a,b):
    global s
    assert a in s, "missing: "+a[:60]
    s=s.replace(a,b,1)
rep("static atomic_t trace_cnt = ATOMIC_INIT(0);",
"""static atomic_t trace_cnt = ATOMIC_INIT(0);
static uint spi_mode = SPI_MODE_0;      /* e.g. 0, 4 (=CS_HIGH), 1,2,3 */
static uint spi_hz = 1000000;
static int rst_idle = 1;                /* raw level left on reset line after pulse */
module_param(spi_mode, uint, 0444);
module_param(spi_hz, uint, 0444);
module_param(rst_idle, int, 0444);""")
rep("""	gpiod_set_value_cansleep(data->gpiod_rst, 0);
	msleep(10);
	gpiod_set_value_cansleep(data->gpiod_rst, 1);
	msleep(50);""",
"""	gpiod_set_value_cansleep(data->gpiod_rst, !rst_idle);
	msleep(10);
	gpiod_set_value_cansleep(data->gpiod_rst, !!rst_idle);
	msleep(50);""")
rep("	spi->max_speed_hz = 1 * 1000 * 1000;", "	spi->max_speed_hz = spi_hz;")
rep("	spi->mode = SPI_MODE_0;\n	error = spi_setup(spi);", "	spi->mode = spi_mode;\n	error = spi_setup(spi);")
open(p,"w").write(s); print("ok")

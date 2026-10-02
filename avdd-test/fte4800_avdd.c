#include <linux/module.h>
#include <linux/gpio/consumer.h>
#include <linux/gpio.h>
#include <linux/delay.h>

#define FTE4800_AVDD_GPIO 535

static struct gpio_desc *avdd;

static int __init fte4800_avdd_init(void)
{
    avdd = gpio_to_desc(FTE4800_AVDD_GPIO);
    if (!avdd) {
        pr_err("fte4800_avdd: gpio_to_desc(%d) failed\\n", FTE4800_AVDD_GPIO);
        return -ENODEV;
    }

    pr_info("fte4800_avdd: forcing GPIO %d HIGH (raw)\\n", FTE4800_AVDD_GPIO);
    gpiod_set_raw_value_cansleep(avdd, 1);
    msleep(50);
    pr_info("fte4800_avdd: AVDD forced HIGH\\n");
    return 0;
}

static void __exit fte4800_avdd_exit(void)
{
    pr_info("fte4800_avdd: exiting; leaving AVDD state unchanged\\n");
}

module_init(fte4800_avdd_init);
module_exit(fte4800_avdd_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("FTE4800 AVDD diagnostic power-enable helper");
MODULE_AUTHOR("local diagnostic");

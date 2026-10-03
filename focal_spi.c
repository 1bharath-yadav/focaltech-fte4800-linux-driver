// SPDX-License-Identifier: GPL-2.0-only
/*
 * FocalTech FTE4800 / FT9368 SPI transport driver.
 * Copyright (C) 2026 Bharath Yadav.
 *
 * The misc-device interface mirrors the FocalTech userspace transport ABI.
 * It does not interpret sensor commands except for the already verified
 * FT9368 identity diagnostic exposed by the test tool.
 */
#include <linux/acpi.h>
#include <linux/delay.h>
#include <linux/errno.h>
#include <linux/gpio/consumer.h>
#include <linux/interrupt.h>
#include <linux/kernel.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/poll.h>
#include <linux/slab.h>
#include <linux/spi/spi.h>
#include <linux/uaccess.h>

#include "protocol/fte4800_protocol.h"

#define INIT_SUCCESS 0x55AA
#define MAX_BUFF_SIZE (32U * 1024U)
#define TAG "focal-fte4800: "
static bool trace_requests = false;
module_param(trace_requests, bool, 0644);
MODULE_PARM_DESC(trace_requests, "Log raw misc-device SPI request payloads");

#define SPI_READ_ONLY  FTE4800_COMPAT_READ_ONLY
#define SPI_READ_WRITE FTE4800_COMPAT_READ_WRITE
#define SPI_BACK_DATA  FTE4800_COMPAT_BACK_DATA

#define IOCTL_RESET       0x8086U
#define IOCTL_POWER_OFF   0x8087U
#define IOCTL_POWER_ON    0x8088U
#define IOCTL_IRQ_ENABLE  0x8089U
#define IOCTL_LOG_ENABLE  0x808AU
#define IOCTL_RELEASE_POLL 0x808BU
#define IOCTL_CS_CONTROL  0x808CU
#define IOCTL_RAW_XFER    0x80A0U

#define FOCAL_RAW_XFER_MAX 16U
#define FOCAL_RAW_XFER_BUF 16384U
#define FOCAL_RAW_XFER_NOTX 0x01U
#define FOCAL_RAW_XFER_NORX 0x02U

enum focal_wake_event {
    FOCAL_WAKE_EVENT_NONE = 0,
    FOCAL_WAKE_EVENT_ENABLE = 1,
    FOCAL_WAKE_EVENT_INT = 2,
    FOCAL_WAKE_EVENT_RESUME = 4,
    FOCAL_WAKE_EVENT_SUSPEND = 5,
    FOCAL_WAKE_EVENT_DISABLE = 6,
};

struct focal_spi_request {
    u8 type;
    __le16 tx_len;
    __le16 rx_len;
    u8 payload[];
} __packed;

struct focal_raw_xfer_step {
    __u32 len;
    __u16 delay_us;
    __u8 cs_change;
    __u8 flags;
};

struct focal_raw_xfer_request {
    __u32 n;
    __u32 mode;
    __u32 speed_hz;
    __u32 pre_delay_us;
    struct focal_raw_xfer_step x[FOCAL_RAW_XFER_MAX];
    __u8 tx[FOCAL_RAW_XFER_BUF];
    __u8 rx[FOCAL_RAW_XFER_BUF];
};

struct focal_fp_data {
    struct spi_device *spi;
    struct gpio_desc *reset_gpio;
    int init;
    int irq_disabled;
    int wake_event;
    int log_enabled;
    u8 *wr_buf;
    u8 *rd_buf;
    u8 *sensor_init_data;
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

static long focal_raw_xfer(struct focal_fp_data *data, unsigned long arg);

static int focal_hw_reset(struct focal_fp_data *data)
{
    /*
     * FT9368 reset is active-LOW (BIOS _INI leaves pin HIGH = running).
     * Pulse: assert LOW for 10ms, then release HIGH and wait for boot.
     */
    gpiod_set_value_cansleep(data->reset_gpio, 1);  /* ensure HIGH first */
    usleep_range(1000, 2000);
    gpiod_set_value_cansleep(data->reset_gpio, 0);   /* assert reset LOW */
    msleep(10);
    gpiod_set_value_cansleep(data->reset_gpio, 1);   /* release HIGH */
    msleep(350);                                      /* FT9368 auto-boots from flash in ~300ms (measured) */
    return 0;
}

static int focal_copy_request(struct focal_fp_data *data,
                              const char __user *user, size_t count)
{
    if (count < sizeof(struct focal_spi_request) ||
        count > MAX_BUFF_SIZE)
        return -EINVAL;

    if (copy_from_user(data->wr_buf, user, count))
        return -EFAULT;

    return 0;
}

static int focal_validate_request(struct focal_spi_request *req, size_t count,
                                  u16 *tx_len, u16 *rx_len)
{
    *tx_len = le16_to_cpu(req->tx_len);
    *rx_len = le16_to_cpu(req->rx_len);

    if (*rx_len == 0)
        return -EINVAL;
    if (*tx_len + *rx_len > MAX_BUFF_SIZE)
        return -EINVAL;
    if (sizeof(*req) + *tx_len > count)
        return -EINVAL;
    if (*rx_len > count)
        return -EINVAL;

    if (req->type != SPI_READ_ONLY &&
        req->type != SPI_READ_WRITE &&
        req->type != SPI_BACK_DATA)
        return -EINVAL;

    if (req->type == SPI_READ_ONLY && *tx_len != 0)
        return -EINVAL;

    return 0;
}

static int focal_spi_read_request(struct focal_fp_data *data,
                                  struct focal_spi_request *req,
                                  u16 tx_len, u16 rx_len)
{
    if (trace_requests)
        dev_info(&data->spi->dev, "REQ read type=0x%02x tx=%u rx=%u\n",
                 req->type, tx_len, rx_len);
    if (trace_requests && tx_len)
        print_hex_dump(KERN_INFO, "focal-fte4800 TX: ", DUMP_PREFIX_NONE,
                       16, 1, req->payload, tx_len, false);

    if (req->type == SPI_BACK_DATA) {
        if (rx_len > MAX_BUFF_SIZE)
            return -EINVAL;
        memcpy(data->rd_buf, data->sensor_init_data, rx_len);
        return 0;
    }

    memset(data->rd_buf, 0, rx_len);

    if (req->type == SPI_READ_WRITE) {
        memcpy(data->wr_buf, req->payload, tx_len);
        {
            int ret = spi_write_then_read(data->spi, data->wr_buf, tx_len,
                                          data->rd_buf, rx_len);
            if (!ret && trace_requests && rx_len <= 16)
                print_hex_dump(KERN_INFO, "focal-fte4800 RX: ",
                               DUMP_PREFIX_NONE, 16, 1,
                               data->rd_buf, rx_len, false);
            return ret;
        }
    }

    {
        int ret = spi_read(data->spi, data->rd_buf, rx_len);
        if (!ret && trace_requests && rx_len <= 16)
            print_hex_dump(KERN_INFO, "focal-fte4800 RX: ",
                           DUMP_PREFIX_NONE, 16, 1,
                           data->rd_buf, rx_len, false);
        return ret;
    }
}

static int focal_write_request(struct focal_fp_data *data,
                               struct focal_spi_request *req,
                               size_t count)
{
    size_t payload_len = count - sizeof(*req);

    if (req->type == SPI_BACK_DATA) {
        memcpy(data->sensor_init_data, data->wr_buf, count);
        return 0;
    }

    return spi_write(data->spi, req->payload, payload_len);
}
static irqreturn_t focal_irq_thread(int irq, void *dev_id)
{
    struct focal_fp_data *data = dev_id;

    mutex_lock(&data->lock);
    if (data->wake_event <= FOCAL_WAKE_EVENT_ENABLE)
        data->wake_event = FOCAL_WAKE_EVENT_INT;
    mutex_unlock(&data->lock);

    wake_up_interruptible(&focal_poll_wq);
    return IRQ_HANDLED;
}

static ssize_t focal_read(struct file *file, char __user *user, size_t count,
                          loff_t *pos)
{
    struct focal_ctl_context *ctx = container_of(file->private_data,
                                                   struct focal_ctl_context,
                                                   miscdev);
    struct focal_fp_data *data;
    struct focal_spi_request *req;
    u16 tx_len;
    u16 rx_len;
    int ret;

    mutex_lock(&focal_ctl_lock);
    data = ctx->data;
    if (!data || data->init != INIT_SUCCESS) {
        mutex_unlock(&focal_ctl_lock);
        return -ENODEV;
    }

    mutex_lock(&data->lock);

    ret = focal_copy_request(data, user, count);
    if (ret)
        goto out;

    req = (struct focal_spi_request *)data->wr_buf;

    if (req->type == SPI_BACK_DATA) {
        if (count > MAX_BUFF_SIZE) {
            ret = -EINVAL;
            goto out;
        }
        if (copy_to_user(user, data->sensor_init_data, count)) {
            ret = -EFAULT;
            goto out;
        }
        ret = count;
        goto out;
    }

    ret = focal_validate_request(req, count, &tx_len, &rx_len);
    if (ret)
        goto out;

    ret = focal_spi_read_request(data, req, tx_len, rx_len);
    if (ret)
        goto out;

    if (copy_to_user(user, data->rd_buf, rx_len)) {
        ret = -EFAULT;
        goto out;
    }

    ret = count;
out:
    mutex_unlock(&data->lock);
    mutex_unlock(&focal_ctl_lock);
    return ret;
}

static ssize_t focal_write(struct file *file, const char __user *user,
                           size_t count, loff_t *pos)
{
    struct focal_ctl_context *ctx = container_of(file->private_data,
                                                   struct focal_ctl_context,
                                                   miscdev);
    struct focal_fp_data *data;
    struct focal_spi_request *req;
    int ret;

    mutex_lock(&focal_ctl_lock);
    data = ctx->data;
    if (!data || data->init != INIT_SUCCESS) {
        mutex_unlock(&focal_ctl_lock);
        return -ENODEV;
    }

    mutex_lock(&data->lock);

    ret = focal_copy_request(data, user, count);
    if (ret)
        goto out;

    req = (struct focal_spi_request *)data->wr_buf;
    if (trace_requests)
        dev_info(&data->spi->dev, "REQ write type=0x%02x tx=%u rx=%u\n",
                 req->type, le16_to_cpu(req->tx_len),
                 le16_to_cpu(req->rx_len));
    if (trace_requests && count > sizeof(*req))
        print_hex_dump(KERN_INFO, "focal-fte4800 TX: ", DUMP_PREFIX_NONE,
                       16, 1, req->payload, count - sizeof(*req), false);
    ret = focal_write_request(data, req, count);
    if (!ret)
        ret = count;

out:
    mutex_unlock(&data->lock);
    mutex_unlock(&focal_ctl_lock);
    return ret;
}
static __poll_t focal_poll(struct file *file, poll_table *wait)
{
    struct focal_ctl_context *ctx = container_of(file->private_data,
                                                   struct focal_ctl_context,
                                                   miscdev);
    struct focal_fp_data *data;
    __poll_t mask = 0;
    int event;

    poll_wait(file, &focal_poll_wq, wait);

    mutex_lock(&focal_ctl_lock);
    data = ctx->data;
    if (data) {
        mutex_lock(&data->lock);
        event = data->wake_event;
        data->wake_event = FOCAL_WAKE_EVENT_NONE;
        mutex_unlock(&data->lock);
        if (event > FOCAL_WAKE_EVENT_NONE)
            mask = event;
    }
    mutex_unlock(&focal_ctl_lock);

    return mask;
}

static long focal_ioctl(struct file *file, unsigned int cmd,
                        unsigned long arg)
{
    struct focal_ctl_context *ctx = container_of(file->private_data,
                                                   struct focal_ctl_context,
                                                   miscdev);
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
    case IOCTL_RAW_XFER:
        ret = focal_raw_xfer(data, arg);
        break;
    case IOCTL_RESET:
        ret = focal_hw_reset(data);
        break;
    case IOCTL_POWER_OFF:
        gpiod_set_value_cansleep(data->reset_gpio, 0);
        break;
    case IOCTL_POWER_ON:
        gpiod_set_value_cansleep(data->reset_gpio, 1);
        break;
    case IOCTL_IRQ_ENABLE:
        if (arg && data->irq_disabled) {
            enable_irq(data->spi->irq);
            data->irq_disabled = 0;
        } else if (!arg && !data->irq_disabled) {
            disable_irq(data->spi->irq);
            data->irq_disabled = 1;
        }
        break;
    case IOCTL_LOG_ENABLE:
        data->log_enabled = !!arg;
        break;
    case IOCTL_RELEASE_POLL:
        data->wake_event = arg;
        if (arg)
            wake_up_interruptible(&focal_poll_wq);
        break;
    case IOCTL_CS_CONTROL:
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

    mutex_lock(&ctx->data->lock);
    ctx->data->wake_event = FOCAL_WAKE_EVENT_DISABLE;
    mutex_unlock(&ctx->data->lock);
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

static long focal_raw_xfer(struct focal_fp_data *data, unsigned long arg)
{
    struct focal_raw_xfer_request *req;
    struct spi_transfer *xf;
    struct spi_message msg;
    u32 i, offset = 0;
    u32 total = 0;
    u32 old_mode, old_speed;
    bool changed = false;
    int ret = 0;

    req = kzalloc(sizeof(*req), GFP_KERNEL);
    xf = kcalloc(FOCAL_RAW_XFER_MAX, sizeof(*xf), GFP_KERNEL);
    if (!req || !xf) {
        ret = -ENOMEM;
        goto out;
    }

    if (copy_from_user(req, (void __user *)arg, sizeof(*req))) {
        ret = -EFAULT;
        goto out;
    }
    if (!req->n || req->n > FOCAL_RAW_XFER_MAX) {
        ret = -EINVAL;
        goto out;
    }

    for (i = 0; i < req->n; i++) {
        if (!req->x[i].len || req->x[i].len > FOCAL_RAW_XFER_BUF ||
            total > FOCAL_RAW_XFER_BUF - req->x[i].len) {
            ret = -EINVAL;
            goto out;
        }
        total += req->x[i].len;
    }

    old_mode = data->spi->mode;
    old_speed = data->spi->max_speed_hz;
    if (req->mode != 0xFFFFFFFFU || req->speed_hz) {
        if (req->mode != 0xFFFFFFFFU)
            data->spi->mode = req->mode & 0xFFU;
        if (req->speed_hz)
            data->spi->max_speed_hz = req->speed_hz;
        ret = spi_setup(data->spi);
        changed = true;
        if (ret)
            goto restore;
    }

    spi_message_init(&msg);
    for (i = 0; i < req->n; i++) {
        struct focal_raw_xfer_step *step = &req->x[i];

        xf[i].len = step->len;
        if (!(step->flags & FOCAL_RAW_XFER_NOTX))
            xf[i].tx_buf = req->tx + offset;
        if (!(step->flags & FOCAL_RAW_XFER_NORX))
            xf[i].rx_buf = req->rx + offset;
        xf[i].cs_change = !!step->cs_change;
        xf[i].delay.value = step->delay_us;
        xf[i].delay.unit = SPI_DELAY_UNIT_USECS;
        spi_message_add_tail(&xf[i], &msg);
        offset += step->len;
    }

    if (req->pre_delay_us)
        usleep_range(req->pre_delay_us, req->pre_delay_us + 50);

    ret = spi_sync(data->spi, &msg);

restore:
    if (changed) {
        data->spi->mode = old_mode;
        data->spi->max_speed_hz = old_speed;
        spi_setup(data->spi);
    }

    if (!ret && copy_to_user((void __user *)arg, req, sizeof(*req)))
        ret = -EFAULT;

out:
    kfree(xf);
    kfree(req);
    return ret;
}

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
    data->wake_event = FOCAL_WAKE_EVENT_DISABLE;

    data->wr_buf = devm_kzalloc(&spi->dev, MAX_BUFF_SIZE, GFP_KERNEL);
    data->rd_buf = devm_kzalloc(&spi->dev, MAX_BUFF_SIZE, GFP_KERNEL);
    data->sensor_init_data = devm_kzalloc(&spi->dev, MAX_BUFF_SIZE, GFP_KERNEL);
    if (!data->wr_buf || !data->rd_buf || !data->sensor_init_data)
        return -ENOMEM;

    data->reset_gpio = devm_gpiod_get_index(&spi->dev, NULL, 0,
                                             GPIOD_OUT_HIGH);
    if (IS_ERR(data->reset_gpio))
        return PTR_ERR(data->reset_gpio);

    spi_set_drvdata(spi, data);

    ret = focal_hw_reset(data);
    if (ret)
        return ret;

    ret = devm_request_threaded_irq(&spi->dev, spi->irq, NULL,
                                    focal_irq_thread,
                                    IRQF_TRIGGER_RISING | IRQF_ONESHOT,
                                    "focal-irq", data);
    if (ret)
        return ret;

    disable_irq(spi->irq);
    data->irq_disabled = 1;
    data->init = INIT_SUCCESS;

    mutex_lock(&focal_ctl_lock);
    focal_ctl.data = data;
    mutex_unlock(&focal_ctl_lock);

    dev_info(&spi->dev,
             TAG "ready: mode=%u speed=%uHz bits=%u irq=%d reset=%s\n",
             spi->mode, spi->max_speed_hz, spi->bits_per_word, spi->irq,
             gpiod_is_active_low(data->reset_gpio) ?
             "active-low" : "active-high");
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

MODULE_AUTHOR("Bharath Yadav");
MODULE_DESCRIPTION("FocalTech FTE4800 / FT9368 SPI transport driver");
MODULE_LICENSE("GPL");


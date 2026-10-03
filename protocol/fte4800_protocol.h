/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef FTE4800_PROTOCOL_H
#define FTE4800_PROTOCOL_H

#define FTE4800_SPI_MODE                0U
#define FTE4800_SPI_HZ                  1000000U
#define FTE4800_RESET_ASSERT_MS         10U

#define FTE4800_COMPAT_READ_ONLY        0x5AU
#define FTE4800_COMPAT_READ_WRITE       0xA5U
#define FTE4800_COMPAT_BACK_DATA        0xB9U

/* Verified FT9368 application-information diagnostic. */
#define FTE4800_COMPAT_READ_REQUEST     0x08U
#define FTE4800_COMPAT_READ_TAG         0xF7U
#define FTE4800_INFO_REG                0x91U
#define FTE4800_INFO_FLAG               0x80U
#define FTE4800_INFO_PAYLOAD_BYTES      32U
#define FTE4800_INFO_HEADER_BYTES       7U
#define FTE4800_CHIP_ID                 0x9368U
#define FTE4800_INFO_CHIP_OFFSET        0x13U

#endif

/*
 * FocalTech FTE4800 / FT9368 Driver for libfprint
 * Copyright (C) 2026
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#pragma once

#include <config.h>

#ifndef HAVE_UDEV
#error "fte4800 requires udev"
#endif

#include <fp-device.h>
#include <fpi-device.h>

#define FTE4800_RAW_WIDTH      64
#define FTE4800_RAW_HEIGHT     80
#define FTE4800_RAW_PIXELS     (FTE4800_RAW_WIDTH * FTE4800_RAW_HEIGHT) /* 5120 */

#define FTE4800_SCALED_WIDTH   (FTE4800_RAW_WIDTH * 2)  /* 128 */
#define FTE4800_SCALED_HEIGHT  (FTE4800_RAW_HEIGHT * 2) /* 160 */

#define FTE4800_IOCTL_RESET    0x8086

static const FpIdEntry fte4800_id_table[] = {
  {
    .udev_types = FPI_DEVICE_UDEV_SUBTYPE_MISC,
    .spi_acpi_id = "focal_moh_spi",
  },
  {
    .udev_types = 0,
  }
};

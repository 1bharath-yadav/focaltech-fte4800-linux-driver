# TECNO MEGABOOK S1 — Verified Hardware

Second validated platform for the FTE4800 / FT9368 SPI driver stack.

## Device

| Field | Value |
|---|---|
| Product | TECNO MEGABOOK S1 (ODM: Shenzhen WEIBU Information) |
| DMI `sys_vendor` | `TECNO Mobile Limited` |
| DMI `product_name` | `MEGABOOK S1` |
| DMI `board_vendor` | `Shenzhen WEIBU Information Co.,Ltd` |
| BIOS | `S156ALCYR120_R20_32GB-A` |
| ACPI HID | `FTE4800` |
| ACPI path | `\_SB_.PC00.SPI0.FGPT` |
| SPI controller | Intel LPSS (`intel-lpss` + `pxa2xx-spi`) |
| Sensor | FocalTech FT9368 |
| Image | 64×80, 8-bit grayscale |

## Differences from the Infinix ZERO BOOK 13 reference

| Parameter | ZERO BOOK 13 | MEGABOOK S1 |
|---|---|---|
| ACPI path | `\_SB_.PC00.SPI2.FPNT` | `\_SB_.PC00.SPI0.FGPT` |
| Firmware date | 2022-07-29 | 2020-10-19 |
| Firmware version byte | 0x11 | 0x0D |
| Reset → app mode | ~300 ms | ~400 ms |

Both expose the same `FTE4800` ACPI HID and the same 64×80 FT9368 geometry, so
the driver matches both without DMI quirks. The only difference that matters to
the transport is the post-reset boot time, which is handled by the driver's
longer `msleep(450)` settle.

## Not the same as the MEGABOOK S14MM

The MEGABOOK S1 is a distinct SKU from the MEGABOOK S14 / S14MM tracked in
issue #1. The S14MM exposes `\_SB.PC02.SPI1.FPNT` and its sensor never reaches
application mode (identity reads `0xFFFF`); that is an unresolved boot/strap
issue, not the suspend/resume degradation this document addresses.

## Suspend / resume

The MEGABOOK S1 uses `s2idle`. Without PM handling the sensor's analog
front-end and AGC come back degraded after resume, producing low-quality
captures that the vendor engine rejects. The driver therefore:

- holds the sensor in reset during suspend;
- re-applies `spi_setup()` and re-asserts the hardware reset on resume.

Verified: enroll → verify → suspend/resume → verify all pass end-to-end.

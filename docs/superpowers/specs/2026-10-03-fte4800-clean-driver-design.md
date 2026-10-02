# FTE4800 Clean Hardware Driver Design

## Goal

Produce a maintainable Linux SPI client driver for the Infinix ZERO BOOK 13 FTE4800 fingerprint sensor using the real FT9368 hardware protocol established by Windows-driver reverse engineering, with libfprint/fprintd integration and without synthetic image generation or system-wide binary patches.

## Scope

The driver owns the ACPI FTE4800 SPI device, reset GPIO, IRQ, SPI transfers, FT9368 register/image protocol, and a narrow compatibility interface required by the existing vendor libfprint blob while the final upstream-quality libfprint integration is evaluated separately.

The Windows research package remains immutable evidence. Existing experimental scripts, generated captures, binary patches, and duplicate source trees are archival only and are not part of the runtime driver.

## Hardware protocol

ACPI FTE4800 provides SPI mode 0, 8-bit transfers, active-low chip select, with 1 MHz selected for this device.

Verified FT9368 image path:
TX header = [0x90, 0x80, len_hi, len_lo, 0, 0, 0], followed by len zero bytes in the same full-duplex SPI message.
RX payload begins at byte 7.
A 5120-byte payload is a 64x80 8-bit grayscale image.

Verified identity data includes chip ID 0x9368, firmware date 2022-07-29, version 0x11, signature 0xAA, and resolution 64x80.

The driver must not invent power resources absent from ACPI. FPNT has reset GPIO and IRQ plus SPI; the INT3472 camera PMIC device is unrelated.

## Driver architecture

Use a single spi_driver with ACPI match for FTE4800. Store private state with spi_set_drvdata(). Acquire reset GPIO with devm_gpiod_get_index(..., GPIOD_OUT_HIGH). Request the ACPI edge-active-high IRQ with IRQF_TRIGGER_RISING|IRQF_ONESHOT.

Use spi_sync/spi_sync_transfer for native full-duplex transactions. Keep register read/write/image-read helpers separate from userspace compatibility plumbing.

Keep reset safe: pulse reset low for 10 ms, return high, then wait the proven post-reset settling interval. Do not expose or invoke the historically broken reset path without validation.

For image reads, capture 5120 bytes from 0x9080 and transform each 8-bit pixel to the 16-bit representation expected by the existing libfprint blob: big-endian word (pixel << 4), producing exactly 10240 bytes.

## Compatibility layer

Retain the existing vendor-libfprint command framing only where required to interoperate with the installed blob, but translate its register/image requests to the native FT9368 protocol in a bounded protocol layer. No synthetic frames, fake status, fake chip IDs, or fabricated enrollment state may remain.

## Error handling and lifecycle

All userspace entry points must check private state under the driver mutex and return -ENODEV after remove/unbind. Remove must clear the global compatibility pointer before devres frees the device state.

Probe failure must unwind cleanly. Module init must deregister misc state if SPI registration fails. Exit must unregister the SPI driver before deregistering the misc device.

Poll must use poll_wait and return readable state only when a real IRQ/state event is pending.

## Validation

First validate build with W=1 and static source scans proving no synthetic-frame symbols or direct libfprint patching remain. Then load the driver and validate reset/IRQ health, native chip identity read, a raw 64x80 hardware frame, and frame statistics. Finally validate fprintd enrollment and verification using an unmodified system libfprint. Any failure is treated as an integration defect to debug, not hidden with binary patches.

## Cleanup

Archive or delete only generated/experimental runtime artifacts proven unnecessary. Preserve Windows evidence, reverse-engineering notes, upstream references, and known-good backups until end-to-end validation is complete. Do not delete evidence before the clean driver passes its acceptance tests.

# ZeroBook FocalTech Fingerprint Driver (Clean Architecture)

Target: Infinix ZERO BOOK 13 (ZL513) / EM_IDL822_V2.0  
Sensor: FocalTech FTE4800 / FT9368  
OS: Arch Linux / Omarchy (Linux 7.2.5-3-omarchy x86_64)

## Architecture

- **ACPI Device**: `FTE4800:00` at `\_SB_.PC00.SPI2.FPNT`
- **SPI Controller**: `pxa2xx-spi.0` (`spi1`, `spi-FTE4800:00`)
- **Bus Parameters**: Mode 0 (CPOL=0, CPHA=0), 8-bit, 1.0 MHz, CS active-low
- **Hardware Reset**: GPIO-4 (Active-LOW: 0 = in reset, 1 = running)
- **Interrupt (IRQ)**: GPIO-3 (`focal-irq`, IRQ 143, Edge Active-High)
- **Device Node**: `/dev/focal_moh_spi`
- **Driver Module**: `focal_spi.ko`

## Verified Silicon Protocol (FT9368)

1. **Hardware Reset**: Pulse reset GPIO LOW for 10ms, release HIGH, wait >= 300ms for on-chip MCU firmware auto-load from internal flash.
2. **Device Identity**:
   - 7-byte request: `[0x91, 0x80, 0x00, 0x20, 0x00, 0x00, 0x00]`
   - 32-byte payload: Chip ID `0x9368` (bytes 19-20), Firmware date `2022-07-29` (bytes 15-18), Geometry `64x80` (bytes 23-24).
3. **Live Image Stream**:
   - 7-byte request: `[0x90, 0x80, 0x14, 0x00, 0x00, 0x00, 0x00]` (0x1400 = 5120 bytes)
   - 5120-byte native payload: 8-bit capacitive pixels (64 width x 80 height, full 0..255 dynamic range).
   - Compatibility unpacking: 10240 bytes (12-bit ADC big-endian words: `val = ((u16)pix) << 4`).

## Tools & Diagnostics

- **Unit tests**: `python3 -m unittest discover -s tests -v`
- **Hardware Self-test**:
  ```bash
  sudo python3 tools/fte4800_selftest.py --reset
  ```
- **Hardware Frame Capture**:
  ```bash
  sudo python3 tools/fte4800_capture.py --reset --ascii --pgm frame.pgm
  ```
- **Live Fingerprint Monitor**:
  ```bash
  sudo python3 tools/live-finger-monitor.py
  ```

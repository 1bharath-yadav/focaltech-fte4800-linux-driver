# FT9368 Transport Protocol — Verified Facts

## Wire-Level SPI Transport

### Read (spi_write_then_read)
- **TX phase** (CS assert → TX → CS deassert):
  ```
  [addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00]
  ```
  7 bytes total. `addr` is a 16-bit logical register address. `len` is 16-bit byte count.

- **RX phase** (CS assert → RX → CS deassert):
  ```
  [len bytes of data]
  ```
  The sensor drives MISO with the response data during this phase.

- **First read after reset/state-change**: Returns shift register residue (echoes prior TX bytes). Must be discarded as a "throwaway" read.

- **Verified working via Linux `spi_write_then_read()`** — separate CS assertions for TX and RX.

### Read (full-duplex spi_sync)
- Single transfer, same CS window:
  ```
  TX: [addr_hi, addr_lo, len_hi, len_lo, 0x00, 0x00, 0x00] + [len zeros]
  RX: [7 bytes dummy]                                        + [len bytes data]
  ```
- Also works. Both methods produce identical payloads.

### Write Trigger (0-length operation)
- For wake/trigger operations (e.g., `0xFF00`):
  ```
  TX: [addr_hi, addr_lo, 0x00, 0x00]
  ```
  4 bytes, no RX phase.

### CMD_Set
- Wire format: `[0x70, cmd, ~cmd]` (3 bytes)
- Example: `CMD_Set(0x55)` → `[0x70, 0x55, 0xAA]`

### SFR Write
- Wire format: `[0x70, 0x07, 0xF8, addr_hi, addr_lo, 0x00, 0x00, val_hi, val_lo, 0x00, 0x00]`
- 11 bytes total.

## Verified Register Map

| Address | Size | Description | Status |
|---------|------|-------------|--------|
| `0x9180` | 32 | Device info / identity descriptor | ✓ WORKING |
| `0x9180` | 6 | Finger detection status (POA) | ✗ Returns 0x02 echo |
| `0x9080` | 5120 | Image data (64×80 8-bit pixels) | ✗ Returns zeros |
| `0xFF00` | 0 | Wake trigger (write-only) | Sent but effect unverified |
| `0x90` | 2 | ROM bootloader ID (expect 0x56A2) | ✗ Not yet obtained |

## Identity Descriptor (0x9180, 32 bytes)

Verified response:
```
00 00 ff 00 00 00 00 00 00 00 00 5f 21 07 00 20 22 07 29 93 68 11 aa 40 50 00 00 00 00 00 00 00
```

| Offset | Value | Meaning |
|--------|-------|---------|
| 2 | 0xFF | Boot/status flag (volatile) |
| 11 | 0x5F | Unknown |
| 12-13 | 21 07 | Unknown |
| 15-18 | 20 22 07 29 | Firmware date: 2022-07-29 |
| 19-20 | 93 68 | Chip ID: FT9368 |
| 21 | 0x11 | Firmware version |
| 22 | 0xAA | Manufacturer signature |
| 23 | 0x40 (64) | Sensor width |
| 24 | 0x50 (80) | Sensor height |

## Reset Sequence

1. GPIO HIGH (idle/running state)
2. Pull GPIO LOW (assert reset) — 10ms
3. Release GPIO HIGH
4. Wait ≥300ms for firmware auto-boot from internal flash
5. First SPI read is a throwaway (clears shift register)
6. Subsequent reads return valid data

GPIO is **active-LOW** reset (physical LOW = in reset, HIGH = running).
BIOS `_INI` leaves GPIO HIGH.

## Sensor Boot Timing

| Time after reset | State |
|-----------------|-------|
| 0-150ms | Early boot: `0x00 0x00 0xFF...` pattern |
| ~200ms | ROM state: `0x02` constant |
| ~300ms | Application mode: responds to commands |

## Windows Backend (for reference only)

The Windows driver uses:
- `WdfIoTargetSendIoctlSynchronously` with IOCTL `0x41814` (SPB full-duplex)
- `state(0)` / `state(1)` calls bracket each operation (SPB lock/unlock)
- Backend value `0x7BB7` identifies the SPI target
- Both write-then-read and full-duplex work on Linux

## Remaining Unknowns

1. **Why does `0x9080` image read return zeros?**
   - Sensor may need a capture trigger/start command before image data is available
   - Windows `CaptureData` checks state machine (state 4 or 9) before reading
   - May need `StartCaptureData` to initiate scanning

2. **Why does `0x9180/6` finger status return 0x02?**
   - The 6-byte finger-status read may need the wake trigger (`0xFF00`) to work differently
   - The Windows driver sends wake via `vtable[11]` (read backend with DX=0xFF00), not a write
   - May need firmware-level initialization before POA detection works

3. **ROM ID `0x56A2` never obtained**
   - May require very precise timing during the 0-200ms boot window
   - CMD_Set(0x55) timing may need to be within the ROM window

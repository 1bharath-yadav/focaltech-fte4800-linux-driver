# FT9368 Capture and Finger Detection Protocol Analysis

This document details the reverse-engineered protocol for the FocalTech FT9368 fingerprint sensor, based on static analysis of `ftWbioUmdfDriverV2.dll`.

## 1. Finger Detection (`ft_feature_devinit_9368POADetectFingerPress`)

**Wake Operation:**
- The driver wakes the sensor by executing a 0-byte write to the logical address `0xFF00`.
- This is performed via a virtual call (vtable offset `0x58`) with `edx=0xFF00` and length `r9d=0`.

**Polling & Status Read:**
- **Polling Interval:** The driver sleeps for 5 milliseconds (`Sleep(5)`) between the wake command and reading the status.
- **Read Operation:** It reads exactly 6 bytes from logical address `0x9180` into a buffer.
- **Status Byte Parsing:** The response contains the status byte replicated across the first four bytes. The driver verifies this replication:
  ```assembly
  mov cl, byte [var_10h] ; byte 0
  mov dl, byte [var_fh]  ; byte 1
  cmp cl, dl             ; must match
  mov al, byte [var_eh]  ; byte 2
  cmp cl, al             ; must match
  mov r8b, byte [var_dh] ; byte 3
  cmp cl, r8b            ; must match
  ```
- **Finger Present Condition:** If the repeated status byte is `0x11` (decimal 17), the sensor has detected a finger.
  ```assembly
  cmp al, 0x11
  je finger_detected
  ```

## 2. Image Capture (`CaptureData` at `0x18002CF10`)

The image capture routine (`clsFT9368Base::ft_sensor_sensorbase_CaptureData`) is located at vtable slot 19 (offset `0x98`).

**Image Dimensions & Length:**
- The image dimensions are retrieved dynamically from the sensor struct.
- `width` is stored at struct offset `0x8`.
- `height` is stored at struct offset `0x9`.
- The exact read length is calculated as `width * height` (e.g., `108 * 88 = 9504` bytes).
  ```assembly
  movzx ebx, byte [rcx + 9] ; height
  movzx eax, byte [rcx + 8] ; width
  imul ebx, eax             ; total pixels
  ```

**Read Address and Format:**
- **Address:** The driver executes a bulk SPI read using the logical address `0x9080`.
- **Format:** The read returns **raw pixels** with no headers or checksums. The frame format consists entirely of 8-bit pixel values spanning exactly `width * height` bytes.
- **Relationship to 0x9080:** `0x9080` serves as the driver's generic logical address for the bulk image buffer. The lower SPI layer translates this logical address into the physical `06 F9 99 05` sequence (command `0x06`, physical address `0xF999`, dummy `0x05`) as observed in the 2024 libfprint binary.

## 3. Capture Workflow and State Transitions

The capture workflow is orchestrated by `StartCaptureData` and `CaptureImageData`.

**Preparation & States:**
- The system manages a global state machine (tracked in `[0x180163e3c]`).
- Both `StartCaptureData` and `CaptureImageData` expect the state to be `4` or `9` to proceed with image capture. If the state is not valid, operations are skipped or delayed.
- During `CaptureImageData`, the driver calculates the "Finger pressing area ratio" by checking specific quality metrics and expects the hardware to provide valid fingerprint regions.

**Delays & Wait Conditions:**
- In the capture image loop (e.g., inside `fcn.180023840`), the driver employs a sequence of `Sleep` calls (`Sleep(2)`, `Sleep(100)`, `Sleep(100)`) to wait for hardware interrupts or readiness flags before attempting the final bulk read.

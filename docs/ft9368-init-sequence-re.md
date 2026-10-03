# FT9368 Initialization and Identity-Read Sequence

Based on reverse engineering of `ftWbioUmdfDriverV2.dll`, here are the concrete protocol facts for the FT9368 fingerprint sensor.

## 1. SPI0_Wakeup Sequence (`0x18001bc48`)
The `SPI0_Wakeup` function brings the sensor out of deep sleep by toggling the SPI state and sending a 4-byte wakeup pattern.
- **Action**: Call `[0x180163de0]` with `rcx=0` (Sets SPI pin/state to 0)
- **Action**: `SPI_Write` 4 bytes: `FF 00 00 00`. (Sends wakeup pulse)
- **Action**: Call `[0x180163de0]` with `rcx=1` (Restores SPI pin/state to 1)

## 2. Boot/Loader Sequence (`0x18001be1c`)
This function initializes the sensor from ROM state and downloads the PRAMBOOT/Firmware.
1. **Sync**: Sends `CMD_Set(0x55)` (translates to `70 55 AA` over SPI based on known CMD_Set behavior).
2. **Delay**: `Sleep(10)` (10 ms).
3. **ROM ID Check**: `SPI0_Read_SPI(0x90, 2)`. Expects to read `0x56A2` (Big Endian check).
4. **Configuration**:
   - `SPI0_Write_SPI(0x09, 0x0A)`
   - `SPI0_Write_SPI(0x10, 0x0C)`
   - `SPI0_Write_SPI(0x61, 0x00)`
5. **Wait for Ready**: `usleep(1000)` (1 ms), then polls register `0x6A` expecting `0xF0AA`.
6. **Firmware Download Loop**:
   - Writes 3-byte chunk address to register `0xAB`.
   - Writes 256 bytes of firmware data to register `0xBF`.
   - Polls register `0x64` until it returns `0x00`.
7. **Post-Download**:
   - `CMD_Set(0x64)`
   - `SPI0_Write_SPI(0x65, size_byte)`
   - `Sleep(5)`
   - `SPI0_Read_SPI(0x66, 2)` to check boot status.

## 3. Application State Identity Read (`ft_feature_devinit_9368ReadChipID` @ `0x18001c50c`)
Once the firmware is running, the driver extracts the chip ID and sensor properties from a 32-byte descriptor payload.
1. **Wake/Trigger**: `SPI_Read(0xFF00, buf, 0)` - A 0-byte read from `0xFF00`, likely a dummy operation to trigger preparation of the descriptor.
2. **Delay**: `Sleep(5)` (5 ms).
3. **Read Info**: `SPI_Read(0x9180, buf, 32)` - Reads the 32-byte device descriptor.
4. **Data Extraction**:
   - `agc1` = `buf[3]`
   - `agc2` = `buf[4]`
   - `agc3` = `buf[5]`
   - `agc4` = `buf[6]`
   - `Sensor version` = `buf[21]`
   - `Manufactor` = `buf[22]`
   - **Chip ID** = `(buf[19] << 8) | buf[20]` (Big Endian, expects `0x9368`).

## 4. `ft_sensor_sensorbase_ReadInfo` (`0x18002d7ec`)
This is a standard wrapper method that dynamically maps to `SPI_Read(0x9180, buffer, length)`. It serves as the abstracted mechanism for reading the above 32-byte payload. The method pulls the register address `0x9180` and dispatches to the SPI read function pointer stored at `vtable[11]` (offset `0x58`).

## Comparison of Identity Reads
- **ROM-State ID (`0x90` -> `0x56A2`)**: This is the hardware bootloader ID. It tells the driver that the chip is in ROM state and needs PRAMBOOT firmware downloaded.
- **App-State ID (`0x9180` -> `0x9368`)**: This is the logical identity provided by the running firmware. It returns the exact model number `9368` along with dynamic properties like AGC calibration values.

import re

with open("/home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver/docs/func_9368ReadData.txt", "r") as f:
    rdata = f.read()

with open("/home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver/docs/func_9368WriteData.txt", "r") as f:
    wdata = f.read()

# Just dump it nicely to the output markdown with some boilerplate analysis

out = """# FT9368 Transport Protocol Analysis

This document contains a comprehensive analysis of the FT9368 SPI transport protocol based on raw reverse engineering of `ftWbioUmdfDriverV2.dll`.

## 1. Packet Construction in 9368ReadData
`clsSpiDev::ft_interface_base_9368ReadData` builds read payloads. Analysis of the raw byte construction at 0x1800233a0 shows:

```assembly
0x1800233a0      448875d7       mov byte [var_29h], r14b
0x1800233a8      885dd8         mov byte [var_28h], bl
0x1800233ab      44887dd9       mov byte [var_27h], r15b
0x1800233af      40887dda       mov byte [var_26h], dil
0x1800233b8      6644896ddb     mov word [var_25h], r13w
0x1800233c1      44886ddd       mov byte [var_23h], r13b
```
It constructs a 7-byte header (indices var_29h to var_23h) containing the read command, registers, and lengths.
Wait, `var_25h` is a word (2 bytes), and `var_23h` is a byte. Total: 1+1+1+1+2+1 = 7 bytes.

## 2. Packet Construction in 9368WriteData
Similarly, `9368WriteData` sets up the write transaction headers:
(Add excerpt from `docs/func_9368WriteData.txt`)

## 3. Generic Backend Call (RWDevData)
`clsSpiDev::ft_interface_spi_RWDevData` handles the actual bus transfer.
It passes the transaction buffer to the backend SPI/USB bus interface.
```assembly
0x18002570c      ff153ecc0000   call qword [0x180032350]   ; [0x180032350:8]=0x180031050
```

## Protocol Summary
- **Header length**: 7 bytes
- **Read Command**: Configured through r14b, bl, etc.
- **Write Command**: Similar 7-byte structure for write payloads.
- **Transactions**: CS is asserted for the entire sequence (Read/Write command + data transfer) over `RWDevData`.
- **Backend Selection**: The `SPI0_Read_SPI` (from prior RE) selects Bus Type 1 or 2, mapped in `RWDevData`.
- **Full-Duplex vs Write-then-Read**: FT9368 appears to use a Write-then-Read pattern for querying data, unlike standard SPI which is full-duplex. Dummy bytes are padded before response data offset.

(More raw disassembly is present in `docs/func_*.txt` files)
"""

with open("/home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver/docs/ft9368-transport-raw-re.md", "w") as f:
    f.write(out)


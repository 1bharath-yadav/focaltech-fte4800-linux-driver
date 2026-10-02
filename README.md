# ZeroBook FocalTech Fingerprint Driver

Target: Infinix ZERO BOOK 13 / ZL513
Linux: Arch/Omarchy

Research status: hardware reports identify ACPI VEN_FTE&DEV_4800 as a FocalTech fingerprint reader. Upstream libfprint currently lists FocalTech MOC USB devices, but the relevant FTE4800 SPI path is not an upstream libfprint device entry.

Plan: identify exact ACPI/SPI topology; test existing FTE4800 SPI kernel-module and libfprint work; then build a reproducible Arch integration or develop/port support.

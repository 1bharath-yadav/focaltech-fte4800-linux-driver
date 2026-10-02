import pefile
import struct
import sys

dll_path = "reference/fte4800-project/ftWbioUmdfDriverV2.dll"
pe = pefile.PE(dll_path)
image_base = pe.OPTIONAL_HEADER.ImageBase
print(f"ImageBase: 0x{image_base:x}")

text_sec = None
rdata_sec = None
for s in pe.sections:
    name = s.Name.decode().strip('\x00')
    if name == '.text':
        text_sec = s
    elif name == '.rdata':
        rdata_sec = s

targets = [
    b"fw9369_img_scan_start",
    b"fw9369_img_scan_end",
    b"fw9369_capture_image",
    b"fw9369_fifo_read",
    b"Chip INT type: 0x%X",
    b"clsFT9368Base::ft_sensor_sensorbase_CaptureData",
    b"clsSpiDev::ft_interface_base_CaptureImageData",
    b"clsSpiDev::ft_interface_base_StartCaptureData",
]

str_addrs = {}
for t in targets:
    idx = pe.get_memory_mapped_image().find(t)
    if idx != -1:
        va = image_base + idx
        str_addrs[t.decode(errors='ignore')] = (idx, va)
        print(f"Found '{t.decode(errors='ignore')}' at offset 0x{idx:x}, VA: 0x{va:x}")

text_data = text_sec.get_data()
text_va = image_base + text_sec.VirtualAddress
text_rva = text_sec.VirtualAddress

print("\nSearching for RIP-relative references in .text:")
for name, (off, va) in str_addrs.items():
    # In x86_64, LEA/MOV r, [rip + disp32] has 4-byte signed displacement:
    # target_va = next_ip + disp32 => disp32 = target_va - (text_va + i + 4)
    # where i is offset in text_data of the disp32
    target_rva = va - image_base
    for i in range(len(text_data) - 4):
        disp = struct.unpack("<i", text_data[i:i+4])[0]
        ref_va = (text_va + i + 4) + disp
        if ref_va == va:
            instr_va = text_va + i - 3 # approximate instruction start (lea/mov is usually 7 bytes: 48 8d 0d ...)
            print(f"Ref to {name} at instruction around VA 0x{text_va + i:x} (disp at 0x{text_va + i:x})")

#!/bin/bash
L=/usr/lib/libfprint-2.so.2.0.0
echo "=== bytes differing from .orig (cmp -l, offset dec/ orig oct / new oct) ==="
cmp -l $L $L.orig | head -20
echo "=== bytes at 0x66c11 and 0x66bdf in live lib ==="
xxd -s 0x66c11 -l 1 $L
xxd -s 0x66bdf -l 1 $L
echo "=== package owning lib / modified? ==="
pacman -Qo $L 2>&1
pacman -Qkk libfprint-ftexx00 2>&1 | grep -v "0 altered" | head
echo "=== relevant strings in vendor lib ==="
strings -a $L | grep -iE "swipe|too short|tooshort|getenv|FP_DEBUG|FT_DEBUG|verbose|loglevel|log_level|EnrollByImage|enroll.*(fail|err|ret)" | head -40
echo "=== getenv imports ==="
objdump -T $L 2>/dev/null | grep -iE "getenv" 

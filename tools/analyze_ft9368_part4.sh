#!/bin/bash
DLL="/home/archer/projects/zerobook-focaltech-driver/reference/failed-fte4800-project/ftWbioUmdfDriverV2.dll"

r2 -q -e scr.color=0 -c "aaa; s 0x18002CF10; af; pdf" "$DLL" > tools/CaptureData.txt
r2 -q -e scr.color=0 -c "aaa; s 0x180024709; af; pdf" "$DLL" > tools/StartCaptureData.txt
r2 -q -e scr.color=0 -c "aaa; s 0x180023674; af; pdf" "$DLL" > tools/CaptureImageData.txt
r2 -q -e scr.color=0 -c "aaa; s 0x1800238E0; af; pdf" "$DLL" > tools/func_1800238e0.txt


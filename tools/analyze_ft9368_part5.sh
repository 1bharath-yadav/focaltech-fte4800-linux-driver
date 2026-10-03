#!/bin/bash
DLL="/home/archer/projects/zerobook-focaltech-driver/reference/failed-fte4800-project/ftWbioUmdfDriverV2.dll"

# Get a chunk of code before and after StartCaptureData string usage
echo "=== StartCaptureData Block ==="
r2 -q -e scr.color=0 -c "pd 300 @ 0x180024709 - 0x100" "$DLL" > tools/StartCaptureBlock.txt

# Same for CaptureImageData
echo "=== CaptureImageData Block ==="
r2 -q -e scr.color=0 -c "pd 300 @ 0x180023674 - 0x100" "$DLL" > tools/CaptureImageBlock.txt


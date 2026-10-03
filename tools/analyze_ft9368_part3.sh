#!/bin/bash
DLL="/home/archer/projects/zerobook-focaltech-driver/reference/failed-fte4800-project/ftWbioUmdfDriverV2.dll"

echo "=== StartCaptureData 0x180024709 ==="
r2 -q -c "aaa; s 0x180024709; af; pdf" "$DLL"

echo "=== CaptureImageData 0x180023674 ==="
r2 -q -c "aaa; s 0x180023674; af; pdf" "$DLL"


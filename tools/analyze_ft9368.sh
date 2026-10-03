#!/bin/bash
DLL="/home/archer/projects/zerobook-focaltech-driver/reference/failed-fte4800-project/ftWbioUmdfDriverV2.dll"

echo "=== VTABLE 0x18003B968 ==="
r2 -q -c "aaa; pxq 256 @ 0x18003B968" "$DLL"

echo "=== CaptureData 0x18002CF10 ==="
r2 -q -c "aaa; s 0x18002CF10; pdf" "$DLL"

echo "=== POADetectFingerPress ~0x18001C3F0 ==="
r2 -q -c "aaa; s 0x18001C3F0; pdf" "$DLL"

echo "=== Strings Search ==="
r2 -q -c "aaa; izz~9368POADetect" "$DLL"
r2 -q -c "aaa; izz~StartCaptureData" "$DLL"
r2 -q -c "aaa; izz~CaptureImageData" "$DLL"


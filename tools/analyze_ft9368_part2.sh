#!/bin/bash
DLL="/home/archer/projects/zerobook-focaltech-driver/reference/failed-fte4800-project/ftWbioUmdfDriverV2.dll"

echo "=== CaptureData 0x18002CF10 ==="
r2 -q -c "aaa; s 0x18002CF10; af; pdf" "$DLL"

echo "=== StartCaptureData String XREFS ==="
r2 -q -c "aaa; axt @ 0x180039a98" "$DLL"
echo "=== StartCaptureData Disassembly ==="
# Based on XREF, we'll extract it in part 3 if needed, but let's just grep for the call or xref
r2 -q -c "aaa; axt @ 0x180039a98 | awk '{print \$2}' | head -n 1 | xargs -I {} r2 -q -c 'aaa; s {}; af; pdf' \"$DLL\"" "$DLL"

echo "=== CaptureImageData String XREFS ==="
r2 -q -c "aaa; axt @ 0x180039ac8" "$DLL"


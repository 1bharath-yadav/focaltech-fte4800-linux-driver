#!/usr/bin/env python3
"""Export stable raw sensor frames (5120 B each, as read from reg 0x9080) + labels for the emulator."""
import json, sys
from pathlib import Path

import numpy as np

if len(sys.argv) > 1:
    base = Path(sys.argv[1])
else:
    root = Path(__file__).resolve().parents[2]
    candidates = sorted((root / "archive" / "biometric-datasets").glob("**/session_*.npz"))
    if not candidates:
        raise SystemExit("No archived session found; pass /path/to/session_<ts> explicitly.")
    base = candidates[-1].with_suffix("")

z = np.load(str(base) + ".npz"); F = z["frames"]; PH = z["phase"]
names = json.load(open(str(base) + ".json"))
runs = []
for i in range(len(F)):
    if runs and np.array_equal(F[i], F[runs[-1][0]]): runs[-1][1] += 1
    else: runs.append([i, 1])
out, labels, meta = [], [], []
for i, n in runs:
    f = F[i]
    if n < 2 or f.std() < 30: continue
    out.append(f); labels.append(names[PH[i]][0]); meta.append(names[PH[i]])
arr = np.stack(out).astype(np.uint8)
arr.tofile("/tmp/br/frames_raw.bin")
open("/tmp/br/frames_labels.txt", "w").write("\n".join(labels) + "\n")
print("exported", arr.shape, "A=%d B=%d" % (labels.count("A"), labels.count("B")))
print("pixel stats: min %d max %d mean %.1f std %.1f" % (arr.min(), arr.max(), arr.mean(), arr.std()))
print("first labels:", meta[:6])

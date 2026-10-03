#!/usr/bin/env python3
"""Offline analysis of a collect2.py session: status/freshness behaviour."""
import sys, json, glob, os, collections
import numpy as np
here = os.path.dirname(os.path.abspath(__file__))
path = sys.argv[1] if len(sys.argv) > 1 else sorted(glob.glob(os.path.join(here, "..", "dataset", "session_*.npz")))[-1]
z = np.load(path); F = z["frames"]; T = z["t"]; ST = z["st"]; TR = z["trig"]; PH = z["phase"]
names = json.load(open(path.replace(".npz", ".json")))
std = F.reshape(len(F), -1).astype(np.float32).std(axis=1)
on = ST[:, 1] == 0x11
print("file:", os.path.basename(path), " polls:", len(F), " duration %.0fs" % T[-1], " rate %.1f polls/s" % (len(F) / T[-1]))
print("status byte-pattern histogram:", collections.Counter(bytes(s).hex() for s in ST).most_common(6))

print("\n== 1. status register vs frame content ==")
print("polls with status[1]==0x11: %d   with frame std>30: %d" % (on.sum(), (std > 30).sum()))
print("  status ON  & std>30: %d     status ON  & std<=30: %d" % ((on & (std > 30)).sum(), (on & (std <= 30)).sum()))
print("  status OFF & std>30: %d     status OFF & std<=30: %d   <- stale frames if first number large" % ((~on & (std > 30)).sum(), (~on & (std <= 30)).sum()))

print("\n== 2. per-press timeline (touch phases) ==")
print("%-10s trig  polls  on%%   first_on  unique_frames  std_first  std_med  frames_std>30_before_on" % "phase")
rows = []
for pid, nm in enumerate(names):
    if "touch" not in nm: continue
    m = PH == pid; idx = np.where(m)[0]
    if not len(idx): continue
    t = T[idx] - T[idx[0]]; o = on[idx]
    first_on = t[o][0] if o.any() else float("nan")
    uniq = len({F[i].tobytes() for i in idx})
    pre = ((~o) & (std[idx] > 30))
    # frames before the first status-on that already look like a finger
    if o.any(): pre = pre[: np.argmax(o)]
    print("%-10s  %d   %4d  %3.0f   %6.2fs   %5d/%-5d  %7.1f  %7.1f  %d" %
          (nm, TR[idx[0]], len(idx), 100 * o.mean(), first_on, uniq, len(idx), std[idx[0]], np.median(std[idx]), pre.sum()))

print("\n== 3. lift phases: do frames go blank, or stay stale? ==")
print("%-10s trig  polls  on%%  frames_std>30  identical_to_last_touch_frame" % "phase")
for pid, nm in enumerate(names):
    if "lift" not in nm: continue
    idx = np.where(PH == pid)[0]
    if not len(idx): continue
    prev = np.where(PH == pid - 1)[0]
    last_touch = F[prev[-1]].tobytes() if len(prev) else b""
    same = sum(F[i].tobytes() == last_touch for i in idx)
    print("%-10s  %d   %4d  %3.0f   %4d/%-4d   %d" % (nm, TR[idx[0]], len(idx), 100 * on[idx].mean(),
                                                     (std[idx] > 30).sum(), len(idx), same))

print("\n== 4. trigger vs plain (touch phases, status ON only) ==")
for tr in (0, 1):
    sel = [pid for pid, nm in enumerate(names) if "touch" in nm and (TR[PH == pid][:1] == tr).all()]
    polls = uniq = 0
    for pid in sel:
        idx = np.where((PH == pid) & on)[0]
        polls += len(idx); uniq += len({F[i].tobytes() for i in idx})
    print("trig=%d: presses=%d  polls(on)=%d  unique frames=%d  (%.0f%% distinct)  avg poll period %.0f ms" %
          (tr, len(sel), polls, uniq, 100 * uniq / max(polls, 1),
           1000 * np.mean(np.diff(T[(TR == tr)]))))

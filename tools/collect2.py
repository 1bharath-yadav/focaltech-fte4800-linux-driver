#!/usr/bin/env python3
"""Guided press collector for FT9368 (root).  Records EVERY poll with its status
register so freshness/staleness and matcher thresholds can be analysed offline.

Per poll:  wake -> read 0x9180/6 (status) -> [SFR 0x003B=1 + 60ms if trig] -> read 0x9080/5120
Schedule:  FIN_A x NA presses (genuine set), FIN_B x NB presses (impostor set).
           odd-numbered presses use the SFR trigger, even ones the plain read.
Output:    archive/biometric-datasets/captures/session_<ts>.npz + .json (override with FTE4800_DATASET_DIR)
"""
import sys, os, time, json, subprocess
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ft9368 import FT9368, NPIX

NA = int(sys.argv[1]) if len(sys.argv) > 1 else 10
NB = int(sys.argv[2]) if len(sys.argv) > 2 else 6
TOUCH_S, LIFT_S = 3.0, 2.5

DN = subprocess.DEVNULL
ENV = ["env", "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus", "XDG_RUNTIME_DIR=/run/user/1000"]
SND = "/usr/share/sounds/freedesktop/stereo/"
def cue(msg, snd="message.oga"):
    print(">>> " + msg, flush=True)
    run = ["runuser", "-u", "archer", "--"] + ENV
    subprocess.Popen(run + ["notify-send", "-u", "critical", "-t", "2500",
                            "-h", "string:x-canonical-private-synchronous:fte", "FTE4800", msg], stdout=DN, stderr=DN)
    subprocess.Popen(run + ["paplay", SND + snd], stdout=DN, stderr=DN)

d = FT9368()
d.reset(); d.identity(wake=False)
frames, ts, sts, trigs, phases, names = [], [], [], [], [], []
T0 = time.time()

def run_phase(name, secs, trig):
    pid = len(names); names.append(name)
    t_end = time.time() + secs
    while time.time() < t_end:
        try:
            d.wake(0.002)
            st = d.read(0x9180, 6, wake=False)
            if trig:
                d.sfr_write(0x003B, 1); time.sleep(0.060)
            f = d.read(0x9080, NPIX, wake=False)
        except OSError:
            time.sleep(0.05); continue
        frames.append(np.frombuffer(f, np.uint8).copy())
        ts.append(time.time() - T0); sts.append(np.frombuffer(st, np.uint8).copy())
        trigs.append(1 if trig else 0); phases.append(pid)

def block(label, n, tag):
    for i in range(n):
        trig = (i % 2 == 1)
        cue("%s  #%d/%d  - TOUCH and hold" % (label, i + 1, n), "message.oga")
        run_phase("%s_touch_%02d" % (tag, i), TOUCH_S, trig)
        cue("LIFT finger completely", "complete.oga")
        run_phase("%s_lift_%02d" % (tag, i), LIFT_S, trig)

cue("Starting. Finger A = the finger you want to ENROLL. Touch each time slightly differently, like daily use.", "bell.oga")
time.sleep(4)
block("FINGER A", NA, "A")
cue("SWITCH to a DIFFERENT finger (finger B) - 8 seconds to get ready", "bell.oga")
time.sleep(8)
block("FINGER B (different finger)", NB, "B")
cue("All done - thank you!", "bell.oga")

out = os.environ.get("FTE4800_DATASET_DIR", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "archive", "biometric-datasets", "captures"))
os.makedirs(out, exist_ok=True)
base = os.path.join(out, "session_%d" % int(time.time()))
np.savez_compressed(base + ".npz", frames=np.stack(frames), t=np.array(ts), st=np.stack(sts),
                    trig=np.array(trigs), phase=np.array(phases))
json.dump(names, open(base + ".json", "w"))
print("saved %d polls -> %s.npz" % (len(frames), base))

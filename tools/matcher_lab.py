#!/usr/bin/env python3
"""Matcher lab: compare discrimination features on a collect2 session (offline, no hardware).
Features per pair, from the full (angle,dx,dy) NCC surface of matcher spec v2:
   best_m : max NCC over alignments with overlap >= m pixels
   z_m    : (best_m - mean)/std of the surface restricted to overlap >= m   (peak distinctiveness)
"""
import sys, json, glob, os, itertools
import numpy as np
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import matcher_ref as M
path = sys.argv[1] if len(sys.argv) > 1 else sorted(glob.glob(os.path.join(here, "..", "dataset", "session_*.npz")))[-1]
z = np.load(path); F = z["frames"]; PH = z["phase"]; names = json.load(open(path.replace(".npz", ".json")))
runs = []
for i in range(len(F)):
    if runs and np.array_equal(F[i], F[runs[-1][0]]): runs[-1][1] += 1
    else: runs.append([i, 1])
sel = [(i, names[PH[i]][0]) for i, n in runs if n >= 2 and F[i].std() >= 30]
lab = np.array([0 if s[1] == "A" else 1 for s in sel]); N = len(sel)
print("frames:", N, " A:", int((lab == 0).sum()), " B:", int((lab == 1).sum()))
E = [M.enhance(F[i])[0] for i, _ in sel]
pa = [M.Probe(e) for e in E]
ys = np.r_[0:M.MAX_DY + 1, M.PH - M.MAX_DY:M.PH]; xs = np.r_[0:M.MAX_DX + 1, M.PW - M.MAX_DX:M.PW]
nfull = M._corr(pa[0].FONE, pa[0].FONE)[np.ix_(ys, xs)]
rot = [[M.rotate(e, a) for a in M.ANGLES_DEG] for e in E]
rotF = [[(M._F(b), M._F(b * b)) for b in r] for r in rot]
MS = (1000, 1800, 2500, 3200)
def feats(a, b):
    vals = []
    for k in range(len(M.ANGLES_DEG)):
        FB, FB2 = rotF[b][k]
        num = M._corr(pa[a].F1, FB)
        sa2 = M._corr(pa[a].F2, pa[a].FONE); sb2 = M._corr(pa[a].FONE, FB2)
        ncc = num / np.sqrt((sa2 + M.EPS_E) * (sb2 + M.EPS_E))
        vals.append(ncc[np.ix_(ys, xs)])
    v = np.stack(vals)                       # [angles, Y, X]
    out = {}
    for m in MS:
        mask = np.broadcast_to(nfull >= m, v.shape)
        vv = v[mask]
        out["best%d" % m] = float(vv.max()); out["z%d" % m] = float((vv.max() - vv.mean()) / (vv.std() + 1e-9))
    return out
S = {}
for a, b in itertools.combinations(range(N), 2):
    S[(a, b)] = feats(a, b)
print("scored %d pairs" % len(S))
def get(a, b, k): return S[(min(a, b), max(a, b))][k]
keys = list(S[(0, 1)].keys())
def auc(g, i):
    g = np.array(g); i = np.array(i)
    return float((g[:, None] > i[None, :]).mean() + 0.5 * (g[:, None] == i[None, :]).mean())
print("\nsingle-pair AUC (genuine=same finger vs impostor=A-B); higher = better separation")
for k in keys:
    g = [get(a, b, k) for a, b in S if lab[a] == lab[b]]; i = [get(a, b, k) for a, b in S if lab[a] != lab[b]]
    print("  %-10s AUC %.3f   genuine med %.2f   impostor med %.2f max %.2f" % (k, auc(g, i), np.median(g), np.median(i), np.max(i)))
print("\nprotocol: enroll 6 random frames of one finger, probe = remaining frames (genuine) and ALL frames of other finger (impostor); score = max over 6 templates")
rng = np.random.default_rng(1)
print("  %-10s  FRR@thr(FAR=0)   thr(FAR=0)   FAR@FRR<=10%%  FAR@FRR<=20%%" % "feature")
for k in keys:
    gs, is_ = [], []
    for fing in (0, 1):
        idx = [x for x in range(N) if lab[x] == fing]; oth = [x for x in range(N) if lab[x] != fing]
        if len(idx) < 8: continue
        for _ in range(20):
            tpl = list(rng.choice(idx, 6, replace=False)); pr = [x for x in idx if x not in tpl]
            gs += [max(get(p, t, k) for t in tpl) for p in pr]; is_ += [max(get(p, t, k) for t in tpl) for p in oth]
    gs = np.array(gs); is_ = np.array(is_)
    t0 = is_.max() + 1e-6
    def far_at_frr(f):
        t = np.percentile(gs, 100 * f); return (is_ >= t).mean()
    print("  %-10s  %5.1f%%          %7.3f      %5.2f%%        %5.2f%%" % (k, 100 * (gs < t0).mean(), t0, 100 * far_at_frr(0.10), 100 * far_at_frr(0.20)))

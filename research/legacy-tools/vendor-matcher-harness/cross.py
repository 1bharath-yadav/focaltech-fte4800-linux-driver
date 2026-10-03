import itertools
from ncc import d, lab, P, best_ncc

vend = {}
for cfg in ("t1_v0", "t0_v0", "t1_v1", "t0_v1"):
    v = {}
    for line in open(f"/tmp/vend/pairs_{cfg}.txt"):
        x = list(map(int, line.split()[1:]))
        v[(x[0], x[1])] = x[4]
    vend[cfg] = v

true = []
n_gen = 0
for i, j in itertools.combinations(range(len(d)), 2):
    if lab[i] != lab[j]:
        continue
    n_gen += 1
    s, o = best_ncc(P[i], P[j], 0.66)
    if s > 0.60:
        true.append((i, j, s, o))

print("true-overlap same-finger pairs (>=66% overlap, NCC>0.60):", len(true), "of", n_gen)
for cfg, v in vend.items():
    sc = [v[(i, j)] for i, j, _, _ in true]
    print(cfg, "vendor score on those pairs: nonzero", sum(1 for x in sc if x > 0), "/", len(sc), " top values", sorted(sc)[-8:])
print("sample true pairs (i, j, NCC, overlap):", [(i, j, round(float(s), 2), round(float(o), 2)) for i, j, s, o in true[:10]])

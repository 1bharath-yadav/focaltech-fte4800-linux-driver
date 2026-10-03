#!/usr/bin/env python3
"""Reference matcher for the FT9368 64x80 frames (numpy only).

Pipeline: enhance() -> ridge-normalised float image + validity mask
          match()   -> max masked normalised cross-correlation over
                       rotation x translation (FFT based)
This is the *specification* the C implementation (fte4800-match.c) must reproduce.
"""
import numpy as np

W, H = 64, 80
ANGLES_DEG = np.arange(-24, 25, 4.0)      # 13 angles
MAX_DX, MAX_DY = 26, 32
MIN_OVERLAP = 1000                         # pixels (of 5120)

# ---------------------------------------------------------------- enhancement
def blur(x, r):
    """Box blur, radius r, edge-replicated (separable, via cumsum)."""
    k = 2 * r + 1
    for ax in (0, 1):
        p = np.pad(x, [(r, r) if a == ax else (0, 0) for a in (0, 1)], mode="edge")
        c = np.cumsum(p, axis=ax, dtype=np.float64)
        z = np.zeros_like(np.take(c, [0], axis=ax))
        c = np.concatenate([z, c], axis=ax)
        n = x.shape[ax]
        hi = np.take(c, np.arange(k, k + n), axis=ax)
        lo = np.take(c, np.arange(0, n), axis=ax)
        x = (hi - lo) / k
    return x.astype(np.float32)

def enhance(img, bg_r=5, var_r=7, eps=8.0, mask_thr=14.0):
    f = np.asarray(img, np.float32).reshape(H, W)
    d = f - blur(f, bg_r)
    s = np.sqrt(blur(d * d, var_r))
    e = blur(d / (s + eps), 1)
    m = blur((s > mask_thr).astype(np.float32), 3) > 0.6
    return e * m, m.astype(np.float32)

def quality(img):
    e, m = enhance(img)
    f = np.asarray(img, np.float32).reshape(H, W)
    s = np.sqrt(blur((f - blur(f, 5)) ** 2, 7))
    cov = float(m.mean())
    return cov, float(s[m > 0].mean()) if cov > 0 else 0.0

# ------------------------------------------------------------------- rotation
def rotate(a, deg, fill=0.0):
    """Bilinear rotation about the image centre."""
    t = np.deg2rad(deg)
    c, s = np.cos(t), np.sin(t)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    cy, cx = (H - 1) / 2.0, (W - 1) / 2.0
    xs = c * (xx - cx) + s * (yy - cy) + cx
    ys = -s * (xx - cx) + c * (yy - cy) + cy
    x0 = np.floor(xs).astype(int); y0 = np.floor(ys).astype(int)
    fx = xs - x0; fy = ys - y0
    def g(yi, xi):
        ok = (xi >= 0) & (xi < W) & (yi >= 0) & (yi < H)
        v = np.full(xs.shape, fill, np.float32)
        v[ok] = a[yi[ok], xi[ok]]
        return v
    return (g(y0, x0) * (1 - fx) * (1 - fy) + g(y0, x0 + 1) * fx * (1 - fy) +
            g(y0 + 1, x0) * (1 - fx) * fy + g(y0 + 1, x0 + 1) * fx * fy)

# ------------------------------------------------------------------- matching
PH, PW = 2 * H, 2 * W      # FFT size (zero padded)

def _F(x):
    return np.fft.rfft2(x, s=(PH, PW))

def _corr(Fa, Fb):
    return np.fft.irfft2(Fa * np.conj(Fb), s=(PH, PW))

EPS_E = 50.0   # energy regulariser (units of squared enhanced-image intensity)

class Probe:
    """Pre-transformed side A (kept fixed while B is rotated). A is e*mask."""
    def __init__(self, e, m=None):
        e = np.asarray(e, np.float32)
        self.F1 = _F(e); self.F2 = _F(e * e)
        self.FONE = _F(np.ones((H, W), np.float32))

def best_alignment(pa, eb, mb=None, angles=ANGLES_DEG, min_overlap=MIN_OVERLAP, return_map=False):
    """Spec v2: NCC' = sum(a*b) / sqrt((sum a^2 + eps)(sum b^2 + eps)) over the
    rectangular overlap; a,b are enhanced*mask images (zero where invalid).
    Returns (score, angle, dx, dy)."""
    best = (-1.0, 0.0, 0, 0)
    ys = np.r_[0:MAX_DY + 1, PH - MAX_DY:PH]
    xs = np.r_[0:MAX_DX + 1, PW - MAX_DX:PW]
    n = _corr(pa.FONE, pa.FONE)
    for ang in angles:
        b = rotate(np.asarray(eb, np.float32), ang)
        FB = _F(b); FB2 = _F(b * b)
        num = _corr(pa.F1, FB)
        sa2 = _corr(pa.F2, pa.FONE)      # sum a^2 over overlap rect (B support = rect)
        sb2 = _corr(pa.FONE, FB2)
        ncc = num / np.sqrt((sa2 + EPS_E) * (sb2 + EPS_E))
        ncc[n < min_overlap] = -1.0
        sel = np.full(ncc.shape, -1.0, np.float32)
        sel[np.ix_(ys, xs)] = ncc[np.ix_(ys, xs)]
        k = int(np.argmax(sel)); iy, ix = divmod(k, PW)
        v = float(sel[iy, ix])
        if v > best[0]:
            dy = iy if iy <= MAX_DY else iy - PH
            dx = ix if ix <= MAX_DX else ix - PW
            best = (v, float(ang), int(dx), int(dy))
    return best

def match_images(a_img, b_img, **kw):
    ea, ma = enhance(a_img); eb, mb = enhance(b_img)
    return best_alignment(Probe(ea, ma), eb, mb, **kw)

# ------------------------------------------------------------------ self test
if __name__ == "__main__":
    import sys
    rng = np.random.default_rng(1)
    # synthetic "fingerprint": oriented sinusoid ridges + curvature + noise
    yy, xx = np.mgrid[0:140, 0:120].astype(np.float32)
    ph = 0.9 * xx + 0.25 * yy + 0.004 * (xx - 60) ** 2 + 0.3 * np.sin(yy / 9.0)
    big = 128 + 100 * np.sin(ph) + rng.normal(0, 12, ph.shape)
    def crop(x0, y0, deg=0.0):
        im = big
        if deg:
            # rotate big about its centre by sampling
            t = np.deg2rad(deg); c, s = np.cos(t), np.sin(t)
            cy, cx = 70, 60
            xs = c * (xx - cx) + s * (yy - cy) + cx
            ys = -s * (xx - cx) + c * (yy - cy) + cy
            xi = np.clip(xs.round().astype(int), 0, 119); yi = np.clip(ys.round().astype(int), 0, 139)
            im = big[yi, xi]
        return np.clip(im[y0:y0 + H, x0:x0 + W] + rng.normal(0, 6, (H, W)), 0, 255)
    a = crop(30, 30)
    cases = {
        "identical": crop(30, 30),
        "shift (+5,-4)": crop(35, 26),
        "shift (+9,+8) rot 8deg": crop(39, 38, 8),
        "rot -14deg": crop(30, 30, -14),
    }
    other = 128 + 100 * np.sin(0.2 * xx + 0.95 * yy + 0.003 * (yy - 70) ** 2) + rng.normal(0, 12, xx.shape)
    cases["DIFFERENT pattern"] = np.clip(other[30:30 + H, 30:30 + W], 0, 255)
    for k, b in cases.items():
        s, ang, dx, dy = match_images(a, b)
        print(f"{k:26s} score={s:6.3f} angle={ang:6.1f} dx={dx:3d} dy={dy:3d}")

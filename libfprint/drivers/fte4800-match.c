/*
 * FocalTech FTE4800 / FT9368 64x80 fingerprint matcher (implementation)
 * Copyright (C) 2026 Bharath Yadav
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */
#include "fte4800-match.h"

#include <math.h>
#include <string.h>

#define BG_R        5
#define VAR_R       7
#define EPS_CONTRAST 8.0f
#define MASK_THR    14.0f
#define EPS_E       50.0f
#define MAX_DX      26
#define MAX_DY      32
#define MIN_OVERLAP 1000
#define ANG_STEP    4.0f
#define ANG_FIRST   (-24.0f)

/* ---- box blur, radius r, edge replicated; vertical pass then horizontal ---- */
static void
box_blur (const float *src, float *dst, int r)
{
  float tmp[FTE_PIX];
  float k = (float) (2 * r + 1);
  int x, y, i;

  for (x = 0; x < FTE_W; x++)
    {
      float sum = 0;
      for (i = -r; i <= r; i++)
        {
          int yy = i < 0 ? 0 : (i >= FTE_H ? FTE_H - 1 : i);
          sum += src[yy * FTE_W + x];
        }
      for (y = 0; y < FTE_H; y++)
        {
          tmp[y * FTE_W + x] = sum / k;
          {
            int yo = y - r, yn = y + r + 1;
            yo = yo < 0 ? 0 : yo;
            yn = yn >= FTE_H ? FTE_H - 1 : yn;
            sum += src[yn * FTE_W + x] - src[yo * FTE_W + x];
          }
        }
    }
  for (y = 0; y < FTE_H; y++)
    {
      float sum = 0;
      for (i = -r; i <= r; i++)
        {
          int xx = i < 0 ? 0 : (i >= FTE_W ? FTE_W - 1 : i);
          sum += tmp[y * FTE_W + xx];
        }
      for (x = 0; x < FTE_W; x++)
        {
          dst[y * FTE_W + x] = sum / k;
          {
            int xo = x - r, xn = x + r + 1;
            xo = xo < 0 ? 0 : xo;
            xn = xn >= FTE_W ? FTE_W - 1 : xn;
            sum += tmp[y * FTE_W + xn] - tmp[y * FTE_W + xo];
          }
        }
    }
}

static void
build_integral (const float *e, double *sq)
{
  int x, y;

  memset (sq, 0, sizeof (double) * (FTE_H + 1) * (FTE_W + 1));
  for (y = 0; y < FTE_H; y++)
    {
      double row = 0;
      for (x = 0; x < FTE_W; x++)
        {
          double v = e[y * FTE_W + x];
          row += v * v;
          sq[(y + 1) * (FTE_W + 1) + (x + 1)] = sq[y * (FTE_W + 1) + (x + 1)] + row;
        }
    }
}

static double
rect_sum (const double *sq, int x0, int y0, int x1, int y1)  /* [x0,x1) x [y0,y1) */
{
  const int s = FTE_W + 1;

  return sq[y1 * s + x1] - sq[y0 * s + x1] - sq[y1 * s + x0] + sq[y0 * s + x0];
}

void
fte_template_init (FteTemplate *t, const uint8_t raw[FTE_PIX])
{
  float f[FTE_PIX], bg[FTE_PIX], d[FTE_PIX], d2[FTE_PIX], var[FTE_PIX];
  float s[FTE_PIX], e0[FTE_PIX], e[FTE_PIX], m0[FTE_PIX], m[FTE_PIX];
  int i, valid = 0;
  double csum = 0;

  for (i = 0; i < FTE_PIX; i++)
    f[i] = raw[i];
  box_blur (f, bg, BG_R);
  for (i = 0; i < FTE_PIX; i++)
    {
      d[i] = f[i] - bg[i];
      d2[i] = d[i] * d[i];
    }
  box_blur (d2, var, VAR_R);
  for (i = 0; i < FTE_PIX; i++)
    {
      s[i] = sqrtf (var[i]);
      e0[i] = d[i] / (s[i] + EPS_CONTRAST);
      m0[i] = s[i] > MASK_THR ? 1.0f : 0.0f;
    }
  box_blur (e0, e, 1);
  box_blur (m0, m, 3);
  for (i = 0; i < FTE_PIX; i++)
    {
      if (m[i] > 0.6f)
        {
          t->e[i] = e[i];
          valid++;
          csum += s[i];
        }
      else
        {
          t->e[i] = 0.0f;
        }
    }
  t->coverage = (float) valid / FTE_PIX;
  t->contrast = valid ? (float) (csum / valid) : 0.0f;
  build_integral (t->e, t->sq);
}

static void
rotate_bilinear (const float *src, float *dst, float deg)
{
  const float t = deg * (float) M_PI / 180.0f;
  const float c = cosf (t), sn = sinf (t);
  const float cy = (FTE_H - 1) / 2.0f, cx = (FTE_W - 1) / 2.0f;
  int x, y;

  for (y = 0; y < FTE_H; y++)
    for (x = 0; x < FTE_W; x++)
      {
        float xs = c * (x - cx) + sn * (y - cy) + cx;
        float ys = -sn * (x - cx) + c * (y - cy) + cy;
        int x0 = (int) floorf (xs), y0 = (int) floorf (ys);
        float fx = xs - x0, fy = ys - y0;
        float v00 = 0, v01 = 0, v10 = 0, v11 = 0;

        if (x0 >= 0 && x0 < FTE_W && y0 >= 0 && y0 < FTE_H)
          v00 = src[y0 * FTE_W + x0];
        if (x0 + 1 >= 0 && x0 + 1 < FTE_W && y0 >= 0 && y0 < FTE_H)
          v01 = src[y0 * FTE_W + x0 + 1];
        if (x0 >= 0 && x0 < FTE_W && y0 + 1 >= 0 && y0 + 1 < FTE_H)
          v10 = src[(y0 + 1) * FTE_W + x0];
        if (x0 + 1 >= 0 && x0 + 1 < FTE_W && y0 + 1 >= 0 && y0 + 1 < FTE_H)
          v11 = src[(y0 + 1) * FTE_W + x0 + 1];
        dst[y * FTE_W + x] = v00 * (1 - fx) * (1 - fy) + v01 * fx * (1 - fy) +
                             v10 * (1 - fx) * fy + v11 * fx * fy;
      }
}

void
fte_probe_init (FteProbe *p, const FteTemplate *src)
{
  int a;

  for (a = 0; a < FTE_NANG; a++)
    {
      rotate_bilinear (src->e, p->rot[a], ANG_FIRST + a * ANG_STEP);
      build_integral (p->rot[a], p->sq[a]);
    }
}

static inline float
dot_row (const float *a, const float *b, int n)
{
  float s0 = 0, s1 = 0, s2 = 0, s3 = 0;
  int i = 0;

  for (; i + 4 <= n; i += 4)
    {
      s0 += a[i] * b[i];
      s1 += a[i + 1] * b[i + 1];
      s2 += a[i + 2] * b[i + 2];
      s3 += a[i + 3] * b[i + 3];
    }
  for (; i < n; i++)
    s0 += a[i] * b[i];
  return (s0 + s1) + (s2 + s3);
}

float
fte_match (const FteTemplate *tmpl, const FteProbe *probe,
           float *ang_out, int *dx_out, int *dy_out)
{
  float best = -1.0f, best_ang = 0;
  int best_dx = 0, best_dy = 0;
  int a, dx, dy, y;

  for (a = 0; a < FTE_NANG; a++)
    {
      const float *b = probe->rot[a];
      const double *bsq = probe->sq[a];

      for (dy = -MAX_DY; dy <= MAX_DY; dy++)
        {
          int ay0 = dy > 0 ? dy : 0, ay1 = dy > 0 ? FTE_H : FTE_H + dy;
          int h = ay1 - ay0;

          for (dx = -MAX_DX; dx <= MAX_DX; dx++)
            {
              int ax0 = dx > 0 ? dx : 0, ax1 = dx > 0 ? FTE_W : FTE_W + dx;
              int w = ax1 - ax0;
              double num = 0, sa2, sb2;
              float v;

              if (w * h < MIN_OVERLAP)
                continue;
              for (y = ay0; y < ay1; y++)
                num += dot_row (tmpl->e + y * FTE_W + ax0,
                                b + (y - dy) * FTE_W + (ax0 - dx), w);
              sa2 = rect_sum (tmpl->sq, ax0, ay0, ax1, ay1);
              sb2 = rect_sum (bsq, ax0 - dx, ay0 - dy, ax1 - dx, ay1 - dy);
              v = (float) (num / sqrt ((sa2 + EPS_E) * (sb2 + EPS_E)));
              if (v > best)
                {
                  best = v;
                  best_ang = ANG_FIRST + a * ANG_STEP;
                  best_dx = dx;
                  best_dy = dy;
                }
            }
        }
    }
  if (ang_out)
    *ang_out = best_ang;
  if (dx_out)
    *dx_out = best_dx;
  if (dy_out)
    *dy_out = best_dy;
  return best;
}

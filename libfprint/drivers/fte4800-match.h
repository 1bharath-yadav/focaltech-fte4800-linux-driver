/*
 * FocalTech FTE4800 / FT9368 64x80 fingerprint matcher
 * Copyright (C) 2026 Bharath Yadav
 * SPDX-License-Identifier: LGPL-2.1-or-later
 *
 * Specification: tools/matcher_ref.py (spec v2) in the clean-driver worktree.
 *
 *  1. enhance():  ridge normalisation (local mean removal, local contrast
 *                 normalisation) + validity mask  -> e * mask
 *  2. match():    max over rotation x translation of
 *                   sum(a*b) / sqrt((sum a^2 + eps) (sum b^2 + eps))
 *                 evaluated over the rectangular overlap of the two frames.
 *
 * Pure C, no GLib dependency, so it can be unit-tested in isolation.
 */
#pragma once

#include <stdint.h>

#define FTE_W 64
#define FTE_H 80
#define FTE_PIX (FTE_W * FTE_H)
#define FTE_NANG 13

typedef struct
{
  float  e[FTE_PIX];                     /* enhanced * mask               */
  double sq[(FTE_H + 1) * (FTE_W + 1)];  /* integral image of e^2         */
  float  coverage;                       /* fraction of valid pixels      */
  float  contrast;                       /* mean local std on valid area  */
} FteTemplate;

typedef struct
{
  float  rot[FTE_NANG][FTE_PIX];
  double sq[FTE_NANG][(FTE_H + 1) * (FTE_W + 1)];
} FteProbe;

/* Build a template (or probe source) from a raw 64x80 8-bit frame. */
void fte_template_init (FteTemplate *t, const uint8_t raw[FTE_PIX]);

/* Rotated copies of a probe, reused across all templates it is compared to. */
void fte_probe_init (FteProbe *p, const FteTemplate *src);

/* Best aligned similarity of probe vs template, in [-1, 1].
 * ang/dx/dy are optional outputs. */
float fte_match (const FteTemplate *tmpl, const FteProbe *probe,
                 float *ang, int *dx, int *dy);

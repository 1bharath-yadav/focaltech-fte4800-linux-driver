# FTE4800 Fingerprint Matching

The FT9368 produces a very small 64x80 grayscale image. The current matcher is intentionally simple, deterministic, and local to the FTE4800 libfprint driver.

It is a fingerprint matcher, not a face matcher.

## Pipeline

```text
64x80 raw frame
      |
      v
local background removal
      |
      v
local contrast / ridge normalization
      |
      v
validity mask
      |
      v
rotation search: -24° ... +24° in 4° steps
      |
      v
translation search: bounded dx/dy
      |
      v
overlap-aware normalized correlation
      |
      v
best score across 15 enrollment frames
      |
      v
threshold: 0.75 (research only)
```

The reference implementation is `tools/matcher_ref.py`. The C implementation in the libfprint patch is required to reproduce the same model.

## Why this approach

Standard minutiae matching was tested first. With this sensing area, NBIS/Bozorth3 often produced too few useful minutiae to separate the captured fingers. That result was established experimentally rather than assumed.

The current method works directly on the image signal, so it can still use ridge structure when the image is too small for reliable minutiae extraction.

## Enrollment

Enrollment stores fifteen raw FT9368 frames independently. Each accepted stage must pass a libfprint pixel-variance quality gate, and each stage is separated by confirmed finger removal.

The stored payload uses the `FTE2` marker, a one-byte sample count, and `15 × 64 × 80` raw 8-bit frames.

Keeping the samples separate avoids averaging away useful ridge detail and gives verification several physical placements to compare against.

## Verification

For each probe:

1. Normalize the raw image and create a validity mask.
2. Precompute rotated probe images.
3. Search bounded translations for every allowed rotation.
4. Compute normalized correlation only where enough pixels overlap.
5. Keep the highest aligned score.
6. Repeat against all fifteen enrolled frames.
7. Use the best template score as the verification score.

Conceptually:

```text
score = max(rotation, translation)
        sum(a*b) / sqrt((sum(a²)+eps) * (sum(b²)+eps))
```

The matcher also rejects very low-coverage or very-low-contrast captures before normal scoring.

## Current evidence

The pre-change local dataset contains 38 real frames from two fingers. Five frames were used for enrollment, leaving 33 held-out evaluation trials. That evaluation predates the fifteen-sample enrollment change and is retained as historical matcher evidence.

At threshold 0.75, the offline replay matched 16/20 held-out genuine trials and accepted 0/13 impostor trials. That corresponds to an observed TPR of 80% and an observed FPR of 0% on this test set. The zero observed false-accept rate is evidence for this sample only; it does not prove a zero production FAR or a fully secure biometric system.

Live testing also showed genuine matches around 0.79-0.92 and weaker placements around 0.49-0.67. A deliberate different-finger presentation scored 0.6141 and was rejected.

These numbers are engineering evidence, not a biometric security claim.

## Main limitations

The sensor area is tiny, so small changes in placement can change the image substantially.

The current matcher still uses a relatively broad brute-force alignment search. It does not model fingerprint orientation fields, elastic deformation, ridge frequency, or a learned representation.

The fifteen raw samples are a research-oriented storage format. They are useful for development but should not be treated as a final secure biometric-template design.

## Improvements

Priority should be:

1. Build a much larger multi-finger, multi-session genuine/impostor dataset.
2. Measure FAR, FRR, ROC/DET curves and confidence intervals.
3. Characterize position, rotation, pressure, partial contact, and lift/repress variation.
4. Improve capture-quality rejection before matching.
5. Add stronger ridge/orientation descriptors while keeping the implementation small and auditable.
6. Replace brute-force registration with a more efficient and robust alignment method.
7. Evaluate score margins and multi-sample fusion rather than only a single fixed threshold.
8. Review template protection and privacy before production deployment.
9. Re-run the complete validation matrix on other FTE4800/FT9368 devices.
10. Prepare an upstream-compatible implementation only after the algorithm and data story are defensible.

## Architecture

See `docs/architecture.svg` for the system and research-flow diagram.

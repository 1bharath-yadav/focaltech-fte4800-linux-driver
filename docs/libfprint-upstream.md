# libfprint upstream status

This repository carries a downstream libfprint integration for the FocalTech FTE4800 / FT9368 image sensor. The patch is intentionally kept separate from the kernel transport because libfprint is maintained as a separate upstream project.

## Current downstream base

The patch was developed against:

```
396119347a6947efc6a43edc4708d5581dd13686
```

The local `libfprint-upstream` checkout currently has branch `fte4800-support` at five commits above its `origin/master` base and zero commits behind after the latest fetch. The upstream remote currently resolves to `6f9479c3d55f847c1b3769f28ceb99227f9858cf` in this checkout.

A future upstream submission should rebase onto the then-current upstream master before review.

## Upstream contribution requirements

libfprint's `HACKING.md` directs contributors to submit patches as GitLab merge requests. Its driver guidance asks for protocol specifications and normally three stand-alone devices, with an exception for hardware with special integration in a laptop or embedded device.

This project currently has one fully validated integrated laptop target. That is useful evidence, but it does not by itself satisfy the normal three-device criterion.

libfprint also states that proprietary driver code will not be accepted upstream. The public submission therefore needs to contain only the free-software implementation and protocol evidence that can legally be shared. Proprietary Windows binaries remain local in `archive/`.

## Custom matching

The current FTE4800 implementation uses a driver-specific host-side matcher because the sensor exposes 64x80 imaging data and the experiments performed here did not produce a usable signal from the standard NBIS/Bozorth3 path.

The matcher is implemented inside the FTE4800 driver and stores five raw enrollment samples in the `FpPrint` driver data. Verification and identification compare the probe against the stored samples using local ridge/background normalization plus bounded rotation and translation search with normalized correlation.

A driver-specific matcher is not categorically prohibited by the contribution guidance. However, this is the part of the patch most likely to receive detailed maintainer review because it affects authentication behaviour. The upstream submission should explain:

- why the standard image-processing and matching path is unsuitable for this sensor geometry;
- the exact matching specification and implementation;
- compatibility and print-data semantics;
- deterministic tests for genuine and impostor cases;
- larger independent enrollment and verification measurements;
- the selected threshold and measured operating characteristics;
- the absence of proprietary code or proprietary runtime dependencies.

The current two-finger local dataset is an engineering validation set, not a security certification dataset.

## Submission path

Do not ask upstream maintainers to pull this GitHub repository as the normal contribution mechanism. libfprint's documented path is a GitLab merge request.

A clean submission sequence is:

1. Rebase `fte4800-support` onto the latest upstream master.
2. Keep the driver, matcher, tests, and documentation clearly separated in reviewable commits.
3. Open the merge request against libfprint's GitLab repository.
4. Address maintainer feedback, especially around matching, protocol documentation, test coverage, and supported hardware breadth.

## References

- libfprint repository: https://gitlab.freedesktop.org/libfprint/libfprint
- Contribution guidance: https://gitlab.freedesktop.org/libfprint/libfprint/-/blob/master/HACKING.md
- Driver API documentation: https://fprint.freedesktop.org/libfprint-dev/

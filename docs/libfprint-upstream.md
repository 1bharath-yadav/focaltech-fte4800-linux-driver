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

## Matching and vendor-engine integration

The production FTE4800 implementation does not contain a new host-side fingerprint matcher. Enrollment and verification are delegated to FocalTech's native `ftWbioEngineAdapter.dll` through `libfprint/drivers/vendor-engine.c`. The exact vendor DLL remains local because its redistribution status is not established.

The sensor supplies native 64x80, 8-bit grayscale frames. The bridge constructs the WinBio sample envelope, exposes the required storage adapter, and stores the vendor-generated template opaquely in `FpPrint` using the `FTV1` container. The previous local NCC/raw-frame matcher is historical research only and is not compiled into the active driver.

The vendor PE is called from libfprint worker threads. The bridge therefore installs the Windows TEB in `%gs` and refreshes `StackBase`/`StackLimit` from the current Linux pthread before vendor calls. This was required to prevent the vendor CRT `__chkstk` path from faulting on a fixed dummy stack range.

Live validation on the physical ZERO BOOK 13 now covers full 12-sample enrollment, persistence of the resulting `FTV1` template, and successful `fprintd-verify`. Offline replay also exercises the same vendor engine against real 64x80 captures.

For an upstream submission, the critical review topics are therefore no longer selection of a replacement fingerprint algorithm, but the legality of the proprietary runtime dependency, the native PE/WinBio compatibility layer, protocol documentation, supported hardware scope, and reproducibility of the integration tests.

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

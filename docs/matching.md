# FTE4800 Fingerprint Matching

The production FTE4800 driver does not implement a new generic matcher. It uses FocalTech's own `ftWbioEngineAdapter.dll` through the native Linux PE/WinBio bridge in `libfprint/drivers/vendor-engine.c`.

The sensor supplies native 64x80, 8-bit grayscale frames. The vendor engine is configured for 64x80 and performs its own feature extraction, quality checks, enrollment, template construction, and verification. Static analysis identified a multi-scale feature pipeline including Gaussian/DoG pyramids, scale-space extrema, feature orientation calculation, descriptors, RANSAC, overlap checks, and template verification.

Enrollment uses the vendor engine's enrollment state machine. The engine reports a maximum of 12 enrollment samples and creates an opaque vendor template. The driver stores that blob inside `FpPrint` using the `FTV1` wrapper:

```text
FTV1 | uint32_le(template_size) | opaque FocalTech template
```

Verification feeds the captured 64x80 frame to the same vendor engine and verifies the stored opaque template. No NBIS/Bozorth3 minutiae matching or local NCC score is used in the production path.

The Linux-side state machine remains responsible for hardware interaction and user interaction: it waits for a real finger signal, accepts the frame into the vendor engine, waits for confirmed finger release between enrollment stages, and reports libfprint retry/match states.

## Proven engine path

The exact FTE4800 Windows engine package was executed natively on Linux without Wine. The loader maps the PE at its preferred base, installs the required x64 Windows TEB in `%gs`, resolves the required Windows API shims, initializes the DLL, and calls the exported WinBio engine interface.

The vendor engine is called from libfprint operation worker threads. The bridge therefore re-arms the Windows TEB for the current Linux pthread before each engine operation and derives `StackBase`/`StackLimit` from that thread's real pthread stack. This is required by the vendor CRT's `__chkstk` path; a fixed dummy stack range caused a reproducible SIGSEGV before `VerifyFeatureSet` could run.

An offline replay using real 64x80 FTE4800 BMP captures produced:

- engine open: success
- geometry: 64x80
- five enrollment samples accepted
- committed opaque template: 458,800 bytes
- same-finger verification: 5/5 matches

These measurements validate the vendor-engine integration path; they do not by themselves establish production FAR/FRR.

After deployment to the ZERO BOOK 13, live `fprintd-enroll` completed a full 12-sample enrollment and live `fprintd-verify` completed successfully using the resulting `FTV1` record. The production path therefore has now been exercised end-to-end on the physical FT9368, including sensor capture, vendor enrollment, persistent template storage, vendor verification, and libfprint/fprintd integration.

The vendor DLL is installed to `/usr/local/lib/fte4800/ftWbioEngineAdapter.dll`. A system fprintd service should not use `~/.local/bin` for this library: the service runs outside the login user directory permissions, and bin is intended for executable programs rather than loadable library/data files.

The old local NCC matcher research remains in `tools/matcher_ref.py`, `tools/matcher_lab.py`, and related evaluation tooling as historical research only. It is no longer part of the active driver or template format.

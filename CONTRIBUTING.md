# Contributing

Contributions to the FTE4800 / FT9368 Linux driver are welcome.

## Scope

The primary project is the Linux kernel SPI transport for FocalTech FTE4800 / FT9368 sensors exposed through ACPI/SPI. The repository also contains a downstream libfprint integration patch, diagnostic tooling, and reverse-engineering documentation.

Keep the kernel transport hardware-backed. Do not add synthetic fingerprint frames, vendor-emulation shortcuts, or undocumented register behaviour presented as verified protocol.

## Before submitting changes

Run the source-contract and integration tests:

```bash
tests/run-tests.sh
```

Run shell syntax checks and whitespace validation:

```bash
bash -n install/*.sh tests/run-tests.sh tools/*.sh
git diff --check
```

When changing the kernel transport, also build against the target kernel headers:

```bash
make
```

Hardware changes should include the exact device, kernel version, reset sequence, SPI parameters, and observed results.

## libfprint work

`libfprint-patches/` is maintained as a downstream patch series. It is not presented as an upstream-approved libfprint implementation.

Do not include proprietary FocalTech binaries, Windows driver packages, raw ACPI dumps, captured biometric datasets, or other local reverse-engineering material in a public change. Those artifacts are preserved locally under `archive/` and are ignored by Git.

## Commit style

Use concise imperative commit subjects. Keep unrelated changes in separate commits. Prefer changes that are reproducible from source and documented test commands.

## Security

Fingerprint authentication is security-sensitive. Do not weaken matching thresholds, bypass verification, or remove the password fallback just to improve convenience. Report security issues privately according to `SECURITY.md`.

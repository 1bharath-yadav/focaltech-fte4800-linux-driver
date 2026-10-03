# Repository layout

The public tree contains source, reproducible tooling, documentation, tests, and installation helpers. Machine-specific and potentially non-redistributable research artifacts are preserved locally under the root archive and are ignored by Git.

```
focal_spi.c                         Kernel SPI transport driver
protocol/                           Shared FTE4800 protocol definitions
libfprint-patches/                  Downstream libfprint patch
docs/                               Protocol, hardware, and integration documentation
install/                            Build, install, and recovery helpers
tests/                              Source and integration tests
tools/                              Hardware diagnostics and matcher research tools
LICENSES/                           License texts referenced by the repository
.github/workflows/                  Continuous integration
archive/                            Local-only research and machine artifacts
```

The archive currently preserves ACPI dumps, captured biometric datasets, extracted Windows firmware, legacy driver references, raw reverse-engineering dumps, internal agent material, and generated build artifacts.

The public source tree does not depend on those archived files for a normal build or installation.

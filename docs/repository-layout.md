# Repository Layout

    focal_spi.c                         Linux SPI transport
    protocol/                           FTE4800 protocol definitions
    libfprint/drivers/                  canonical native FTE4800 sources
    libfprint-patches/                  downstream libfprint patch
    packaging/arch/                     complete local Arch package
    docs/                               hardware and integration documentation
    install/                            development and recovery helpers
    tests/                              tests
    tools/                              diagnostics and historical matcher research
    LICENSES/                           license texts
    archive/                            local research and sensitive artifacts

## Package

packaging/arch/PKGBUILD is the production packaging entry point.

It installs:

    DKMS source
    native FTE4800 libfprint
    vendor-engine bridge
    FocalTech vendor DLL
    udev rule
    fprintd systemd drop-in

The stock Arch fprintd package is used.

## Installed paths

    /usr/src/focaltech-fte4800-1.0.3/
    /usr/lib/focaltech-fte4800/lib/
    /usr/lib/focaltech-fte4800/ftWbioEngineAdapter.dll
    /usr/lib/systemd/system/fprintd.service.d/00-fte4800.conf
    /usr/lib/udev/rules.d/70-focal-spi.rules

## Vendor runtime

The PKGBUILD consumes the preserved local vendor DLL from:

    archive/research/windows-package/package/ftWbioEngineAdapter.dll

It is installed by the package under /usr/lib/focaltech-fte4800.

## Source of truth

Active native libfprint:

    libfprint/drivers/fte4800.c
    libfprint/drivers/fte4800.h
    libfprint/drivers/vendor-engine.c
    libfprint/drivers/vendor-engine.h

Packaging:

    packaging/arch/PKGBUILD
    packaging/arch/focaltech-fte4800.install

Hardware protocol:

    protocol/fte4800_protocol.h
    docs/ft9368-*.md

Generated package/build trees are ignored.

# Development Guidance

## Current baseline

The FTE4800 project is a complete downstream Linux driver stack.

    FT9368
      -> focal_spi DKMS
      -> /dev/focal_moh_spi
      -> native FTE4800 libfprint
      -> FocalTech native WinBio engine
      -> stock fprintd
      -> PAM
      -> SDDM / Omarchy

The production packaging entry point is:

    packaging/arch/PKGBUILD

It builds the selected upstream libfprint release, applies our patch, builds native libfprint, packages focal_spi as DKMS, includes the vendor engine, and installs udev plus fprintd system integration.

## Package policy

Use one package for the complete stack:

    cd ~/projects/focaltech-fte4800-linux-driver/packaging/arch
    makepkg -Cfs
    sudo pacman -U ./focaltech-fte4800-*.pkg.tar.zst

The package owns all FTE4800-specific runtime files.

Arch DKMS guidance expects module source under /usr/src and has pacman hooks for DKMS installation and removal. Do not put manual dkms install or dkms remove operations in the package lifecycle.

## Upstream libfprint policy

Never make the old project development commit the permanent package base.

Use:

    current upstream release
            +
    FTE4800 downstream patch

The current selected release is v1.94.10.

For every upstream update:

    1. bump _libfprint_version;
    2. build from a clean upstream tree;
    3. apply the downstream patch;
    4. rebase the patch when APIs or files move;
    5. verify the FTE4800 discovery path;
    6. run tests;
    7. perform live enrollment and verification.

A successful compile is not enough. The sensor must still be discoverable and usable through fprintd.

## Why libfprint core changes are in the patch

The ZERO BOOK exposes the reader as /dev/focal_moh_spi through the misc subsystem rather than a normal spidev node.

The downstream patch therefore adds the small libfprint core plumbing needed for:

    MISC-backed udev resource identification
    ACPI/SPI discovery
    device-path handoff
    SPI data accessor support
    supported-device listing
    FTE4800 driver registration and udev dependency registration

This is libfprint plumbing, not fprintd plumbing.

## Native vendor engine

The production biometric path uses FocalTech's native WinBio engine.

vendor-engine.c provides:

    native PE loading
    Windows runtime compatibility
    x64 Windows TEB setup
    current pthread stack bounds
    WinBio sample construction
    vendor storage ABI
    enrollment and verification calls

The TEB handling is required because the vendor CRT can execute __chkstk. The current Linux pthread stack bounds are installed before vendor calls.

The active vendor template format is:

    FTV1
    uint32 little-endian size
    opaque FocalTech template

## Biometric validation

Keep three concepts separate.

Functional:

    device discovery
    real capture
    enrollment
    persistence
    verification
    finger release
    cancellation
    recovery

Integration:

    fprintd uses intended libfprint
    vendor DLL loads
    PAM works
    password fallback works
    Omarchy uses the same backend

Security characterization:

    FAR and FRR require a sufficiently large evaluation set
    successful enrollment is not biometric certification
    successful vendor verification is not proof of zero false accepts

## Security interpretation

Using the native FocalTech engine is a major algorithmic compatibility improvement over the old experimental matcher.

It does not prove:

    100 percent security
    100 percent efficiency
    zero false accepts
    zero false rejects
    security certification

The vendor DLL is proprietary and not independently auditable. The native PE and WinBio bridge is another security-sensitive component.

Use this wording:

    The active Linux driver uses FocalTech's native biometric engine and has been validated end-to-end on the target hardware.

Do not claim more without new evidence.

## fprintd policy

fprintd remains stock Arch software.

Do not:

    rebuild fprintd for normal installation
    apply the old preflight-status patch
    maintain a custom fprintd binary without a reproducible bug

## Desktop integration

Desktop integration comes after hardware and userspace validation.

Keep hardware code below:

    PAM
    SDDM
    sudo
    polkit
    Omarchy lock screen

Fingerprint authentication is userspace PAM. It is not an early-LUKS unlock mechanism.

## Legacy paths

The old manual deployment used:

    /opt/fte4800
    /usr/local/lib/fte4800

The package uses:

    /usr/lib/focaltech-fte4800

Do not document the old paths as the production architecture.

## AI-assisted engineering

AI is an engineering multiplier, not an authority.

Require exact evidence, exact file locations and reproducible commands.

Use:

    observe
      -> record
      -> reproduce
      -> implement
      -> test
      -> document
      -> commit

System-wide changes should remain centrally controlled.

## Release checklist

    tests/run-tests.sh
    bash -n install/*.sh
    bash -n tests/run-tests.sh
    git diff --check
    cd packaging/arch
    makepkg -Cfs
    pacman -Qp ./focaltech-fte4800-*.pkg.tar.zst
    tar -tf ./focaltech-fte4800-*.pkg.tar.zst

Then perform live:

    fresh enrollment
    persistent-template verification
    same-finger verification
    different-finger rejection
    fprintd restart
    module reload
    reboot
    suspend/resume
    lock-screen authentication

## What not to repeat

    synthetic fingerprint frames
    kernel-side biometric matching
    lowering thresholds for demo success
    replacing system libfprint during package use
    rebuilding fprintd without a proven defect
    calling a small biometric dataset a security guarantee
    uncontrolled retry loops

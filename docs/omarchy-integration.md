# Omarchy Integration — FTE4800

## Current stack

    FTE4800 / FT9368
        -> focal_spi DKMS
        -> /dev/focal_moh_spi
        -> native FTE4800 libfprint
        -> stock fprintd
        -> pam_fprintd
        -> SDDM / sudo / polkit / Omarchy

Omarchy is the desktop authentication layer. It is not the owner of the hardware driver.

## Current packaged deployment

The complete stack is installed through:

    focaltech-fte4800

Package-owned runtime:

    /usr/src/focaltech-fte4800-1.0.3/
    /usr/lib/focaltech-fte4800/
    /usr/lib/systemd/system/fprintd.service.d/00-fte4800.conf
    /usr/lib/udev/rules.d/70-focal-spi.rules

The daemon remains stock Arch fprintd.

## SDDM and PAM

SDDM can use pam_fprintd.so through the normal PAM configuration.

Fingerprint authentication happens in userspace. It is not an early-LUKS unlock mechanism.

Password fallback should remain available.

## GNOME Keyring

Fingerprint authentication does not provide a normal password token in PAM_AUTHTOK.

Therefore a password-protected GNOME Keyring cannot automatically be unlocked solely from fingerprint success.

This is a general PAM/keyring constraint, not an FTE4800 hardware defect.

Do not weaken keyring protection simply to remove a password prompt.

## Lock screen

The Omarchy lock screen can consume the same fprintd and PAM backend.

Keep:

    password fallback
    bounded retry behavior
    recovery from transient fprintd errors
    suspend/resume handling

Do not move FTE4800 protocol or biometric matching into the shell.

## Security

The native FocalTech engine improves algorithmic compatibility, but it does not make Omarchy authentication 100 percent secure.

The security boundary includes the sensor, kernel transport, libfprint, vendor DLL, PE/WinBio bridge, fprintd, PAM, templates and desktop session.

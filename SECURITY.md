# Security

Fingerprint authentication is security-sensitive software.

## Current posture

The production FTE4800 stack uses FocalTech's native biometric engine instead of the former experimental NCC and raw-frame matcher.

This is a substantial algorithmic and compatibility improvement.

It does not establish a 100 percent secure system.

## Security boundary

The boundary includes:

    FTE4800 sensor
    focal_spi kernel transport
    native libfprint driver
    native PE and WinBio compatibility bridge
    proprietary FocalTech vendor DLL
    fprintd
    PAM policy
    template persistence
    desktop and session integration

The proprietary DLL is not independently auditable by this project. The native compatibility bridge is additional security-sensitive native code.

## Biometric claims

Validated:

    real sensor capture
    vendor-engine enrollment
    opaque FTV1 persistence
    vendor-engine verification
    live fprintd enrollment and verification

Not established:

    production-scale FAR and FRR
    zero false accepts
    zero false rejects
    security certification
    immunity from implementation vulnerabilities

Do not describe the system as 100 percent secure, 100 percent accurate or security certified.

## Why the vendor engine is preferred

The vendor engine is preferable to the historical local matcher because it preserves the vendor's intended enrollment and verification implementation instead of relying on an experimental replacement.

Correct claim:

    The active Linux driver uses FocalTech's native biometric engine and has been validated end-to-end on the target hardware.

## Authentication policy

Keep password fallback available.

Do not lower matcher or verification thresholds solely for convenience.

Do not treat fingerprint authentication as a substitute for the LUKS disk-unlock key.

## Proprietary runtime

The vendor DLL is kept local because redistribution terms have not been established.

Do not publish the vendor DLL, Windows driver package, raw biometric captures or sensitive reverse-engineering artifacts without establishing the legal and security constraints.

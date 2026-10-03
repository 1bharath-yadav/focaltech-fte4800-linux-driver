# Security

Fingerprint authentication is security-sensitive software. This project has not been security-certified and the current FTE4800 matcher has not been evaluated on a production-scale biometric dataset.

In the current local evaluation at threshold 0.75, 0 of 13 impostor trials were accepted (observed FPR: 0%), but this is a result for a small test set and must not be interpreted as proof of a zero production FAR or a fully secure biometric system. Do not rely on the current research threshold or the small local evaluation dataset as a measured FAR/FRR guarantee.

For suspected vulnerabilities, authentication bypasses, template-handling issues, kernel memory-safety bugs, or device-access problems, do not publish exploit details in a normal issue. Contact the project maintainer privately first and include the affected commit, kernel version, hardware identifier, and a minimal reproduction where safe.

The repository intentionally keeps proprietary driver packages, raw biometric captures, and other sensitive reverse-engineering artifacts outside the public source tree under `archive/`.

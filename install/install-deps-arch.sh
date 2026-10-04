#!/usr/bin/env bash
set -euo pipefail

# Arch/Omarchy build prerequisites for the FTE4800 transport + native libfprint.
# This script does not install the fingerprint driver itself.

if ! command -v pacman >/dev/null; then
  echo "This helper is for Arch Linux / Omarchy." >&2
  exit 1
fi

packages=(
  base-devel
  git
  meson
  ninja
  pkgconf
  python
  dkms
  glib2
  libgusb
  cairo
  gobject-introspection
  pixman
  openssl
  libgudev
)

if [ "$(id -u)" -eq 0 ]; then
  pacman -S --needed "${packages[@]}"
else
  sudo pacman -S --needed "${packages[@]}"
fi

if [ ! -e "/lib/modules/$(uname -r)/build" ]; then
  echo
  echo "Kernel headers for $(uname -r) are missing."
  echo "Install the headers package matching the running kernel, then rebuild the package."
fi

echo "Build prerequisites check complete."

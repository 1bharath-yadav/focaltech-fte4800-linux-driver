#!/usr/bin/env bash
set -euo pipefail
sudo pacman -S --needed \
  radare2 \
  binwalk \
  hivex \
  python-pefile \
  cabextract
printf '\nReverse-engineering tools installed.\n'

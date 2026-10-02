#!/usr/bin/env bash
set -euo pipefail
cd /home/archer/projects/zerobook-focaltech-driver
sudo pacman -S --needed acpica
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
sudo cp /sys/firmware/acpi/tables/DSDT "$TMP/DSDT.dat"
for f in /sys/firmware/acpi/tables/SSDT*; do [ -r "$f" ] && sudo cp "$f" "$TMP/$(basename "$f").dat" || true; done
sudo chown -R "$USER:$USER" "$TMP"
(cd "$TMP" && iasl -d ./*.dat >/dev/null 2>&1 || true)
grep -Rni -A100 -B30 'FTE4800' "$TMP"/*.dsl 2>/dev/null || true
grep -Rni -E -A25 -B25 'FTE4800|GpioIo|GpioInt' "$TMP"/*.dsl 2>/dev/null | head -500 || true
cp "$TMP"/*.dsl /home/archer/projects/zerobook-focaltech-driver/ 2>/dev/null || true

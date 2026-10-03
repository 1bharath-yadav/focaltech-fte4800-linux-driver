#!/usr/bin/env bash
set -u
echo '--- RUN ENROLL ---'
fprintd-enroll "$USER" 2>&1 || true
echo '--- NEW JOURNAL ---'
sudo -n journalctl -u fprintd.service --since '20 seconds ago' --no-pager 2>&1 | grep -Ei 'focal|fw936|device id|spi mode|init sensor|claim|open' || true
echo '--- BACKEND PACKAGE ---'
pacman -Qi libfprint-ftexx00 | grep -E 'Name|Version|Repository|Packager|URL|Provides|Architecture' || true

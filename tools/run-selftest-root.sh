#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
sudo -n systemctl stop fprintd.service || true
sudo -n python3 tools/fte4800_selftest.py --wait-touch --touch-timeout 20 --pgm /tmp/fte4800-clean.pgm
status=$?
sudo -n systemctl restart fprintd.service || true
exit $status

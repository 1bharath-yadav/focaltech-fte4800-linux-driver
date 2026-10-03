#!/usr/bin/env bash
set -euo pipefail

sudo -n true || { echo "ERROR: passwordless sudo is required"; exit 1; }

DROPIN=/etc/systemd/system/fprintd.service.d/10-fte4800-device.conf
sudo install -d -m755 /etc/systemd/system/fprintd.service.d

cat <<'EOF' | sudo tee "$DROPIN" >/dev/null
[Service]
DeviceAllow=/dev/focal_moh_spi rw
EOF

sudo systemctl daemon-reload
sudo systemctl restart fprintd

echo "=== effective device policy ==="
systemctl show fprintd -p DevicePolicy -p DeviceAllow

echo "=== device ==="
ls -l /dev/focal_moh_spi

echo "=== native library override ==="
systemctl cat fprintd.service | grep -A2 '00-native-fte4800.conf' || true

echo "=== service ==="
systemctl is-active fprintd

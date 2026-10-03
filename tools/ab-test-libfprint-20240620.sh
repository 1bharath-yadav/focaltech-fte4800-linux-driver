#!/usr/bin/env bash
set -u
set -o pipefail
CURRENT="/usr/lib/libfprint-2.so.2.0.0"
BACKUP="/tmp/libfprint-current.ab-backup.so"
OLD="/tmp/libfprint-20240620.so.2.0.0"

sudo -n cp "$CURRENT" "$BACKUP" || exit 2
sudo -n cp "$OLD" "$CURRENT" || {
    sudo -n cp "$BACKUP" "$CURRENT"
    exit 3
}
restore() {
    sudo -n cp "$BACKUP" "$CURRENT" >/dev/null 2>&1 || true
    sudo -n systemctl restart fprintd.service >/dev/null 2>&1 || true
}
trap restore EXIT

sudo -n systemctl restart fprintd.service || exit 4
sleep 1

echo "active_hash=$(sha256sum "$CURRENT" | cut -d" " -f1)"
echo "=== ENROLL WITH 20240620 ==="
timeout 15s fprintd-enroll "$USER" 2>&1
rc=$?
echo "enroll_exit=$rc"

echo "=== DAEMON ==="
sudo -n journalctl -u fprintd.service --since "30 seconds ago" --no-pager 2>&1 |
grep -Ei 'focal|fw936|device id|spi mode|init sensor|claim|open|enroll|error' | tail -240 || true

exit 0

#!/usr/bin/env bash
set -euo pipefail

ROOT="/home/archer/projects/zerobook-focaltech-driver/.worktrees/fte4800-clean-driver"
INSTALL_DIR="$ROOT/install"
MODE="${1:-full}"
NATIVE_LIB="/opt/fte4800/libfprint/lib/libfprint-2.so.2.0.0"
NATIVE_DROPIN="/etc/systemd/system/fprintd.service.d/00-native-fte4800.conf"
DETECTOR_SRC="$INSTALL_DIR/omarchy-hw-fingerprint-fte4800"
SETUP_SRC="$INSTALL_DIR/omarchy-setup-security-fingerprint-fte4800"
LOCK_QML="/usr/share/omarchy/shell/plugins/lock/Service.qml"
STATE_DIR="/var/lib/omarchy-fte4800"

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Run this installer with sudo." >&2
    exit 1
  fi
}

install_system_helpers() {
  install -d -m 755 /usr/local/bin /usr/local/sbin "$STATE_DIR"
  install -m 755 "$DETECTOR_SRC" /usr/local/bin/omarchy-hw-fingerprint-fte4800
  install -m 755 "$SETUP_SRC" /usr/local/bin/omarchy-setup-security-fingerprint-fte4800
  install -m 755 "$0" /usr/local/sbin/omarchy-fte4800-root-install.sh

  cat > /usr/local/bin/omarchy-hw-fingerprint <<'EOF'
#!/usr/bin/env bash
exec /usr/local/bin/omarchy-hw-fingerprint-fte4800 "$@"
EOF
  chmod 755 /usr/local/bin/omarchy-hw-fingerprint

  cat > /usr/local/bin/omarchy-setup-security-fingerprint <<'EOF'
#!/usr/bin/env bash
exec /usr/local/bin/omarchy-setup-security-fingerprint-fte4800 "$@"
EOF
  chmod 755 /usr/local/bin/omarchy-setup-security-fingerprint
}

configure_pam() {
  local pam="/usr/lib/security/pam_fprintd.so"
  [[ -f "$pam" ]] || { echo "Missing $pam; install fprintd/libfprint first." >&2; exit 1; }

  local gate='auth      [success=1 default=ignore] pam_exec.so quiet /usr/bin/omarchy-hw-laptop-closed'

  if [[ -f /etc/pam.d/sudo ]] && ! grep -q '^[[:space:]]*auth[[:space:]].*pam_fprintd\.so' /etc/pam.d/sudo; then
    cp -a /etc/pam.d/sudo "$STATE_DIR/sudo.orig"
    { printf '%s\n' "$gate" 'auth      sufficient pam_fprintd.so'; cat /etc/pam.d/sudo; } > /etc/pam.d/sudo.fte4800
    mv /etc/pam.d/sudo.fte4800 /etc/pam.d/sudo
  fi

  if [[ ! -f /etc/pam.d/polkit-1 ]]; then
    cat > /etc/pam.d/polkit-1 <<EOF
$gate
auth      sufficient pam_fprintd.so
auth      required pam_unix.so

account   required pam_unix.so
password  required pam_unix.so
session   required pam_unix.so
EOF
  elif ! grep -q '^[[:space:]]*auth[[:space:]].*pam_fprintd\.so' /etc/pam.d/polkit-1; then
    cp -a /etc/pam.d/polkit-1 "$STATE_DIR/polkit-1.orig"
    { printf '%s\n' "$gate" 'auth      sufficient pam_fprintd.so'; cat /etc/pam.d/polkit-1; } > /etc/pam.d/polkit-1.fte4800
    mv /etc/pam.d/polkit-1.fte4800 /etc/pam.d/polkit-1
  fi

  cat > /etc/pam.d/omarchy-lock-fingerprint <<'EOF'
# FTE4800 / Omarchy fingerprint unlock
auth       required                    pam_fprintd.so
account    include                     system-local-login
EOF
}

patch_lock_qml() {
  [[ -f "$LOCK_QML" ]] || { echo "Omarchy lock Service.qml not found; skipping lock patch."; return 0; }

  python3 - "$LOCK_QML" "$STATE_DIR" <<'PY'
from pathlib import Path
import shutil
import sys

qml = Path(sys.argv[1])
state = Path(sys.argv[2])
text = qml.read_text()

marker = "// FTE4800 PATCH: bounded fingerprint retry"
if marker in text:
    print("Omarchy lock QML already patched.")
    raise SystemExit(0)

backup = state / "Service.qml.orig"
if not backup.exists():
    shutil.copy2(qml, backup)

marker = "// FTE4800 PATCH: bounded fingerprint retry"
if marker not in text:
    if "  property int fingerprintRetryCount: 0" not in text:
        needle = "  property int failedAttempts: 0"
        if needle not in text:
            raise SystemExit("Unsupported Service.qml: fingerprint state block changed")
        text = text.replace(
            needle,
            needle + "\n  property int fingerprintRetryCount: 0\n  readonly property int fingerprintRetryLimit: 5",
            1,
        )

old = '''    failedAttempts = 0
    authenticatingPassword = false'''
new = '''    failedAttempts = 0
    fingerprintRetryCount = 0
    authenticatingPassword = false'''
if old not in text:
    raise SystemExit("Unsupported Service.qml: resetAuthenticationState changed")
text = text.replace(old, new, 1)

old = '''    } else if (fingerprintConfigured) {
      fingerprintRetryTimer.restart()
    }'''
new = '''    } else if (fingerprintConfigured && fingerprintRetryCount < fingerprintRetryLimit) {
      fingerprintRetryCount += 1
      fingerprintRetryTimer.restart()
    } else if (fingerprintConfigured) {
      root.logEvent("fingerprint-retry-limit")
    }'''
if old not in text:
    raise SystemExit("Unsupported Service.qml: fingerprint completion block changed")
text = text.replace(old, new, 1)

old = '''    onError: function(error) {
      root.fingerprintAuthenticating = false
      if (root.lockRequested && root.fingerprintConfigured) fingerprintRetryTimer.restart()
    }'''
new = '''    onError: function(error) {
      root.fingerprintAuthenticating = false
      if (root.lockRequested && root.fingerprintConfigured && root.fingerprintRetryCount < root.fingerprintRetryLimit) {
        root.fingerprintRetryCount += 1
        fingerprintRetryTimer.restart()
      } else if (root.lockRequested && root.fingerprintConfigured) {
        root.logEvent("fingerprint-retry-limit")
      }
    }'''
text = text.replace(old, new, 1)

old = '''  Timer {
    id: fingerprintRetryTimer
    interval: 250'''
new = '''  // FTE4800 PATCH: bounded fingerprint retry
  Timer {
    id: fingerprintRetryTimer
    interval: 1000'''
text = text.replace(old, new, 1)

qml.write_text(text)
PY
}

install_pacman_hook() {
  install -d -m 755 /etc/pacman.d/hooks
  cat > /etc/pacman.d/hooks/99-fte4800-omarchy-fingerprint.hook <<'EOF'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = omarchy

[Action]
Description = Reapply FTE4800 Omarchy fingerprint integration
When = PostTransaction
Exec = /usr/local/sbin/omarchy-fte4800-root-install.sh --lock-only
EOF
}

verify_install() {
  echo "=== Omarchy FTE4800 integration ==="
  command -v omarchy-hw-fingerprint
  command -v omarchy-setup-security-fingerprint
  omarchy-hw-fingerprint
  test -s "$NATIVE_LIB"
  test -f "$NATIVE_DROPIN"
  grep -q 'pam_fprintd.so' /etc/pam.d/sudo
  grep -q 'pam_fprintd.so' /etc/pam.d/polkit-1
  grep -q 'pam_fprintd.so' /etc/pam.d/omarchy-lock-fingerprint
  grep -q 'FTE4800 PATCH: bounded fingerprint retry' "$LOCK_QML"
  echo "FTE4800 detector: PASS"
  echo "PAM sudo/polkit/lock: PASS"
  echo "Omarchy lock retry patch: PASS"
}

require_root

case "$MODE" in
  full)
    install_system_helpers
    configure_pam
    patch_lock_qml
    install_pacman_hook
    verify_install
    ;;
  --lock-only)
    install -d -m 755 "$STATE_DIR"
    patch_lock_qml
    ;;
  *)
    echo "Usage: $0 [--lock-only]" >&2
    exit 2
    ;;
esac

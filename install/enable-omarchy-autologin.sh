#!/usr/bin/env bash
set -euo pipefail

# Restore Omarchy's automatic post-LUKS login path.
# This intentionally does NOT attempt fingerprint authentication inside
# Plymouth/LUKS. The FTE4800 remains available to fprintd for the running
# desktop lock screen and other PAM consumers.
#
# Usage:
#   ./install/enable-omarchy-autologin.sh --check
#   ./install/enable-omarchy-autologin.sh --enable

BACKUP_ROOT=/var/lib/fte4800/sddm-fingerprint
PAM_FILE=/etc/pam.d/sddm
SDDM_CONF_DIR=/etc/sddm.conf.d
ORIGINAL_BACKUP="$BACKUP_ROOT/20261004-111224/autologin.conf.disabled"
FPRINT_LINE='auth        sufficient pam_fprintd.so'

die() { echo "ERROR: $*" >&2; exit 1; }

check_state() {
  echo "=== SDDM autologin ==="
  find "$SDDM_CONF_DIR" -maxdepth 1 -type f -name 'autologin.conf*' -print 2>/dev/null || true
  echo
  echo "=== SDDM PAM ==="
  grep -nE 'pam_fprintd|pam_gnome_keyring|pam_kwallet5' "$PAM_FILE" 2>/dev/null || true
}

enable() {
  command -v sudo >/dev/null || die "sudo is required"
  [[ -f "$PAM_FILE" ]] || die "$PAM_FILE is missing"
  [[ -f "$ORIGINAL_BACKUP" ]] || die "safe original autologin backup is missing: $ORIGINAL_BACKUP"

  sudo -v

  local stamp backup tmp
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup="$BACKUP_ROOT/$stamp"
  sudo install -d -m 700 "$backup"

  sudo cp -a "$PAM_FILE" "$backup/sddm-before-autologin"
  while IFS= read -r -d '' f; do
    sudo cp -a "$f" "$backup/$(basename "$f")-before-autologin"
  done < <(find "$SDDM_CONF_DIR" -maxdepth 1 -type f -name 'autologin.conf*' -print0)

  # Restore the exact Omarchy autologin configuration that was active before
  # the temporary SDDM fingerprint-login experiment.
  sudo install -m 644 "$ORIGINAL_BACKUP" "$SDDM_CONF_DIR/autologin.conf"

  # Keep manual SDDM fingerprint login available, but prevent SDDM from
  # managing the password-protected GNOME Login keyring. This matches
  # Omarchy's own SDDM policy.
  tmp="$(mktemp)"
  sed \
    -e '/^[[:space:]-]*auth[[:space:]].*pam_gnome_keyring\.so/d' \
    -e '/^[[:space:]-]*password[[:space:]].*pam_gnome_keyring\.so/d' \
    "$PAM_FILE" > "$tmp"

  if ! grep -qF "$FPRINT_LINE" "$tmp"; then
    printf '%s\n' "$FPRINT_LINE" | cat - "$tmp" > "$tmp.with-fp"
    mv "$tmp.with-fp" "$tmp"
  fi

  sudo install -m 644 "$tmp" "$PAM_FILE"
  rm -f "$tmp"

  echo
  echo "Configured: LUKS passphrase -> automatic Omarchy desktop."
  echo "SDDM login screen will no longer appear after boot."
  echo "FTE4800 fingerprint remains enabled for the desktop lock screen."
  echo "No SDDM restart was performed."
  echo "Backup: $backup"
}

case "${1:-}" in
  --check) check_state ;;
  --enable) enable ;;
  -h|--help)
    sed -n '1,45p' "$0"
    ;;
  *) echo "Usage: $0 --check|--enable"; exit 2 ;;
esac

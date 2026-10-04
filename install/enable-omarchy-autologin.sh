#!/usr/bin/env bash
set -euo pipefail

# Restore Omarchy's automatic post-LUKS login path.
#
# Omarchy treats LUKS decryption as the authentication boundary on encrypted
# installs and autologs the owner into the desktop afterward. Do NOT attempt
# to put pam_fprintd into Plymouth/LUKS; fprintd becomes available later in
# userspace.
#
# This helper:
#   - backs up the current SDDM state
#   - writes Omarchy's standard autologin.conf for the current user
#   - keeps fingerprint PAM available as a manual SDDM fallback
#   - keeps SDDM GNOME-keyring auth/password hooks removed
#   - never restarts SDDM automatically
#
# Usage:
#   ./install/enable-omarchy-autologin.sh --check
#   ./install/enable-omarchy-autologin.sh --enable

BACKUP_ROOT=/var/lib/fte4800/sddm-fingerprint
PAM_FILE=/etc/pam.d/sddm
SDDM_CONF_DIR=/etc/sddm.conf.d
FPRINT_LINE='auth        sufficient pam_fprintd.so'
AUTLOGIN_FILE=$SDDM_CONF_DIR/autologin.conf

die() {
  echo "ERROR: $*" >&2
  exit 1
}

check_state() {
  echo "=== Root encryption ==="
  findmnt -n -o SOURCE / 2>/dev/null || true

  echo
  echo "=== SDDM autologin ==="
  if [[ -f $AUTLOGIN_FILE ]]; then
    cat "$AUTLOGIN_FILE"
  else
    echo "NOT CONFIGURED"
  fi

  echo
  echo "=== SDDM PAM ==="
  grep -nE 'pam_fprintd|pam_gnome_keyring|pam_kwallet5' "$PAM_FILE" 2>/dev/null || true
}

enable() {
  command -v sudo >/dev/null || die "sudo is required"
  [[ -f "$PAM_FILE" ]] || die "$PAM_FILE is missing"
  [[ -d "$SDDM_CONF_DIR" ]] || die "$SDDM_CONF_DIR is missing"

  sudo -v

  local stamp backup tmp
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup="$BACKUP_ROOT/$stamp"
  sudo install -d -m 700 "$backup"

  echo "Backing up current SDDM state to: $backup"
  sudo cp -a "$PAM_FILE" "$backup/sddm-before-autologin"
  while IFS= read -r -d '' f; do
    sudo cp -a "$f" "$backup/$(basename "$f")-before-autologin"
  done < <(find "$SDDM_CONF_DIR" -maxdepth 1 -type f -name 'autologin.conf*' -print0)

  # This is Omarchy's own encrypted-install autologin format. Do not rely on
  # a root-owned historical backup merely to reconstruct these two lines.
  tmp="$(mktemp)"
  printf '[Autologin]\nUser=%s\nSession=omarchy.desktop\n' "$USER" > "$tmp"
  sudo install -m 644 "$tmp" "$AUTLOGIN_FILE"
  rm -f "$tmp"

  # Keep fingerprint-first manual SDDM authentication available as a fallback,
  # but match Omarchy's SDDM keyring policy: no pam_gnome_keyring auth/password
  # hooks here, because fingerprint auth cannot supply PAM_AUTHTOK.
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
  echo "Configured Omarchy autologin:"
  cat "$AUTLOGIN_FILE"
  echo
  echo "Result after the next reboot:"
  echo "LUKS passphrase -> automatic Omarchy desktop."
  echo "No second SDDM login screen."
  echo "FTE4800 fingerprint remains available for the desktop lock screen."
  echo
  echo "Existing keyrings and application credentials were not modified."
  echo "No SDDM restart was performed."
  echo "Backup: $backup"
}

case "${1:-}" in
  --check) check_state ;;
  --enable) enable ;;
  -h|--help)
    sed -n '1,55p' "$0"
    ;;
  *) echo "Usage: $0 --check|--enable"; exit 2 ;;
esac

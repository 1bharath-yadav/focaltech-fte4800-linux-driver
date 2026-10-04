#!/usr/bin/env bash
set -euo pipefail

# Configure SDDM for fingerprint-first login while keeping password fallback.
# Omarchy uses a passwordless Default_keyring, so SDDM must not create or
# attempt to unlock a separate password-protected GNOME "Login" keyring.
#
# This helper backs up the changed files and never restarts SDDM automatically.
#
# Usage:
#   ./install/configure-sddm-fingerprint.sh --check
#   ./install/configure-sddm-fingerprint.sh --enable
#   ./install/configure-sddm-fingerprint.sh --restore

BACKUP_ROOT=/var/lib/fte4800/sddm-fingerprint
PAM_FILE=/etc/pam.d/sddm
SDDM_CONF_DIR=/etc/sddm.conf.d
FPRINT_LINE='auth        sufficient pam_fprintd.so'

die() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: configure-sddm-fingerprint.sh --check|--enable|--restore

--check    Show SDDM fingerprint/keyring/autologin state.
--enable   Back up the current SDDM state, disable autologin, add
           fingerprint-first PAM authentication, and align GNOME keyring
           PAM handling with Omarchy's passwordless Default_keyring model.
--restore  Restore the most recent backup created by --enable.
EOF
}

latest_backup() {
  find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null |
    sort | tail -1
}

check_state() {
  echo "=== SDDM PAM ==="
  if [[ -f $PAM_FILE ]]; then
    if grep -qF "$FPRINT_LINE" "$PAM_FILE"; then
      echo "fingerprint PAM: enabled"
    else
      echo "fingerprint PAM: not configured"
    fi
    if grep -Eq '^[[:space:]-]*auth.*pam_gnome_keyring\.so|^[[:space:]-]*password.*pam_gnome_keyring\.so' "$PAM_FILE"; then
      echo "GNOME keyring auth/password PAM lines: present"
    else
      echo "GNOME keyring auth/password PAM lines: removed (Omarchy mode)"
    fi
  else
    echo "ERROR: $PAM_FILE is missing"
  fi

  echo
  echo "=== active autologin.conf* files ==="
  if find "$SDDM_CONF_DIR" -maxdepth 1 -type f -name 'autologin.conf*' -print -quit 2>/dev/null |
       grep -q .; then
    find "$SDDM_CONF_DIR" -maxdepth 1 -type f -name 'autologin.conf*' -print
  else
    echo "none"
  fi

  echo
  echo "=== Omarchy Default_keyring ==="
  if [[ -f "$HOME/.local/share/keyrings/default" ]]; then
    echo "default=$(cat "$HOME/.local/share/keyrings/default")"
  else
    echo "default file: missing"
  fi
  if [[ -f "$HOME/.local/share/keyrings/Default_keyring.keyring" ]]; then
    echo "Default_keyring.keyring: present"
  else
    echo "Default_keyring.keyring: missing"
  fi
}

enable() {
  command -v sudo >/dev/null || die "sudo is required"
  command -v fprintd-list >/dev/null || die "fprintd-list is required"

  fprintd-list "$USER" 2>/dev/null | grep -qi finger ||
    die "no enrolled fingerprint was found for $USER"

  [[ -f $PAM_FILE ]] || die "$PAM_FILE is missing"
  [[ -d $SDDM_CONF_DIR ]] || die "$SDDM_CONF_DIR is missing"

  sudo -v

  local stamp backup tmp
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup="$BACKUP_ROOT/$stamp"
  sudo install -d -m 700 "$backup"

  echo "Backing up SDDM state to: $backup"
  sudo cp -a "$PAM_FILE" "$backup/sddm"

  while IFS= read -r -d '' f; do
    [[ -f $f ]] || continue
    local base
    base="$(basename "$f")"
    echo "Disabling SDDM autologin config: $f"
    sudo cp -a "$f" "$backup/$base"
    sudo rm -f -- "$f"
  done < <(find "$SDDM_CONF_DIR" -maxdepth 1 -type f -name 'autologin.conf*' -print0)

  tmp="$(mktemp)"
  sed \
    -e '/^[[:space:]-]*auth[[:space:]].*pam_gnome_keyring\.so/d' \
    -e '/^[[:space:]-]*password[[:space:]].*pam_gnome_keyring\.so/d' \
    "$PAM_FILE" >"$tmp"

  if ! grep -qF "$FPRINT_LINE" "$tmp"; then
    printf '%s\n' "$FPRINT_LINE" | cat - "$tmp" >"$tmp.with-fp"
    mv "$tmp.with-fp" "$tmp"
    echo "Adding fingerprint authentication to $PAM_FILE"
  else
    echo "Fingerprint authentication is already configured."
  fi

  sudo install -m 644 "$tmp" "$PAM_FILE"
  rm -f "$tmp"

  echo
  echo "SDDM fingerprint login is configured in Omarchy mode."
  echo "No SDDM restart was performed."
  echo "Fingerprint auth succeeds at SDDM without supplying PAM_AUTHTOK;"
  echo "the passwordless Default_keyring remains the intended secret store."
  echo "Existing Login keyring data was NOT deleted or modified."
}

restore() {
  command -v sudo >/dev/null || die "sudo is required"
  sudo -v

  local name backup
  name="$(latest_backup)"
  [[ -n $name ]] || die "no SDDM backup exists under $BACKUP_ROOT"
  backup="$BACKUP_ROOT/$name"
  [[ -f $backup/sddm ]] || die "backup is incomplete: $backup/sddm"

  echo "Restoring SDDM PAM from $backup/sddm"
  sudo install -m 644 "$backup/sddm" "$PAM_FILE"

  while IFS= read -r -d '' f; do
    local base
    base="$(basename "$f")"
    echo "Restoring $SDDM_CONF_DIR/$base"
    sudo install -m 644 "$f" "$SDDM_CONF_DIR/$base"
  done < <(find "$backup" -maxdepth 1 -type f -name 'autologin.conf*' -print0)

  echo
  echo "Latest SDDM fingerprint configuration restored."
  echo "No SDDM restart was performed."
}

case "$1" in
  --check) check_state ;;
  --enable) enable ;;
  --restore) restore ;;
  -h|--help) usage ;;
  *) usage; exit 2 ;;
esac

#!/usr/bin/env bash
set -u
sudo -n dmesg | tail -220 | grep -E 'focal-fte4800|REQ (read|write)|TX:' | tail -180 || true

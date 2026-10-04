#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
LIBDIR="\${FTE4800_LIBDIR:-/usr/lib/focaltech-fte4800/lib}"
OUT="\${TMPDIR:-/tmp}/fte4800-native-live-test"

[ -s "$LIBDIR/libfprint-2.so.2.0.0" ] || {
  echo "Missing packaged native libfprint: $LIBDIR/libfprint-2.so.2.0.0" >&2
  echo "Build/install focaltech-fte4800 first, or set FTE4800_LIBDIR." >&2
  exit 1
}

gcc -O2 -o "$OUT" "$ROOT/tools/native-live-test.c" \
  $(pkg-config --cflags --libs libfprint-2) \
  -L"$LIBDIR" -Wl,-rpath,"$LIBDIR" -ldl -lpthread

LD_LIBRARY_PATH="$LIBDIR\${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  exec "$OUT"

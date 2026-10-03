#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PROJECT_ROOT=$(cd "$ROOT/../.." && pwd)
SRC="${LIBFPRINT_SRC:-$PROJECT_ROOT/libfprint-upstream}"
BUILD="${LIBFPRINT_BUILD:-$SRC/build-fte}"
OUT="${TMPDIR:-/tmp}/fte4800-native-live-test"

[ -x "$BUILD/libfprint/libfprint-2.so.2.0.0" ] ||
  { echo "Missing native libfprint build: $BUILD" >&2; echo "Run: $ROOT/install/build-libfprint.sh $SRC" >&2; exit 1; }

gcc -O2 -o "$OUT" "$ROOT/tools/native-live-test.c" \
  -Wl,--allow-shlib-undefined \
  $(pkg-config --cflags --libs libfprint-2) -ldl -lpthread

LD_LIBRARY_PATH="$BUILD/libfprint${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  exec "$OUT"

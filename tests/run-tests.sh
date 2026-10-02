#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
exec python3 -m unittest discover -s tests -p 'test_*.py' -v

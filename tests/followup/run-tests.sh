#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

status=0
for test in "$SCRIPT_DIR"/test-followup-*.sh; do
  echo "== $(basename "$test")"
  bash "$test" || status=1
done
exit "$status"

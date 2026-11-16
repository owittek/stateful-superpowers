#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$SCRIPT_DIR/test-tracker-errors.sh"
bash "$SCRIPT_DIR/test-tracker-local.sh"

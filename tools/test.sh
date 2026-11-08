#!/usr/bin/env bash
# Imports the project headlessly and runs the GDScript test suite.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$ROOT/tools/setup_godot.sh")"
"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
"$GODOT" --headless --path "$ROOT" -s res://tests/run_tests.gd
# English: every player-facing Turkish string needs a translation
python3 -B "$ROOT/tools/i18n_extract.py" --check

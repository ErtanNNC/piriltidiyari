#!/usr/bin/env bash
# Imports the project headlessly and runs the GDScript test suite.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$ROOT/tools/setup_godot.sh")"
"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
"$GODOT" --headless --path "$ROOT" -s res://tests/run_tests.gd
# every script must compile (most scenes are never loaded by the tests)
LOG="$(mktemp)"
"$GODOT" --headless --path "$ROOT" -- --compile-check 2>&1 | grep -E "DERLE|SCRIPT ERROR|Parse Error" | tee "$LOG" || true
grep -q "^DERLEME .* 0 hata" "$LOG" || { echo "HATA: betik derlenmedi"; exit 1; }
if grep -qE "SCRIPT ERROR|Parse Error" "$LOG"; then echo "HATA: betik hatası"; exit 1; fi
# English: every player-facing Turkish string needs a translation
python3 -B "$ROOT/tools/i18n_extract.py" --check

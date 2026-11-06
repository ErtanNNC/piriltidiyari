#!/usr/bin/env bash
# Renders the game under a virtual display and saves a PNG.
# Usage: tools/screenshot.sh out.png [extra user args, e.g. --demo=talk --frames=90]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$ROOT/tools/setup_godot.sh")"
OUT="$(realpath -m "${1:-$ROOT/screenshots/shot.png}")"; shift || true
mkdir -p "$(dirname "$OUT")"
"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --path "$ROOT" \
  --rendering-driver opengl3 --resolution 1280x720 --audio-driver Dummy \
  -- --shot="$OUT" "$@" 2>&1 | grep -E "SCRIPT ERROR|ERROR:|Parse Error|SHOT" | grep -v "set_use_vsync" || true
test -f "$OUT" && echo "Kaydedildi: $OUT"

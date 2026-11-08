#!/usr/bin/env bash
# Builds the browser version into export/web/ (index.html + .wasm + .pck).
# No threads, so it runs on itch.io and any static host without special
# COOP/COEP headers. Template is pulled once with tools/fetch_template.py.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$ROOT/tools/setup_godot.sh")"
VER="${GODOT_VERSION:-4.7.2-stable}"
TPL="$HOME/.local/share/godot/export_templates/${VER/-/.}"
if [ ! -f "$TPL/web_nothreads_release.zip" ]; then
  python3 "$ROOT/tools/fetch_template.py" "$VER" web_nothreads_release.zip
fi
mkdir -p "$ROOT/export/web"
"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
"$GODOT" --headless --path "$ROOT" --export-release "Web" "$ROOT/export/web/index.html" 2>&1 | grep -vE "^\s*$" | tail -5
ls -la "$ROOT/export/web"

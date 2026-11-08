#!/usr/bin/env bash
# Pushes export/web to itch.io with butler (HTML5 channel "web").
#   BUTLER_API_KEY=... ITCH_TARGET=kullanici/pirilti-diyari tools/publish_itch.sh
# Build first with tools/build_web.sh. On itch.io, set the project's
# "Kind of project" to HTML and tick "This file will be played in the browser".
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${BUTLER_API_KEY:?BUTLER_API_KEY eksik (itch.io → Settings → API keys)}"
: "${ITCH_TARGET:?ITCH_TARGET eksik, örn. kullanici/pirilti-diyari}"
BUTLER="$ROOT/.tools/butler/butler"
if [ ! -x "$BUTLER" ]; then
  mkdir -p "$ROOT/.tools/butler"
  curl -fsSL -o "$ROOT/.tools/butler/butler.zip" https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default
  (cd "$ROOT/.tools/butler" && unzip -q -o butler.zip && rm butler.zip && chmod +x butler)
fi
VERSION="$(grep -m1 'version/name=' "$ROOT/export_presets.cfg" | cut -d'"' -f2)"
"$BUTLER" push "$ROOT/export/web" "$ITCH_TARGET:web" --userversion "$VERSION"

#!/usr/bin/env bash
# Model textures (extracted from assets/models/*.glb on import) are stored as
# lossy WebP instead of lossless: ~10x smaller APK for the same look on a phone.
# Run after adding a model: tools/model_textures.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$ROOT/tools/setup_godot.sh")"
"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
for f in "$ROOT"/assets/models/*.jpg.import; do
  [ -f "$f" ] || continue
  sed -i 's/^compress\/mode=0/compress\/mode=1/; s/^compress\/lossy_quality=.*/compress\/lossy_quality=0.8/' "$f"
done
"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
ls -la "$ROOT"/assets/models/*.jpg | awk '{s+=$5} END {print NR " doku, " int(s/1024) " KB (kaynak)"}'

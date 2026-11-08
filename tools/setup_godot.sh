#!/usr/bin/env bash
# Downloads the pinned Godot editor binary into .tools/ (once) and prints its path.
set -euo pipefail
VERSION="${GODOT_VERSION:-4.7.2-stable}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/.tools/godot-$VERSION"
BIN="$DIR/Godot_v${VERSION}_linux.x86_64"
if [ ! -x "$BIN" ]; then
  mkdir -p "$DIR"
  echo "Godot $VERSION indiriliyor..." >&2
  curl -fsSL --retry 5 --retry-delay 5 --retry-all-errors -o "$DIR/godot.zip" \
    "https://github.com/godotengine/godot/releases/download/${VERSION}/Godot_v${VERSION}_linux.x86_64.zip"
  (cd "$DIR" && unzip -q -o godot.zip && rm godot.zip)
  chmod +x "$BIN"
fi
echo "$BIN"

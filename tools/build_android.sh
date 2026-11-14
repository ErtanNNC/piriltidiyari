#!/usr/bin/env bash
# Builds export/PiriltiDiyari.apk (release template, arm64) without the Android SDK:
# Godot's non-Gradle export + our own v2 signer (tools/sign_apk.py).
# The SDK path only has to exist for Godot's checks; it points to stubs.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$ROOT/tools/setup_godot.sh")"
VER="${GODOT_VERSION:-4.7.2-stable}"
TPL="$HOME/.local/share/godot/export_templates/${VER/-/.}"
if [ ! -f "$TPL/android_debug.apk" ]; then
  echo "Android şablonları indiriliyor (1.3 GB, bir kez)..." >&2
  mkdir -p "$TPL" "$ROOT/.tools/tpl"
  curl -fsSL -o "$ROOT/.tools/tpl/t.tpz" \
    "https://github.com/godotengine/godot/releases/download/${VER}/Godot_v${VER}_export_templates.tpz"
  (cd "$ROOT/.tools/tpl" && unzip -o -q t.tpz templates/android_debug.apk templates/android_release.apk templates/version.txt \
    && mv templates/* "$TPL/" && rm -rf t.tpz templates)
fi
SDK="$ROOT/.tools/android-sdk-stub"
mkdir -p "$SDK/platform-tools" "$SDK/build-tools/35.0.0"
printf '#!/bin/sh\nexit 0\n' > "$SDK/platform-tools/adb"
printf '#!/bin/sh\necho "apksigner yok: tools/sign_apk.py imzalar" >&2\nexit 1\n' > "$SDK/build-tools/35.0.0/apksigner"
chmod +x "$SDK/platform-tools/adb" "$SDK/build-tools/35.0.0/apksigner"
"$GODOT" --headless --path "$ROOT" --quit >/dev/null 2>&1 || true   # creates editor settings
SETTINGS="$(ls "$HOME"/.config/godot/editor_settings-4*.tres | head -1)"
python3 - "$SETTINGS" "$SDK" <<'PY'
import re, sys
f, sdk = sys.argv[1], sys.argv[2]
s = open(f).read()
s = re.sub(r'\nexport/android/android_sdk_path = ".*"', '', s)
s = s.replace('[resource]\n', '[resource]\nexport/android/android_sdk_path = "%s"\n' % sdk, 1)
open(f, "w").write(s)
PY
mkdir -p "$ROOT/export"
"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
# release template (optimized, no debugger); BUILD=debug for a debug build.
# Still signed with the local test key: Play needs an AAB with your own
# upload key (docs/yayin-rehberi.md).
MODE="--export-${BUILD:-release}"
"$GODOT" --headless --path "$ROOT" "$MODE" "Android" "$ROOT/export/PiriltiDiyari-unsigned.apk" 2>&1 | grep -E "ERROR" || true
python3 "$ROOT/tools/sign_apk.py" "$ROOT/export/PiriltiDiyari-unsigned.apk" "$ROOT/export/PiriltiDiyari.apk" \
  --key "$ROOT/.tools/debug-key.pem" --cert "$ROOT/.tools/debug-cert.der"
rm -f "$ROOT/export/PiriltiDiyari-unsigned.apk"
# a copy named with the version (export_presets.cfg version/name), the one to hand out
VERSION="$(sed -n 's/^version\/name="\(.*\)"/\1/p' "$ROOT/export_presets.cfg" | head -1)"
rm -f "$ROOT"/export/PiriltiDiyari-[0-9]*.apk
cp "$ROOT/export/PiriltiDiyari.apk" "$ROOT/export/PiriltiDiyari-$VERSION.apk"
ls -la "$ROOT/export/PiriltiDiyari.apk" "$ROOT/export/PiriltiDiyari-$VERSION.apk"

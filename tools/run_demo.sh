#!/usr/bin/env bash
# Runs one headless gameplay demo and prints only its tagged lines and errors:
#   tools/run_demo.sh <scene> <demo> [seconds] [extra args...]
# Imports first (new class_names), and holds a lock so several runs (or
# agents) never import at the same time.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$ROOT/tools/setup_godot.sh")"
SCENE="$1"; DEMO="$2"; SECS="${3:-300}"; shift; shift; [ $# -gt 0 ] && shift
LOG="$(mktemp)"
(
  flock 9
  "$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
  timeout "$SECS" "$GODOT" --headless --path "$ROOT" -- --scene="$SCENE" --demo="$DEMO" "$@" >"$LOG" 2>&1
  echo "exit=$?"
) 9>/tmp/pirilti_godot.lock
grep -E "^[A-Z0-9_]{3,} |ERROR|SCRIPT|Parse|at: " "$LOG" | grep -v "resources still in use" | head -60
rm -f "$LOG"

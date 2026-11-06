# Pırıltı Diyarı — agent notes

Godot 4.7 (GDScript, GL Compatibility renderer), kids' 2.5D action RPG. Design
system and story live outside this repo (claude.ai artifacts); `design/tokens.json`
is a copy of the design system's tokens.

## Commands

- `tools/test.sh` — import + headless tests. Run before every commit.
- `tools/screenshot.sh out.png [--demo=talk|quest|kids|done] [--frames=N] [--touch]`
  renders under Xvfb with llvmpipe. Look at the PNG after any visual change.
- Godot is downloaded by `tools/setup_godot.sh` into `.tools/` (gitignored).

## Rules

- Colors, type, spacing, radii, strokes come from `Tokens` (design/tokens.json),
  never hard-coded hex in UI. World greybox colors may use local Colors.
- UI text: Turkish, "sen" address, dialogue lines ≤ 70 chars, no death/blood/fear
  words; nobody dies ("uykuya daldı", boss "uyandı"). Text on colored fills uses
  `on-color` (dark). No text on `leaf`.
- Touch targets ≥ 48px. Smallest text 14px (`text-caption`), reading text 18px.
- Story is data: new quests/dialogue go in `content/`, not code.
- Game rules stay in `src/core/` (RefCounted, no nodes) so tests can run them.
- Use `set_anchors_and_offsets_preset`, not `set_anchors_preset` (the latter
  leaves size 0 for code-built Controls).
- Identifiers in English; player-facing strings and docs in Turkish.

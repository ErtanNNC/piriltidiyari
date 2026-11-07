# Pırıltı Diyarı — agent notes

Godot 4.7 (GDScript, GL Compatibility renderer), kids' 2.5D action RPG. Design
system and story live outside this repo (claude.ai artifacts); `design/tokens.json`
is a copy of the design system's tokens.

## Commands

- `tools/test.sh` — import + headless tests. Run before every commit.
- `tools/screenshot.sh out.png [--scene=scene1..scene6|chapter0|chapter1|chapter2] [--demo=...] [--at=SECONDS | --frames=N] [--auto] [--touch]`
  renders under Xvfb with llvmpipe. `--scene` jumps there with earlier progress
  (DevTools.preset); `--auto` advances dialogue by itself; demos live in each
  scene script's `_run_demo`. Look at the PNG after any visual change.
- Gameplay checks run headless: `godot --headless --path . -- --scene=scene3 --demo=hop`
  (demos that print and quit: beamtest, touchtest, climb, hop, climb2, flow, win;
  chapter1: wrong, mobs, bossfight, spots with --keeper=pati|bado|citir|lumi;
  chapter2: crystals, bossfight).
- `tools/build_android.sh` builds and signs export/PiriltiDiyari.apk; bump
  version/code in export_presets.cfg for every APK you hand out.
- Godot is downloaded by `tools/setup_godot.sh` into `.tools/` (gitignored).

## Rules

- Colors, type, spacing, radii, strokes come from `Tokens` (design/tokens.json),
  never hard-coded hex in UI. World greybox colors may use local Colors.
- UI text: Turkish, "sen" address, dialogue lines ≤ 70 chars, no death/blood/fear
  words; nobody dies ("uykuya daldı", boss "uyandı"). Text on colored fills uses
  `on-color` (dark). No text on `leaf`.
- Touch targets ≥ 48px. Smallest text 14px (`text-caption`), reading text 18px.
- Story is data: new quests/dialogue/barks/cutscenes go in `content/<chapter>/`, not code.
- Every attack is announced 0.8 s ahead (`Mob.TELEGRAPH`); only one mob attacks
  at a time (`MobStats.MAX_ATTACKERS`). Nothing a kid must reach may become
  unreachable (mobs knocked off ledges return home).
- A chapter's `theme` (content/<chapter>/chapter.json) switches the UI to the
  design system's Gece theme ("dark"). Text drawn over the 3D scene with a dark
  outline uses `"panel@light"` so it stays light in both themes.
- Restoring a save relights things with `light_up(true)`, which must not emit
  `lit` (no repeated barks, notifies or gate openings).
- Mobs and bosses hold attacks while a dialogue is open (`GameState.in_dialogue`).
- Story stones must be reachable by every keeper; keeper-only corners hold Pırıl.
- Game rules stay in `src/core/` (RefCounted, no nodes) so tests can run them.
- On-screen buttons must send an `InputEventAction` (`TouchControls._send`), not
  only `Input.action_press`: attack/roll/skill react to events. Check with
  `-- --scene=scene2 --demo=touchtest --touch` (headless).
- Use `set_anchors_and_offsets_preset`, not `set_anchors_preset` (the latter
  leaves size 0 for code-built Controls).
- Identifiers in English; player-facing strings and docs in Turkish.

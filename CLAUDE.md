# Pırıltı Diyarı — agent notes

Godot 4.7 (GDScript, GL Compatibility renderer), kids' 2.5D action RPG. Design
system and story live outside this repo (claude.ai artifacts); `design/tokens.json`
is a copy of the design system's tokens.

## Commands

- `tools/test.sh` — import + headless tests. Run before every commit.
- `tools/screenshot.sh out.png [--scene=scene1..scene6|chapter0..chapter5|final] [--flag=name] [--pus=0..1] [--demo=...] [--at=SECONDS | --frames=N] [--auto] [--touch]`
  renders under Xvfb with llvmpipe. `--scene` jumps there with earlier progress
  (DevTools.preset); `--auto` advances dialogue by itself; demos live in each
  scene script's `_run_demo`. Look at the PNG after any visual change.
- Gameplay checks run headless: `godot --headless --path . -- --scene=scene3 --demo=hop`
  (demos that print and quit: beamtest, touchtest, climb, hop, climb2, flow, win (scene4);
  chapter1: wrong, mobs, bossfight, spots with --keeper=pati|bado|citir|lumi;
  chapter2: crystals, bossfight; chapter3: travel, wind, balloon, bossfight,
  spots with --keeper=...; chapter4: climb, ice, ramp, bossfight, spots; chapter5: walk, finalfight with --auto).
- Characters: build with named parts (Body, Head, HandL/R, FootL/R, Tail, EarL/R,
  WingL/R), faces via `Face.add`, then `CharacterRig.attach(root)` (blink, breath,
  steps). Use `"ellipsoid"` (honors size.z) for new parts. A `assets/models/<id>.glb`
  replaces any keeper/Fıstık/NPC placeholder through `ModelImport`. Preview:
  `--scene=preview [--demo=npcs|import|props|mobs]`. Mobs get the same rig
  (blink/breath); Pus mobs keep a faint tint of their own color (`MobModels._c`).
- Ground decor is automatic: `Decor.auto(scene, style)` in each scene's `_ready`
  scatters non-colliding MultiMesh props on upright floors; thin meshes are paths.
- Atmosphere comes with `WorldLook.add(parent, mood)`: sky shader (SKIES table),
  ground cloud shadows (global `cloud_shadow`), `Weather` particles + Pus wisps
  that follow Pus.amount, `Backdrop` scenery ring. Flat water/syrup/ice:
  `WorldLook.water(mesh, kind)`. Sky check: `--scene=preview --demo=sky --mood=...`.
- Sound: `Audio.play("name")` (assets/audio/sfx/<name>.wav), music per scene in
  `Audio.SCENE_MUSIC`, boss track via `Hud.show_boss/hide_boss`. Files are made by
  `python3 tools/make_audio.py [sfx|music [track...]]`; check with
  `--scene=preview --demo=audio` (headless). Every `Effects.warning` also plays "warn".
- Landed hits go through `Effects.hit(target, strong)` (sound, star, shake, 45 ms
  hit-stop via Engine.time_scale). Pırıl pickups have a magnet that needs a clear
  line and the same height, so keeper-only corners stay keeper-only.
- HUD has a Mola (pause) menu: `Hud.toggle_pause()`, Esc; `--demo=pause` opens it.
- New chapters extend `ChapterBase` (src/world/chapter_base.gd): npc(),
  boss_camera(), fly_spark(), and test helpers close_dialogs()/walk_to().
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
  Test each corner both ways: blocked without the ability, reachable with it
  (and the spot to stand on must be on solid ground).
- Keep side corners and props off the main route: a full scripted walk of the
  chapter (like chapter4 `climb`) catches walls placed across a path.
- An NPC's lesson/quest variant should also require the region lantern
  (`objective_done: <quest>/fener`), so "light the lantern first" can show.
- Game rules stay in `src/core/` (RefCounted, no nodes) so tests can run them.
- On-screen buttons must send an `InputEventAction` (`TouchControls._send`), not
  only `Input.action_press`: attack/roll/skill react to events. Check with
  `-- --scene=scene2 --demo=touchtest --touch` (headless).
- Use `set_anchors_and_offsets_preset`, not `set_anchors_preset` (the latter
  leaves size 0 for code-built Controls).
- Identifiers in English; player-facing strings and docs in Turkish.

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
  `--scene=preview [--demo=npcs|import|props|mobs]`; `--demo=ref --model=<id>` renders one
  character front-on, flat unlit colors, no outline, white background (reference for
  image-to-3D). Real models (Higgsfield art + Tripo) exist for every character:
  keepers, Fıstık, villagers, all mobs (Gölge Kopya greys the player's own model)
  and the six bosses (`--demo=bosses`; `ModelImport.with_parts(id, {"WingL": pos...})`
  adds the empty parts the boss code turns, and CharacterRig passes their
  rotation to that side of the model via `rig_arms`); json "pus": 0 keeps a
  model out of the scene's Pus grey; `<id>.json` sets facing (-90 for Tripo), height, tint,
  outline, glow, lift, "model" (reuse another id's file) and keeper "anchors"
  (Head/head_r/hat_scale/Body/HandL/HandR) so outfits and tools still attach.
  Imported mobs drain to Pus grey via the toon `desat` uniform. New model:
  `tools/shrink_glb.py` (1024 px textures) then `tools/model_textures.sh`
  (lossy WebP imports). Imported models have no skeleton: `src/world/rig.gdshaderinc`
  bends them by body region (feet step, arms swing/strike/cheer or wings flap,
  head looks/nods, tail wags; json "rig" tunes the regions), driven by
  `CharacterRig._animate_shape`; eyes blink with a lid drawn in the toon shader
  ("eyes" [x,y,r,z] fractions of the height + "lid" color, found by
  `--demo=eyes` + `tools/find_eyes.py`, run twice). Fur variants on textured
  keepers: json "fur" hue is shifted to the variant color (`fur_shift`).
  Checks: `--scene=preview --demo=anim --pose=walk|attack|blink|happy`, `--demo=fur`. Thin rings: use shape
  `"ring"` (size.y = tube thickness); `"torus"` reads size.y as the inner radius. Mobs get the same rig
  (blink/breath); Pus mobs keep a faint tint of their own color (`MobModels._c`).
- Ground decor is automatic: `Decor.auto(scene, style)` in each scene's `_ready`
  scatters non-colliding MultiMesh props on upright floors; thin meshes are paths.
- Rigged keepers: Pati, Bado, Çıtır and Lumi play real bone clips (idle,
  walk, run, jump, attack). The Meshy auto-rig placed bones badly (it took the
  +X-facing Tripo mesh for +Z), so `tools/rebuild_rig.py --turn=-90 idle=..`
  turns the mesh to +Z, builds a clean skeleton from the mesh shape, binds
  vertices by body region (head rigid, tail/wings on the hips) and retargets
  the clips (torso bends softened, `CALM`); their json has "facing": 0. Hats
  and tools ride the head/hand bones (`KeeperModels._follow_bones`).
  Shop tools (group "held_tool") tuck away while running and pop back when
  standing or striking (`CharacterRig._held_tools`).
  CharacterRig plays the clips (`CLIP_SPEED`); blink still via the toon
  shader; `ArmSwing` adds a strike only when a model has no attack clip.
  Checks: `--scene=preview --demo=rigtest --model=<id>`, from the side:
  `--demo=play --act=walk|attack|roll`. Attack is a short wind-up twist (no
  full spin); roll curls the model into a ball with a dust/sparkle trail.
- World props: `PropModel.swap(node, "prop_<kind>", keep, roof)` replaces a
  prop's primitive meshes with `assets/models/prop_*.glb` (same height and
  footprint; colliders, lights, particles and `keep` nodes stay; roof hue via
  json "fur"). Used by Prop (house, tree, well, lantern_post, bush, tower),
  ForestKit.face_tree, chapter4 pines, SmallLantern (lantern, campfire).
- Sound credits: most sfx and the ambience loops come from Meta's Oculus Audio
  Pack (CC BY 4.0, github.com/facebookincubator/Meta-open-sound,
  corpora/oculus-audio-pack/ogg), listed in `assets/audio/CREDITS.md`; keep
  that list current. New one: `tools/sfx_prep.py <file>.ogg assets/audio/sfx/<name>.wav`
  and add the name to `tools/make_audio.py` REAL. Ambience: `Audio.SCENE_AMBIENCE`
  (mono OGG in assets/audio/ambience, quiet, on the Sfx bus).
- Music: generated tracks become loops with `tools/music_loop.py`; sounds in
  `tools/make_audio.py` REAL come from `tools/sfx_prep.py` (not re-synthesized).
  Store assets and the Play guide: `docs/yayin-rehberi.md`, `docs/play/`,
  `assets/icon/`.
- Life: grass bends in rolling gusts (decor.gdshader), tree crowns rock via
  `Sway.crown(tree, from_y, pivot_y)` (one Sway node per scene), `AmbientLife`
  adds drifting 3D clouds and butterflies (when Pus < 0.45).
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
- Village houses: `HouseDoor` (chapter0) → scene "house" (`SceneFlow.house_id`
  dukkan|bekci, `SceneFlow.return_point` brings you back to the door; `go_to(id,
  save, card)`). Shop kinds in `Shop.buy`: outfit/weapon (owned + equipped in
  `PlayerData.equipped`), sling, ammo (count), charm. `PlayerData.switch_keeper`
  keeps the adventure. Tools change the J attack in `Player.spin_attack` (değnek
  bolt, asa wide ring, kılıç wave); outfits give `bonus` (items.json) via
  `Shop.outfit_bonus` (regen, speed, magnet, mp_regen, guard). Checks: `--scene=house --house=dukkan --demo=shopping`,
  `--house=bekci --demo=switch|mirror|wardrobe`, `--demo=leave`.
- Levels: mobs have `MobStats.LEVELS` (region ranges) and `MobStats.scaled(kind,
  level)` (HP vs `Progression.expected_power`, damage vs `expected_hp`, XP =
  22% of a level). Level gains: `Progression.hp_gain/power_gain`. Bosses take
  `Progression.boss_damage` (same hit count at any level). Each level adds a
  `PlayerData.power_picks`; the HUD shows `LevelUpPanel` (paused) with
  `Powers.choices`; demos auto-pick. Powers: 4 active (2 slots, O/P, HUD buttons
  on the left), 3 passive, rank 1–5 (`src/core/powers.gd`). `DevTools.preset`
  levels you to the region (`LEVEL_AT`); `PlayerData.catch_up()` lifts old saves.
  Checks: `--scene=chapter0 --demo=powers`, `--demo=levelup` (screenshot).
- Findability: `Beacon.attach(node, height, color)` puts a through-walls star on
  things to find (unlit crystals/lanterns, memories, unread stones); remove it when
  done (`Interactable.done()` does). `FollowCamera.turn(±1)` (Q/R, HUD "Çevir");
  Player input is rotated by `cam.yaw`. `--turn=N` starts turned (screenshots).
  Mola has "Takıldım" → `Player.unstick()`. `Mob.spawn` sets the mob's home
  (where it returns after falling).
- Signs: `TravelSign.board(parent, text, at, width)` (cream board, dark text,
  tilted to the camera, text shrinks to fit).
- New chapters extend `ChapterBase` (src/world/chapter_base.gd): npc(),
  boss_camera(), fly_spark(), and test helpers close_dialogs()/walk_to().
- `tools/build_web.sh` → export/web (no threads; template pulled by range
  requests with `tools/fetch_template.py`); `tools/publish_itch.sh` pushes it
  with butler (BUTLER_API_KEY, ITCH_TARGET). `.github/workflows/ci.yml` runs
  tests on every push/PR and builds web on main.
- Save slots: `SaveGame.SLOTS` (3), `SaveGame.slot` is the one in play (slot 1 =
  the old `user://kayit.json`); title has Devam et (`latest_slot`), Yeni oyun and
  Kayıtlar (`SaveSlotsPanel`, `--demo=slots|slotsnew`); Mola has "Kaydet".
  The HUD quest panel follows `PlayerData.tracked_quest(Content.quests)` (only
  the loaded chapter's quests). After a boss, `TravelSign.exit_home` shows a
  "Köye dön" sign by the Kıvılcım Feneri (`--near=ExitSign` for screenshots).
- Saves: `SaveGame.write` is atomic (.tmp → rename, .bak kept), `load_dict`
  falls back to .bak, `SaveGame.migrate` upgrades by VERSION. Stats are derived:
  `PlayerData.recompute_stats(Content.items)` from `base_stats` + level + charms
  + powers. Art direction for real models: docs/sanat-yonu.md.
- `tools/build_android.sh` builds and signs export/PiriltiDiyari.apk plus a
  copy named with the version (export/PiriltiDiyari-<version/name>.apk); bump
  version/code in export_presets.cfg for every APK you hand out, and hand out
  the versioned file.
- Godot is downloaded by `tools/setup_godot.sh` into `.tools/` (gitignored).

## Season 2 (Kor Vadisi)

- Opens only after Season 1's ending (flag "sezon1_bitti"): the season summary
  (`SeasonEnd`) has "Sezon 2'ye başla" next to "Köyde dolaş"/"Ana menü", and the
  title shows it while the newest save qualifies (`PlayerData.can_start_season2`).
  `SeasonFlow.start_season2` → `PlayerData.start_season2`: level 1, no powers,
  skills or Pırıl; owned outfits/tools/charms stay; `season` = 2, the Season 1
  keeper is kept in `s1_keeper`; `catch_up` never lifts a Season 2 save.
- Story pack `content/s2_prologue/`; scenes `s2_scene1` (Mırıl'ın İlk Doğum
  Günü: invitations, glide course to Çıtır's hill) and `s2_scene2` (Kırmızı
  Rüzgâr). The prologue is played as Mırıl (`character_id` "miril",
  `MirilModel.star_child`, no Pus grey): hold jump while falling to float
  (`Player.GLIDE_TIME`). Keepers can be NPC kinds (`Npc.kind` pati/bado/citir/lumi).
- Kızıl Sis: `Pus.set_color(Pus.RED)` (global `pus_color`; SceneFlow resets to
  grey). Köpüklüler (`MobStats` "breath": kopuklu_tavuk, gurultucu_kurbaga) sit
  dazed at 0 HP (`Mob._daze`, group "dazed") until Sakinleş (C / touch
  "Sakinleş", hold: `BreathCalm` ring, `Mob.breathe_calm`, double Pırıl,
  events "breathe" + kind/"any"), or calm by themselves after `DAZE_TIME`.
  Their angry look: toon `desat` toward `desat_tint` (warm red) + steam.
- Öfke barı (`BreathCalm.anger`, HUD `StatBar` "anger"): scenes set
  `player.calm.heat` inside thick mist; full = kızgın (×1.5 hits, wobbly walk, no
  Sakinleş for others); hold Sakinleş alone or Nane Şekeri (`buff` "serin") cools it.
- Prologue scenes 3–6: `s2_scene3` Yankıların Peşinde (steam springs warned like
  attacks, chasm only a float crosses, first level-up, Mırıl's skill Yıldız
  Ninnisi → `Mob.lull`, event "lull"), `s2_scene4` Gürledek boss (`GurledekPlan`
  in core, `Gurledek` actor: hittable only while low; at 0 HP it cries in group
  "dazed" with meta `calm_reach`, Sakinleş ends the fight), `s2_scene5` cutscene
  Mırıl'ın Seçimi (`HirilModel`), `s2_scene6` Kulak Bekçileri: Tıpış
  (`tipis_panda`, real model, skill Derin Nefes = `Player._guard_until`) and the
  5-keeper select (`KeeperSelect.order/lines` from `content/keepers_s2.json`,
  `Content.keeper(id)` finds S1 and S2 keepers; S1 tests iterate only
  `Content.keepers`). Choosing resets powers, level 1, then `PrologueDone`.
- Bölüm 0 `s2_chapter0` (Buharlı Kaplıca Köyü, pack `content/s2_chapter0/`):
  four neighbours talk over each other (Label3D shouts until heard; quest
  `kopuk_koy`), Tospik Nine (shop "tospik", open except while she hands out a
  quest), Madenci Kazma's anvil stall (shop "kazma": tools, sling, seeds),
  mini boss Homurdanan Çaydanlık (`KettlePlan` + `Kettle`:
  jets/splash warned, hittable while the lid is up, Sakinleş at the end), and
  the first Ses Çanı (`EchoBell`, `needs` = "quest/objective", flag `s2_can0`,
  event "ring"/"ses_cani") that lifts the Kızıl Sis. `PrologueDone` leads here.
- Bölüm 1 `s2_chapter1` (Kızıl Yaprak Ormanı, pack `content/s2_chapter1/`,
  entered from Bölüm 0's north exit once `s2_can0` rang): Kapıcı Rakunlar carry
  the cubs' toys (`Mob` meta "carry" drops a Pickup when calmed; quest
  `once_sor` delivers them), Somurtkan Sincap throws acorns, the forest bell
  (`EchoBell.needs` = a whole quest) opens the Sis Perdesi, boss Tilki Fırfır
  (`FirfirPlan` + `Firfir`: leaf circles, a dash, sits tired = hittable,
  Sakinleş ends it) gives the Turuncu Kor (flag `kor_turuncu`); Terzi Dikiş
  runs the forest stall. New primitive creatures (raccoon, squirrel, fox...)
  are placeholders: an `assets/models/<id>.glb` replaces them.
- Bölüm 2 `s2_chapter2` (Fokurdayan Göl, from Bölüm 1's north exit after
  `s2_bolum1_bitti`): frogs heard in turn (ordered quest `sira_bekle`, dialogue
  variants need the previous objective), Demlik's shop with Papatya Çayı (buff
  "papatya" → `BreathCalm.fast_until`), a boiling lake (hot-water Area puts you
  back at `respawn_point`), lily pads to the island, boss Kaynar Kurbağa Fokur
  (`FokurPlan` + `Fokur`: bubbles, croak ring, hop → tired = hittable), Mercan
  Kor (flag `kor_mercan`). Exits back are TriggerAreas at the map edges (keep
  spawn points away from them).
- Bölüm 3 `s2_chapter3` (Patpat Tarlaları, from the lake island's north edge
  after `s2_bolum2_bitti`): fair games at `FairStall`s ("Oyna" → `_on_play`):
  Balon Patlat (`FairBalloon`, hittable) and Bayrak Koşusu (flags in order),
  timed; losing just lets you play again (events "win"/<game>). Popping corn
  spots in the fields (warned). Boss Tavuk Patpat = `Patpat extends Firfir`
  (`_make_model`, `attack_color`, `tired_hint`, `calm_event`), Kehribar Kor
  (`kor_kehribar`), then Minnoş runs off (`s2_minnos_kacti`). HUD shows the five
  Kor (`KorTracker`, flags `kor_<id>`) once `s2_prolog_bitti`.
- Bölüm 4 `s2_chapter4` (Gümbür Kanyonu, from Patpat Tarlaları' north edge
  after `s2_bolum3_bitti`): Keçi Yavrusu Çıngır (`goat_kid`, `MobModels.goat`)
  asks for the five teasing echoes (shouting Label3D orbs, flags
  `s2c4_yanki<i>`, objective `collect`/"yanki" count 5) and the old drumstick
  (`collect`/"tokmak"); mobs Yankı Yarasası and Tepinen Keçi; the canyon bell
  `s2_can4` opens the Ritim Arenası. Boss Davulcu Keçi Gümbür = `Gumbur extends
  Firfir` with `GumburPlan` bars ("x" hit at the keeper, "o" ring round him,
  "-" quiet; one beat = `Mob.TELEGRAPH`, so every hit lands one beat after its
  warning), then rests (hittable). Calmed, he knows Hırıl's drumstick: memory
  (`_memory`, small calm Hırıl drumming, flag `s2c4_ani`), then Bakır Kor
  (`kor_bakir`); Çıngır sends you on to Kükreyen Dağ (`s2_bolum4_bitti`).
- Bölüm 5 `s2_chapter5` (Kükreyen Dağ, the final; from the canyon's north
  edge after `s2_bolum4_bitti`): Davulcu Gümbür (NPC kind "gumbur") asks for
  the five words on the walls (boards read barks `s2c5_e<i>`, objective
  `collect`/"hiril_soz") and Minnoş, who sits alone (`SittingFriend`: group
  "dazed", Sakinleş beside him, event "breathe"/"minnos"). Bell `s2_can5`.
  Boss `Hiril extends Firfir` (`HirilPlan`: lava balls, calls up earlier
  Köpüklüler, tired = hittable). At 0 HP Faz 2: no fighting; word orbs float
  round the summit, each goes back to him (`_play_echo`: his line, `Hud.ask`
  with the replies in bark `s2c5_cevap`), `hear(n)` lowers the steam; the
  fifth → `become_calm` (event "listen"/"hiril"), Tıpış says sorry (NPC unless
  you are Tıpış), Al Kor (`kor_al`); talking to Mırıl sets `sezon2_bitti` →
  `s2_final` (Gökkuşağı Şenliği, cutscene `s2_chapter5/cutscenes/senlik.json`:
  the five Kor fly to the Fener, seven colors + rainbow arc, Fıstık hands Hırıl
  a drum, everyone dances, keeper beat `s2f_<id>`, a blue trembling mist over
  the sea = next season's seed) → `Season2End` (line per keeper in `ENDINGS`),
  save goes to s2_chapter0.
- Yol arkadaşları: Season 1 friends travel along (Sahne 6 `companions_arrive`,
  bark `s6b_yol`) and fill Season 2's roles instead of new characters (saves
  model credits, keeps the story together): Tospik Nine (Kaplıca Köyü guide
  and stall), Madenci Kazma (smith), Terzi Dikiş (forest tailor), Kaptan
  Pırpır (runs the Patpat fair). Çıngır reuses Gümbür's model
  (`goat_kid.json` "model"). The Season 1 duckling is Vakvak (Tıpış is only
  the red panda).
- Season 2 calming skills (`Skills` "season": 2, learned at `S2_LEVEL` 5 via
  `PlayerData.learn_season_skill`, then on the skill button): Pati Mırlama
  (lulls Köpüklüler around), Bado Kocaman Sarılma (nearest Köpüklü calms at
  once), Çıtır Komik Yüz (laugh: lull in a wider ring), Lumi Ninni Işığı
  (`Mob.slow` + heal). Check: `--scene=s2_chapter0 --demo=skills`.
- Rung Ses Çanları are travel points ("Seyahat", `BellTravel` in core, arrival
  via `SceneFlow.return_point` + `ChapterBase.take_return_point`); check:
  `--scene=s2_chapter4 --demo=travel`. Sis Kalkanı potion (buff "sis_kalkani"
  → `BreathCalm.shield_until`), Gümbür's drum stall in the canyon after he
  calms (shop "gumbur", Ritim Tılsımı: charm "power").
- Kaplıca Köyü has a Bekçi Evi (`HouseDoor` "bekci" on the first house):
  the house scene goes back to `SceneFlow.house_from` (the door's own scene),
  in Season 2 the mirror and pedestals show all five keepers (Tıpış too) and
  `switch_keeper` also brings the new keeper's calming skill. Check:
  `--scene=s2_chapter0 --demo=bekci` (in and out, headless).
- After a Season 2 boss the quest giver comes to the arena (`ChapterBase.
  giver_comes`, also placed there on reload once the Kor is taken) so the last
  talk happens there; `way_on(flag, exit, region)` then stars the exit to the
  next region with a hint. Fokur's fight: tongue along a warned line, hops
  between attacks (`_shuffle`), and every cycle ends with his song: wait it
  out for a long rest (`SONG_REST`), hit him during it and he croaks back
  (`--scene=s2_chapter2 --demo=song|tongue`).
- Attack warnings (`Effects.warning`, every boss and mob in both seasons): a
  bold red ring with a dark edge drawn over the ground decor, and a red fill
  growing from the middle that lands when it reaches the ring.
- Region exits ask first: `SceneFlow.ask_go(scene)` ("… yoluna çıkalım mı?",
  Evet/Burada kal) instead of switching on contact; exit TriggerAreas are
  `once = false` so they ask again (`--scene=s2_chapter3 --demo=exit`).
  `SceneFlow.go_to` releases every held input before and after the change
  (a held stick used to keep the keeper walking in the next scene).
- Map edges (`Backdrop._border`, every scene with a WorldLook mood except
  islands/spires): a frame of ground continues outside the walkable area and
  a ring of low mounds with bushes/trees/rocks marks the edge, gaps at exits.
  The edge comes from WorldBoundary walls, else the floors connected to the
  ground at the keeper's height. `--zoom=N` (FollowCamera) for wide shots.
- Mobs don't twitch: chase uses hysteresis (`_circling`) and the facing is
  smoothed (`_face_dir`); a mob on the edge of its circling distance used to
  flip direction every other frame.
- Shops: a chapter's `chapter.json` needs `"shop": "shop"` or its shop.json is
  never loaded (a test checks every `open_shop` in the Season 2 packs). Stalls:
  Tospik (Kaplıca Köyü), Kazma (Kaplıca Köyü), Dikiş (forest, outfits), Demlik
  (lake), Pırpır (fair), Gümbür (canyon).
- Never a dead end: `s2_scene3` respawns Köpüklüler when too few are left to
  lull or to breathe with (check `--scene=s2_scene3 --demo=hitfirst`).
- Kızıl Sis mobs keep their own colors: their builders use `_c(false, ...)`
  (only the face and steam show the anger).
- Checks: `--scene=s2_scene1 --demo=glide|jump|party`, `--scene=s2_scene2 --demo=redwind|breath|guide|angry`,
  `--scene=s2_scene3 --demo=path|jumponly|stairs`, `--scene=s2_scene4 --demo=win --auto`,
  `--scene=s2_scene5 --demo=flow --auto`, `--scene=s2_scene6 --demo=pick_<id> --auto`,
  `--scene=s2_chapter0 --demo=village|bell_locked|stairs [--keeper=tipis_panda]`,
  `--scene=s2_chapter1 --demo=forest|veil|boss`, `--scene=s2_chapter2 --demo=lake|water|pads`,
  `--scene=s2_chapter3 --demo=fair|stalls`,
  `--scene=s2_chapter4 --demo=canyon|dodge|arena|echo`,
  `--scene=s2_chapter5 --demo=summit|faz2|arena|minnos|words`,
  `--scene=s2_final --demo=run --auto` (prints S2FINAL and quits).

## Agent skills

`.claude/skills/` holds a selection of gamedev skills from
github.com/gamedev-skills/awesome-gamedev-agent-skills (Apache-2.0, see the
LICENSE-/NOTICE- files there): `router` picks the right ones; Godot 4.7 engine
skills plus game-feel, camera-systems, game-ui-ux, audio-design, save-systems,
performance-optimization, level-design, rpg, create-game-assets and others.
They are general advice; this file's rules win where they differ. Excluded
from exports (`.claude/*` in export_presets.cfg).

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
  only `Input.action_press`: attack/roll/skill react to events. Touch layout:
  floating stick on the left, round Vur button bottom right with Zıpla,
  Yuvarlan, skill, both powers and At on an arc (`TouchControls.power_buttons`
  replace the HUD's left power bar), drag the right side to turn/tilt the
  camera (`FollowCamera.drag`; no Çevir button on touch). The arc is laid out
  in the control's own (safe-area) rect, never the viewport's. Every pause
  (level-up, Mola) calls `Hud._release_touch()` so nothing stays held. Check
  with `-- --scene=scene2 --demo=touchtest --touch` (headless).
- Use `set_anchors_and_offsets_preset`, not `set_anchors_preset` (the latter
  leaves size 0 for code-built Controls).
- Identifiers in English; player-facing strings and docs in Turkish.
- English: Turkish text is the source; `translations/en.po` (built from
  `translations/strings.json` by `tools/i18n_build.py`) translates it. Labels,
  buttons and Label3D translate by themselves; a formatted string must go
  through `TranslationServer.translate("…%s…") % [TranslationServer.translate(def["name"]), …]`
  (content values inside too). After adding text: `python3 tools/i18n_extract.py`,
  fill the empty English values, `python3 tools/i18n_build.py`; `tools/test.sh`
  fails on any untranslated string. Language: `Audio.language` ("tr"/"en",
  first run follows the phone), Dil/Language button on the title and in Mola,
  `--lang=en` for screenshots (the fallback locale is "tr", so Turkish shows the
  source text; with the default "en" fallback Turkish players saw English).
  English names follow the story doc's "İngilizce İsimler" tab: Glimmerland
  (app name via `config/name_localized`), the Gloom (Pus), Glim (Pırıl), Peanut,
  Paws, Crunch, Mumble, Granny Shelly, Teacher Hoo, King Stump, Pinch, Gale.

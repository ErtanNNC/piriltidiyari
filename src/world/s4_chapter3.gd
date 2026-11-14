extends S4Garden
## Sezon 4 · Bölüm 3 – Yuva Ağacı (Gül Tohumu). A giant tree full of nest
## houses. Serçe Pıtpıt has shut the top nest with thorns since four new
## chicks hatched: he thinks nobody looks at him any more. Anne Serçe (she
## can't leave the chicks) asks you to climb ("dallara_tirman"): clap for
## three nest houses, plant three vine ladders, calm four Dikenciler. Then
## the ark sluice on the upper branch opens ("kapali_yuva"): the thorn hedge
## on the top level dries, Pıtpıt fights, sulks, gets his clap; his mother
## shows him the first feather she wove into the nest ("Sen benim ilk
## yuvamsın"), four chicks hop out and he decides to teach them to fly. The
## Gül Tohumu drops, then Dırıl's first memory (`s4c3_ani`). Side story:
## Bado (or you, as Bado) and Minnoş half-way up.
##
## Layout (the camera looks from the south, +z; every level is a solid
## terrace, so a fall only lands on the level below and the ladders stay):
##   ground  y 0  z 30..6    gate (z 29), Anne Serçe, nest 0, ladder A (x -13)
##   level 1 y 3  z 6..-2    west half (nest 1) – hanging bridge over the
##                           6 m gap – east half (Bado + Minnoş, ladder B x 7)
##   level 2 y 6  z -2..-10  nest 2 (east), the ark (west), ladder C (x -4)
##   level 3 y 9  z -10..-32 landing, the hedge (z -12.5), Pıtpıt's arena
##                           (z -20), the top nest under the giant trunk
## Yonca's corner: a perch in the east corridor (x 21, z 2) with Pırıl.

const Q1 := "dallara_tirman"
const Q2 := "kapali_yuva"
const GRASS := Color("#8fcf7a")
const WOOD := Color("#b98a5a")
const BARK := Color("#8a6040")
const ARENA := Vector3(0, 9.0, -20.0)
const ANNE_AT := Vector3(3.5, 0, 21.0)
## A vine stair runs sideways up a terrace's south face (in view, gentle)
const RISE := Vector3(7.2, 3.0, -0.6)
## Nest houses [house position, thorns in front]: thorn patches 0..2
const NESTS := [Vector3(-17, 0, 15), Vector3(-13.5, 3, 0), Vector3(11, 6, -7.8)]
const LADDERS := [Vector3(-13, 0, 7.0), Vector3(7.0, 3, -1.0), Vector3(-4, 6, -9.0)]
const DIKENCILER := [["somurtkan_civciv", Vector3(-3, 0, 15)], ["itici_sincap", Vector3(7, 0, 12)],
	["somurtkan_civciv", Vector3(-10, 3, 3.5)], ["itici_sincap", Vector3(6, 6, -6)]]
const SIDE_AT := Vector3(12.5, 3, 3.8)

var _hedge: ThornPatch
var _door: ThornPatch
var _nests: Array[ThornPatch] = []
var _ladders: Array[SeedPlot] = []
var _corner: SeedPlot
var _mobs := false
var _chicks := false
var _was_high := false


func _ready() -> void:
	begin_garden("s4_chapter3")
	var d := GameState.data
	ark_flag = "s4_ark3"
	haze(0.3)
	_build()
	Decor.auto(self, "koy")
	var anne := npc(self, "anne_serce", "pitpit", ANNE_AT, -150.0)
	anne.name = "AnneSerce"
	anne.scale = Vector3.ONE * 1.25
	_side_story()
	var calm := d.objective_done(Q2, "pitpit")
	make_boss("pitpit", ARENA, calm)
	if calm:
		_show_chicks(false)
		if not _door.is_open:
			_door.open()
		if d.quest_state(Q2) != "done":
			giver_comes("AnneSerce", ARENA + Vector3(3.5, 0, 5.0), false)
			drop_seed("gul", ARENA + Vector3(0, 0, 3.0), "Gül Tohumu", "Sevgi paylaşılınca çoğalır")
	_spawn_mobs()
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.8, false).timeout
	if not d.has_flag("s4c3_geldi"):
		d.set_flag("s4c3_geldi")
		GameState.bark("s4k3_basla")
	elif d.has_flag("tohum_gul") and not d.has_flag("s4c3_ani"):
		_memory()
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _build() -> void:
	land(Vector3(0, 0, -6), Vector2(52, 76), GRASS)
	fence(Vector3(0, 0, -1), Vector2(48, 62))
	gate(Vector3(0, 0, 29.0))
	WorldLook.block(lv, Vector3(0, 0.02, 20), Vector3(3.0, 0.04, 16), Color("#e6d3a8"), 0.0)
	WorldLook.block(lv, Vector3(-7.0, 0.02, 11.0), Vector3(14.0, 0.04, 2.4), Color("#e6d3a8"), 0.0)
	# the terraces (solid down to the ground: no pits)
	land(Vector3(-9.5, 0, 2), Vector2(13, 8), WOOD, 3.0, 6.0)
	land(Vector3(9.5, 0, 2), Vector2(13, 8), WOOD, 3.0, 6.0)
	land(Vector3(0, 0, -6), Vector2(32, 8), WOOD, 6.0, 9.0)
	land(Vector3(0, 0, -21), Vector2(32, 22), WOOD, 9.0, 12.0)
	_hanging_bridge()
	# the giant trunk behind the top level, the top nest at its foot
	if prop("dev_kutuk", Vector3(0, 0, -42.0), 28.0) == null:
		Toon.part(lv, "cylinder", Vector3(18, 28, 18), BARK, Vector3(0, 14, -42))
	var top := prop("yuva_evi", Vector3(0, 9, -30.0), 5.0)
	if top == null:
		Toon.part(lv, "sphere", Vector3(5, 4, 5), WOOD, Vector3(0, 11, -30))
	_solid(Vector3(0, 9, -30.5), Vector3(5.0, 5.0, 3.0))
	# three nest houses, each behind its own clump (thorn patches 0..2)
	for at: Vector3 in NESTS:
		if prop("yuva_evi", at, 2.8, 0.0) == null:
			Toon.part(lv, "sphere", Vector3(2.6, 2.4, 2.6), WOOD, at + Vector3(0, 1.2, 0))
		_solid(at, Vector3(2.2, 3.0, 2.0))
		var t := thorns(at + Vector3(0, 0, 2.2), 4.0, false, true, "yuva")
		t.retracted.connect(func(_t: ThornPatch) -> void:
			if not GameState.data.has_flag("s4c3_ilk_yuva"):
				GameState.data.set_flag("s4c3_ilk_yuva")
				GameState.bark("s4k3_yuva"))
		_nests.append(t)
	# two clumps beside the route (patches 3, 4): they only prick the bar
	thorns(Vector3(5.5, 0, 16.5), 3.0, false)
	thorns(Vector3(1.0, 6, -3.4), 3.0, false)
	# vine ladders: the only way up from level to level
	for at: Vector3 in LADDERS:
		var p := plot(at, "merdiven", RISE)
		p.grown.connect(func(_p: SeedPlot) -> void:
			if not GameState.data.has_flag("s4c3_ilk_merdiven"):
				GameState.data.set_flag("s4c3_ilk_merdiven")
				GameState.bark("s4k3_merdiven"))
		_ladders.append(p)
		_ramp_when_grown(p)
	# the ark on the upper branch; the hedge across the top level (patch 5)
	ark(Vector3(-11.0, 6, -7.0), "s4_ark3", Q1, "s4k3_kilit", PI)
	_hedge = thorns(Vector3(0, 9, -12.5), 32.0, true)
	if GameState.data.has_flag("s4_ark3") and not _hedge.is_open:
		_hedge.open()
	# Pıtpıt's own thorns over the nest door (patch 6): a look, not a hazard
	_door = thorns(Vector3(0, 9, -28.2), 4.5, false)
	_door.strength = 0.0
	# Yonca's corner: a perch in the east corridor with Pırıl on it
	land(Vector3(21, 0, 2), Vector2(4, 4), WOOD, 3.0, 6.0)
	_corner = plot(Vector3(21, 0, 12.2), "merdiven", Vector3(0, 3.0, -7.5), true)
	_ramp_when_grown(_corner)
	if not GameState.data.has_flag("s4c3_kose"):
		for k in 4:
			var pk := Pickup.new()
			pk.amount = 6
			add_child(pk)
			pk.global_position = Vector3(20.2 + 1.6 * (k % 2), 3.0, 1.2 + 1.6 * (k / 2))
		var got := TriggerArea.new()
		got.area_id = "s4c3_kose"
		got.radius = 1.6
		add_child(got)
		got.position = Vector3(21, 3, 2)
		got.reached.connect(func() -> void: GameState.data.set_flag("s4c3_kose"))
	# scenery, off the route
	prop("yuva_evi", Vector3(14.0, 3, 5.0), 2.4, 0.5)
	prop("yuva_evi", Vector3(-13.5, 6, -8.0), 2.4, -0.4)
	prop("yuva_evi", Vector3(12.5, 9, -15.5), 2.6, -0.6)
	prop("yuva_evi", Vector3(-12.5, 9, -16.0), 2.6, 0.6)
	for p: Vector3 in [Vector3(-20, 0, 24), Vector3(20, 0, 24), Vector3(-21, 0, 6), Vector3(-21, 0, 16)]:
		prop("prop_tree", p, 5.0, p.x)
	for p: Vector3 in [Vector3(-12, 0, 22), Vector3(13, 0, 19), Vector3(-21, 0, 12)]:
		prop("koy_cali", p, 1.2, p.z)
	prop("cicek_tarhi", Vector3(8, 0, 23.5), 1.0, 0.3)
	prop("saksi", Vector3(-3, 0, 26), 0.8, 0.0)
	prop("gul", Vector3(-6.5, 9, -27.5), 1.6, 0.0)
	prop("gul", Vector3(6.5, 9, -27.5), 1.6, 0.5)


func _ramp_when_grown(p: SeedPlot) -> void:
	if p.is_grown:
		_ramp(p)
	else:
		p.grown.connect(_ramp)


## The keeper has no step-up (a 0.4 m leaf step is a wall to walk into), so
## a grown vine stair gets an unseen slope along the front edges of its
## steps: it is walked up, no jumping needed.
func _ramp(p: SeedPlot) -> void:
	var run := Vector2(p.span.x, p.span.z)
	var along_x := absf(run.x) > absf(run.y)
	var from := -(1.6 if along_x else 0.7)
	var to := run.length() + from
	var tilt := atan2(p.span.y, to - from)
	var holder := Node3D.new()
	p.add_child(holder)
	holder.rotation.y = atan2(-run.y, run.x)
	var body := StaticBody3D.new()
	body.set_meta("camera_ignore", true)
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(Vector2(to - from, p.span.y).length(), 0.3, 2.2)
	c.shape = b
	body.add_child(c)
	holder.add_child(body)
	body.rotation.z = tilt
	body.position = Vector3((from + to) * 0.5 + sin(tilt) * 0.15, p.span.y * 0.5 - cos(tilt) * 0.15, 0)


## An invisible box so nobody walks through a nest house.
func _solid(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	c.shape = b
	c.position.y = size.y * 0.5
	body.add_child(c)
	body.position = at
	lv.add_child(body)


## Planks on ropes between the two halves of level 1 (always there).
func _hanging_bridge() -> void:
	WorldLook.block(lv, Vector3(0, 2.86, 2.0), Vector3(7.0, 0.28, 2.6), Color("#d9b37a"), 0.02)
	for i in 7:
		Toon.part(lv, "box", Vector3(0.12, 0.05, 2.6), BARK, Vector3(-3.0 + i, 3.02, 2.0), Vector3.ZERO, 0.0, 0.0)
	for sx: float in [-3.4, 3.4]:
		for sz: float in [0.6, 3.4]:
			Toon.part(lv, "cylinder", Vector3(0.22, 1.3, 0.22), BARK, Vector3(sx, 3.65, sz))
	for sz: float in [0.6, 3.4]:
		Toon.part(lv, "box", Vector3(6.8, 0.07, 0.07), Color("#e8d8b0"), Vector3(0, 4.0, sz), Vector3.ZERO, 0.0, 0.0)


## Half-way up: Bado notices his own little thorn. As keeper Bado you say it
## yourself to Minnoş (npc "minnos"); otherwise an NPC Bado stands there with
## him (both answer as "bado").
func _side_story() -> void:
	var me := GameState.data.character_id == "bado"
	if not me:
		npc(self, "bado", "bado", SIDE_AT, -160.0).name = "Bado"
	var m := npc(self, "minnos" if me else "bado", "bado", SIDE_AT + Vector3(-1.7, 0, 0.5), 160.0)
	m.name = "Minnos"
	m.scale = Vector3.ONE * 0.6


## The Dikenciler come with Quest 1 (calmed before it they wouldn't count).
func _spawn_mobs() -> void:
	var d := GameState.data
	if _mobs or d.quest_state(Q1) != "active":
		return
	_mobs = true
	var done := d.objective_count(Q1, "dikenci").x
	for i in range(mini(done, DIKENCILER.size()), DIKENCILER.size()):
		dikenci(DIKENCILER[i][0], DIKENCILER[i][1])
	if not d.has_flag("s4c3_ilk_dikenci"):
		d.set_flag("s4c3_ilk_dikenci")
		GameState.bark("s4k3_dikenci")


## Nests clapped open and ladders grown before the quest asked still count
## (they stay done by their flags, so their events never come again).
func _recount() -> void:
	var d := GameState.data
	if d.quest_state(Q1) != "active":
		return
	var open := _nests.filter(func(t: ThornPatch) -> bool: return t.is_open).size()
	var grown := _ladders.filter(func(p: SeedPlot) -> bool: return p.is_grown).size()
	for e: Array in [["alkis", open], ["merdiven", grown]]:
		var c := d.objective_count(Q1, e[0])
		if int(e[1]) > c.x and c.x < c.y:
			d.advance_objective(Q1, e[0], mini(int(e[1]), c.y) - c.x)


func _process(delta: float) -> void:
	super._process(delta)
	# a fall from a branch: soft, and a line that says the way up is still there
	var y := _player.global_position.y
	if y > 2.5:
		_was_high = true
	elif y < 0.6 and _was_high:
		_was_high = false
		var d := GameState.data
		if not d.has_flag("s4c3_dustum") and not fighting and not GameState.in_dialogue:
			d.set_flag("s4c3_dustum")
			GameState.bark("s4k3_dustum")


func _on_ark() -> void:
	_hedge.open()
	GameState.bark("s4k3_ark")
	_refresh()


func fight_ready() -> bool:
	var d := GameState.data
	return d.quest_state(Q2) == "active" and d.has_flag("s4_ark3") and not d.objective_done(Q2, "pitpit")


func _begin_fight() -> void:
	start_fight("s4k3_pitpit", "Rüzgâra karşı yürü, atılınca kenara çekil. Yorulunca vur!", "Rüzgârdan kaç, yorulunca vur!")


## His mother shows him the first feather, the chicks hop out, the seed drops.
func _on_boss_calmed() -> void:
	_hud.clear_hint()
	boss_camera(false)
	fighting = false
	Effects.sparkle(self, boss.global_position + Vector3.UP * 2.0, Tokens.color("spark-yellow"), 16)
	GameState.bark("s4k3_sakin")
	await GameState.dialogue_closed
	await giver_comes("AnneSerce", ARENA + Vector3(3.5, 0, 5.0))
	var anne := get_node("AnneSerce") as Node3D
	var feather := Toon.part(self, "ellipsoid", Vector3(0.22, 0.7, 0.08), Color("#fff3d6"), anne.global_position + Vector3(-0.9, 1.6, 0), Vector3(0, 0, 25), 1.4, 0.02)
	var ft := feather.create_tween()
	ft.tween_property(feather, "position:y", feather.position.y + 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	Effects.sparkle(self, feather.global_position, Tokens.color("spark-white"), 14)
	Audio.play("memory")
	GameState.bark("s4k3_tuy")
	await GameState.dialogue_closed
	feather.queue_free()
	if not _door.is_open:
		_door.open()
	_show_chicks(true)
	Audio.play("laugh")
	GameState.bark("s4k3_kardes")
	await GameState.dialogue_closed
	drop_seed("gul", ARENA + Vector3(0, 0, 3.0), "Gül Tohumu", "Sevgi paylaşılınca çoğalır")
	_refresh()


## The four new chicks hop about in front of the top nest (scenery, not mobs).
func _show_chicks(pop: bool) -> void:
	if _chicks:
		return
	_chicks = true
	for i in 4:
		var at := Vector3(-2.7 + 1.8 * i, 9.0, -25.6 + 0.5 * (i % 2))
		var c := prop("somurtkan_civciv", at, 0.7, PI * 0.1 * (i - 1.5))
		if c == null:
			c = Node3D.new()
			lv.add_child(c)
			c.position = at
			Toon.part(c, "sphere", Vector3(0.6, 0.6, 0.6), Color("#ffe08a"), Vector3(0, 0.3, 0))
		if pop:
			Effects.sparkle(self, at + Vector3.UP * 0.5, Tokens.color("spark-yellow"), 6)
		var tw := c.create_tween().set_loops()
		tw.tween_interval(0.25 * i)
		tw.tween_property(c, "position:y", at.y + 0.45, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "position:y", at.y, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_interval(0.9 - 0.25 * i)


func _on_seed(_id: String) -> void:
	GameState.bark("s4k3_tohum")
	await GameState.dialogue_closed
	await _memory()
	_refresh()


## What the seed remembers: Dırıl's first memory.
func _memory() -> void:
	var d := GameState.data
	if d.has_flag("s4c3_ani"):
		return
	d.set_flag("s4c3_ani")
	Audio.play("memory")
	_hud.show_scene_card("Anı", "Gölgeli Köşe", "Dırıl'ın ilk anısı")
	await get_tree().create_timer(2.6, false).timeout
	GameState.bark("s4k3_ani")
	await GameState.dialogue_closed


func _refresh() -> void:
	var d := GameState.data
	_spawn_mobs()
	_recount()
	var t := get_node_or_null("AnneSerce") as Node3D
	if t == null:
		return
	var q1 := d.quest_state(Q1)
	var q2 := d.quest_state(Q2)
	var go := q1 in ["none", "ready"] or q2 == "ready"
	if go and not t.has_node("Beacon"):
		Beacon.attach(t, 2.8, Tokens.color("spark-white"))
	elif not go and t.has_node("Beacon"):
		t.get_node("Beacon").queue_free()
	if q1 == "none":
		_hud.show_hint("Kapının yanındaki Anne Serçe ile konuş", "Anne Serçe ile konuş")
	elif q1 == "active":
		_hud.show_hint("Dalın dibindeki toprağa merdiven ek. Yuvaları ve Dikencileri alkışla (C)", "Toprağa merdiven ek, yuvaları alkışla!")
	elif q1 == "ready":
		_hud.show_hint("Aşağıya, Anne Serçe'ye dön", "Anne Serçe'ye dön")
	elif q2 == "ready":
		_hud.show_hint("Tepe yuvanın önündeki Anne Serçe ile konuş", "Anne Serçe ile konuş")
	elif q2 == "active" and not d.has_flag("s4_ark3"):
		_hud.show_hint("İkinci dala çık, batıdaki ark kapağının çarkını çevir", "İkinci dalda ark kapağını aç")
	elif q2 == "active" and not d.objective_done(Q2, "pitpit") and not fighting:
		_hud.show_hint("En üst dala tırman: Pıtpıt tepe yuvada", "En üst dala tırman")
	elif q2 == "active" and not d.has_flag("tohum_gul") and has_node("Seed"):
		_hud.show_hint("Yuvanın önünde parlayan Gül Tohumu'nu al", "Gül Tohumu'nu al")


## Demo helper: stand south of ladder `i`, plant it, wait until it has grown.
func _plant(i: int) -> void:
	var p := _ladders[i]
	await walk_to(p.position + Vector3(0, 0, 0.4), 8.0)
	await get_tree().create_timer(0.3, false).timeout
	_player.interact()
	await get_tree().create_timer(0.3, false).timeout
	if not p._planted:
		print("S4K3_PLANT_MISS i=%d at=%s" % [i, _player.global_position])
		p.use(_player)
	for k in 60:
		if p.is_grown:
			break
		await get_tree().create_timer(0.25, false).timeout
	await close_dialogs()


## Demo helper: up the vine stair `i` and onto the branch above. A stair is
## walked on from its foot (west end), like a real one: its side is a lip.
func _climb(i: int) -> void:
	var p := _ladders[i].position
	await walk_to(p + Vector3(-2.2, 0, 1.6), 10.0)
	await walk_to(p + Vector3(-2.2, 0, 0.0), 4.0)
	await walk_to(p + Vector3(RISE.x + 0.4, 0, RISE.z), 8.0)
	await walk_to(p + Vector3(RISE.x, 0, -2.6), 4.0)


func _clap_here() -> int:
	_player.clap._cd = 0.0
	var hits := _player.clap.clap()
	await get_tree().create_timer(0.9, false).timeout
	await close_dialogs()
	return hits


func _run_demo(which: String) -> void:
	var d := GameState.data
	match which:
		"garden":
			# the whole chapter on foot: the quest, three nests, three ladders
			# (each wall tried first), the bridge, Bado, the Dikenciler, the
			# ark, the hedge, Pıtpıt, the feather, the seed, the last talk
			DevTools.auto_dialogue = true
			await walk_to(ANNE_AT + Vector3(0, 0, 1.8), 6.0)
			GameState.talk_to("anne_serce")
			await close_dialogs()
			print("S4K3_Q1 state=%s mobs=%d clap=%s" % [d.quest_state(Q1), get_tree().get_nodes_in_group("mob").size(), _player.clap != null])
			await walk_to(Vector3(-9, 0, 20.5), 8.0)
			await walk_to(Vector3(-16, 0, 19.8), 6.0)
			var h0: int = await _clap_here()
			print("S4K3_CLAP0 hits=%d count=%s" % [h0, d.objective_count(Q1, "alkis")])
			# ladder A: the branch is a wall until the seed has grown
			await walk_to(Vector3(-9, 0, 10.0), 8.0)
			await walk_to(Vector3(-9, 0, 3.0), 2.5)
			print("S4K3_WALL blocked=%s z=%.1f y=%.1f" % [_player.global_position.z > 6.0 and _player.global_position.y < 1.0, _player.global_position.z, _player.global_position.y])
			await _plant(0)
			await _climb(0)
			print("S4K3_LADDER_A grown=%s up=%s y=%.1f" % [_ladders[0].is_grown, _player.global_position.y > 2.6, _player.global_position.y])
			await walk_to(Vector3(-12.5, 0, 4.4), 6.0)
			var h1: int = await _clap_here()
			print("S4K3_CLAP1 hits=%d count=%s" % [h1, d.objective_count(Q1, "alkis")])
			await walk_to(Vector3(-4.5, 0, 2.0), 6.0)
			await walk_to(Vector3(5.0, 0, 2.0), 6.0)
			print("S4K3_BRIDGE crossed=%s x=%.1f y=%.1f" % [_player.global_position.x > 3.5 and _player.global_position.y > 2.6, _player.global_position.x, _player.global_position.y])
			await walk_to(SIDE_AT + Vector3(-0.8, 0, 1.6), 6.0)
			GameState.talk_to("minnos" if d.character_id == "bado" else "bado")
			await close_dialogs()
			print("S4K3_BADO keeper=%s fark=%s bado_npc=%s" % [d.character_id, d.has_flag("s4c3_bado_fark"), has_node("Bado")])
			await walk_to(Vector3(8, 0, 2.0), 6.0)
			await walk_to(Vector3(8, 0, -4.0), 2.5)
			var wall_b := _player.global_position.z > -2.0
			await walk_to(Vector3(5, 0, 1.5), 4.0)
			await _plant(1)
			await _climb(1)
			print("S4K3_LADDER_B blocked_before=%s up=%s y=%.1f" % [wall_b, _player.global_position.y > 5.6, _player.global_position.y])
			await walk_to(Vector3(11, 0, -3.6), 6.0)
			var h2: int = await _clap_here()
			print("S4K3_CLAP2 hits=%d count=%s" % [h2, d.objective_count(Q1, "alkis")])
			await walk_to(Vector3(-4, 0, -6.0), 8.0)
			await _plant(2)
			print("S4K3_LADDERS count=%s" % d.objective_count(Q1, "merdiven"))
			await _calm_dikenciler()
			await close_dialogs()
			print("S4K3_DIKENCI count=%s q1=%s" % [d.objective_count(Q1, "dikenci"), d.quest_state(Q1)])
			await _talk("anne_serce", "AnneSerce")
			print("S4K3_Q2 q1=%s q2=%s" % [d.quest_state(Q1), d.quest_state(Q2)])
			# back up the whole tree on foot: the ladders are still there
			await walk_to(Vector3(-13, 0, 11.0), 10.0)
			await _climb(0)
			await walk_to(Vector3(-4.5, 0, 2.0), 6.0)
			await walk_to(Vector3(4.0, 0, 2.0), 6.0)
			await _climb(1)
			await walk_to(Vector3(-4, 0, -6.5), 8.0)
			await _climb(2)
			await walk_to(Vector3(0, 0, -11.0), 4.0)
			print("S4K3_CLIMB top=%s y=%.1f" % [_player.global_position.y > 8.6, _player.global_position.y])
			await walk_to(Vector3(0, 0, -16.0), 2.5)
			print("S4K3_HEDGE blocked=%s z=%.1f" % [_player.global_position.z > -12.2, _player.global_position.z])
			# stepping off the top branch lands on the one below
			await walk_to(Vector3(-9, 0, -8.0), 6.0)
			await walk_to(Vector3(-11, 0, -5.2), 5.0)
			print("S4K3_FALL landed_below=%s y=%.1f" % [absf(_player.global_position.y - 6.0) < 0.6, _player.global_position.y])
			await get_tree().create_timer(0.3, false).timeout
			_player.interact()
			await get_tree().create_timer(1.0, false).timeout
			await close_dialogs()
			print("S4K3_ARK ark=%s hedge_open=%s" % [d.has_flag("s4_ark3"), _hedge.is_open])
			await walk_to(Vector3(-6, 0, -6.5), 6.0)
			await _climb(2)
			await walk_to(Vector3(0, 0, -11.0), 4.0)
			await walk_to(ARENA + Vector3(0, 0, 6.0), 8.0)
			print("S4K3_PASSED passed=%s z=%.1f y=%.1f" % [_player.global_position.z < -13.0, _player.global_position.z, _player.global_position.y])
			await _beat_boss()
			for i in 120:
				await close_dialogs()
				if has_node("Seed"):
					break
				await get_tree().create_timer(0.2, false).timeout
			print("S4K3_BOSS pitpit=%s chicks=%s door_open=%s seed=%s anne_up=%s" % [d.objective_done(Q2, "pitpit"), _chicks, _door.is_open, has_node("Seed"), (get_node("AnneSerce") as Node3D).global_position.y > 8.0])
			await walk_to(ARENA + Vector3(0, 0, 3.0), 8.0)
			for i in 120:
				await close_dialogs()
				if d.has_flag("s4c3_ani") and not GameState.in_dialogue:
					break
				await get_tree().create_timer(0.2, false).timeout
			await close_dialogs()
			print("S4K3_SEED tohum=%s ani=%s q2=%s" % [d.has_flag("tohum_gul"), d.has_flag("s4c3_ani"), d.quest_state(Q2)])
			await _talk("anne_serce", "AnneSerce")
			await get_tree().create_timer(3.5, false).timeout
			print("S4K3_DONE q2=%s ark=%s tohum=%s bitti=%s gate_star=%s" % [d.quest_state(Q2), d.has_flag("s4_ark3"), d.has_flag("tohum_gul"), d.has_flag("s4_bolum3_bitti"), lv.get_node("Gate").has_node("Beacon")])
			get_tree().quit()
		"climbdbg":
			DevTools.auto_dialogue = true
			for l in _ladders:
				l.plant()
			for k in 40:
				if _ladders[2].is_grown:
					break
				await get_tree().create_timer(0.25, false).timeout
			await close_dialogs()
			await _climb(0)
			print("DBG A %s" % _player.global_position)
			await walk_to(Vector3(-4.5, 0, 2.0), 6.0)
			await walk_to(Vector3(4.0, 0, 2.0), 6.0)
			print("DBG bridge %s" % _player.global_position)
			await _climb(1)
			print("DBG B %s" % _player.global_position)
			await walk_to(Vector3(-4, 0, -6.5), 8.0)
			await _climb(2)
			print("DBG C %s" % _player.global_position)
			get_tree().quit()
		"corner":
			# Yonca's corner both ways: the soil answers only Yonca
			await walk_to(Vector3(21, 0, 13.3), 12.0)
			await walk_to(Vector3(21, 0, 2.0), 3.5)
			var wall := _player.global_position.y < 1.0
			await walk_to(Vector3(21, 0, 13.3), 5.0)
			await get_tree().create_timer(0.3, false).timeout
			_player.interact()
			for k in 40:
				if _corner.is_grown:
					break
				await get_tree().create_timer(0.25, false).timeout
			await walk_to(Vector3(21, 0, 2.0), 8.0)
			await get_tree().create_timer(0.5, false).timeout
			print("S4K3_CORNER keeper=%s wall_before=%s grown=%s up=%s kose=%s" % [d.character_id, wall, _corner.is_grown, _player.global_position.y > 2.6, d.has_flag("s4c3_kose")])
			get_tree().quit()

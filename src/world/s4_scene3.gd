extends S4Garden
## Sezon 4 · Prolog · Sahne 3 – Köklerin Peşinde. Tırıl follows the vines'
## roots north to the edge of Fısıltı Ormanı. Teaches growing a way through
## (a ladder seed over the thorn hedge, a bridge seed over the creek), the
## first level-up with Tırıl's skill Işık Dalgası (the shadow hedge draws
## back from its light), and a short climb over tree stumps. A thin voice
## among the vines: "Onunki daha güzel... neden ben değilim?"
## Quests "koklerin_pesinde" (done at the root: `_learn_wave` lifts to level 2) then "ince_ses" →
## `s4_sahne3_bitti` → s4_scene4. Linear scene.
##
## Layout (the camera looks from the south, +z): start z 26, thorn hedge at
## z 10 with the ledge on the east side (ladder plot at z 16), creek at z -6
## (bridge plot at x 0), the giant root at z -13, the shadow hedge at z -20,
## two Dikenciler at z -24..-28, stumps at z -31.5 and -35.5, the forest
## edge (plateau, top 2.4) from z -38.

const Q1 := "koklerin_pesinde"
const Q2 := "ince_ses"
const GRASS := Color("#6fae6a")
const WOOD := Color("#9a6b45")
const HEDGE_Z := 10.0
const CREEK_Z := -6.0
const ROOT_AT := Vector3(0, 0, -13.0)
const SHADE_Z := -20.0
const TOP := 2.4
## the ledge is four low leaf steps high (the keeper has no step-up)
const LEDGE := 1.5
const EDGE_AT := Vector3(0, TOP, -45.0)
const NEED := 2
const DIKENCILER := [["kapici_tavsan", Vector3(-6, 0, -25)], ["kiskanc_salyangoz", Vector3(6, 0, -27)]]
const WHISPERS := [["Onunki daha güzel...", Vector3(-5, 2.2, 5)], ["...neden ben değilim?", Vector3(6, 2.4, -16)],
	["Onunki daha güzel...", Vector3(-7, 4.4, -41)]]

var _ladder: SeedPlot
var _bridge: SeedPlot
var _creek_block: StaticBody3D
var _shade: ThornPatch
var _mobs := false
var _next_mob := 0
var _mob_t := 3.0
var _ended := false


func _ready() -> void:
	begin_garden("s4_scene3", "orman")
	Pus.set_amount(0.18)
	_build()
	S4Village.balloon(_player)
	Decor.auto(self, "orman")
	var d := GameState.data
	if d.quest_state(Q1) == "none":
		d.start_quest(Content.quests[Q1])
	if d.quest_state(Q1) == "done" and d.quest_state(Q2) == "none":
		d.start_quest(Content.quests[Q2])
	if _ladder.is_grown:
		GameState.notify("grow", "merdiven")
	if _bridge.is_grown:
		GameState.notify("grow", "kopru")
	d.quest_changed.connect(func(_id: String) -> void: _check())
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.5, false).timeout
	if d.quest_state(Q2) == "done":
		_end()
		return
	GameState.bark("s4a_kok_basla")
	_check()
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _build() -> void:
	land(Vector3(0, 0, -12), Vector2(30, 86), GRASS)
	fence(Vector3(0, 0, -12), Vector2(28, 84))
	# the vines' roots: a brown trail all the way north
	WorldLook.block(lv, Vector3(0, 0.02, 18.5), Vector3(1.6, 0.04, 13), WOOD, 0.0)
	WorldLook.block(lv, Vector3(5.2, 0.02, 18.2), Vector3(9.0, 0.04, 1.6), WOOD, 0.0)
	WorldLook.block(lv, Vector3(0, 0.02, -16.0), Vector3(1.6, 0.04, 28), WOOD, 0.0)
	# A: the thorn hedge, and the ledge that passes over its east end
	var hedge := thorns(Vector3(-3.5, 0, HEDGE_Z), 21.0, true)
	hedge.strength = 0.5
	land(Vector3(10.5, 0, 8.0), Vector2(7, 10), Color("#8a9a6a"), LEDGE)
	_ladder = plot(Vector3(10.5, 0, 16.8), "merdiven", Vector3(0, LEDGE, -3.8))
	_ladder.grown.connect(func(p: SeedPlot) -> void:
		_ramp(p)
		GameState.bark("s4a_merdiven")
		_check())
	if _ladder.is_grown:
		_ramp(_ladder)
	# B: the creek, passable only by the leaf bridge
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(28, 3.0)
	water.mesh = pm
	water.position = Vector3(0, 0.07, CREEK_Z)
	WorldLook.water(water, "lake")
	lv.add_child(water)
	for x: float in [-7.75, 7.75]:
		_wall(Vector3(x, 0, CREEK_Z), Vector2(12.5, 2.6))
	_creek_block = _wall(Vector3(0, 0, CREEK_Z), Vector2(3.0, 2.6))
	_bridge = plot(Vector3(0, 0, CREEK_Z + 2.4), "kopru", Vector3(0, 0, -4.8))
	_bridge.grown.connect(func(_p: SeedPlot) -> void:
		_open_creek()
		GameState.bark("s4a_kopru")
		_check())
	if _bridge.is_grown:
		_open_creek()
	_area("ses1", Vector3(0, 0, 3.0), 3.5).reached.connect(func() -> void: GameState.bark("s4a_ses1"))
	# C: the giant root every vine grows from
	if prop("dev_kutuk", ROOT_AT + Vector3(5.5, 0, -1.5), 4.0, 0.4) != null:
		S4Village._solid(lv, ROOT_AT + Vector3(5.5, 0, -1.5), Vector3(3.0, 4.0, 3.0))
	for p: Vector3 in [Vector3(3.0, 0, -15.0), Vector3(8.5, 0, -12.0), Vector3(-9, 0, -14)]:
		prop("sarmasik", p, 1.6, p.x)
	_area("dev_kok", ROOT_AT, 3.5)
	# D: the shadow hedge: it draws back from Tırıl's light
	_shade = thorns(Vector3(0, 0, SHADE_Z), 28.0, true)
	_shade.strength = 0.3
	_area("ses2", Vector3(0, 0, -24.0), 4.0).reached.connect(func() -> void: GameState.bark("s4a_ses2"))
	# E: stumps up to the forest edge
	land(Vector3(0, 0, -31.5), Vector2(3.4, 3.0), WOOD, 0.8, 0.8)
	land(Vector3(0, 0, -35.5), Vector2(3.4, 3.0), WOOD, 1.6, 1.6)
	land(Vector3(0, 0, -46.5), Vector2(30, 17), Color("#5f9a62"), TOP, TOP)
	_area("orman_kenari", EDGE_AT, 4.0)
	TravelSign.board(lv, "Fısıltı Ormanı ↑", Vector3(-4.0, 1.4, -29.5), 3.0)
	Toon.part(lv, "box", Vector3(0.16, 1.3, 0.16), WOOD, Vector3(-4.0, 0.65, -29.55))
	# the forest behind, a vegetable patch with one very big pumpkin
	for x: float in [-10.0, -3.5, 3.5, 10.0]:
		prop("orman_agaclar", Vector3(x, TOP, -53.0), 7.0, x)
	prop("dev_kabak", Vector3(5.0, TOP, -49.5), 2.6, PI)
	for p: Vector3 in [Vector3(-11, 0, 21), Vector3(11, 0, 23), Vector3(-11, 0, -2), Vector3(11.5, 0, -24), Vector3(-11.5, 0, -33)]:
		prop("orman_kutuk", p, 1.4, p.z)
		prop("orman_mantar", p + Vector3(1.4, 0, 0.8), 0.9, p.x)
	for w: Array in WHISPERS:
		var l := Label3D.new()
		l.text = w[0]
		l.font = Tokens.font_for("text-heading")
		l.font_size = 40
		l.pixel_size = 0.006
		l.outline_size = 12
		l.outline_modulate = Tokens.color("outline")
		l.modulate = Tokens.color("panel@light")
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.position = w[1]
		lv.add_child(l)
		var tw := l.create_tween().set_loops()
		tw.tween_property(l, "modulate:a", 0.25, 1.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(l, "modulate:a", 1.0, 1.6).set_trans(Tween.TRANS_SINE)


func _area(id: String, at: Vector3, radius: float) -> TriggerArea:
	var t := TriggerArea.new()
	t.area_id = id
	t.radius = radius
	t.position = at
	lv.add_child(t)
	return t


func _wall(center: Vector3, size: Vector2) -> StaticBody3D:
	var wall := StaticBody3D.new()
	wall.set_meta("camera_ignore", true)
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(size.x, 8.0, size.y)
	c.shape = b
	wall.add_child(c)
	wall.position = center + Vector3(0, 4, 0)
	lv.add_child(wall)
	return wall


## The leaf steps are 0.4 m each and the keeper has no step-up: an unseen
## slope over them lets a kid simply walk up.
func _ramp(p: SeedPlot) -> void:
	var run := absf(p.span.z)
	var a := atan2(p.span.y, run)
	var body := StaticBody3D.new()
	body.set_meta("camera_ignore", true)
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.0, 0.2, Vector2(run, p.span.y).length())
	c.shape = b
	body.add_child(c)
	lv.add_child(body)
	body.rotation.x = a
	body.position = p.position + Vector3(0, p.span.y * 0.5, 0.7 - run * 0.5) - Vector3(0, cos(a), sin(a)) * 0.1


func _open_creek() -> void:
	if _creek_block and is_instance_valid(_creek_block):
		_creek_block.queue_free()
		_creek_block = null


func _live_mobs() -> int:
	var n := get_tree().get_nodes_in_group("mob").size()
	for m in get_tree().get_nodes_in_group("dazed"):
		if m is Mob:
			n += 1
	return n


func _spawn_next() -> void:
	var e: Array = DIKENCILER[_next_mob % DIKENCILER.size()]
	_next_mob += 1
	dikenci(e[0], e[1])


func _process(delta: float) -> void:
	super._process(delta)
	var d := GameState.data
	if _ended or d.quest_state(Q2) != "active":
		return
	if not _mobs:
		_mobs = true
		for i in NEED - d.objective_count(Q2, "dikenci").x:
			_spawn_next()
	# never a dead end: a Dikenci that calmed by itself didn't count
	_mob_t -= delta
	if _mob_t <= 0.0:
		_mob_t = 3.0
		if _live_mobs() < NEED - d.objective_count(Q2, "dikenci").x \
				and absf(_player.global_position.z - (DIKENCILER[_next_mob % DIKENCILER.size()][1] as Vector3).z) > 7.0:
			_spawn_next()
	if _shade.is_open:
		return
	var near := absf(_player.global_position.z - SHADE_Z) < 6.0
	# Tırıl never stands before the hedge without light to give
	if near and d.mp < int(Skills.DEFS["isik_dalgasi"]["mp"]):
		d.mp = d.max_mp
		d.stats_changed.emit()
		Effects.sparkle(self, _player.global_position + Vector3.UP * 1.2, Tokens.color("sky"), 8)
	for n in get_tree().get_nodes_in_group("light_ring"):
		var t := n as TempLight
		if t and absf(t.global_position.z - SHADE_Z) < 6.5:
			_shade.open()
			GameState.notify("collect", "isik_cit")
			GameState.bark("s4a_isik")
			break


## The first level-up: Tırıl's light learns to roll out as a wave.
func _learn_wave() -> void:
	var d := GameState.data
	while d.level < 2:
		d.add_xp(Progression.xp_to_next(d.level) - d.xp)
	d.unlock_skill("isik_dalgasi")
	d.mp = d.max_mp
	d.stats_changed.emit()
	GameState.bark("s4a_kok")
	await GameState.dialogue_closed
	_hud.show_scene_card("Yeni yetenek!", "Işık Dalgası", "Işığın dalga dalga yayılır. Gölge çitleri ışıktan çekilir.")
	if d.quest_state(Q2) == "none":
		d.start_quest(Content.quests[Q2])
	_check()


func _check() -> void:
	var d := GameState.data
	var s1 := d.quest_state(Q1)
	var s2 := d.quest_state(Q2)
	if s1 == "ready":
		d.complete_quest(Content.quests[Q1])
		_learn_wave()
		return
	if s1 == "active":
		if not d.objective_done(Q1, "merdiven"):
			_hud.show_hint("Dikenli çit yolu kapatmış. Sağdaki toprağa git, E ile tohum ek!", "Sağdaki toprağa git, Ek'e bas!")
		elif not d.objective_done(Q1, "kopru"):
			_hud.show_hint("Yaprak basamaklardan çık, çiti aş. Derenin başına köprü tohumu ek!", "Basamaklardan çık. Derede Ek'e bas!")
		else:
			_hud.show_hint("Köprüden geç, kökleri izle", "Köprüden geç, kökleri izle")
	elif s2 == "active":
		if not d.objective_done(Q2, "isik"):
			_hud.show_hint("L: Işık Dalgası. Gölge çitinin önünde kullan!", "Çitin önünde Işık düğmesine bas!")
		elif not d.objective_done(Q2, "dikenci"):
			_hud.show_hint("J: Dikenciyi sersemlet. Sonra C: yanında alkışla!", "Vur: sersemlet. Sonra yanında Alkış'a bas!")
		else:
			_hud.show_hint("Kütüklere zıpla, orman kenarına çık. Boşluk'u bırakma: süzülürsün!", "Kütüklere zıpla. Zıpla'ya basılı tut: süzül!")
	elif s2 == "ready":
		d.complete_quest(Content.quests[Q2])
	elif s2 == "done" and not _ended:
		_end()


## The voice comes from the vegetable patch at the forest's edge (Sahne 4).
func _end() -> void:
	if _ended:
		return
	_ended = true
	var d := GameState.data
	d.set_flag("s4_sahne3_bitti")
	_hud.clear_hint()
	while GameState.in_dialogue:
		await get_tree().create_timer(0.2, false).timeout
	await get_tree().create_timer(0.5, false).timeout
	GameState.bark("s4a_son3")
	if DevTools.demo != "":
		await close_dialogs()
		print("S4A3_DONE quest=%s/%s flag=%s level=%d skill=%s next=s4_scene4" % [d.quest_state(Q1), d.quest_state(Q2), d.has_flag("s4_sahne3_bitti"), d.level, d.active_skill()])
	while GameState.in_dialogue:
		await get_tree().create_timer(0.2, false).timeout
	SceneFlow.go_to("s4_scene4")


func _grow(p: SeedPlot) -> void:
	await get_tree().create_timer(0.4, false).timeout
	_player.interact()
	for i in 60:
		if p.is_grown:
			break
		await get_tree().create_timer(0.25, false).timeout
	await close_dialogs()


func _run_demo(which: String) -> void:
	var d := GameState.data
	match which:
		"roots":
			# the whole path on foot: hedge shut, ladder, ledge, creek shut,
			# bridge, the root (level 2 + skill), shadow hedge shut, the light
			# wave, two Dikenciler, the stumps, the forest edge
			DevTools.auto_dialogue = true
			print("S4A3_START keeper=%s level=%d q=%s" % [d.character_id, d.level, d.quest_state(Q1)])
			await walk_to(Vector3(0, 0, 13.5), 8.0)
			await walk_to(Vector3(0, 0, 6.0), 2.5)
			print("S4A3_HEDGE blocked=%s z=%.1f" % [_player.global_position.z > HEDGE_Z, _player.global_position.z])
			await walk_to(Vector3(10.5, 0, 18.2), 8.0)
			await _grow(_ladder)
			print("S4A3_LADDER grown=%s obj=%s" % [_ladder.is_grown, d.objective_done(Q1, "merdiven")])
			await walk_to(Vector3(10.5, 0, 11.0), 6.0)
			var up := _player.global_position.y
			await walk_to(Vector3(10.5, 0, 1.5), 6.0)
			await walk_to(Vector3(0, 0, 0.5), 6.0)
			await close_dialogs()
			print("S4A3_LEDGE top_y=%.1f over=%s z=%.1f" % [up, _player.global_position.z < HEDGE_Z - 2.0, _player.global_position.z])
			await walk_to(Vector3(0, 0, CREEK_Z - 3.0), 2.5)
			print("S4A3_CREEK blocked=%s z=%.1f" % [_player.global_position.z > CREEK_Z, _player.global_position.z])
			await walk_to(Vector3(0, 0, CREEK_Z + 3.5), 4.0)
			await _grow(_bridge)
			await walk_to(Vector3(0, 0, CREEK_Z - 3.0), 5.0)
			print("S4A3_BRIDGE grown=%s crossed=%s" % [_bridge.is_grown, _player.global_position.z < CREEK_Z - 1.5])
			await walk_to(ROOT_AT, 6.0)
			await get_tree().create_timer(1.5, false).timeout
			await close_dialogs()
			await get_tree().create_timer(1.0, false).timeout
			await close_dialogs()
			print("S4A3_ROOT q1=%s q2=%s level=%d skill=%s" % [d.quest_state(Q1), d.quest_state(Q2), d.level, d.active_skill()])
			await walk_to(Vector3(0, 0, SHADE_Z - 3.0), 3.0)
			print("S4A3_SHADE blocked=%s z=%.1f" % [_player.global_position.z > SHADE_Z, _player.global_position.z])
			d.mp = 0
			await get_tree().create_timer(0.3, false).timeout
			_player._attack_cd = 0.0
			_player.use_skill()
			await get_tree().create_timer(0.8, false).timeout
			await close_dialogs()
			print("S4A3_WAVE open=%s isik=%s mp=%d" % [_shade.is_open, d.objective_done(Q2, "isik"), d.mp])
			await walk_to(Vector3(0, 0, SHADE_Z - 2.5), 4.0)
			await close_dialogs()
			for i in 5:
				if d.objective_done(Q2, "dikenci"):
					break
				await _calm_dikenciler()
				await close_dialogs()
				await get_tree().create_timer(3.5, false).timeout
			print("S4A3_DIKENCI count=%s passed=%s" % [d.objective_count(Q2, "dikenci"), _shade.is_open])
			# the stumps: jump, jump, jump (holding jump floats)
			_player.global_position = Vector3(0, 0.3, -27.0)
			await get_tree().create_timer(0.3, false).timeout
			var heights := []
			for z: float in [-31.5, -35.5, -39.5]:
				for k in 3:
					Input.action_press("jump")
					await get_tree().physics_frame
					await get_tree().physics_frame
					await walk_to(Vector3(0, 0, z), 1.6)
					Input.action_release("jump")
					await get_tree().create_timer(0.5, false).timeout
					if absf(_player.global_position.z - z) < 1.2 and _player.is_on_floor():
						break
				heights.append(snappedf(_player.global_position.y, 0.1))
			print("S4A3_STUMPS y=%s top=%s" % [heights, _player.global_position.y > TOP - 0.2])
			DevTools.report_next_scene("S4A3_NEXT")
			await walk_to(EDGE_AT, 6.0)

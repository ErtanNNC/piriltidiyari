extends S4Garden
## Sezon 4 · Bölüm 0 – Sera Kasabası (hub). Glass greenhouses whose owners
## have drawn the curtains and peek at each other's plants. Solucan Dede
## Toprak asks for three things (quest "perdeler_acilsin"): clap for the
## three neighbours' greenhouses (their thorns draw back), sober up and clap
## for four Dikenciler, and plant the bridge seed over the canal. Then the
## ark sluice opens ("huysuz_korkuluk"): the thorn hedge to the north dries
## and the Huysuz Korkuluk in the vegetable patch can be met: fight, he
## sulks, a clap, birds land on his arms. Toprak sends you on to Parlak
## Pazar (`s4_bolum0_bitti`).
##
## Layout (the camera looks from the south, +z): gate and spawn at z 20–27,
## the square with Toprak and the two stalls at z 12–18, greenhouses left and
## right at z 4 and -5, the canal at z -12 (bridge plot at x 0), the ark at
## z -17, the thorn hedge at z -21, the scarecrow's patch at z -29.

const Q1 := "perdeler_acilsin"
const Q2 := "huysuz_korkuluk"
const GRASS := Color("#8fcf7a")
const PATH := Color("#e6d3a8")
const ARENA := Vector3(0, 0, -29.0)
const TOPRAK_AT := Vector3(3.5, 0, 16.5)
## [npc id, model kind, greenhouse position]: the thorns before them are
## thorn patches 0..2 (flags s4_chapter0_d0..2, read by their dialogue)
const NEIGHBOURS := [["marul", "bunny", Vector3(-14, 0, 4)], ["turp", "mole", Vector3(14, 0, 4)], ["fasulye", "frog", Vector3(-14, 0, -5)]]
const DIKENCILER := [["kapici_tavsan", Vector3(6, 0, 6)], ["kiskanc_salyangoz", Vector3(-5, 0, 0)],
	["kapici_tavsan", Vector3(9, 0, -5)], ["kiskanc_salyangoz", Vector3(2, 0, -6)]]

var _hedge: ThornPatch
var _canal_block: StaticBody3D
var _bridge: SeedPlot
var _mobs := false


func _ready() -> void:
	begin_garden("s4_chapter0")
	var d := GameState.data
	ark_flag = "s4_ark0"
	haze(0.3)
	_build()
	Decor.auto(self, "koy")
	npc(self, "toprak", "toprak", TOPRAK_AT, -150.0).name = "Toprak"
	npc(self, "boynuz", "boynuz", Vector3(-9, 0, 14), 110.0).name = "Boynuz"
	npc(self, "kozacik", "kozacik", Vector3(9, 0, 14), -110.0).name = "Kozacik"
	for i in NEIGHBOURS.size():
		var nb: Array = NEIGHBOURS[i]
		var side := signf((nb[2] as Vector3).x)
		npc(self, nb[0], nb[1], nb[2] + Vector3(-side * 5.5, 0, 1.5), 90.0 * side).name = String(nb[0]).capitalize()
	make_boss("korkuluk", ARENA, d.objective_done(Q2, "korkuluk"))
	if d.objective_done(Q2, "korkuluk") and d.quest_state(Q2) != "done":
		giver_comes("Toprak", ARENA + Vector3(3.5, 0, 5.0), false)
	_spawn_mobs()
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.8, false).timeout
	if not d.has_flag("s4c0_geldi"):
		d.set_flag("s4c0_geldi")
		GameState.bark("s4k0_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _build() -> void:
	land(Vector3(0, 0, -3), Vector2(46, 68), GRASS)
	fence(Vector3(0, 0, -3), Vector2(44, 66))
	gate(Vector3(0, 0, 27.0))
	# paths: from the gate up the middle, and to each greenhouse
	WorldLook.block(lv, Vector3(0, 0.02, 4), Vector3(3.2, 0.04, 34), PATH, 0.0)
	for nb: Array in NEIGHBOURS:
		var at: Vector3 = nb[2]
		WorldLook.block(lv, Vector3(at.x * 0.5, 0.02, at.z + 1.5), Vector3(absf(at.x), 0.04, 2.0), PATH, 0.0)
	# the three greenhouses, each behind its own clump of Yeşil Diken (the
	# first three thorn patches: flags ..._d0, _d1, _d2)
	for nb: Array in NEIGHBOURS:
		var at: Vector3 = nb[2]
		var side := signf(at.x)
		if prop("sera", at + Vector3(side * 2.0, 0, 0), 4.0, -90.0 * side * PI / 180.0) == null:
			Toon.part(lv, "box", Vector3(4, 3, 4), Color("#dff2f0"), at + Vector3(side * 2.0, 1.5, 0))
		var body := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(4.0, 4.0, 4.0)
		c.shape = b
		c.position.y = 2.0
		body.add_child(c)
		body.position = at + Vector3(side * 2.0, 0, 0)
		lv.add_child(body)
		var t := thorns(at + Vector3(-side * 1.6, 0, 0), 4.5, false, true, "sera", PI * 0.5)
		t.retracted.connect(func(_t: ThornPatch) -> void:
			if not GameState.data.has_flag("s4c0_ilk_sera"):
				GameState.data.set_flag("s4c0_ilk_sera")
				GameState.bark("s4k0_sera"))
		prop("cicek_tarhi", at + Vector3(-side * 3.4, 0, -2.4), 1.1, 0.4)
	# stalls on the square
	prop("pazar_tezgahi", Vector3(-11.5, 0, 14.5), 3.0, PI * 0.5)
	prop("pazar_tezgahi", Vector3(11.5, 0, 14.5), 3.0, -PI * 0.5)
	for x: float in [-6.0, 6.0]:
		prop("saksi", Vector3(x, 0, 22.0), 0.8, 0.0)
	# the canal: water right across, passable only by the leaf bridge
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(44, 3.0)
	water.mesh = pm
	water.position = Vector3(0, 0.07, -12.0)
	WorldLook.water(water, "lake")
	lv.add_child(water)
	for x: float in [-12.0, 12.0]:
		_wall(Vector3(x, 0, -12.0), Vector2(21.0, 2.6))
	_canal_block = _wall(Vector3(0, 0, -12.0), Vector2(3.0, 2.6))
	_bridge = plot(Vector3(0, 0, -9.6), "kopru", Vector3(0, 0, -4.8))
	_bridge.grown.connect(func(_p: SeedPlot) -> void:
		_open_canal()
		GameState.bark("s4k0_tohum"))
	if _bridge.is_grown:
		_open_canal()
	# the ark sluice and the thorn hedge that dries when it opens
	ark(Vector3(7.0, 0, -17.0), "s4_ark0", Q1, "s4k0_kilit", PI)
	_hedge = thorns(Vector3(0, 0, -21.5), 44.0, true)
	if GameState.data.has_flag("s4_ark0") and not _hedge.is_open:
		_hedge.open()
	# the scarecrow's vegetable patch
	for p: Vector3 in [Vector3(-7, 0, -27), Vector3(7, 0, -27), Vector3(-8, 0, -33), Vector3(8, 0, -33)]:
		prop("korkuluk_tarla", p, 0.9, 0.3 * p.x)
	prop("bahar_cesmesi", Vector3(-15, 0, 18), 3.4, 0.0)


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


func _open_canal() -> void:
	if _canal_block and is_instance_valid(_canal_block):
		_canal_block.queue_free()
		_canal_block = null


## The Dikenciler come with Quest 1 (calmed before it they wouldn't count).
func _spawn_mobs() -> void:
	var d := GameState.data
	if _mobs or d.quest_state(Q1) != "active":
		return
	_mobs = true
	var done := d.objective_count(Q1, "dikenci").x
	for i in range(mini(done, DIKENCILER.size()), DIKENCILER.size()):
		dikenci(DIKENCILER[i][0], DIKENCILER[i][1])
	if not d.has_flag("s4c0_ilk_dikenci"):
		d.set_flag("s4c0_ilk_dikenci")
		GameState.bark("s4k0_dikenci")


func _on_ark() -> void:
	_hedge.open()
	GameState.bark("s4k0_ark")
	_refresh()


func fight_ready() -> bool:
	var d := GameState.data
	return d.quest_state(Q2) == "active" and d.has_flag("s4_ark0") and not d.objective_done(Q2, "korkuluk")


func _begin_fight() -> void:
	start_fight("s4k0_korkuluk", "Rüzgâra karşı yürü, halkalardan kaç. Yorulunca vur!", "Halkalardan kaç, yorulunca vur!")


## Birds land on his arms: the scarecrow giggles for the first time.
func _on_boss_calmed() -> void:
	_hud.clear_hint()
	boss_camera(false)
	for k in 5:
		Effects.sparkle(self, boss.global_position + Vector3(randf_range(-1.6, 1.6), 2.6, randf_range(-0.6, 0.6)), Tokens.color("sky"), 6)
	Audio.play("laugh")
	GameState.bark("s4k0_sakin")
	await GameState.dialogue_closed
	await giver_comes("Toprak", ARENA + Vector3(3.5, 0, 5.0))
	_refresh()


func _refresh() -> void:
	var d := GameState.data
	_spawn_mobs()
	var t := get_node_or_null("Toprak") as Node3D
	if t == null:
		return
	var q1 := d.quest_state(Q1)
	var q2 := d.quest_state(Q2)
	var go := q1 in ["none", "ready"] or q2 == "ready"
	if go and not t.has_node("Beacon"):
		Beacon.attach(t, 2.6, Tokens.color("spark-white"))
	elif not go and t.has_node("Beacon"):
		t.get_node("Beacon").queue_free()
	if q1 == "none":
		_hud.show_hint("Kapının yanındaki Solucan Dede Toprak ile konuş", "Dede Toprak ile konuş")
	elif q1 == "active":
		_hud.show_hint("C: alkışla. Seraların önünde, sersemleyen Dikencilerin yanında!", "Alkış'a bas: seraların ve Dikencilerin yanında!")
	elif q1 == "ready" or q2 == "ready":
		_hud.show_hint("Solucan Dede Toprak'a dön", "Dede Toprak'a dön")
	elif q2 == "active" and not d.has_flag("s4_ark0"):
		_hud.show_hint("Yaprak köprüden geç, ark kapağının çarkını çevir", "Köprüden geç, ark kapağını aç")
	elif q2 == "active" and not d.objective_done(Q2, "korkuluk") and not fighting:
		_hud.show_hint("Kuzeydeki bostana git: Huysuz Korkuluk orada", "Kuzeydeki bostana git")


func _run_demo(which: String) -> void:
	var d := GameState.data
	match which:
		"garden":
			# the whole chapter on foot: quest, three claps, Dikenciler, the
			# bridge seed, the ark, the hedge, the scarecrow, the last talk
			DevTools.auto_dialogue = true
			await walk_to(TOPRAK_AT + Vector3(0, 0, 1.8), 6.0)
			GameState.talk_to("toprak")
			await close_dialogs()
			print("S4K0_Q1 state=%s mobs=%d clap=%s" % [d.quest_state(Q1), get_tree().get_nodes_in_group("mob").size(), _player.clap != null])
			for nb: Array in NEIGHBOURS:
				var at: Vector3 = nb[2]
				await walk_to(Vector3(0, 0, at.z + 1.5), 8.0)
				await walk_to(at + Vector3(-signf(at.x) * 4.5, 0, 1.5), 8.0)
				_player.clap._cd = 0.0
				var hits := _player.clap.clap()
				await get_tree().create_timer(0.9, false).timeout
				await close_dialogs()
				print("S4K0_CLAP %s hits=%d count=%s" % [nb[0], hits, d.objective_count(Q1, "alkis")])
			await _calm_dikenciler()
			await close_dialogs()
			print("S4K0_DIKENCI count=%s" % d.objective_count(Q1, "dikenci"))
			_player.global_position = Vector3(0, 0.3, -4.0)
			await walk_to(Vector3(0, 0, -8.4), 6.0)
			var blocked_z := _player.global_position.z
			await walk_to(Vector3(0, 0, -14.0), 2.5)
			print("S4K0_CANAL blocked=%s z=%.1f" % [_player.global_position.z > -11.0, _player.global_position.z])
			await walk_to(Vector3(0, 0, -8.6), 4.0)
			await get_tree().create_timer(0.3, false).timeout
			_player.interact()
			for i in 60:
				if _bridge.is_grown:
					break
				await get_tree().create_timer(0.25, false).timeout
			await close_dialogs()
			print("S4K0_GROW grown=%s tohum=%s q1=%s from_z=%.1f" % [_bridge.is_grown, d.objective_done(Q1, "tohum"), d.quest_state(Q1), blocked_z])
			await _talk("toprak", "Toprak")
			print("S4K0_Q2 q1=%s q2=%s" % [d.quest_state(Q1), d.quest_state(Q2)])
			_player.global_position = Vector3(0, 0.3, -8.0)
			await walk_to(Vector3(0, 0, -15.5), 8.0)
			print("S4K0_BRIDGE crossed=%s z=%.1f" % [_player.global_position.z < -14.5, _player.global_position.z])
			await walk_to(Vector3(7.0, 0, -15.2), 6.0)
			await get_tree().create_timer(0.3, false).timeout
			_player.interact()
			await get_tree().create_timer(1.0, false).timeout
			await close_dialogs()
			print("S4K0_ARK ark=%s hedge_open=%s" % [d.has_flag("s4_ark0"), _hedge.is_open])
			await walk_to(Vector3(0, 0, -18.5), 6.0)
			await walk_to(ARENA + Vector3(0, 0, 6.0), 8.0)
			print("S4K0_HEDGE passed=%s z=%.1f" % [_player.global_position.z < -21.8, _player.global_position.z])
			await _beat_boss()
			await close_dialogs()
			await get_tree().create_timer(2.5, false).timeout
			await close_dialogs()
			print("S4K0_BOSS korkuluk=%s" % d.objective_done(Q2, "korkuluk"))
			await _talk("toprak", "Toprak")
			await get_tree().create_timer(3.5, false).timeout
			print("S4K0_DONE q2=%s ark=%s bitti=%s gate_star=%s next=%s" % [d.quest_state(Q2), d.has_flag("s4_ark0"), d.has_flag("s4_bolum0_bitti"), lv.get_node("Gate").has_node("Beacon"), GardenTravel.next_stop(d)])
			get_tree().quit()

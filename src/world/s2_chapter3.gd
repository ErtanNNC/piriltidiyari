extends ChapterBase
## Sezon 2 · Bölüm 3 – Patpat Tarlaları, Kehribar Kor (levels 15–20). Corn
## fields where kernels pop in the heat, and a fair nobody plays at: since
## the Kızıl Sis came everyone sulks when they lose. Horoz Kukuri's two fair
## games (Balon Patlat, Bayrak Koşusu) can be lost and played again (the
## lesson: losing is part of the game). The fields' Ses Çanı clears the fair
## square where Tavuk Patpat sulks (boss); "Bir daha oynayalım mı?" (Sakinleş)
## calms her; she gives the Kehribar Kor. Then Minnoş runs off into the mist.

const Q1 := "panayir"
const Q2 := "patpat"
const FIELD := Color("#c9b45a")
const GRASS := Color("#9cc05a")
const PATH := Color("#e3c08c")
const BELL_AT := Vector3(-15.0, 0, -6.0)
const SQUARE := Vector3(0, 0, -27.0)
const VEIL_Z := -16.0
const BALLOON_TIME := 25.0
const RACE_TIME := 22.0
const RACE_FLAGS := [Vector3(10, 0, -2), Vector3(13, 0, 9), Vector3(4, 0, 15), Vector3(-6, 0, 13)]
## Spots in the side fields where kernels pop (warned like attacks).
const POPS := [Vector3(-14, 0, 12), Vector3(-18, 0, 3), Vector3(15, 0, -8), Vector3(18, 0, 14)]

var _boss: Patpat
var _veil: Node3D
var _fight := false
var _game := ""
var _game_left := 0.0
var _balloons_left := 0
var _flag_next := 0
var _flags: Array[Node3D] = []


func _ready() -> void:
	WorldLook.add(self, "sabah")
	Pus.set_color(Pus.RED)
	var d := GameState.data
	Pus.set_amount(0.03 if d.has_flag("s2_can3") else 0.15)
	_build()
	Decor.auto(self, "koy")
	npc(self, "kukuri", "rooster", Vector3(0.0, 0, 9.0), 0.0).name = "Kukuri"
	for p: Vector3 in [Vector3(-12, 0, 18), Vector3(14, 0, 20), Vector3(-17, 0, -12)]:
		Mob.spawn(self, "patlayan_misir", p)
	for p: Vector3 in [Vector3(16, 0, -2), Vector3(-9, 0, -10)]:
		Mob.spawn(self, "kiskanc_civciv", p)
	for i in POPS.size():
		_pop_loop(POPS[i], i * 0.8)
	_boss = Patpat.new()
	add_child(_boss)
	_boss.position = SQUARE
	_boss.home = SQUARE
	_boss.hp_changed.connect(func(h: int, m: int) -> void: _hud.set_boss_hp(h, m))
	_boss.phase_changed.connect(_on_phase)
	_boss.sad.connect(_on_sad)
	_boss.calmed.connect(_on_calmed)
	if d.objective_done(Q2, "patpat"):
		_boss._cross.visible = false
		_boss._soft.visible = true
		if not d.objective_done(Q2, "kor"):
			_drop_kor()
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.8).timeout
	if not d.has_flag("s2c3_geldi"):
		d.set_flag("s2c3_geldi")
		GameState.bark("s2c3_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _process(delta: float) -> void:
	var d := GameState.data
	if not _fight and d.objective_done(Q2, "can") and not d.objective_done(Q2, "patpat") \
			and _player.global_position.distance_to(SQUARE) < 9.0 and not GameState.in_dialogue:
		_start_fight()
	if _game != "":
		_game_left -= delta
		if _game == "balon":
			_hud.show_hint(TranslationServer.translate("Balon: %d kaldı · %d sn") % [_balloons_left, ceili(_game_left)], "")
		else:
			_hud.show_hint(TranslationServer.translate("Bayrak %d/%d · %d sn") % [_flag_next, RACE_FLAGS.size(), ceili(_game_left)], "")
		if _game_left <= 0.0:
			_end_game(false)


# --- fair games -----------------------------------------------------------

func _on_play(game_id: String) -> void:
	var d := GameState.data
	if _game != "" or d.quest_state(Q1) != "active" or d.objective_done(Q1, game_id):
		if d.quest_state(Q1) == "none":
			GameState.talk_to("kukuri")
		return
	_game = game_id
	if game_id == "balon":
		_game_left = BALLOON_TIME
		_balloons_left = 8
		var stall := get_node("Level/BalonStall") as Node3D
		for i in 8:
			var a := TAU * i / 8.0
			var b := FairBalloon.new()
			b.name = "Balloon%d" % i
			add_child(b)
			b.global_position = stall.global_position + Vector3(cos(a) * 4.5, 0, 4.0 + sin(a) * 3.0)
			b.popped.connect(func() -> void:
				_balloons_left -= 1
				if _balloons_left <= 0 and _game == "balon":
					_end_game(true))
	else:
		_game_left = RACE_TIME
		_flag_next = 0
		_show_flags(true)


func _show_flags(on: bool) -> void:
	for i in _flags.size():
		_flags[i].visible = on
		if on and i == 0 and not _flags[i].has_node("Beacon"):
			Beacon.attach(_flags[i], 3.0, Tokens.color("honey"))


func _on_flag(i: int) -> void:
	if _game != "kosu" or i != _flag_next:
		return
	Effects.sparkle(self, _flags[i].global_position + Vector3.UP * 2.0, Tokens.color("honey"), 12)
	Audio.play("coin")
	if _flags[i].has_node("Beacon"):
		_flags[i].get_node("Beacon").queue_free()
	_flag_next += 1
	if _flag_next >= _flags.size():
		_end_game(true)
	else:
		Beacon.attach(_flags[_flag_next], 3.0, Tokens.color("honey"))


func _end_game(won: bool) -> void:
	var id := _game
	_game = ""
	_hud.clear_hint()
	for n in get_children():
		if n is FairBalloon:
			n.queue_free()
	if id == "kosu":
		_show_flags(false)
		for f in _flags:
			if f.has_node("Beacon"):
				f.get_node("Beacon").queue_free()
	if won:
		GameState.notify("win", id)
		Audio.play("fanfare")
		GameState.bark("s2c3_kazandin")
	else:
		GameState.bark("s2c3_kaybettin")


# --- boss -----------------------------------------------------------------

func _refresh() -> void:
	var d := GameState.data
	var kuk := get_node("Kukuri") as Node3D
	var go := d.quest_state(Q1) in ["none", "ready"] or d.quest_state(Q2) == "ready"
	if go and not kuk.has_node("Beacon"):
		Beacon.attach(kuk, 2.8, Tokens.color("spark-white"))
	elif not go and kuk.has_node("Beacon"):
		kuk.get_node("Beacon").queue_free()
	for s: String in ["BalonStall", "KosuStall"]:
		var st := get_node_or_null("Level/" + s) as Node3D
		if st:
			var gid := "balon" if s == "BalonStall" else "kosu"
			var on := d.quest_state(Q1) == "active" and not d.objective_done(Q1, gid)
			if on and not st.has_node("Beacon"):
				Beacon.attach(st, 3.4, Tokens.color("spark-white"))
			elif not on and st.has_node("Beacon"):
				st.get_node("Beacon").queue_free()
	var bell := get_node_or_null("Level/Bell") as Node3D
	if bell and d.quest_state(Q2) == "active" and not d.has_flag("s2_can3") and not bell.has_node("Beacon"):
		Beacon.attach(bell, 4.4, Tokens.color("spark-yellow"))
		_hud.show_hint("Tarlaların Ses Çanı'nı çal", "Tarlaların çanını çal")
	if d.has_flag("s2_can3") and _veil:
		_open_veil()


func _start_fight() -> void:
	_fight = true
	boss_camera(true, SQUARE, 0.4, 19.0)
	GameState.bark("s2c3_patpat")
	await GameState.dialogue_closed
	_hud.show_boss("Tavuk Patpat", _boss.hp, FirfirPlan.MAX_HP)
	_hud.show_hint("Mısır halkalarından ve koşusundan kaç. Oturunca vur!", "Halkalardan kaç, oturunca vur!")
	_boss.start()


func _on_phase(_p: int) -> void:
	for id: String in ["bal_surubu", "nane_sekeri"]:
		var pk := Pickup.new()
		pk.item_id = id
		add_child(pk)
		pk.global_position = SQUARE + Vector3(randf_range(-5, 5), 0, randf_range(3, 6))


func _on_sad() -> void:
	_hud.hide_boss()
	GameState.bark("s2c3_patpat_yorgun")
	await GameState.dialogue_closed
	_hud.show_hint("Yanına git, Sakinleş'e basılı tut. Ona bir daha oynamayı sor.", "Yanına git, Sakinleş'e basılı tut!")


func _on_calmed() -> void:
	_hud.clear_hint()
	boss_camera(false)
	GameState.bark("s2c3_patpat_son")
	await GameState.dialogue_closed
	_drop_kor()


func _drop_kor() -> void:
	var kor := Node3D.new()
	kor.name = "Kor"
	add_child(kor)
	kor.position = SQUARE + Vector3(0, 1.2, 3.0)
	var col := Color("#f2b33d")
	Toon.part(kor, "sphere", Vector3(0.7, 0.85, 0.7), col, Vector3.ZERO, Vector3.ZERO, 2.4, 0.03)
	var l := OmniLight3D.new()
	l.light_color = col
	l.omni_range = 5.0
	l.light_energy = 2.0
	kor.add_child(l)
	Beacon.attach(kor, 1.4, col)
	var tw := kor.create_tween().set_loops()
	tw.tween_property(kor, "position:y", 1.5, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(kor, "position:y", 1.2, 0.8).set_trans(Tween.TRANS_SINE)
	var t := TriggerArea.new()
	t.area_id = "kehribar_kor"
	t.radius = 1.4
	add_child(t)
	t.position = SQUARE + Vector3(0, 0, 3.0)
	t.reached.connect(func() -> void:
		GameState.data.set_flag("kor_kehribar")
		Effects.ring(self, kor.global_position, 3.0, col, 0.5)
		Effects.sparkle(self, kor.global_position, col, 20)
		Audio.play("fanfare")
		kor.queue_free()
		_hud.show_scene_card("Kor", "Kehribar Kor", "Patpat Tarlaları'nda panayır yeniden açıldı")
		GameState.bark("s2c3_kor")
		_minnos_runs())


## Bado's little brother, caught by the Kızıl Sis, runs off north.
func _minnos_runs() -> void:
	if GameState.data.has_flag("s2_minnos_kacti"):
		return
	await GameState.dialogue_closed
	var m := KeeperModels.build("bado")
	m.scale = Vector3.ONE * 0.55
	add_child(m)
	m.position = SQUARE + Vector3(7.0, 0, -4.0)
	m.rotation.y = PI
	MobModels._pus_wisps(m, 2.4, Tokens.color("hp"), 6, 0.6)
	await get_tree().create_timer(0.6).timeout
	GameState.bark("s2c3_minnos")
	await GameState.dialogue_closed
	var rig := CharacterRig.of(m)
	if rig:
		rig.speed = 1.0
	var tw := m.create_tween()
	tw.tween_property(m, "position", SQUARE + Vector3(4.0, 0, -18.0), 2.0)
	tw.tween_callback(m.queue_free)
	GameState.data.set_flag("s2_minnos_kacti")


func _open_veil() -> void:
	if not _veil:
		return
	var v := _veil
	_veil = null
	var tw := v.create_tween()
	tw.tween_property(v, "scale", Vector3(1.0, 0.01, 1.0), 1.2)
	tw.tween_callback(v.queue_free)


func _on_bell_rung(_b: EchoBell) -> void:
	Pus.fade_to(self, 0.05, 3.0)
	_hud.clear_hint()
	var bell := get_node_or_null("Level/Bell") as Node3D
	if bell and bell.has_node("Beacon"):
		bell.get_node("Beacon").queue_free()
	GameState.bark("s2c3_can")
	_open_veil()


## A kernel pops in the field: a warned circle, then a little burst.
func _pop_loop(at: Vector3, delay: float) -> void:
	await get_tree().create_timer(2.5 + delay).timeout
	while is_inside_tree():
		Effects.warning(self, at, 1.4, Mob.TELEGRAPH)
		await get_tree().create_timer(Mob.TELEGRAPH).timeout
		if not is_inside_tree():
			return
		Effects.ring(self, at + Vector3.UP * 0.3, 1.6, Color("#fff4d6"), 0.35)
		Effects.sparkle(self, at + Vector3.UP * 1.0, Color("#fff4d6"), 8)
		if Vector2(_player.global_position.x - at.x, _player.global_position.z - at.z).length() < 1.4 and not GameState.in_dialogue:
			_player.hurt(6, at)
		await get_tree().create_timer(3.6).timeout


# --- level ---------------------------------------------------------------

func _build() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	WorldLook.block(lv, Vector3(0, -0.5, -6), Vector3(64, 1, 74), GRASS, 0.0)
	Toon.part(lv, "box", Vector3(3, 0.06, 50), PATH, Vector3(0, 0.0, -2), Vector3.ZERO, 0.0, 0.0)
	Toon.part(lv, "cylinder", Vector3(20, 0.06, 20), PATH, Vector3(0, 0.02, 4.0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(lv, "cylinder", Vector3(18, 0.06, 18), PATH, Vector3(0, 0.02, SQUARE.z), Vector3.ZERO, 0.0, 0.0)
	# corn rows in the side fields
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for side: float in [-1.0, 1.0]:
		for row in 3:
			for k in 12:
				var p := Vector3(side * (20.0 + row * 2.2), 0, 22.0 - k * 4.0 + rng.randf_range(-0.6, 0.6))
				Toon.part(lv, "cylinder", Vector3(0.22, 2.2, 0.22), Color("#7aa04a"), p + Vector3.UP * 1.1)
				Toon.part(lv, "ellipsoid", Vector3(0.4, 0.8, 0.4), Color("#f2c53d"), p + Vector3(0.18, 1.6, 0))
	for p: Vector3 in POPS:
		Toon.part(lv, "cylinder", Vector3(2.8, 0.05, 2.8), FIELD, p + Vector3.UP * 0.01, Vector3.ZERO, 0.0, 0.0)
	# fair tents round the square
	var cols := ["berry", "sky", "spark-yellow", "leaf", "spark-purple", "hp"]
	# on the two sides of the square (never between the camera and the games)
	for i in 6:
		var p := Vector3(-13.0 if i < 3 else 13.0, 0, -4.0 + (i % 3) * 7.0)
		Toon.part(lv, "cylinder", Vector3(2.4, 2.0, 2.4), Color("#f4e2c0"), p + Vector3.UP * 1.0)
		Toon.part(lv, "cone", Vector3(3.0, 1.6, 3.0), cols[i], p + Vector3.UP * 2.8)
		var body := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = 1.2
		cs.height = 2.0
		c.shape = cs
		c.position.y = 1.0
		body.add_child(c)
		body.position = p
		lv.add_child(body)
	var balloon := FairStall.new()
	balloon.name = "BalonStall"
	balloon.game_id = "balon"
	balloon.title = "Balon Patlat"
	balloon.accent = "berry"
	lv.add_child(balloon)
	balloon.position = Vector3(-6.0, 0, 1.0)
	balloon.played.connect(_on_play)
	var race := FairStall.new()
	race.name = "KosuStall"
	race.game_id = "kosu"
	race.title = "Bayrak Koşusu"
	race.accent = "sky"
	lv.add_child(race)
	race.position = Vector3(6.0, 0, 1.0)
	race.played.connect(_on_play)
	for i in RACE_FLAGS.size():
		var f := Node3D.new()
		f.name = "Flag%d" % i
		lv.add_child(f)
		f.position = RACE_FLAGS[i]
		Toon.part(f, "cylinder", Vector3(0.1, 2.6, 0.1), Color("#a86b45"), Vector3(0, 1.3, 0))
		Toon.part(f, "box", Vector3(0.9, 0.55, 0.05), ["hp", "honey", "leaf", "sky"][i], Vector3(0.45, 2.3, 0))
		f.visible = false
		_flags.append(f)
		var t := TriggerArea.new()
		t.radius = 1.6
		t.once = false
		f.add_child(t)
		t.reached.connect(_on_flag.bind(i))
	# the fields' bell
	var bell := EchoBell.new()
	bell.name = "Bell"
	bell.bell_id = "s2_can3"
	bell.needs = Q1
	bell.locked_bark = "s2c3_kilit"
	lv.add_child(bell)
	bell.position = BELL_AT
	bell.rung.connect(_on_bell_rung)
	if not GameState.data.has_flag("s2_can3"):
		_veil = Node3D.new()
		_veil.name = "Veil"
		lv.add_child(_veil)
		_veil.position = Vector3(0, 0, VEIL_Z)
		var body := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(40, 6, 1.0)
		c.shape = b
		c.position.y = 3.0
		body.add_child(c)
		_veil.add_child(body)
		var wall := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(40, 3, 0.3)
		wall.mesh = bm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(Tokens.color("hp"), 0.3)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wall.material_override = m
		wall.position.y = 1.5
		_veil.add_child(wall)
	TravelSign.board(lv, "Fokurdayan Göl ↓", Vector3(-3.0, 1.3, 26.0), 2.6)
	Toon.part(lv, "box", Vector3(0.16, 1.2, 0.16), Color("#a86b45"), Vector3(-3.0, 0.6, 25.95))
	var back := TriggerArea.new()
	back.radius = 1.5
	lv.add_child(back)
	back.position = Vector3(0, 0, 29.0)
	back.reached.connect(func() -> void: SceneFlow.go_to("s2_chapter2"))
	for n in 4:
		var w := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var wb := WorldBoundaryShape3D.new()
		var dir: Vector3 = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK][n]
		var dist: float = [26.0, 26.0, 40.0, 30.0][n]
		wb.plane = Plane(-dir, -dist)
		c.shape = wb
		w.add_child(c)
		lv.add_child(w)


func _run_demo(which: String) -> void:
	match which:
		"fair":
			# the whole chapter, scripted (headless check)
			DevTools.auto_dialogue = true
			var d := GameState.data
			_player.global_position = get_node("Kukuri").global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("kukuri")
			await close_dialogs()
			# lose the balloon game once (do nothing), then win it
			_on_play("balon")
			await get_tree().create_timer(BALLOON_TIME + 0.5).timeout
			await close_dialogs()
			print("S2C3 lost_once balon=%s" % d.objective_done(Q1, "balon"))
			_on_play("balon")
			for n in get_children():
				if n is FairBalloon:
					_player.global_position = n.global_position + Vector3(0, 0.3, 1.0)
					await get_tree().physics_frame
					(n as FairBalloon).hit(1, _player.global_position, 0.0)
					await get_tree().create_timer(0.2).timeout
			await close_dialogs()
			_on_play("kosu")
			for f in _flags:
				_player.global_position = f.global_position + Vector3.UP * 0.3
				await get_tree().create_timer(0.4).timeout
			await close_dialogs()
			print("S2C3 games balon=%s kosu=%s" % [d.objective_done(Q1, "balon"), d.objective_done(Q1, "kosu")])
			_player.global_position = get_node("Kukuri").global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("kukuri")
			await close_dialogs()
			_player.global_position = BELL_AT + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.4).timeout
			(get_node("Level/Bell") as EchoBell).use(_player)
			await close_dialogs()
			await get_tree().create_timer(1.6).timeout
			_player.global_position = SQUARE + Vector3(0, 0.3, 8.0)
			for i in 400:
				await get_tree().create_timer(0.3).timeout
				await close_dialogs()
				if _boss.tired:
					_player.global_position = _boss.global_position + Vector3(0, 0.3, 2.2)
					_player._attack_cd = 0.0
					_player.spin_attack()
				if _boss.is_sad or d.objective_done(Q2, "patpat"):
					break
			print("S2C3 boss hp=%d sad=%s player_hp=%d" % [_boss.hp, _boss.is_sad, d.hp])
			await get_tree().create_timer(0.6).timeout
			await close_dialogs()
			_player.global_position = _boss.global_position + Vector3(0, 0.3, 2.4)
			await get_tree().create_timer(0.3).timeout
			Input.action_press("calm")
			await get_tree().create_timer(BreathCalm.BREATH_IN + BreathCalm.BREATH_OUT + 0.5).timeout
			Input.action_release("calm")
			for i in 10:
				await close_dialogs()
				await get_tree().create_timer(0.3).timeout
				if has_node("Kor"):
					break
			_player.global_position = SQUARE + Vector3(3, 0.3, 6.0)
			await get_tree().create_timer(0.3).timeout
			_player.global_position = SQUARE + Vector3(0, 0.3, 3.0)
			for i in 12:
				await get_tree().create_timer(0.5).timeout
				await close_dialogs()
			_player.global_position = get_node("Kukuri").global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("kukuri")
			await close_dialogs()
			print("S2C3_DONE q2=%s kor=%s minnos=%s flag=%s level=%d" % [d.quest_state(Q2), d.has_flag("kor_kehribar"), d.has_flag("s2_minnos_kacti"), d.has_flag("s2_bolum3_bitti"), d.level])
			get_tree().quit()
		"stalls":
			_player.global_position = Vector3(0, 0.3, 6.0)

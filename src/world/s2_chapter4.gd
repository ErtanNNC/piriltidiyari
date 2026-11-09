extends ChapterBase
## Sezon 2 · Bölüm 4 – Gümbür Kanyonu, Bakır Kor (levels 20–25). A copper
## canyon where every word echoes a thousand times. Once the kids laughed at
## Gümbür's drum ("Davul mu o, tencere mi?"); now the canyon shouts those
## words back. Keçi Yavrusu Çıngır asks the keeper to gather the five mocking
## echoes (the lesson: teasing hurts) and something lost: an old broken
## drumstick. The canyon's Ses Çanı clears the Ritim Arenası where Davulcu
## Keçi Gümbür fights to his drum (rhythm boss, `GumburPlan`). Calmed, he
## knows the drumstick: it was Hırıl's. Gümbür's memory of little Hırıl
## drumming, laughed at, then the Bakır Kor.

const Q1 := "yankilar"
const Q2 := "gumbur"
const ROCK := Color("#c27a52")
const ROCK_DARK := Color("#9a5a3e")
const FLOOR := Color("#e2b48a")
const PATH := Color("#f0d2a8")
const BELL_AT := Vector3(-7.0, 0, -11.0)
const ARENA := Vector3(0, 0, -29.0)
const VEIL_Z := -17.0
## The five mocking echoes (two on low ledges, every keeper can hop up).
const ECHOES := [Vector3(-8, 0, 12), Vector3(9, 0.8, 6), Vector3(-9, 0.8, -1), Vector3(7, 0, -7), Vector3(-3, 0, 3)]
const LEDGES := [Vector3(9.5, 0.4, 6), Vector3(-9.5, 0.4, -1)]
## The old drumstick lies in a side nook.
const STICK_AT := Vector3(9.0, 0, 15.0)
## What the canyon keeps shouting (the kids' old words to Gümbür).
const ECHO_LINES := ["Davul mu o, tencere mi?", "Ne gürültü! Sus artık!", "Bum bum bum, of!", "Kulaklarım ağrıdı!", "Kim dinler bu davulu?"]

var _boss: Gumbur
var _veil: Node3D
var _fight := false
var _echoes: Array[Node3D] = []


func _ready() -> void:
	WorldLook.add(self, "dag")
	Pus.set_color(Pus.RED)
	var d := GameState.data
	Pus.set_amount(0.03 if d.has_flag("s2_can4") else 0.15)
	_build()
	Decor.auto(self, "dag")
	npc(self, "cingir", "goat_kid", Vector3(2.5, 0, 18.0), 0.0).name = "Cingir"
	for p: Vector3 in [Vector3(-6, 0, 7), Vector3(6, 0, -3), Vector3(-5, 0, -9)]:
		Mob.spawn(self, "tepinen_keci", p)
	for p: Vector3 in [Vector3(5, 0, 9), Vector3(-7, 0, 2)]:
		Mob.spawn(self, "yanki_yarasasi", p)
	_boss = Gumbur.new()
	add_child(_boss)
	_boss.position = ARENA
	_boss.home = ARENA
	_boss.hp_changed.connect(func(h: int, m: int) -> void: _hud.set_boss_hp(h, m))
	_boss.phase_changed.connect(_on_phase)
	_boss.sad.connect(_on_sad)
	_boss.calmed.connect(_on_calmed)
	if d.objective_done(Q2, "gumbur"):
		_boss_to_shop()
		if not d.objective_done(Q2, "kor"):
			_drop_kor()
	if d.objective_done(Q2, "kor"):
		giver_comes("Cingir", ARENA + Vector3(3.5, 0, 5.5), false)
	way_on("s2_bolum4_bitti", Vector3(0, 0, -39.5), "Kükreyen Dağ")
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	_player.respawn_point = _player.global_position
	take_return_point()
	await get_tree().create_timer(1.8).timeout
	if not d.has_flag("s2c4_geldi"):
		d.set_flag("s2c4_geldi")
		GameState.bark("s2c4_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _process(_delta: float) -> void:
	var d := GameState.data
	if not _fight and d.objective_done(Q2, "can") and not d.objective_done(Q2, "gumbur") \
			and _player.global_position.distance_to(ARENA) < 10.0 and not GameState.in_dialogue:
		_start_fight()
	# the echoes that are still out there keep shouting, a little wobbly
	var k := Time.get_ticks_msec() / 1000.0
	for e in _echoes:
		if is_instance_valid(e):
			var l := e.get_node_or_null("Shout") as Label3D
			if l:
				l.position.y = 2.0 + sin(k * 2.0 + e.position.x) * 0.12


# --- echoes ---------------------------------------------------------------

func _collect_echo(i: int) -> void:
	var d := GameState.data
	if d.quest_state(Q1) != "active":
		if d.quest_state(Q1) == "none":
			_hud.show_hint("Önce Keçi Yavrusu Çıngır'la konuş", "Önce Çıngır'la konuş")
		return
	var e := _echoes[i]
	if not is_instance_valid(e) or e.get_meta("done", false):
		return
	e.set_meta("done", true)
	d.set_flag("s2c4_yanki%d" % i)
	Effects.ring(self, e.global_position, 1.6, Tokens.color("honey"), 0.4)
	Effects.sparkle(self, e.global_position + Vector3.UP, Tokens.color("honey"), 14)
	Audio.play("memory")
	var tw := e.create_tween()
	tw.tween_property(e, "scale", Vector3(0.01, 0.01, 0.01), 0.4).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(e.queue_free)
	GameState.notify("collect", "yanki")
	if not d.has_flag("s2c4_ilk_yanki"):
		d.set_flag("s2c4_ilk_yanki")
		GameState.bark("s2c4_yanki")


func _take_stick() -> void:
	var d := GameState.data
	if d.quest_state(Q1) != "active" or d.objective_done(Q1, "tokmak"):
		if d.quest_state(Q1) == "none":
			_hud.show_hint("Önce Keçi Yavrusu Çıngır'la konuş", "Önce Çıngır'la konuş")
		return
	var s := get_node_or_null("Level/Stick") as Node3D
	if s:
		Effects.sparkle(self, s.global_position + Vector3.UP * 0.5, Tokens.color("spark-yellow"), 14)
		s.queue_free()
	Audio.play("chest")
	GameState.notify("collect", "tokmak")
	GameState.bark("s2c4_tokmak")


# --- boss -----------------------------------------------------------------

func _refresh() -> void:
	var d := GameState.data
	var cin := get_node("Cingir") as Node3D
	var go := d.quest_state(Q1) in ["none", "ready"] or d.quest_state(Q2) == "ready"
	if go and not cin.has_node("Beacon"):
		Beacon.attach(cin, 2.2, Tokens.color("spark-white"))
	elif not go and cin.has_node("Beacon"):
		cin.get_node("Beacon").queue_free()
	var hunting := d.quest_state(Q1) == "active"
	for e in _echoes:
		if is_instance_valid(e) and not e.get_meta("done", false):
			if hunting and not e.has_node("Beacon"):
				Beacon.attach(e, 2.8, Tokens.color("honey"))
	var stick := get_node_or_null("Level/Stick") as Node3D
	if stick and hunting and not d.objective_done(Q1, "tokmak") and not stick.has_node("Beacon"):
		Beacon.attach(stick, 1.6, Tokens.color("spark-yellow"))
	if stick and d.objective_done(Q1, "tokmak"):
		stick.queue_free()
	var bell := get_node_or_null("Level/Bell") as Node3D
	if bell and d.quest_state(Q2) == "active" and not d.has_flag("s2_can4") and not bell.has_node("Beacon"):
		Beacon.attach(bell, 4.4, Tokens.color("spark-yellow"))
		_hud.show_hint("Kanyonun Ses Çanı'nı çal", "Kanyonun çanını çal")
	if d.has_flag("s2_can4") and _veil:
		_open_veil()


func _start_fight() -> void:
	_fight = true
	boss_camera(true, ARENA, 0.4, 19.0)
	GameState.bark("s2c4_gumbur")
	await GameState.dialogue_closed
	_hud.show_boss("Davulcu Keçi Gümbür", _boss.hp, GumburPlan.MAX_HP)
	_hud.show_hint("Bum, bum, sus! Daire bir vuruş sonra iner. Nefeslenince vur!", "Ritmi dinle, nefeslenince vur!")
	_boss.start()


func _on_phase(_p: int) -> void:
	for id: String in ["bal_surubu", "nane_sekeri"]:
		var pk := Pickup.new()
		pk.item_id = id
		add_child(pk)
		pk.global_position = ARENA + Vector3(randf_range(-5, 5), 0, randf_range(3, 6))


func _on_sad() -> void:
	_hud.hide_boss()
	GameState.bark("s2c4_gumbur_yorgun")
	await GameState.dialogue_closed
	_hud.show_hint("Yanına git, Sakinleş'e basılı tut. Davulunu dinle.", "Yanına git, Sakinleş'e basılı tut!")


func _on_calmed() -> void:
	_hud.clear_hint()
	boss_camera(false)
	GameState.bark("s2c4_gumbur_son")
	await GameState.dialogue_closed
	await _memory()
	_drop_kor()
	_boss_to_shop()


## Gümbür remembers little Hırıl drumming in the canyon: a faint, small
## Hırıl appears by the drum, plays, and fades when the laughing starts.
func _memory() -> void:
	if GameState.data.has_flag("s2c4_ani"):
		return
	GameState.data.set_flag("s2c4_ani")
	_hud.show_scene_card("Anı", "Hırıl'ın Davulu", "Gümbür Kanyonu, çok uzun zaman önce")
	var h := HirilModel.build(true)
	h.name = "MemoryHiril"
	h.scale = Vector3.ONE * 0.6
	add_child(h)
	h.position = ARENA + Vector3(-4.0, 0, 3.0)
	h.rotation.y = 0.5
	var glow := OmniLight3D.new()
	glow.light_color = Color("#ffd9a8")
	glow.omni_range = 5.0
	glow.light_energy = 1.5
	glow.position.y = 1.5
	h.add_child(glow)
	var drum := Node3D.new()
	h.add_child(drum)
	drum.position = Vector3(0, 0.9, 1.0)
	Toon.part(drum, "cylinder", Vector3(0.9, 0.6, 0.9), Color("#c87a4a"), Vector3.ZERO, Vector3(90, 0, 0))
	var bounce := drum.create_tween().set_loops(8)
	bounce.tween_property(drum, "scale", Vector3(1.15, 1.15, 0.9), 0.1)
	bounce.tween_property(drum, "scale", Vector3.ONE, 0.3)
	Audio.play("memory")
	GameState.bark("s2c4_ani")
	await GameState.dialogue_closed
	if is_instance_valid(h):
		var tw := h.create_tween()
		tw.tween_property(h, "scale", Vector3(0.01, 0.01, 0.01), 0.8)
		tw.tween_callback(h.queue_free)


## Calmed, Gümbür stays in the arena and runs a little drum stall.
func _boss_to_shop() -> void:
	if has_node("GumburShop"):
		return
	_boss.visible = false
	_boss.process_mode = Node.PROCESS_MODE_DISABLED
	npc(self, "gumbur", "gumbur", ARENA + Vector3(-3.0, 0, -2.0), 20.0).name = "GumburShop"


func _drop_kor() -> void:
	var kor := Node3D.new()
	kor.name = "Kor"
	add_child(kor)
	kor.position = ARENA + Vector3(0, 1.2, 3.5)
	var col := Color("#c87a4a")
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
	t.area_id = "bakir_kor"
	t.radius = 1.4
	add_child(t)
	t.position = ARENA + Vector3(0, 0, 3.5)
	t.reached.connect(func() -> void:
		GameState.data.set_flag("kor_bakir")
		Effects.ring(self, kor.global_position, 3.0, col, 0.5)
		Effects.sparkle(self, kor.global_position, col, 20)
		Audio.play("fanfare")
		kor.queue_free()
		_hud.show_scene_card("Kor", "Bakır Kor", "Gümbür Kanyonu artık şarkı yankılıyor")
		GameState.bark("s2c4_kor")
		_giver_after_kor())


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
	GameState.bark("s2c4_can")
	_open_veil()


# --- level ---------------------------------------------------------------

func _build() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	var d := GameState.data
	WorldLook.block(lv, Vector3(0, -0.5, -6), Vector3(30, 1, 74), FLOOR, 0.0)
	Toon.part(lv, "box", Vector3(3, 0.06, 40), PATH, Vector3(0, 0.0, 6), Vector3.ZERO, 0.0, 0.0)
	Toon.part(lv, "cylinder", Vector3(20, 0.06, 20), PATH, Vector3(0, 0.02, ARENA.z), Vector3.ZERO, 0.0, 0.0)
	# canyon walls: stacked copper rock bands on both sides
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	for side: float in [-1.0, 1.0]:
		for k in 10:
			var z := 26.0 - k * 7.0
			var h := rng.randf_range(7.0, 11.0)
			var w := rng.randf_range(3.0, 4.5)
			WorldLook.block(lv, Vector3(side * (13.0 + w * 0.5), h * 0.5, z), Vector3(w, h, 7.2), ROCK if k % 2 == 0 else ROCK_DARK, 0.03)
			# a lighter band across the rock
			Toon.part(lv, "box", Vector3(w + 0.1, 0.5, 7.25), Color("#e0a072"), Vector3(side * (13.0 + w * 0.5), h * 0.55, z), Vector3.ZERO, 0.0, 0.0)
	# boulders along the sides (never on the path)
	for p: Vector3 in [Vector3(-10, 0, 20), Vector3(10.5, 0, -14), Vector3(-10.5, 0, -20), Vector3(10, 0, 22)]:
		WorldLook.block(lv, p + Vector3.UP * 0.7, Vector3(1.8, 1.4, 1.6), ROCK_DARK, 0.03)
	# two low ledges (one hop) with an echo on each
	for p: Vector3 in LEDGES:
		WorldLook.block(lv, p, Vector3(3.0, 0.8, 3.0), ROCK, 0.03)
	# the arena: a ring of drum-shaped stones
	for i in 10:
		var a := TAU * i / 10.0 + 0.3
		var p := ARENA + Vector3(cos(a) * 10.5, 0, sin(a) * 10.5)
		if p.z > ARENA.z + 8.0:
			continue  # keep the entrance and the camera side open
		WorldLook.block(lv, p + Vector3.UP * 0.6, Vector3(1.4, 1.2, 1.4), ROCK_DARK, 0.03)
		Toon.part(lv, "cylinder", Vector3(1.2, 0.1, 1.2), Color("#fff4dc"), p + Vector3.UP * 1.22, Vector3.ZERO, 0.0, 0.0)
	# the echoes
	for i in ECHOES.size():
		var e := Node3D.new()
		e.name = "Echo%d" % i
		lv.add_child(e)
		e.position = ECHOES[i]
		_echoes.append(e)
		if d.has_flag("s2c4_yanki%d" % i) or d.quest_state(Q1) in ["ready", "done"]:
			e.set_meta("done", true)
			e.visible = false
			continue
		Toon.part(e, "sphere", Vector3(0.7, 0.7, 0.7), Color("#ff9a4a"), Vector3(0, 1.1, 0), Vector3.ZERO, 0.5, 0.03)
		Toon.part(e, "sphere", Vector3(0.3, 0.3, 0.3), Color("#fff1c4"), Vector3(0, 1.1, 0.25), Vector3.ZERO, 0.6, 0.0)
		Toon.part(e, "ring", Vector3(1.3, 0.06, 1.3), "spark-purple", Vector3(0, 1.1, 0), Vector3(90, 0, 0), 0.4, 0.0)
		var pulse := e.create_tween().set_loops()
		pulse.tween_property(e, "scale", Vector3(1.12, 1.12, 1.12), 0.5).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(e, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_SINE)
		var l := Label3D.new()
		l.name = "Shout"
		l.text = ECHO_LINES[i]
		l.font = Tokens.font_for("text-heading")
		l.font_size = 44
		l.pixel_size = 0.006
		l.outline_size = 12
		l.outline_modulate = Tokens.color("outline")
		l.modulate = Tokens.color("panel@light")
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.position.y = 2.0
		e.add_child(l)
		var t := TriggerArea.new()
		t.radius = 1.3
		t.once = false
		e.add_child(t)
		t.reached.connect(_collect_echo.bind(i))
	if not d.objective_done(Q1, "tokmak") and d.quest_state(Q1) in ["none", "active"]:
		var s := Node3D.new()
		s.name = "Stick"
		lv.add_child(s)
		s.position = STICK_AT
		Toon.part(s, "cylinder", Vector3(0.1, 0.8, 0.1), Color("#a86b45"), Vector3(0, 0.12, 0), Vector3(0, 0, 80))
		Toon.part(s, "sphere", Vector3(0.24, 0.24, 0.24), "berry", Vector3(0.42, 0.14, 0))
		Toon.part(s, "box", Vector3(0.12, 0.06, 0.12), Color("#ffd94a"), Vector3(-0.2, 0.2, 0), Vector3.ZERO, 1.0, 0.0)
		var t := TriggerArea.new()
		t.radius = 1.3
		t.once = false
		s.add_child(t)
		t.reached.connect(_take_stick)
	# the canyon's bell
	var bell := EchoBell.new()
	bell.name = "Bell"
	bell.bell_id = "s2_can4"
	bell.needs = Q1
	bell.locked_bark = "s2c4_kilit"
	lv.add_child(bell)
	bell.position = BELL_AT
	bell.rung.connect(_on_bell_rung)
	if not d.has_flag("s2_can4"):
		_veil = Node3D.new()
		_veil.name = "Veil"
		lv.add_child(_veil)
		_veil.position = Vector3(0, 0, VEIL_Z)
		var body := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(30, 6, 1.0)
		c.shape = b
		c.position.y = 3.0
		body.add_child(c)
		_veil.add_child(body)
		var wall := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(26, 3, 0.3)
		wall.mesh = bm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(Tokens.color("hp"), 0.3)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wall.material_override = m
		wall.position.y = 1.5
		_veil.add_child(wall)
	TravelSign.board(lv, "Kükreyen Dağ ↑", Vector3(-3.0, 1.3, -37.0), 2.6)
	Toon.part(lv, "box", Vector3(0.16, 1.2, 0.16), Color("#a86b45"), Vector3(-3.0, 0.6, -37.05))
	var on := TriggerArea.new()
	on.radius = 1.5
	on.once = false
	lv.add_child(on)
	on.position = Vector3(0, 0, -39.5)
	on.reached.connect(func() -> void:
		if GameState.data.has_flag("s2_bolum4_bitti"):
			SceneFlow.go_to("s2_chapter5"))
	TravelSign.board(lv, "Patpat Tarlaları ↓", Vector3(-3.0, 1.3, 26.0), 2.6)
	Toon.part(lv, "box", Vector3(0.16, 1.2, 0.16), Color("#a86b45"), Vector3(-3.0, 0.6, 25.95))
	var back := TriggerArea.new()
	back.radius = 1.5
	lv.add_child(back)
	back.position = Vector3(0, 0, 29.0)
	back.reached.connect(func() -> void: SceneFlow.go_to("s2_chapter3"))
	for n in 4:
		var w := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var wb := WorldBoundaryShape3D.new()
		var dir: Vector3 = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK][n]
		var dist: float = [13.0, 13.0, 41.0, 30.0][n]
		wb.plane = Plane(-dir, -dist)
		c.shape = wb
		w.add_child(c)
		lv.add_child(w)


func _run_demo(which: String) -> void:
	match which:
		"canyon":
			# the whole chapter, scripted (headless check)
			DevTools.auto_dialogue = true
			var d := GameState.data
			_player.global_position = get_node("Cingir").global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("cingir")
			await close_dialogs()
			for i in ECHOES.size():
				_player.global_position = ECHOES[i] + Vector3(0, 0.4, 0)
				await get_tree().create_timer(0.4).timeout
				await close_dialogs()
			_player.global_position = STICK_AT + Vector3(0, 0.3, 0)
			await get_tree().create_timer(0.4).timeout
			await close_dialogs()
			print("S2C4 echoes q1=%s yanki=%s tokmak=%s" % [d.quest_state(Q1), d.objective_done(Q1, "yanki"), d.objective_done(Q1, "tokmak")])
			_player.global_position = get_node("Cingir").global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("cingir")
			await close_dialogs()
			_player.global_position = BELL_AT + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.4).timeout
			(get_node("Level/Bell") as EchoBell).use(_player)
			await close_dialogs()
			await get_tree().create_timer(1.6).timeout
			_player.global_position = ARENA + Vector3(0, 0.3, 8.0)
			var hp_start := d.hp
			for i in 400:
				await get_tree().create_timer(0.3).timeout
				await close_dialogs()
				if _boss.tired:
					_player.global_position = _boss.global_position + Vector3(0, 0.3, 2.2)
					_player._attack_cd = 0.0
					_player.spin_attack()
				if _boss.is_sad or d.objective_done(Q2, "gumbur"):
					break
			print("S2C4 boss hp=%d sad=%s player_hp=%d/%d" % [_boss.hp, _boss.is_sad, d.hp, hp_start])
			await get_tree().create_timer(0.6).timeout
			await close_dialogs()
			for tries in 3:
				if not _boss.is_sad:
					break
				await close_dialogs()
				_player.global_position = _boss.global_position + Vector3(0, 0.3, 2.4)
				await get_tree().create_timer(0.5).timeout
				Input.action_press("calm")
				await get_tree().create_timer(BreathCalm.BREATH_IN + BreathCalm.BREATH_OUT + 0.5).timeout
				Input.action_release("calm")
			print("S2C4 calm sad=%s dist=%.1f q2gumbur=%s" % [_boss.is_sad, _player.global_position.distance_to(_boss.global_position), d.objective_done(Q2, "gumbur")])
			for i in 20:
				await close_dialogs()
				await get_tree().create_timer(0.3).timeout
				if has_node("Kor"):
					break
			_player.global_position = ARENA + Vector3(3, 0.3, 7.0)
			await get_tree().create_timer(0.3).timeout
			_player.global_position = ARENA + Vector3(0, 0.3, 3.5)
			for i in 8:
				await get_tree().create_timer(0.5).timeout
				await close_dialogs()
			_player.global_position = get_node("Cingir").global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("cingir")
			await close_dialogs()
			print("S2C4_DONE q2=%s kor=%s ani=%s flag=%s level=%d cingir_at_arena=%s way_on=%s" % [d.quest_state(Q2), d.has_flag("kor_bakir"), d.has_flag("s2c4_ani"), d.has_flag("s2_bolum4_bitti"), d.level, (get_node("Cingir") as Node3D).global_position.distance_to(ARENA) < 9.0, has_node("WayOn")])
			get_tree().quit()
		"dodge":
			# stand still in the arena through a whole cycle: count the hits
			DevTools.auto_dialogue = true
			var d := GameState.data
			d.set_flag("s2_can4")
			_open_veil()
			_player.global_position = ARENA + Vector3(0, 0.3, 6.0)
			_fight = true
			boss_camera(true, ARENA, 0.4, 19.0)
			_boss.start()
			var hp0 := d.hp
			await get_tree().create_timer(GumburPlan.cycle_time(1)).timeout
			print("S2C4 dodge standing_hits=%d" % roundi(float(hp0 - d.hp) / GumburPlan.DAMAGE))
			get_tree().quit()
		"travel":
			# ring the canyon bell, then travel back to Kaplıca Köyü's bell
			DevTools.auto_dialogue = true
			GameState.data.set_flag("s2_can4")
			var bell := get_node("Level/Bell") as EchoBell
			_player.global_position = BELL_AT + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.3).timeout
			bell.use(_player)
			await get_tree().create_timer(0.4).timeout
			for n in _hud.find_children("*", "ChoicePanel", true, false):
				(n as ChoicePanel)._pick("s2_can0")
		"arena":
			d_arena()
		"echo":
			_player.global_position = ECHOES[4] + Vector3(0, 0.3, 5.0)


func d_arena() -> void:
	var d := GameState.data
	d.set_flag("s2_can4")
	_open_veil()
	_player.global_position = ARENA + Vector3(0, 0.3, 7.0)


## After the Kor: Cingir comes over to the arena for the last talk.
func _giver_after_kor() -> void:
	await GameState.wait_dialogue_closed()
	await get_tree().create_timer(0.4).timeout
	await GameState.wait_dialogue_closed()
	giver_comes("Cingir", ARENA + Vector3(3.5, 0, 5.5))

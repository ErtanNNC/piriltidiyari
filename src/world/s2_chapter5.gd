extends ChapterBase
## Sezon 2 · Bölüm 5 – Kükreyen Dağ, Al Kor and the final (levels 25–30).
## The mountain is full of the words Hırıl never got to say, glowing on its
## walls. Davulcu Gümbür (who came along) asks the keeper to gather five of
## them and to find Minnoş, who sits alone: not chased, just sat beside
## (Sakinleş, `SittingFriend`). The mountain's Ses Çanı opens the summit.
## Faz 1: Hırıl fights (`Hiril`, `HirilPlan`). Faz 2: no fighting; the keeper
## carries each word back to him and answers it (`Hud.ask`). The last word
## lets his steam go: a small warm kor child is left. Tıpış says sorry, the
## Al Kor, and Mırıl takes everyone home: the Gökkuşağı Şenliği (`s2_final`).

const Q1 := "soylenemeyen"
const Q2 := "hiril"
const ROCK := Color("#8a5a4e")
const ROCK_DARK := Color("#6a4440")
const FLOOR := Color("#c99a7a")
const PATH := Color("#e8c09a")
const LAVA := Color("#ff7a3a")
const BELL_AT := Vector3(6.0, 0, -12.0)
const ARENA := Vector3(0, 0, -31.0)
const VEIL_Z := -18.0
## The five words on the walls (their text is barks "s2c5_e<i>").
const WORDS := [Vector3(-10, 0, 13), Vector3(10, 0, 4), Vector3(-10, 0, -1), Vector3(10.5, 0, -8), Vector3(-9, 0, -12)]
const MINNOS_AT := Vector3(10.5, 0, 16.0)
## Warm vents by the walls (warned like attacks).
const VENTS := [Vector3(-6, 0, 8), Vector3(7, 0, -2), Vector3(-5, 0, -7)]

var _boss: Hiril
var _veil: Node3D
var _fight := false
var _faz2 := false
var _heard := 0
var _busy_echo := false
var _words: Array[Node3D] = []
var _orbs: Array[Node3D] = []
var _minnos: SittingFriend
var _ended := false


func _ready() -> void:
	WorldLook.add(self, "aksam")
	Pus.set_color(Pus.RED)
	var d := GameState.data
	Pus.set_amount(0.0 if d.objective_done(Q2, "hiril") else 0.04 if d.has_flag("s2_can5") else 0.18)
	_build()
	Decor.auto(self, "dag")
	npc(self, "gumbur", "gumbur", Vector3(-2.5, 0, 19.0), 0.0).name = "Gumbur"
	var mir := npc(self, "miril", "star_child", ARENA + Vector3(-6.0, 0, -3.0), 0.6)
	mir.name = "Miril"
	for p: Vector3 in [Vector3(-5, 0, 10), Vector3(5, 0, 1), Vector3(-6, 0, -9)]:
		Mob.spawn(self, "lav_damlacigi", p)
	for p: Vector3 in [Vector3(4, 0, 12), Vector3(-4, 0, -3)]:
		Mob.spawn(self, "sus_bulutu", p)
	for i in VENTS.size():
		_vent_loop(VENTS[i], i * 1.1)
	_add_minnos()
	_boss = Hiril.new()
	add_child(_boss)
	_boss.position = ARENA
	_boss.home = ARENA
	_boss.hp_changed.connect(func(h: int, m: int) -> void: _hud.set_boss_hp(h, m))
	_boss.phase_changed.connect(_on_phase)
	_boss.sad.connect(_on_faz2)
	_boss.calmed.connect(_on_calmed)
	if d.objective_done(Q2, "hiril"):
		_boss.show_calm()
		if not d.objective_done(Q2, "kor"):
			_drop_kor()
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	_player.respawn_point = _player.global_position
	take_return_point()
	await get_tree().create_timer(1.8).timeout
	if not d.has_flag("s2c5_geldi"):
		d.set_flag("s2c5_geldi")
		GameState.bark("s2c5_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _process(_delta: float) -> void:
	var d := GameState.data
	if not _fight and d.objective_done(Q2, "can") and not d.objective_done(Q2, "hiril") \
			and _player.global_position.distance_to(ARENA) < 11.0 and not GameState.in_dialogue:
		_start_fight()
	if _minnos and not _minnos.is_calm and not d.has_flag("s2c5_minnos_gor") \
			and _player.global_position.distance_to(_minnos.global_position) < 6.0 and not GameState.in_dialogue:
		d.set_flag("s2c5_minnos_gor")
		GameState.bark("s2c5_minnos_gor")
	if d.has_flag("sezon2_bitti") and not _ended and not GameState.in_dialogue:
		_ended = true
		_season_end()


# --- words and Minnoş -------------------------------------------------------

func _word_text(i: int) -> String:
	var lines: Array = Content.barks.get("s2c5_e%d" % i, [])
	return lines[0]["text"] if not lines.is_empty() else ""


func _collect_word(i: int) -> void:
	var d := GameState.data
	if d.quest_state(Q1) != "active":
		if d.quest_state(Q1) == "none":
			_hud.show_hint("Önce Davulcu Gümbür'le konuş", "Önce Gümbür'le konuş")
		return
	var w := _words[i]
	if not is_instance_valid(w) or w.get_meta("done", false):
		return
	w.set_meta("done", true)
	d.set_flag("s2c5_soz%d" % i)
	var orb := w.get_node_or_null("Orb") as Node3D
	if orb:
		Effects.ring(self, orb.global_position, 1.6, Tokens.color("spark-purple"), 0.4)
		Effects.sparkle(self, orb.global_position, Color("#ffd9a8"), 14)
		orb.queue_free()
	if w.has_node("Beacon"):
		w.get_node("Beacon").queue_free()
	Audio.play("page")
	GameState.notify("collect", "hiril_soz")
	if not d.has_flag("s2c5_ilk_soz"):
		d.set_flag("s2c5_ilk_soz")
		GameState.bark("s2c5_soz")


func _add_minnos() -> void:
	var d := GameState.data
	if d.objective_done(Q1, "minnos") or d.quest_state(Q1) == "done":
		return
	_minnos = SittingFriend.new()
	_minnos.name = "Minnos"
	_minnos.calm_event = "minnos"
	add_child(_minnos)
	_minnos.position = MINNOS_AT
	_minnos.rotation.y = -2.2
	var m := KeeperModels.build("bado")
	m.scale = Vector3(0.55, 0.45, 0.55)  # sitting, curled up
	_minnos.set_model(m)
	_minnos.calmed.connect(func() -> void:
		GameState.bark("s2c5_minnos")
		if _minnos.has_node("Beacon"):
			_minnos.get_node("Beacon").queue_free()
		await GameState.dialogue_closed
		var tw := _minnos.create_tween()
		tw.tween_property(_minnos, "position", Vector3(4.0, 0, 30.0), 3.0)
		tw.tween_callback(_minnos.queue_free))


# --- the summit ---------------------------------------------------------------

func _refresh() -> void:
	var d := GameState.data
	var g := get_node("Gumbur") as Node3D
	var go := d.quest_state(Q1) in ["none", "ready"]
	if go and not g.has_node("Beacon"):
		Beacon.attach(g, 3.2, Tokens.color("spark-white"))
	elif not go and g.has_node("Beacon"):
		g.get_node("Beacon").queue_free()
	var mir := get_node("Miril") as Node3D
	var to_mir := d.quest_state(Q2) == "ready"
	if to_mir and not mir.has_node("Beacon"):
		Beacon.attach(mir, 2.4, Tokens.color("spark-white"))
	var hunting := d.quest_state(Q1) == "active"
	for w in _words:
		if is_instance_valid(w) and not w.get_meta("done", false) and hunting and not w.has_node("Beacon"):
			Beacon.attach(w, 3.4, Tokens.color("spark-purple"))
	if _minnos and is_instance_valid(_minnos) and hunting and not _minnos.is_calm and not _minnos.has_node("Beacon"):
		Beacon.attach(_minnos, 1.8, Tokens.color("spark-green"))
	var bell := get_node_or_null("Level/Bell") as Node3D
	if bell and d.quest_state(Q2) == "active" and not d.has_flag("s2_can5") and not bell.has_node("Beacon"):
		Beacon.attach(bell, 4.4, Tokens.color("spark-yellow"))
		_hud.show_hint("Dağın Ses Çanı'nı çal", "Dağın çanını çal")
	if d.has_flag("s2_can5") and _veil:
		_open_veil()


func _start_fight() -> void:
	_fight = true
	boss_camera(true, ARENA, 0.4, 20.0)
	GameState.bark("s2c5_hiril")
	await GameState.dialogue_closed
	_hud.show_boss("Hırıl", _boss.hp, HirilPlan.MAX_HP)
	_hud.show_hint("Lav toplarından kaç. Buharı bitince vur!", "Lavdan kaç, buharı bitince vur!")
	_boss.start()


func _on_phase(_p: int) -> void:
	for id: String in ["bal_surubu", "nane_sekeri"]:
		var pk := Pickup.new()
		pk.item_id = id
		add_child(pk)
		pk.global_position = ARENA + Vector3(randf_range(-5, 5), 0, randf_range(3, 6))


## Faz 2: the fight stops. The words float round the summit; carry each back.
func _on_faz2() -> void:
	_faz2 = true
	_hud.hide_boss()
	GameState.bark("s2c5_faz2")
	await GameState.dialogue_closed
	_hud.show_hint("Parlayan sözlere git. Her birini Hırıl'a geri götür.", "Sözlere git, Hırıl'a götür")
	for i in HirilPlan.ECHOES:
		var a := TAU * i / float(HirilPlan.ECHOES) + 0.3
		var orb := Node3D.new()
		orb.name = "Echo%d" % i
		add_child(orb)
		orb.position = ARENA + Vector3(cos(a) * 6.5, 0, sin(a) * 6.5 + 1.0)
		Toon.part(orb, "sphere", Vector3(0.6, 0.6, 0.6), Color("#ffd9a8"), Vector3(0, 1.1, 0), Vector3.ZERO, 0.6, 0.03)
		Toon.part(orb, "ring", Vector3(1.1, 0.05, 1.1), "spark-purple", Vector3(0, 1.1, 0), Vector3(90, 0, 0), 0.4, 0.0)
		Beacon.attach(orb, 2.2, Tokens.color("spark-purple"))
		var t := TriggerArea.new()
		t.radius = 1.4
		orb.add_child(t)
		t.reached.connect(_play_echo.bind(i))
		_orbs.append(orb)


## A word goes back to Hırıl: he says it, the keeper answers.
func _play_echo(i: int) -> void:
	if _busy_echo or not _faz2:
		return
	_busy_echo = true
	var orb := _orbs[i]
	var tw := orb.create_tween()
	tw.tween_property(orb, "global_position", _boss.global_position + Vector3.UP * 1.5, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(orb.queue_free)
	Audio.play("memory")
	await get_tree().create_timer(0.6).timeout
	GameState.bark("s2c5_e%d" % i)
	await GameState.dialogue_closed
	var replies: Array = Content.barks.get("s2c5_cevap", [])
	var opts := []
	for k in replies.size():
		opts.append({"id": str(k), "label": replies[k]["text"]})
	var pick := await _hud.ask("Ne dersin?", opts)
	var line: Dictionary = replies[int(pick) if pick != "" else 0]
	GameState.lines_requested.emit(GameState.resolve_speakers([line]), {})
	await GameState.dialogue_closed
	_heard += 1
	_boss.hear(_heard)
	_busy_echo = false
	if _heard >= HirilPlan.ECHOES:
		_hud.clear_hint()
		_boss.become_calm()


func _on_calmed() -> void:
	_faz2 = false
	boss_camera(false)
	Pus.fade_to(self, 0.0, 3.0)
	await get_tree().create_timer(1.2).timeout
	GameState.bark("s2c5_sakin")
	await GameState.dialogue_closed
	# Tıpış comes up the path to say sorry (the player, if they are Tıpış)
	if GameState.data.character_id != "tipis_panda":
		var t := npc(self, "tipis_panda", "tipis_panda", ARENA + Vector3(4.0, 0, 5.0), PI + 0.6)
		t.name = "Tipis"
	GameState.bark("s2c5_tipis")
	await GameState.dialogue_closed
	_drop_kor()


func _drop_kor() -> void:
	var kor := Node3D.new()
	kor.name = "Kor"
	add_child(kor)
	kor.position = ARENA + Vector3(0, 1.2, 3.5)
	var col := Color("#e8463a")
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
	t.area_id = "al_kor"
	t.radius = 1.4
	add_child(t)
	t.position = ARENA + Vector3(0, 0, 3.5)
	t.reached.connect(func() -> void:
		GameState.data.set_flag("kor_al")
		Effects.ring(self, kor.global_position, 3.0, col, 0.5)
		Effects.sparkle(self, kor.global_position, col, 24)
		Audio.play("fanfare")
		kor.queue_free()
		_hud.show_scene_card("Kor", "Al Kor", "Beş Kor tamam! Kızıl Sis dağılıyor")
		GameState.bark("s2c5_kor"))


func _season_end() -> void:
	var d := GameState.data
	if DevTools.demo != "" and DisplayServer.get_name() == "headless":
		print("S2C5_END kor=%d sezon2=%s" % [KorTracker.found(d), d.has_flag("sezon2_bitti")])
		get_tree().quit()
		return
	# everyone goes home: the Gökkuşağı Şenliği in the village
	SceneFlow.go_to("s2_final")


func _open_veil() -> void:
	if not _veil:
		return
	var v := _veil
	_veil = null
	var tw := v.create_tween()
	tw.tween_property(v, "scale", Vector3(1.0, 0.01, 1.0), 1.2)
	tw.tween_callback(v.queue_free)


func _on_bell_rung(_b: EchoBell) -> void:
	Pus.fade_to(self, 0.04, 3.0)
	_hud.clear_hint()
	var bell := get_node_or_null("Level/Bell") as Node3D
	if bell and bell.has_node("Beacon"):
		bell.get_node("Beacon").queue_free()
	GameState.bark("s2c5_can")
	_open_veil()


## A warm vent by the path: a warned circle, then a puff of hot steam.
func _vent_loop(at: Vector3, delay: float) -> void:
	await get_tree().create_timer(3.0 + delay).timeout
	while is_inside_tree():
		Effects.warning(self, at, 1.3, Mob.TELEGRAPH)
		await get_tree().create_timer(Mob.TELEGRAPH).timeout
		if not is_inside_tree():
			return
		Effects.ring(self, at + Vector3.UP * 0.3, 1.5, LAVA, 0.35)
		Effects.sparkle(self, at + Vector3.UP * 1.0, Color("#ffd27a"), 8)
		if Vector2(_player.global_position.x - at.x, _player.global_position.z - at.z).length() < 1.3 and not GameState.in_dialogue:
			_player.hurt(7, at)
		await get_tree().create_timer(4.0).timeout


# --- level ---------------------------------------------------------------

func _build() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	var d := GameState.data
	WorldLook.block(lv, Vector3(0, -0.5, -6), Vector3(30, 1, 76), FLOOR, 0.0)
	Toon.part(lv, "box", Vector3(3, 0.06, 40), PATH, Vector3(0, 0.0, 7), Vector3.ZERO, 0.0, 0.0)
	Toon.part(lv, "cylinder", Vector3(20, 0.06, 20), PATH, Vector3(0, 0.02, ARENA.z), Vector3.ZERO, 0.0, 0.0)
	for p: Vector3 in VENTS:
		Toon.part(lv, "cylinder", Vector3(2.4, 0.05, 2.4), ROCK_DARK, p + Vector3.UP * 0.01, Vector3.ZERO, 0.0, 0.0)
		Toon.part(lv, "cylinder", Vector3(0.9, 0.06, 0.9), LAVA, p + Vector3.UP * 0.02, Vector3.ZERO, 1.2, 0.0)
	# the mountain's walls, with glowing lava cracks
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	for side: float in [-1.0, 1.0]:
		for k in 11:
			var z := 27.0 - k * 7.0
			var h := rng.randf_range(8.0, 13.0)
			var w := rng.randf_range(3.0, 4.5)
			var wall := WorldLook.block(lv, Vector3(side * (13.5 + w * 0.5), h * 0.5, z), Vector3(w, h, 7.2), ROCK if k % 2 == 0 else ROCK_DARK, 0.03)
			# real volcanic rock over the box (the boards on the walls stay clear)
			if ModelImport.cover_block(wall, "volkan_sutun" if k % 2 == 0 else "volkan_kaya", Vector3(1.25, 1.06, 1.2), PI * float(k % 2)):
				continue
			if k % 3 == 1:
				Toon.part(lv, "box", Vector3(0.12, h * 0.5, 0.2), Color("#e8603a"), Vector3(side * 13.45, h * 0.3, z + 1.0), Vector3(0, 0, 8 * side), 0.5, 0.0)
	# the summit: a ring of dark rocks round the arena (open to the south)
	for i in 12:
		var a := TAU * i / 12.0
		var p := ARENA + Vector3(cos(a) * 11.0, 0, sin(a) * 11.0)
		if p.z > ARENA.z + 7.0:
			continue
		ModelImport.cover_block(WorldLook.block(lv, p + Vector3.UP * 0.9, Vector3(1.6, 1.8, 1.6), ROCK_DARK, 0.03), "volkan_kaya", Vector3(1.3, 1.1, 1.3), a)
	# the words on the walls
	for i in WORDS.size():
		var w := Node3D.new()
		w.name = "Word%d" % i
		lv.add_child(w)
		w.position = WORDS[i]
		_words.append(w)
		var side := -1.0 if WORDS[i].x < 0 else 1.0
		TravelSign.board(w, _word_text(i), Vector3(side * 0.6, 2.4, 0), 4.6)
		if d.has_flag("s2c5_soz%d" % i) or d.quest_state(Q1) in ["ready", "done"]:
			w.set_meta("done", true)
			continue
		var orb := Node3D.new()
		orb.name = "Orb"
		w.add_child(orb)
		orb.position = Vector3(0, 1.0, 0)
		Toon.part(orb, "sphere", Vector3(0.5, 0.5, 0.5), Color("#ffd9a8"), Vector3.ZERO, Vector3.ZERO, 0.6, 0.03)
		Toon.part(orb, "ring", Vector3(0.9, 0.05, 0.9), "spark-purple", Vector3.ZERO, Vector3(90, 0, 0), 0.4, 0.0)
		var t := TriggerArea.new()
		t.radius = 1.4
		t.once = false
		w.add_child(t)
		t.reached.connect(_collect_word.bind(i))
	# Minnoş's quiet nook: two boulders by the east wall
	for p: Vector3 in [MINNOS_AT + Vector3(1.6, 0, -1.6), MINNOS_AT + Vector3(1.4, 0, 1.8)]:
		ModelImport.cover_block(WorldLook.block(lv, p + Vector3.UP * 0.7, Vector3(1.6, 1.4, 1.4), ROCK_DARK, 0.03), "volkan_kaya", Vector3(1.3, 1.1, 1.3), p.z)
	# the mountain's bell
	var bell := EchoBell.new()
	bell.name = "Bell"
	bell.bell_id = "s2_can5"
	bell.needs = Q1
	bell.locked_bark = "s2c5_kilit"
	lv.add_child(bell)
	bell.position = BELL_AT
	bell.rung.connect(_on_bell_rung)
	if not d.has_flag("s2_can5"):
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
		bm.size = Vector3(27, 3, 0.3)
		wall.mesh = bm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(Tokens.color("hp"), 0.3)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wall.material_override = m
		wall.position.y = 1.5
		_veil.add_child(wall)
	TravelSign.board(lv, "Gümbür Kanyonu ↓", Vector3(-3.0, 1.3, 27.0), 2.6)
	Toon.part(lv, "box", Vector3(0.16, 1.2, 0.16), Color("#a86b45"), Vector3(-3.0, 0.6, 26.95))
	var back := TriggerArea.new()
	back.once = false
	back.radius = 1.5
	lv.add_child(back)
	back.position = Vector3(0, 0, 30.0)
	back.reached.connect(func() -> void: SceneFlow.ask_go("s2_chapter4"))
	for n in 4:
		var w := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var wb := WorldBoundaryShape3D.new()
		var dir: Vector3 = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK][n]
		var dist: float = [13.5, 13.5, 43.0, 31.0][n]
		wb.plane = Plane(-dir, -dist)
		c.shape = wb
		w.add_child(c)
		lv.add_child(w)


## Headless helper: answers an open choice panel with its first option.
func _answer_choices() -> void:
	for n in _hud.find_children("*", "ChoicePanel", true, false):
		(n as ChoicePanel)._pick("0")


func _run_demo(which: String) -> void:
	match which:
		"summit":
			# the whole chapter, scripted (headless check)
			DevTools.auto_dialogue = true
			var d := GameState.data
			_player.global_position = get_node("Gumbur").global_position + Vector3(0, 0.3, 2.0)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("gumbur")
			await close_dialogs()
			for i in WORDS.size():
				_player.global_position = WORDS[i] + Vector3(0, 0.4, 0)
				await get_tree().create_timer(0.4).timeout
				await close_dialogs()
			_player.global_position = MINNOS_AT + Vector3(-2.2, 0.3, 0)
			await get_tree().create_timer(0.6).timeout
			await close_dialogs()
			for tries in 3:
				if _minnos.is_calm:
					break
				await close_dialogs()
				_player.global_position = MINNOS_AT + Vector3(-2.0, 0.3, 0)
				await get_tree().create_timer(0.4).timeout
				Input.action_press("calm")
				await get_tree().create_timer(BreathCalm.BREATH_IN + BreathCalm.BREATH_OUT + 0.5).timeout
				Input.action_release("calm")
			await close_dialogs()
			print("S2C5 words q1=%s sozler=%s minnos=%s" % [d.quest_state(Q1), d.objective_done(Q1, "sozler"), d.objective_done(Q1, "minnos")])
			_player.global_position = get_node("Gumbur").global_position + Vector3(0, 0.3, 2.0)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("gumbur")
			await close_dialogs()
			_player.global_position = BELL_AT + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.4).timeout
			(get_node("Level/Bell") as EchoBell).use(_player)
			await close_dialogs()
			await get_tree().create_timer(1.6).timeout
			_player.global_position = ARENA + Vector3(0, 0.3, 8.0)
			for i in 500:
				await get_tree().create_timer(0.3).timeout
				await close_dialogs()
				if _boss.tired:
					_player.global_position = _boss.global_position + Vector3(0, 0.3, 2.4)
					_player._attack_cd = 0.0
					_player.spin_attack()
				if _faz2:
					break
			print("S2C5 faz1 hp=%d faz2=%s player_hp=%d" % [_boss.hp, _faz2, d.hp])
			for i in 10:
				await close_dialogs()
				await get_tree().create_timer(0.3).timeout
			for i in HirilPlan.ECHOES:
				_player.global_position = _orbs[i].global_position + Vector3(0, 0.3, 0)
				for k in 20:
					await get_tree().create_timer(0.3).timeout
					_answer_choices()
					await close_dialogs()
					if not _busy_echo:
						break
			print("S2C5 faz2 heard=%d q2hiril=%s" % [_heard, d.objective_done(Q2, "hiril")])
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
			print("S2C5 kor=%s q2=%s" % [d.has_flag("kor_al"), d.quest_state(Q2)])
			_player.global_position = get_node("Miril").global_position + Vector3(0, 0.3, 2.0)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("miril")
			for i in 20:
				await close_dialogs()
				await get_tree().create_timer(0.3).timeout
			print("S2C5 no_end q2=%s flag=%s" % [d.quest_state(Q2), d.has_flag("sezon2_bitti")])
			get_tree().quit()
		"faz2":
			# straight to the listening part (screenshots)
			DevTools.auto_dialogue = true
			GameState.data.set_flag("s2_can5")
			_open_veil()
			_player.global_position = ARENA + Vector3(0, 0.3, 8.0)
			_fight = true
			boss_camera(true, ARENA, 0.4, 20.0)
			_boss.active = true
			_boss.tired = true
			_boss.hit(99999, _player.global_position, 0.0)
		"arena":
			GameState.data.set_flag("s2_can5")
			_open_veil()
			_player.global_position = ARENA + Vector3(0, 0.3, 8.0)
		"minnos":
			_player.global_position = MINNOS_AT + Vector3(-4.0, 0.3, 2.0)
		"words":
			_player.global_position = WORDS[2] + Vector3(4.0, 0.3, 3.0)

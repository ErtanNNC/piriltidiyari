extends ChapterBase
## Sezon 2 · Bölüm 2 – Fokurdayan Göl, Mercan Kor (levels 10–15). A frog town
## on the shore of a boiling lake. The frogs all croak at once: hear them in
## turn, oldest first (quest "sira_bekle", the lesson: wait your turn). The
## lake's Ses Çanı clears the mist over the lily pads; hop across to the
## island where Kaynar Kurbağa Fokur boils (boss). Hear his song to the end
## (Sakinleş) and he gives the Mercan Kor. Falling in the hot water stings a
## little and puts you back on the shore (or the island once reached).

const Q1 := "sira_bekle"
const Q2 := "fokur"
const SAND := Color("#e3c79a")
const GRASS := Color("#8fbf63")
const ISLAND := Vector3(0, 0, -30.0)
const ISLAND_R := 9.0
const BELL_AT := Vector3(15.0, 0, 16.0)
const VEIL_Z := 4.5
const PADS := [Vector3(0.0, 0, 2.0), Vector3(1.6, 0, -1.2), Vector3(0.0, 0, -4.4), Vector3(-1.7, 0, -7.6), Vector3(0.0, 0, -10.8),
	Vector3(1.8, 0, -14.0), Vector3(0.2, 0, -17.2), Vector3(-1.4, 0, -20.2)]
const FROGS := {
	"dede_virak": [Vector3(-6.0, 0, 13.0), 25.0, 1.25],
	"vrakvrak": [Vector3(-2.0, 0, 15.0), 0.0, 1.0],
	"vik": [Vector3(2.5, 0, 14.0), -20.0, 0.7],
}

var _boss: Fokur
var _veil: Node3D
var _fight := false


func _ready() -> void:
	WorldLook.add(self, "sabah")
	Pus.set_color(Pus.RED)
	var d := GameState.data
	Pus.set_amount(0.03 if d.has_flag("s2_can2") else 0.15)
	_build()
	Decor.auto(self, "koy")
	var demlik := npc(self, "demlik", "frog", Vector3(7.0, 0, 13.0), -30.0)
	demlik.name = "Demlik"
	Toon.part(demlik, "cylinder", Vector3(0.6, 0.35, 0.6), "spark-green", Vector3(0, 1.62, 0))
	Toon.part(demlik, "cone", Vector3(0.18, 0.4, 0.18), "spark-green", Vector3(0.38, 1.6, 0), Vector3(0, 0, -60))
	for id: String in FROGS:
		var f: Array = FROGS[id]
		var n := npc(self, id, "frog", f[0], f[1])
		n.name = id.capitalize().replace(" ", "")
		n.scale = Vector3.ONE * float(f[2])
	for p: Vector3 in [Vector3(-14, 0, 15), Vector3(13, 0, 24)]:
		Mob.spawn(self, "balon_balik", p)
	for p: Vector3 in [Vector3(-8, 0, 24), Vector3(10, 0, 9)]:
		Mob.spawn(self, "laf_kesen_ordek", p)
	_boss = Fokur.new()
	add_child(_boss)
	_boss.position = ISLAND
	_boss.home = ISLAND
	_boss.hp_changed.connect(func(h: int, m: int) -> void: _hud.set_boss_hp(h, m))
	_boss.phase_changed.connect(_on_phase)
	_boss.sad.connect(_on_sad)
	_boss.calmed.connect(_on_calmed)
	if d.objective_done(Q2, "fokur"):
		_boss._cross.visible = false
		_boss._soft.visible = true
		if not d.objective_done(Q2, "kor"):
			_drop_kor()
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.8).timeout
	if not d.has_flag("s2c2_geldi"):
		d.set_flag("s2c2_geldi")
		GameState.bark("s2c2_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _process(_delta: float) -> void:
	var d := GameState.data
	if not _fight and d.objective_done(Q2, "can") and not d.objective_done(Q2, "fokur") \
			and _player.global_position.distance_to(ISLAND) < 8.0 and not GameState.in_dialogue:
		_start_fight()


func _frog_node(id: String) -> Node3D:
	return get_node_or_null(id.capitalize().replace(" ", "")) as Node3D


func _refresh() -> void:
	var d := GameState.data
	# the frog whose turn it is gets the star
	var order := ["dede_virak", "vrakvrak", "vik"]
	var objs := ["dede", "orta", "kucuk"]
	var next := ""
	if d.quest_state(Q1) == "active":
		for i in 3:
			if not d.objective_done(Q1, objs[i]):
				next = order[i]
				break
	for id: String in order:
		var n := _frog_node(id)
		if n:
			var on := id == next
			if on and not n.has_node("Beacon"):
				Beacon.attach(n, 2.6, Tokens.color("spark-white"))
			elif not on and n.has_node("Beacon"):
				n.get_node("Beacon").queue_free()
	var dem := get_node("Demlik") as Node3D
	var go := d.quest_state(Q1) in ["none", "ready"] or d.quest_state(Q2) == "ready"
	if go and not dem.has_node("Beacon"):
		Beacon.attach(dem, 2.8, Tokens.color("spark-white"))
	elif not go and dem.has_node("Beacon"):
		dem.get_node("Beacon").queue_free()
	var bell := get_node_or_null("Level/Bell") as Node3D
	if bell and d.quest_state(Q2) == "active" and not d.has_flag("s2_can2") and not bell.has_node("Beacon"):
		Beacon.attach(bell, 4.4, Tokens.color("spark-yellow"))
		_hud.show_hint("Gölün Ses Çanı'nı çal", "Gölün çanını çal")
	if d.has_flag("s2_can2") and _veil:
		_open_veil()


func _start_fight() -> void:
	_fight = true
	boss_camera(true, ISLAND, 0.4, 19.0)
	GameState.bark("s2c2_fokur")
	await GameState.dialogue_closed
	_hud.show_boss("Kaynar Kurbağa Fokur", _boss.hp, FokurPlan.MAX_HP)
	_hud.show_hint("Kabarcıklardan kaç, vıraklayınca uzaklaş. Zıplayınca vur!", "Kaç, zıpladıktan sonra vur!")
	_boss.start()


func _on_phase(_p: int) -> void:
	for id: String in ["bal_surubu", "nane_sekeri"]:
		var pk := Pickup.new()
		pk.item_id = id
		add_child(pk)
		pk.global_position = ISLAND + Vector3(randf_range(-5, 5), 0, randf_range(2, 5))


func _on_sad() -> void:
	_hud.hide_boss()
	GameState.bark("s2c2_fokur_yorgun")
	await GameState.dialogue_closed
	_hud.show_hint("Yanına git, Sakinleş'e basılı tut. Şarkısını dinle.", "Yanına git, Sakinleş'e basılı tut!")


func _on_calmed() -> void:
	_hud.clear_hint()
	boss_camera(false)
	_boss.sing()
	GameState.bark("s2c2_fokur_son")
	await GameState.dialogue_closed
	_drop_kor()


## The Mercan Kor: a coral-pink ember hovering by Fokur.
func _drop_kor() -> void:
	var kor := Node3D.new()
	kor.name = "Kor"
	add_child(kor)
	kor.position = ISLAND + Vector3(0, 1.2, 3.0)
	var col := Color("#ff7f8f")
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
	t.area_id = "mercan_kor"
	t.radius = 1.4
	add_child(t)
	t.position = ISLAND + Vector3(0, 0, 3.0)
	t.reached.connect(func() -> void:
		GameState.data.set_flag("kor_mercan")
		Effects.ring(self, kor.global_position, 3.0, col, 0.5)
		Effects.sparkle(self, kor.global_position, col, 20)
		Audio.play("fanfare")
		kor.queue_free()
		_hud.show_scene_card("Kor", "Mercan Kor", "Fokurdayan Göl serinledi")
		GameState.bark("s2c2_kor"))


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
	GameState.bark("s2c2_can")
	_open_veil()


## Hot water: a little sting and back to the last dry place.
func _on_water(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	var p := body as Player
	p.global_position = p.respawn_point + Vector3.UP * 0.5
	p.velocity = Vector3.ZERO
	# pushed gently toward the lake side, never back out of the region
	p.hurt(4, p.global_position + Vector3.BACK)
	if not GameState.data.has_flag("s2c2_su"):
		GameState.data.set_flag("s2c2_su")
		GameState.bark("s2c2_su")


# --- level ---------------------------------------------------------------

func _build() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	# the shore (south) and a strip round the lake
	WorldLook.block(lv, Vector3(0, -0.5, 19.0), Vector3(64, 1, 24), GRASS, 0.0)
	Toon.part(lv, "box", Vector3(64, 0.06, 4.0), SAND, Vector3(0, 0.0, 8.8), Vector3.ZERO, 0.0, 0.0)
	for side: float in [-1.0, 1.0]:
		WorldLook.block(lv, Vector3(29.0 * side, -0.5, -18.0), Vector3(6, 1, 52), GRASS, 0.0)
	WorldLook.block(lv, Vector3(0, -0.5, -46.0), Vector3(64, 1, 6), GRASS, 0.0)
	# the lake: a floor deep below, the boiling surface, the hot-water area
	WorldLook.block(lv, Vector3(0, -2.0, -18.0), Vector3(52, 1, 52), Color("#6a8a9a"), 0.0)
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(52, 52)
	water.mesh = plane
	water.position = Vector3(0, -0.35, -18.0)
	lv.add_child(water)
	WorldLook.water(water, "lake")
	var hot := Area3D.new()
	hot.collision_layer = 0
	hot.collision_mask = 1 | 2
	var hc := CollisionShape3D.new()
	var hb := BoxShape3D.new()
	hb.size = Vector3(52, 1.2, 52)
	hc.shape = hb
	hot.add_child(hc)
	hot.position = Vector3(0, -1.0, -18.0)
	lv.add_child(hot)
	hot.body_entered.connect(_on_water)
	for i in 14:
		var steam := Node3D.new()
		steam.position = Vector3(randf_range(-22, 22), -0.3, randf_range(-40, 4))
		lv.add_child(steam)
		MobModels._pus_wisps(steam, 0.2, Color(1, 1, 1), 3, 0.4)
	# lily pads to hop across
	for p: Vector3 in PADS:
		var pad := WorldLook.block(lv, p + Vector3.DOWN * 0.15, Vector3(2.2, 0.3, 2.2), Color("#5fa84a"), 0.03)
		Toon.part(pad, "cylinder", Vector3(0.3, 0.32, 0.3), Color("#ff9ac0"), Vector3(0.6, 0.05, 0.4), Vector3.ZERO, 0.6, 0.0)
	# the island
	var island := StaticBody3D.new()
	var ic := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = ISLAND_R
	cyl.height = 1.0
	ic.shape = cyl
	island.add_child(ic)
	island.position = ISLAND + Vector3.DOWN * 0.5
	lv.add_child(island)
	Toon.part(lv, "cylinder", Vector3(ISLAND_R * 2, 1.0, ISLAND_R * 2), GRASS, ISLAND + Vector3.DOWN * 0.5, Vector3.ZERO, 0.0, 0.03)
	Toon.part(lv, "cylinder", Vector3(ISLAND_R * 1.4, 0.06, ISLAND_R * 1.4), SAND, ISLAND + Vector3.UP * 0.02, Vector3.ZERO, 0.0, 0.0)
	var isle := TriggerArea.new()
	isle.radius = 3.0
	isle.checkpoint = true
	lv.add_child(isle)
	isle.position = ISLAND + Vector3(0, 0, ISLAND_R - 2.0)
	# frog town huts on the shore
	var accents := ["spark-green", "sky", "leaf", "spark-yellow"]
	var spots := [Vector3(-16, 0, 20), Vector3(-9, 0, 25), Vector3(9, 0, 26), Vector3(17, 0, 21)]
	for i in spots.size():
		var h := Prop.new()
		h.kind = "house"
		h.accent = accents[i]
		lv.add_child(h)
		h.position = spots[i]
		h.rotation.y = atan2(-spots[i].x, -spots[i].z + 10.0)
	# the lake's bell
	var bell := EchoBell.new()
	bell.name = "Bell"
	bell.bell_id = "s2_can2"
	bell.needs = Q1
	bell.locked_bark = "s2c2_kilit"
	lv.add_child(bell)
	bell.position = BELL_AT
	bell.rung.connect(_on_bell_rung)
	if not GameState.data.has_flag("s2_can2"):
		_veil = Node3D.new()
		_veil.name = "Veil"
		lv.add_child(_veil)
		_veil.position = Vector3(0, 0, VEIL_Z)
		var body := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(10, 6, 1.0)
		c.shape = b
		c.position.y = 3.0
		body.add_child(c)
		_veil.add_child(body)
		var veil_mist := Node3D.new()
		veil_mist.position.y = 0.5
		_veil.add_child(veil_mist)
		for i in 7:
			var puff := Node3D.new()
			puff.position = Vector3(-4.5 + i * 1.5, 0, 0)
			veil_mist.add_child(puff)
			MobModels._pus_wisps(puff, 0.5, Tokens.color("hp"), 5, 0.3)
		var wall := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(10, 3, 0.3)
		wall.mesh = bm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(Tokens.color("hp"), 0.3)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wall.material_override = m
		wall.position.y = 1.5
		_veil.add_child(wall)
	TravelSign.board(lv, "Kızıl Yaprak Ormanı ↓", Vector3(-3.0, 1.3, 29.5), 2.8)
	Toon.part(lv, "box", Vector3(0.16, 1.2, 0.16), Color("#a86b45"), Vector3(-3.0, 0.6, 29.45))
	var back := TriggerArea.new()
	back.radius = 1.5
	lv.add_child(back)
	back.position = Vector3(0, 0, 31.0)
	back.reached.connect(func() -> void: SceneFlow.go_to("s2_chapter1"))
	for n in 4:
		var wall := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var wb := WorldBoundaryShape3D.new()
		var dir: Vector3 = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK][n]
		var dist: float = [31.0, 31.0, 48.0, 31.0][n]
		wb.plane = Plane(-dir, -dist)
		c.shape = wb
		wall.add_child(c)
		lv.add_child(wall)


func _run_demo(which: String) -> void:
	match which:
		"lake":
			# the whole chapter, scripted (headless check)
			DevTools.auto_dialogue = true
			var d := GameState.data
			# wrong order first: the little one waits
			for id: String in ["demlik", "vik", "dede_virak", "vrakvrak", "vik", "demlik"]:
				_player.global_position = (get_node("Demlik") if id == "demlik" else _frog_node(id)).global_position + Vector3(0, 0.3, 1.8)
				await get_tree().create_timer(0.3).timeout
				GameState.talk_to(id)
				await close_dialogs()
				if id == "vik" and d.objective_count(Q1, "kucuk").x == 0:
					print("S2C2 vik waits=%s" % (not d.objective_done(Q1, "kucuk")))
			print("S2C2 q1=%s q2=%s tea=%d" % [d.quest_state(Q1), d.quest_state(Q2), d.item_count("papatya_cayi")])
			_player.global_position = BELL_AT + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.4).timeout
			(get_node("Level/Bell") as EchoBell).use(_player)
			await close_dialogs()
			await get_tree().create_timer(1.6).timeout
			# hop the lily pads
			_player.global_position = Vector3(0, 0.3, 6.5)
			_player.respawn_point = _player.global_position
			await get_tree().create_timer(0.4).timeout
			for p: Vector3 in PADS:
				await _hop_to(p, 1.6)
			await _hop_to(ISLAND + Vector3(0, 0, ISLAND_R - 1.0), 1.6)
			print("S2C2 crossed pos=%s" % _player.global_position)
			for i in 400:
				await get_tree().create_timer(0.3).timeout
				await close_dialogs()
				if _boss.tired:
					_player.global_position = _boss.global_position + Vector3(0, 0.3, 2.2)
					_player._attack_cd = 0.0
					_player.spin_attack()
				if _boss.is_sad or d.objective_done(Q2, "fokur"):
					break
			print("S2C2 boss hp=%d sad=%s player_hp=%d" % [_boss.hp, _boss.is_sad, d.hp])
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
			_player.global_position = ISLAND + Vector3(3, 0.3, 6.0)
			await get_tree().create_timer(0.3).timeout
			_player.global_position = ISLAND + Vector3(0, 0.3, 3.0)
			await get_tree().create_timer(0.8).timeout
			await close_dialogs()
			_player.global_position = get_node("Demlik").global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("demlik")
			await close_dialogs()
			print("S2C2_DONE q2=%s kor=%s flag=%s level=%d" % [d.quest_state(Q2), d.has_flag("kor_mercan"), d.has_flag("s2_bolum2_bitti"), d.level])
			get_tree().quit()
		"water":
			_player.global_position = Vector3(6, 0.3, 2.0)
			await get_tree().create_timer(1.5).timeout
			print("S2C2 water back=%s pos=%s" % [_player.global_position.z > 5.0, _player.global_position])
			get_tree().quit()
		"pads":
			GameState.data.set_flag("s2_can2")
			_player.global_position = Vector3(0, 0.3, 6.5)


## Test helper: walk toward `target`, jumping once on the way (pad hops).
func _hop_to(target: Vector3, seconds: float) -> void:
	var t := 0.0
	var jumped := false
	while t < seconds:
		var aim := target - _player.global_position
		aim.y = 0.0
		if aim.length() < 0.4 and _player.is_on_floor():
			break
		var dir := aim.normalized()
		for a in ["move_left", "move_right", "move_forward", "move_back"]:
			Input.action_release(a)
		if dir.x > 0.2: Input.action_press("move_right", dir.x)
		if dir.x < -0.2: Input.action_press("move_left", -dir.x)
		if dir.z > 0.2: Input.action_press("move_back", dir.z)
		if dir.z < -0.2: Input.action_press("move_forward", -dir.z)
		if not jumped and _player.is_on_floor():
			jumped = true
			Input.action_press("jump")
		elif jumped:
			Input.action_release("jump")
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	for a in ["move_left", "move_right", "move_forward", "move_back", "jump"]:
		Input.action_release(a)

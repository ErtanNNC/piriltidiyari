extends ChapterBase
## Sezon 2 · Bölüm 1 – Kızıl Yaprak Ormanı, Turuncu Kor (levels 5–10). An
## autumn forest where everyone grabs everyone's things. Kapıcı Rakunlar
## carry the cubs' toys: calm them, give each toy back (quest "once_sor",
## the lesson: ask first). Then the forest's Ses Çanı opens the Sis Perdesi
## in front of the glade where Tilki Fırfır sulks (boss, Sakinleş at the
## end). He gives the Turuncu Kor.

const Q1 := "once_sor"
const Q2 := "firfir"
const GRASS := Color("#9cb85a")
const PATH := Color("#d8a86a")
const LEAVES := [Color("#e8833a"), Color("#d9542f"), Color("#f2b33d"), Color("#c9452f"), Color("#e86a3a")]
const BELL_AT := Vector3(-9.0, 0, -12.0)
const VEIL_Z := -20.0
const GLADE := Vector3(0, 0, -34.0)
const CUBS := {
	"pofu": ["bunny", Vector3(-5.0, 0, 15.0), 20.0],
	"paytak": ["duckling", Vector3(5.5, 0, 14.0), -20.0],
	"minik": ["mole_kid", Vector3(-1.0, 0, 18.5), 0.0],
}
## Raccoons and the toy each one carries.
const RACCOONS := [[Vector3(-12, 0, 4), "oyuncak_top"], [Vector3(12, 0, 0), "oyuncak_ucurtma"], [Vector3(3, 0, -8), "oyuncak_bebek"]]

var _boss: Firfir
var _veil: Node3D
var _fight := false


func _ready() -> void:
	WorldLook.add(self, "sabah")
	Pus.set_color(Pus.RED)
	var d := GameState.data
	Pus.set_amount(0.03 if d.has_flag("s2_can1") else 0.15)
	_build()
	Decor.auto(self, "orman")
	npc(self, "kozalak", "squirrel_tailor", Vector3(2.0, 0, 18.0), -10.0).name = "Kozalak"
	for id: String in CUBS:
		var c: Array = CUBS[id]
		npc(self, id, c[0], c[1], c[2]).name = id.capitalize()
	for r: Array in RACCOONS:
		if not _toy_done(String(r[1])):
			var m := Mob.spawn(self, "kapici_rakun", r[0])
			m.set_meta("carry", r[1])
			Beacon.attach(m, 2.4, Tokens.color("berry"))
	for p: Vector3 in [Vector3(-14, 0, -6), Vector3(14, 0, -10), Vector3(8, 0, 6)]:
		Mob.spawn(self, "somurtkan_sincap", p)
	_boss = Firfir.new()
	add_child(_boss)
	_boss.position = GLADE
	_boss.home = GLADE
	_boss.hp_changed.connect(func(h: int, m: int) -> void: _hud.set_boss_hp(h, m))
	_boss.phase_changed.connect(_on_phase)
	_boss.sad.connect(_on_sad)
	_boss.calmed.connect(_on_calmed)
	if d.objective_done(Q2, "firfir"):
		_boss._cross.visible = false
		_boss._soft.visible = true
		if not d.objective_done(Q2, "kor"):
			_drop_kor()
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.8).timeout
	if not d.has_flag("s2c1_geldi"):
		d.set_flag("s2c1_geldi")
		GameState.bark("s2c1_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _toy_done(item: String) -> bool:
	var d := GameState.data
	var obj: String = {"oyuncak_top": "top", "oyuncak_ucurtma": "ucurtma", "oyuncak_bebek": "bebek"}[item]
	return d.has_item(item) or d.objective_done(Q1, obj) or d.quest_state(Q1) == "done"


func _process(_delta: float) -> void:
	var d := GameState.data
	if not _fight and d.objective_done(Q2, "can") and not d.objective_done(Q2, "firfir") \
			and _player.global_position.distance_to(GLADE) < 10.0 and not GameState.in_dialogue:
		_start_fight()


func _refresh() -> void:
	var d := GameState.data
	for id: String in CUBS:
		var n := get_node_or_null(id.capitalize()) as Node3D
		if n:
			var item: String = {"pofu": "oyuncak_top", "paytak": "oyuncak_ucurtma", "minik": "oyuncak_bebek"}[id]
			var on := d.quest_state(Q1) == "active" and d.has_item(item)
			if on and not n.has_node("Beacon"):
				Beacon.attach(n, 2.4, Tokens.color("spark-white"))
			elif not on and n.has_node("Beacon"):
				n.get_node("Beacon").queue_free()
	var koz := get_node("Kozalak") as Node3D
	var go := d.quest_state(Q1) in ["none", "ready"] or d.quest_state(Q2) == "ready"
	if go and not koz.has_node("Beacon"):
		Beacon.attach(koz, 2.6, Tokens.color("spark-white"))
	elif not go and koz.has_node("Beacon"):
		koz.get_node("Beacon").queue_free()
	var bell := get_node_or_null("Level/Bell") as Node3D
	if bell and d.quest_state(Q2) == "active" and not d.has_flag("s2_can1") and not bell.has_node("Beacon"):
		Beacon.attach(bell, 4.4, Tokens.color("spark-yellow"))
		_hud.show_hint("Ormanın Ses Çanı'nı çal", "Ormanın çanını çal")
	if d.has_flag("s2_can1") and _veil:
		_open_veil()


func _start_fight() -> void:
	_fight = true
	boss_camera(true, GLADE, 0.4, 19.0)
	GameState.bark("s2c1_firfir")
	await GameState.dialogue_closed
	_hud.show_boss("Tilki Fırfır", _boss.hp, FirfirPlan.MAX_HP)
	_hud.show_hint("Yaprak halkalarından ve atılmasından kaç. Oturunca vur!", "Halkalardan kaç, oturunca vur!")
	_boss.start()


func _on_phase(_p: int) -> void:
	for id: String in ["bal_surubu", "nane_sekeri"]:
		var pk := Pickup.new()
		pk.item_id = id
		add_child(pk)
		pk.global_position = GLADE + Vector3(randf_range(-5, 5), 0, randf_range(3, 6))


func _on_sad() -> void:
	_hud.hide_boss()
	GameState.bark("s2c1_firfir_yorgun")
	await GameState.dialogue_closed
	_hud.show_hint("Yanına git, Sakinleş'e basılı tut. Onu dinle.", "Yanına git, Sakinleş'e basılı tut!")


func _on_calmed() -> void:
	_hud.clear_hint()
	boss_camera(false)
	GameState.bark("s2c1_firfir_son")
	await GameState.dialogue_closed
	_drop_kor()


## The Turuncu Kor: a warm orange ember hovering by Fırfır.
func _drop_kor() -> void:
	var kor := Node3D.new()
	kor.name = "Kor"
	add_child(kor)
	kor.position = GLADE + Vector3(0, 1.2, 2.5)
	var orb := Toon.part(kor, "sphere", Vector3(0.7, 0.85, 0.7), Color("#ff8a3a"), Vector3.ZERO, Vector3.ZERO, 2.4, 0.03)
	orb.name = "Orb"
	var l := OmniLight3D.new()
	l.light_color = Color("#ff8a3a")
	l.omni_range = 5.0
	l.light_energy = 2.0
	kor.add_child(l)
	Beacon.attach(kor, 1.4, Color("#ff8a3a"))
	var tw := kor.create_tween().set_loops()
	tw.tween_property(kor, "position:y", 1.5, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(kor, "position:y", 1.2, 0.8).set_trans(Tween.TRANS_SINE)
	var t := TriggerArea.new()
	t.area_id = "turuncu_kor"
	t.radius = 1.4
	add_child(t)
	t.position = GLADE + Vector3(0, 0, 2.5)
	t.reached.connect(func() -> void:
		GameState.data.set_flag("kor_turuncu")
		Effects.ring(self, kor.global_position, 3.0, Color("#ff8a3a"), 0.5)
		Effects.sparkle(self, kor.global_position, Color("#ff8a3a"), 20)
		Audio.play("fanfare")
		kor.queue_free()
		_hud.show_scene_card("Kor", "Turuncu Kor", "Kızıl Yaprak Ormanı ısındı")
		GameState.bark("s2c1_kor"))


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
	GameState.bark("s2c1_can")
	_open_veil()


# --- level ---------------------------------------------------------------

func _build() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	WorldLook.block(lv, Vector3(0, -0.5, -8), Vector3(70, 1, 80), GRASS, 0.0)
	Toon.part(lv, "box", Vector3(3, 0.06, 56), PATH, Vector3(0, 0.0, -6), Vector3.ZERO, 0.0, 0.0)
	Toon.part(lv, "cylinder", Vector3(18, 0.06, 18), PATH, Vector3(0, 0.02, GLADE.z), Vector3.ZERO, 0.0, 0.0)
	# autumn trees everywhere but on the path, the clearing and the glade
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in 90:
		var p := Vector3(rng.randf_range(-24, 24), 0, rng.randf_range(-46, 24))
		if absf(p.x) < 6.5 or p.distance_to(GLADE) < 12.0 or (absf(p.x) < 10 and p.z > 10) or p.distance_to(BELL_AT) < 4.0:
			continue
		var tree := Node3D.new()
		lv.add_child(tree)
		tree.position = p
		var h := rng.randf_range(2.5, 4.0)
		Toon.part(tree, "cylinder", Vector3(0.45, h, 0.45), Color("#7a4a32"), Vector3(0, h * 0.5, 0))
		Toon.part(tree, "sphere", Vector3(2.8, 2.4, 2.8) * rng.randf_range(0.9, 1.3), LEAVES[rng.randi() % LEAVES.size()], Vector3(0, h + 0.8, 0))
		var body := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = 0.4
		cs.height = h
		c.shape = cs
		c.position.y = h * 0.5
		body.add_child(c)
		body.set_meta("camera_ignore", true)
		tree.add_child(body)
	# fallen leaves on the ground
	for i in 60:
		var p := Vector3(rng.randf_range(-22, 22), 0.03, rng.randf_range(-44, 22))
		Toon.part(lv, "cylinder", Vector3(0.5, 0.02, 0.35), LEAVES[i % LEAVES.size()], p, Vector3(0, rng.randf() * 180.0, 0), 0.0, 0.0)
	# the forest's bell in a little clearing
	var bell := EchoBell.new()
	bell.name = "Bell"
	bell.bell_id = "s2_can1"
	bell.needs = Q1
	bell.locked_bark = "s2c1_kilit"
	bell.ring_target = "ses_cani"
	lv.add_child(bell)
	bell.position = BELL_AT
	bell.rung.connect(_on_bell_rung)
	# the Sis Perdesi: a red wall of mist across the path to the glade
	if not GameState.data.has_flag("s2_can1"):
		_veil = Node3D.new()
		_veil.name = "Veil"
		lv.add_child(_veil)
		_veil.position = Vector3(0, 0, VEIL_Z)
		var body := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(50, 6, 1.2)
		c.shape = b
		c.position.y = 3.0
		body.add_child(c)
		_veil.add_child(body)
		var p := CPUParticles3D.new()
		p.amount = 60
		p.lifetime = 4.0
		p.preprocess = 4.0
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(22, 1.5, 0.6)
		p.direction = Vector3.UP
		p.spread = 30.0
		p.gravity = Vector3.ZERO
		p.initial_velocity_min = 0.1
		p.initial_velocity_max = 0.3
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
		var col := Tokens.color("hp")
		g.colors = PackedColorArray([Color(col, 0.0), Color(col, 0.5), Color(col, 0.5), Color(col, 0.0)])
		p.color_ramp = g
		var q := QuadMesh.new()
		q.size = Vector2(3.0, 3.0)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.vertex_color_use_as_albedo = true
		m.albedo_texture = Weather.texture("soft")
		q.material = m
		p.mesh = q
		p.position.y = 1.5
		_veil.add_child(p)
		var t := TriggerArea.new()
		t.radius = 3.0
		t.once = false
		lv.add_child(t)
		t.position = Vector3(0, 0, VEIL_Z + 2.5)
		t.reached.connect(func() -> void:
			if _veil and not GameState.in_dialogue:
				GameState.bark("s2c1_perde"))
	TravelSign.board(lv, "Buharlı Kaplıca Köyü ↓", Vector3(2.4, 1.3, 22.0), 2.8)
	Toon.part(lv, "box", Vector3(0.16, 1.2, 0.16), Color("#a86b45"), Vector3(2.4, 0.6, 21.95))
	var home := TriggerArea.new()
	home.radius = 2.0
	lv.add_child(home)
	home.position = Vector3(0, 0, 25.0)
	home.reached.connect(func() -> void: SceneFlow.go_to("s2_chapter0"))
	for n in 4:
		var wall := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var wb := WorldBoundaryShape3D.new()
		var dir: Vector3 = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK][n]
		var dist: float = [25.0, 25.0, 48.0, 26.0][n]
		wb.plane = Plane(-dir, -dist)
		c.shape = wb
		wall.add_child(c)
		lv.add_child(wall)


func _run_demo(which: String) -> void:
	match which:
		"forest":
			# the whole chapter, scripted (headless check)
			DevTools.auto_dialogue = true
			var d := GameState.data
			_player.global_position = get_node("Kozalak").global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("kozalak")
			await close_dialogs()
			# calm each toy raccoon (breath), pick the toy up
			for i in 40:
				var targets := get_tree().get_nodes_in_group("mob").filter(func(m: Node) -> bool: return m.has_meta("carry"))
				var dazed := get_tree().get_nodes_in_group("dazed")
				if targets.is_empty() and dazed.is_empty():
					break
				if not dazed.is_empty():
					_player.global_position = (dazed[0] as Node3D).global_position + Vector3(0, 0.3, 1.3)
					Input.action_press("calm")
					await get_tree().create_timer(BreathCalm.BREATH_IN + BreathCalm.BREATH_OUT + 0.4).timeout
					Input.action_release("calm")
				else:
					(targets[0] as Mob).hit(9999, _player.global_position, 0.5)
				await get_tree().create_timer(0.3).timeout
			for p in get_children():
				if p is Pickup and (p as Pickup).item_id.begins_with("oyuncak"):
					_player.global_position = (p as Node3D).global_position + Vector3.UP * 0.3
					await get_tree().create_timer(0.5).timeout
			await get_tree().create_timer(0.5).timeout
			print("S2C1 toys=%s" % [[d.has_item("oyuncak_top"), d.has_item("oyuncak_ucurtma"), d.has_item("oyuncak_bebek")]])
			for id: String in ["pofu", "paytak", "minik", "kozalak"]:
				_player.global_position = get_node(id.capitalize()).global_position + Vector3(0, 0.3, 1.8)
				await get_tree().create_timer(0.3).timeout
				GameState.talk_to(id)
				await close_dialogs()
			print("S2C1 q1=%s q2=%s" % [d.quest_state(Q1), d.quest_state(Q2)])
			_player.global_position = BELL_AT + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.4).timeout
			(get_node("Level/Bell") as EchoBell).use(_player)
			await close_dialogs()
			await get_tree().create_timer(1.6).timeout
			print("S2C1 bell=%s veil=%s" % [d.has_flag("s2_can1"), is_instance_valid(get_node_or_null("Level/Veil"))])
			_player.global_position = GLADE + Vector3(0, 0.3, 8.0)
			for i in 400:
				await get_tree().create_timer(0.3).timeout
				await close_dialogs()
				if _boss.tired:
					_player.global_position = _boss.global_position + Vector3(0, 0.3, 2.0)
					_player._attack_cd = 0.0
					_player.spin_attack()
				if _boss.is_sad or d.objective_done(Q2, "firfir"):
					break
			print("S2C1 boss hp=%d sad=%s player_hp=%d" % [_boss.hp, _boss.is_sad, d.hp])
			await get_tree().create_timer(0.6).timeout
			await close_dialogs()
			_player.global_position = _boss.global_position + Vector3(0, 0.3, 2.4)
			await get_tree().create_timer(0.3).timeout
			Input.action_press("calm")
			await get_tree().create_timer(BreathCalm.BREATH_IN + BreathCalm.BREATH_OUT + 0.5).timeout
			Input.action_release("calm")
			print("S2C1 breathed sad=%s obj=%s" % [_boss.is_sad, d.objective_done(Q2, "firfir")])
			for i in 10:
				await close_dialogs()
				await get_tree().create_timer(0.3).timeout
				if has_node("Kor"):
					break
			_player.global_position = GLADE + Vector3(3, 0.3, 6.0)
			await get_tree().create_timer(0.3).timeout
			_player.global_position = GLADE + Vector3(0, 0.3, 2.5)
			await get_tree().create_timer(0.8).timeout
			await close_dialogs()
			_player.global_position = get_node("Kozalak").global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("kozalak")
			await close_dialogs()
			print("S2C1_DONE q2=%s kor=%s flag=%s level=%d" % [d.quest_state(Q2), d.has_flag("kor_turuncu"), d.has_flag("s2_bolum1_bitti"), d.level])
			get_tree().quit()
		"veil":
			_player.global_position = Vector3(0, 0.3, VEIL_Z + 4.0)
			await get_tree().create_timer(0.4).timeout
			Input.action_press("move_forward")
			await get_tree().create_timer(2.0).timeout
			Input.action_release("move_forward")
			print("S2C1 veil z=%.2f (blocked if > %.1f)" % [_player.global_position.z, VEIL_Z])
			get_tree().quit()
		"boss":
			GameState.data.set_flag("s2_can1")
			_player.global_position = GLADE + Vector3(0, 0.3, 9.0)

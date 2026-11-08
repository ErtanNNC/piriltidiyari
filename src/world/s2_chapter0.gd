extends ChapterBase
## Sezon 2 · Bölüm 0 – Buharlı Kaplıca Köyü (levels 1–5, the hub). A village
## round hot springs at the foot of the mountain path. The Kızıl Sis has made
## everyone talk at once: four neighbours each want to be heard (talk to
## them, they calm down). Bulut Nine sends the keeper to the village's big
## kettle (Homurdanan Çaydanlık, mini boss, Sakinleş at the end), then the
## first Ses Çanı on the hill lifts the red mist. Bulut Nine runs a little
## shop afterwards.

const Q1 := "kopuk_koy"
const Q2 := "homurdanan_caydanlik"
const GRASS := Color("#79b257")
const PATH := Color("#d9b98a")
const STONE := Color("#c9b9a6")
const RADIUS := 27.0
const KETTLE_AT := Vector3(0, 0, -11.0)
const BELL_AT := Vector3(15.0, 1.5, -17.0)
const VILLAGERS := {
	"pitpit": ["duckling", Vector3(-7, 0, 9), 30.0],
	"pamuk": ["bunny", Vector3(7.5, 0, 10), -30.0],
	"toprak": ["mole", Vector3(-9.5, 0, -5), 50.0],
	"bidik": ["frog", Vector3(9.5, 0, -4), -50.0],
}
const SHOUTS := ["Benim sıram!", "Dinle beni!", "Hayır, ben!", "Bir dakika!", "Hıh!", "Ama ben..."]

var _kettle: Kettle
var _bubbles := {}   # npc id -> Label3D
var _fight := false


func _ready() -> void:
	WorldLook.add(self, "sabah")
	Pus.set_color(Pus.RED)
	var d := GameState.data
	Pus.set_amount(0.03 if d.has_flag("s2_can0") else 0.18)
	_build()
	Decor.auto(self, "koy")
	npc(self, "bulut", "hippo", Vector3(-3.6, 0, 0.6), 30.0).name = "Bulut"
	npc(self, "kalay", "smith_turtle", Vector3(12.0, 0, 2.5), -60.0).name = "Kalay"
	for id: String in VILLAGERS:
		var v: Array = VILLAGERS[id]
		var n := npc(self, id, v[0], v[1], v[2])
		n.name = id.capitalize()
		_bubbles[id] = _bubble(n)
	_kettle = Kettle.new()
	add_child(_kettle)
	_kettle.position = KETTLE_AT
	_kettle.hp_changed.connect(func(h: int, m: int) -> void: _hud.set_boss_hp(h, m))
	_kettle.phase_changed.connect(func(_p: int) -> void: _drop_pickups())
	_kettle.simmering.connect(_on_simmering)
	_kettle.calmed.connect(_on_kettle_calmed)
	if d.objective_done(Q2, "caydanlik"):
		_kettle._face_cross.visible = false
		_kettle._face_calm.visible = true
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.8).timeout
	if not d.has_flag("s2c0_geldi"):
		d.set_flag("s2c0_geldi")
		GameState.bark("s2c0_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _process(_delta: float) -> void:
	var d := GameState.data
	# the kettle fight starts when the keeper walks up to it during the quest
	if not _fight and d.quest_state(Q2) == "active" and not d.objective_done(Q2, "caydanlik") \
			and _player.global_position.distance_to(KETTLE_AT) < 8.5 and not GameState.in_dialogue:
		_start_fight()
	# the neighbours who haven't been heard keep talking over each other
	var k := int(Time.get_ticks_msec() / 1100)
	for id: String in _bubbles:
		var l: Label3D = _bubbles[id]
		var heard := d.objective_done(Q1, id) or d.quest_state(Q1) == "done"
		l.visible = not heard
		if not heard:
			l.text = TranslationServer.translate(SHOUTS[(k + id.length()) % SHOUTS.size()])


func _refresh() -> void:
	var d := GameState.data
	for id: String in VILLAGERS:
		var n := get_node_or_null(id.capitalize()) as Node3D
		if n:
			var on := d.quest_state(Q1) == "active" and not d.objective_done(Q1, id)
			if on and not n.has_node("Beacon"):
				Beacon.attach(n, 2.6, Tokens.color("spark-white"))
			elif not on and n.has_node("Beacon"):
				n.get_node("Beacon").queue_free()
	var bulut := get_node("Bulut") as Node3D
	var go_bulut := d.quest_state(Q1) in ["none", "ready"] or d.quest_state(Q2) == "ready"
	if go_bulut and not bulut.has_node("Beacon"):
		Beacon.attach(bulut, 3.2, Tokens.color("spark-white"))
	elif not go_bulut and bulut.has_node("Beacon"):
		bulut.get_node("Beacon").queue_free()
	if d.quest_state(Q2) == "active" and not d.objective_done(Q2, "caydanlik"):
		_hud.show_hint("Meydandaki büyük kazana git", "Büyük kazana git")
	elif d.quest_state(Q2) == "active" and d.objective_done(Q2, "caydanlik") and not d.has_flag("s2_can0"):
		_hud.show_hint("Tepedeki Ses Çanı'nı çal", "Tepedeki çanı çal")
		var bell := get_node_or_null("Level/Bell") as Node3D
		if bell and not bell.has_node("Beacon"):
			Beacon.attach(bell, 4.4, Tokens.color("spark-yellow"))


func _start_fight() -> void:
	_fight = true
	boss_camera(true, KETTLE_AT, 0.4, 18.0)
	GameState.bark("s2c0_kazan")
	await GameState.dialogue_closed
	_hud.show_boss("Homurdanan Çaydanlık", _kettle.hp, KettlePlan.MAX_HP)
	_hud.show_hint("Buhar çizgilerinden kaç. Kapak kalkınca vur!", "Buhardan kaç, kapak kalkınca vur!")
	_kettle.start()


func _drop_pickups() -> void:
	for id: String in ["bal_surubu", "nane_sekeri"]:
		var pk := Pickup.new()
		pk.item_id = id
		add_child(pk)
		pk.global_position = KETTLE_AT + Vector3(randf_range(-5, 5), 0, randf_range(4, 7))


func _on_simmering() -> void:
	_hud.hide_boss()
	_hud.show_hint("Kazan soğuyor. Yanına git, Sakinleş'e basılı tut!", "Yanına git, Sakinleş'e basılı tut!")


func _on_kettle_calmed() -> void:
	_hud.clear_hint()
	boss_camera(false)
	GameState.bark("s2c0_kazan_son")
	await GameState.dialogue_closed
	_refresh()


func _on_bell_rung(_b: EchoBell) -> void:
	Pus.fade_to(self, 0.03, 3.0)
	GameState.bark("s2c0_can")
	_hud.clear_hint()
	var bell := get_node_or_null("Level/Bell") as Node3D
	if bell and bell.has_node("Beacon"):
		bell.get_node("Beacon").queue_free()


# --- level ---------------------------------------------------------------

func _build() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	WorldLook.block(lv, Vector3(0, -0.5, 0), Vector3(80, 1, 80), GRASS, 0.0)
	Toon.part(lv, "box", Vector3(3, 0.06, 32), PATH, Vector3(0, 0.0, 8.0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(lv, "cylinder", Vector3(9, 0.06, 9), PATH, Vector3(0, 0.02, KETTLE_AT.z), Vector3.ZERO, 0.0, 0.0)
	# hot spring pools, steaming, with a stone rim
	for pool: Array in [[Vector3(0, 0, 3.5), 3.4], [Vector3(-14, 0, 2), 2.2], [Vector3(16, 0, 12), 2.0]]:
		var at: Vector3 = pool[0]
		var r: float = pool[1]
		Toon.part(lv, "cylinder", Vector3(r * 2 + 0.8, 0.3, r * 2 + 0.8), STONE, at + Vector3.UP * 0.12)
		var water := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = r
		cyl.bottom_radius = r
		cyl.height = 0.05
		water.mesh = cyl
		water.position = at + Vector3.UP * 0.29
		lv.add_child(water)
		WorldLook.water(water, "lake")
		var body := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = r + 0.3
		cs.height = 1.0
		c.shape = cs
		body.add_child(c)
		body.position = at + Vector3.UP * 0.5
		lv.add_child(body)
		var steam := Node3D.new()
		steam.position = at
		lv.add_child(steam)
		MobModels._pus_wisps(steam, 0.6, Color(1, 1, 1), int(r * 4), 0.5)
	# houses round the springs
	var accents := ["berry", "sky", "spark-purple", "honey", "leaf", "hp"]
	var spots := [Vector3(-14, 0, -6), Vector3(14, 0, -7), Vector3(-15, 0, 11), Vector3(15, 0, 3), Vector3(-7, 0, -19), Vector3(7, 0, -21)]
	for i in spots.size():
		var h := Prop.new()
		h.kind = "house"
		h.accent = accents[i]
		lv.add_child(h)
		h.position = spots[i]
		h.rotation.y = atan2(-spots[i].x, -spots[i].z)
	for p: Vector3 in [Vector3(-20, 0, -14), Vector3(20, 0, -2), Vector3(-20, 0, 18), Vector3(19, 0, 20), Vector3(-4, 0, -25), Vector3(22, 0, -18)]:
		var t := Prop.new()
		t.kind = "tree"
		lv.add_child(t)
		t.position = p
	# Kalay's forge: a cold anvil
	Toon.part(lv, "box", Vector3(1.0, 0.6, 0.6), Color("#5a5f6a"), Vector3(13.6, 0.3, 4.2))
	Toon.part(lv, "box", Vector3(1.3, 0.25, 0.5), Color("#6e7380"), Vector3(13.6, 0.72, 4.2))
	# the bell hill
	WorldLook.block(lv, Vector3(BELL_AT.x, BELL_AT.y * 0.5, BELL_AT.z), Vector3(6, BELL_AT.y, 6), STONE)
	for i in 2:
		WorldLook.block(lv, Vector3(BELL_AT.x - 1.0, (i + 1) * 0.375, BELL_AT.z + 3.6 + (1 - i) * 0.9), Vector3(2.0, (i + 1) * 0.75, 0.9), STONE)
	var bell := EchoBell.new()
	bell.name = "Bell"
	bell.bell_id = "s2_can0"
	bell.needs = Q2 + "/caydanlik"
	lv.add_child(bell)
	bell.position = BELL_AT
	bell.rung.connect(_on_bell_rung)
	TravelSign.board(lv, "Kızıl Yaprak Ormanı ↑ (yakında)", Vector3(-3.0, 1.3, -24.0), 3.0)
	Toon.part(lv, "box", Vector3(0.16, 1.2, 0.16), Color("#a86b45"), Vector3(-3.0, 0.6, -24.05))
	for n in 4:
		var wall := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var wb := WorldBoundaryShape3D.new()
		var dir: Vector3 = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK][n]
		wb.plane = Plane(-dir, -RADIUS)
		c.shape = wb
		wall.add_child(c)
		lv.add_child(wall)
	# Köpüklüler at the edges of the village
	for p: Vector3 in [Vector3(-17, 0, 16), Vector3(-19, 0, -9), Vector3(18, 0, 17)]:
		Mob.spawn(self, "kopuklu_tavuk", p)
	for p: Vector3 in [Vector3(19, 0, -10), Vector3(-12, 0, 20)]:
		Mob.spawn(self, "gurultucu_kurbaga", p)


func _bubble(n: Node3D) -> Label3D:
	var l := Label3D.new()
	l.font = Tokens.font_for("text-heading")
	l.font_size = 52
	l.pixel_size = 0.006
	l.outline_size = 12
	l.outline_modulate = Tokens.color("outline")
	l.modulate = Tokens.color("hp")
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position.y = 3.0
	n.add_child(l)
	return l


func _run_demo(which: String) -> void:
	match which:
		"village":
			# the whole chapter, scripted (headless check)
			DevTools.auto_dialogue = true
			var d := GameState.data
			for id: String in ["bulut", "pitpit", "pamuk", "toprak", "bidik", "bulut"]:
				var n := get_node(id.capitalize()) as Node3D
				_player.global_position = n.global_position + Vector3(0, 0.3, 1.8)
				await get_tree().create_timer(0.3).timeout
				GameState.talk_to(id)
				await close_dialogs()
			print("S2C0 q1=%s q2=%s" % [d.quest_state(Q1), d.quest_state(Q2)])
			_player.global_position = KETTLE_AT + Vector3(0, 0.3, 6.0)
			for i in 300:
				await get_tree().create_timer(0.3).timeout
				await close_dialogs()
				if _kettle.lid_up:
					_player.global_position = KETTLE_AT + Vector3(0, 0.3, 2.4)
					_player._attack_cd = 0.0
					_player.spin_attack()
				if _kettle.is_simmering or d.objective_done(Q2, "caydanlik"):
					break
			print("S2C0 kettle hp=%d simmering=%s player_hp=%d" % [_kettle.hp, _kettle.is_simmering, d.hp])
			_player.global_position = KETTLE_AT + Vector3(0, 0.3, 2.6)
			await get_tree().create_timer(0.3).timeout
			Input.action_press("calm")
			await get_tree().create_timer(BreathCalm.BREATH_IN + BreathCalm.BREATH_OUT + 0.5).timeout
			Input.action_release("calm")
			await close_dialogs()
			print("S2C0 calmed=%s" % d.objective_done(Q2, "caydanlik"))
			_player.global_position = BELL_AT + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.4).timeout
			(get_node("Level/Bell") as EchoBell).use(_player)
			await close_dialogs()
			var b := get_node("Bulut") as Node3D
			_player.global_position = b.global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("bulut")
			await close_dialogs()
			print("S2C0_DONE q2=%s flag=%s bell=%s level=%d" % [d.quest_state(Q2), d.has_flag("s2_bolum0_bitti"), d.has_flag("s2_can0"), d.level])
			get_tree().quit()
		"bell_locked":
			_player.global_position = BELL_AT + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.4).timeout
			(get_node("Level/Bell") as EchoBell).use(_player)
			await close_dialogs()
			print("S2C0 bell_locked rung=%s" % GameState.data.has_flag("s2_can0"))
			get_tree().quit()
		"stairs":
			_player.global_position = Vector3(BELL_AT.x - 1.0, 0.3, BELL_AT.z + 6.5)
			await get_tree().create_timer(0.4).timeout
			Input.action_press("move_forward")
			for i in 6:
				Input.action_press("jump")
				await get_tree().create_timer(0.2).timeout
				Input.action_release("jump")
				await get_tree().create_timer(0.3).timeout
			Input.action_release("move_forward")
			print("S2C0 stairs y=%.2f z=%.2f" % [_player.global_position.y, _player.global_position.z])
			get_tree().quit()
		"kettle":
			GameState.data.start_quest(Content.quests[Q2])
			_player.global_position = KETTLE_AT + Vector3(0, 0.3, 7.0)

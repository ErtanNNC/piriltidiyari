extends ChapterBase
## Sezon 2 · Bölüm 0 – Buharlı Kaplıca Köyü (levels 1–5, the hub). A village
## round hot springs at the foot of the mountain path. The Kızıl Sis has made
## everyone talk at once: four neighbours each want to be heard (talk to
## them, they calm down). Tospik Nine (who came along with the keepers) sends the keeper to the village's big
## kettle (Homurdanan Çaydanlık, mini boss, Sakinleş at the end), then the
## first Ses Çanı on the hill lifts the red mist. Tospik Nine runs a little
## shop afterwards.

const Q1 := "kopuk_koy"
const Q2 := "homurdanan_caydanlik"
## Side quest: the evening talking circle (one holds the stone and talks)
const Q3 := "konusma_cemberi"
const CIRCLE := Vector3(-13, 0, 17)
const CIRCLE_ORDER := ["pitpit", "pamuk", "toprak", "bidik"]
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
var _stone: Node3D


func _ready() -> void:
	WorldLook.add(self, "sabah")
	Pus.set_color(Pus.RED)
	var d := GameState.data
	Pus.set_amount(0.03 if d.has_flag("s2_can0") else 0.18)
	_build()
	GameState.data.flags_changed.connect(_refresh)  # the last talk sets its flag after the quest
	way_on("s2_bolum0_bitti", Vector3(0, 0, -25.5), "Kızıl Yaprak Ormanı")
	Decor.auto(self, "koy")
	npc(self, "tospik_nine", "turtle", Vector3(-3.6, 0, 0.6), 30.0).name = "Tospik Nine"
	npc(self, "kazma", "mole", Vector3(12.0, 0, 2.5), -60.0).name = "Kazma"
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
	take_return_point()
	await get_tree().create_timer(1.8, false).timeout
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
	_refresh_circle()
	var bulut := get_node("Tospik Nine") as Node3D
	var go_bulut := d.quest_state(Q1) in ["none", "ready"] or d.quest_state(Q2) == "ready" \
			or d.quest_state(Q3) == "ready" or (d.quest_state(Q3) == "none" and d.has_flag("s2_bolum0_bitti"))
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


## Konuşma Çemberi: once it starts the four neighbours sit round the
## stumps; the glowing Konuşma Taşı floats over whoever talks next.
func _refresh_circle() -> void:
	var d := GameState.data
	var state := d.quest_state(Q3)
	if state == "none":
		return
	var next := ""
	if state == "active":
		for id: String in CIRCLE_ORDER:
			if not d.objective_done(Q3, "tas_" + id):
				next = id
				break
	for i in CIRCLE_ORDER.size():
		var id: String = CIRCLE_ORDER[i]
		var n := get_node_or_null(id.capitalize()) as Node3D
		if n == null:
			continue
		var a := i * TAU / CIRCLE_ORDER.size() + PI * 0.25
		var seat := CIRCLE + Vector3(cos(a), 0, sin(a)) * 2.6
		if n.global_position.distance_to(seat) > 0.3:
			n.global_position = seat
			n.look_at(Vector3(CIRCLE.x, n.global_position.y, CIRCLE.z), Vector3.UP, true)
		var want := id == next
		if want and not n.has_node("Beacon"):
			Beacon.attach(n, 2.6, Tokens.color("spark-purple"))
		elif not want and n.has_node("Beacon"):
			n.get_node("Beacon").queue_free()
	var to := CIRCLE + Vector3(0, 1.1, 0)
	if next != "":
		to = (get_node(next.capitalize()) as Node3D).global_position + Vector3(0, 2.0, 0)
	if _stone == null:
		_stone = Node3D.new()
		_stone.name = "KonusmaTasi"
		add_child(_stone)
		Toon.part(_stone, "ellipsoid", Vector3(0.5, 0.36, 0.42), "spark-purple", Vector3.ZERO, Vector3.ZERO, 1.2, 0.03)
		Toon.part(_stone, "sphere", Vector3(0.14, 0.14, 0.14), "spark-white", Vector3(0.1, 0.1, 0.16), Vector3.ZERO, 1.4, 0.0)
		var bob := _stone.get_child(0).create_tween().set_loops()
		bob.tween_property(_stone.get_child(0), "position:y", 0.15, 0.8).set_trans(Tween.TRANS_SINE)
		bob.tween_property(_stone.get_child(0), "position:y", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
		_stone.global_position = to
	elif _stone.global_position.distance_to(to) > 0.1:
		# the stone hops over to the next speaker
		var tw := _stone.create_tween()
		var mid := (_stone.global_position + to) * 0.5 + Vector3.UP * 1.6
		tw.tween_property(_stone, "global_position", mid, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(_stone, "global_position", to, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			Effects.sparkle(self, to, Tokens.color("spark-purple"), 10)
			Audio.play("blip"))


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
	# the talking circle: a ring of stumps round a flat stone
	Toon.part(lv, "cylinder", Vector3(7.4, 0.04, 7.4), PATH, CIRCLE + Vector3.UP * 0.02, Vector3.ZERO, 0.0, 0.0)
	Toon.part(lv, "cylinder", Vector3(1.1, 0.3, 1.1), STONE, CIRCLE + Vector3.UP * 0.15)
	for i in 8:
		var a := i * TAU / 8.0 + PI * 0.125
		Toon.part(lv, "cylinder", Vector3(0.7, 0.4, 0.7), Color("#a0704a"), CIRCLE + Vector3(cos(a), 0.2, sin(a)) * Vector3(3.4, 1, 3.4))
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
	# the first house is the Bekçi Evi: mirror (change keeper) and wardrobe
	var door := HouseDoor.new()
	door.name = "BekciDoor"
	door.house_id = "bekci"
	door.title = "Bekçi Evi"
	lv.add_child(door)
	var face: Vector3 = (-(spots[0] as Vector3)).normalized()
	door.position = (spots[0] as Vector3) + face * 1.8
	door.rotation.y = atan2(face.x, face.z)
	for p: Vector3 in [Vector3(-20, 0, -14), Vector3(20, 0, -2), Vector3(-20, 0, 18), Vector3(19, 0, 20), Vector3(-4, 0, -25), Vector3(22, 0, -18)]:
		var t := Prop.new()
		t.kind = "tree"
		lv.add_child(t)
		t.position = p
	# Kazma's forge: a cold anvil
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
	TravelSign.board(lv, "Kızıl Yaprak Ormanı ↑", Vector3(-3.0, 1.3, -24.0), 2.8)
	Toon.part(lv, "box", Vector3(0.16, 1.2, 0.16), Color("#a86b45"), Vector3(-3.0, 0.6, -24.05))
	# the way on: open once the village's bell has rung
	var exit := TriggerArea.new()
	exit.radius = 2.2
	exit.once = false
	lv.add_child(exit)
	exit.position = Vector3(0, 0, -25.5)
	exit.reached.connect(func() -> void:
		if GameState.data.has_flag("s2_can0"):
			SceneFlow.ask_go("s2_chapter1")
		elif not GameState.in_dialogue:
			GameState.bark("s2c0_kilit"))
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
		"circle":
			# Konuşma Çemberi: out of turn waits, in turn the stone moves on
			DevTools.auto_dialogue = true
			var d := GameState.data
			for q: String in [Q1, Q2]:
				d.start_quest(Content.quests[q])
				d.complete_quest(Content.quests[q])
			d.set_flag("s2_can0")
			d.set_flag("s2_bolum0_bitti")
			GameState.talk_to("tospik_nine")
			await close_dialogs()
			print("S2CIRCLE started=%s" % d.quest_state(Q3))
			await get_tree().create_timer(0.4, false).timeout
			GameState.talk_to("pamuk")
			await close_dialogs()
			print("S2CIRCLE out_of_turn pamuk=%s" % d.objective_done(Q3, "tas_pamuk"))
			for id: String in CIRCLE_ORDER:
				GameState.talk_to(id)
				await close_dialogs()
				await get_tree().create_timer(0.8, false).timeout
				var st := _stone.global_position
				print("S2CIRCLE %s done=%s stone=%s" % [id, d.objective_done(Q3, "tas_" + id), st.snapped(Vector3.ONE * 0.1)])
			GameState.talk_to("tospik_nine")
			await close_dialogs()
			var seated: bool = (get_node("Pitpit") as Node3D).global_position.distance_to(CIRCLE) < 3.0
			print("S2CIRCLE_DONE q3=%s seated=%s" % [d.quest_state(Q3), seated])
			get_tree().quit()
		"travel":
			# arrived by fast travel: standing by the bell, on solid ground
			await get_tree().create_timer(1.0, false).timeout
			print("S2TRAVEL at=%s floor=%s near_bell=%s" % [_player.global_position.snapped(Vector3.ONE * 0.1), _player.is_on_floor(), _player.global_position.distance_to(BELL_AT) < 3.5])
			get_tree().quit()
		"bekci":
			# into the Bekçi Evi and back out again (headless)
			var d := GameState.data
			if d.has_flag("dbg_bekci"):
				while SceneFlow.busy:
					await get_tree().process_frame
				await get_tree().create_timer(0.5, false).timeout
				var door := get_node("Level/BekciDoor") as Node3D
				print("S2HOUSE back scene=%s near_door=%s floor=%s" % [SceneFlow.current, _player.global_position.distance_to(door.global_position) < 3.0, _player.is_on_floor()])
				get_tree().quit()
				return
			d.set_flag("dbg_bekci")
			while SceneFlow.busy:
				await get_tree().process_frame
			(get_node("Level/BekciDoor") as HouseDoor).use(_player)
		"door":
			var door := get_node("Level/BekciDoor") as Node3D
			_player.global_position = door.global_position + door.global_transform.basis.z * 3.0 + Vector3.UP * 0.3
		"shop":
			# talk to Kazma: his anvil stall opens (screenshot)
			DevTools.auto_dialogue = true
			GameState.data.add_piril(150)
			_player.global_position = get_node("Kazma").global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3, false).timeout
			GameState.talk_to("kazma")
			await close_dialogs()
		"skills":
			# each Season 2 calming skill on two fresh Köpüklüler (headless)
			var d := GameState.data
			for k: String in ["pati", "bado", "citir", "lumi"]:
				d.choose_keeper(k, Content.keeper(k)["stats"], {}, k)
				while d.level < Skills.S2_LEVEL:
					d.add_xp(Progression.xp_to_next(d.level) - d.xp)
				d.mp = d.max_mp
				var at := Vector3(-14, 0.3, 14)
				_player.global_position = at
				var a := Mob.spawn(self, "kopuklu_tavuk", at + Vector3(1.5, 0, 0))
				var b := Mob.spawn(self, "kopuklu_tavuk", at + Vector3(-1.5, 0, 1))
				await get_tree().create_timer(0.3, false).timeout
				_player._attack_cd = 0.0
				_player.use_skill()
				await get_tree().create_timer(0.3, false).timeout
				print("S2SKILL %s skill=%s a=%s b=%s slow=%s" % [k, d.active_skill(), a.state, b.state, a._slow_until > GameState.clock])
				a.queue_free()
				b.queue_free()
				await get_tree().create_timer(0.2, false).timeout
			get_tree().quit()
		"village":
			# the whole chapter, scripted (headless check)
			DevTools.auto_dialogue = true
			var d := GameState.data
			for id: String in ["tospik_nine", "pitpit", "pamuk", "toprak", "bidik", "tospik_nine"]:
				var n := get_node(id.capitalize()) as Node3D
				_player.global_position = n.global_position + Vector3(0, 0.3, 1.8)
				await get_tree().create_timer(0.3, false).timeout
				GameState.talk_to(id)
				await close_dialogs()
			print("S2C0 q1=%s q2=%s" % [d.quest_state(Q1), d.quest_state(Q2)])
			_player.global_position = KETTLE_AT + Vector3(0, 0.3, 6.0)
			for i in 300:
				await get_tree().create_timer(0.3, false).timeout
				await close_dialogs()
				if _kettle.lid_up:
					_player.global_position = KETTLE_AT + Vector3(0, 0.3, 2.4)
					_player._attack_cd = 0.0
					_player.spin_attack()
				if _kettle.is_simmering or d.objective_done(Q2, "caydanlik"):
					break
			print("S2C0 kettle hp=%d simmering=%s player_hp=%d" % [_kettle.hp, _kettle.is_simmering, d.hp])
			_player.global_position = KETTLE_AT + Vector3(0, 0.3, 2.6)
			await get_tree().create_timer(0.3, false).timeout
			Input.action_press("calm")
			await get_tree().create_timer(BreathCalm.BREATH_IN + BreathCalm.BREATH_OUT + 0.5, false).timeout
			Input.action_release("calm")
			await close_dialogs()
			print("S2C0 calmed=%s" % d.objective_done(Q2, "caydanlik"))
			_player.global_position = BELL_AT + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.4, false).timeout
			(get_node("Level/Bell") as EchoBell).use(_player)
			await close_dialogs()
			var b := get_node("Tospik Nine") as Node3D
			_player.global_position = b.global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3, false).timeout
			GameState.talk_to("tospik_nine")
			await close_dialogs()
			print("S2C0_DONE q2=%s flag=%s bell=%s level=%d" % [d.quest_state(Q2), d.has_flag("s2_bolum0_bitti"), d.has_flag("s2_can0"), d.level])
			get_tree().quit()
		"bell_locked":
			_player.global_position = BELL_AT + Vector3(0, 0.3, 1.6)
			await get_tree().create_timer(0.4, false).timeout
			(get_node("Level/Bell") as EchoBell).use(_player)
			await close_dialogs()
			print("S2C0 bell_locked rung=%s" % GameState.data.has_flag("s2_can0"))
			get_tree().quit()
		"stairs":
			_player.global_position = Vector3(BELL_AT.x - 1.0, 0.3, BELL_AT.z + 6.5)
			await get_tree().create_timer(0.4, false).timeout
			Input.action_press("move_forward")
			for i in 6:
				Input.action_press("jump")
				await get_tree().create_timer(0.2, false).timeout
				Input.action_release("jump")
				await get_tree().create_timer(0.3, false).timeout
			Input.action_release("move_forward")
			print("S2C0 stairs y=%.2f z=%.2f" % [_player.global_position.y, _player.global_position.z])
			get_tree().quit()
		"kettle":
			GameState.data.start_quest(Content.quests[Q2])
			_player.global_position = KETTLE_AT + Vector3(0, 0.3, 7.0)

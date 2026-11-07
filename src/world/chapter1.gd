extends Node3D
## Bölüm 1 – Fısıltı Ormanı. One continuous forest map, south to north:
## Orman Feneri and Hu's clearing → three whisper crossroads (green tree
## tells the truth, grey tree the opposite; a wrong turn's fog sends you
## back) → three small lanterns open the Pus curtain → the forest heart,
## Kütük Kral and the Yeşil Kıvılcım.

const QUEST := "fisilti_ormani"
const FLOOR := Color("#86b97f")
const PATH := Color("#d9c8a0")
## Crossroads come from content/chapter1/chapter.json "junctions": the wall's
## z, which side is right (+1 / -1), the trees [x, grey?, words] and where a
## wrong turn's fog sends you back.
const HALL := 8.0
const EDGE := 14.0

var _gate: PusGate
var _lanterns_lit := 0
var _king: Node3D
@onready var _hud: Hud = $Hud
@onready var _player: Player = $Player


func _ready() -> void:
	WorldLook.add(self, "orman")
	var d := GameState.data
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	Pus.set_amount(0.5 if not d.objective_done(QUEST, "fener") else 0.35)
	_build()
	d.quest_changed.connect(func(_id: String) -> void: _advance())
	_restore_progress()
	await get_tree().create_timer(1.9).timeout
	if DevTools.demo != "":
		_run_demo(DevTools.demo)
		return
	if not d.objective_done(QUEST, "fener"):
		GameState.bark("c1_giris")
		_hud.show_hint("Orman Feneri'ne git ve yak", "Orman Feneri'ne git, Yak'a bas")


func _advance() -> void:
	var d := GameState.data
	if d.objective_done(QUEST, "fener") and not d.objective_done(QUEST, "hu"):
		_hud.show_hint("Baykuş Öğretmen Hu ile konuş", "")
	elif d.objective_done(QUEST, "hu") and not d.objective_done(QUEST, "kalp"):
		_hud.clear_hint()
	if d.objective_done(QUEST, "fenerler") and d.objective_done(QUEST, "hu") and not _gate.is_open:
		_gate.open()
		Pus.fade_to(self, 0.2, 2.0)
		GameState.bark("c1_kapi")
	if d.objective_done(QUEST, "kalp") and _king == null and not d.objective_done(QUEST, "kral"):
		_start_boss()


## Coming back to a save: relight what was lit, open what was open.
func _restore_progress() -> void:
	var d := GameState.data
	if d.objective_done(QUEST, "fener"):
		$Level/OrmanFeneri.light_up(true)
	var n := d.objective_count(QUEST, "fenerler").x
	for i in n:
		get_node("Level/KucukFener%d" % i).light_up(true)
	_lanterns_lit = n
	if d.objective_done(QUEST, "fenerler") and d.objective_done(QUEST, "hu"):
		_gate.open()
	if d.quest_state(QUEST) == "done":
		$Level/KivilcimFeneri.light_up(true)
		Pus.set_amount(0.05)


# --- level ----------------------------------------------------------------

func _build() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	WorldLook.block(lv, Vector3(0, -0.5, -18), Vector3(EDGE * 2 + 6, 1, 140), FLOOR, 0.0)
	# winding path stripes
	for seg in [[Vector3(0, 0, 46), Vector3(0, 0, 8)], [Vector3(-8, 0, 6), Vector3(8, 0, 6)]]:
		_path(lv, seg[0], seg[1])
	# outer walls
	ForestKit.hedge(lv, Vector3(-EDGE, 0, 48), Vector3(-EDGE, 0, -86))
	ForestKit.hedge(lv, Vector3(EDGE, 0, 48), Vector3(EDGE, 0, -86))
	ForestKit.hedge(lv, Vector3(-EDGE, 0, 48), Vector3(EDGE, 0, 48))
	ForestKit.hedge(lv, Vector3(-EDGE, 0, -86), Vector3(EDGE, 0, -86))
	# Orman Feneri (the region's lantern), Hu, Dikiş
	var big := SmallLantern.new()
	big.name = "OrmanFeneri"
	big.big = true
	big.lantern_id = "orman_feneri"
	big.position = Vector3(0, 0, 36)
	lv.add_child(big)
	big.lit.connect(_on_lantern)
	_npc(lv, "hu", "owl_teacher", Vector3(5.5, 0, 18), -30)
	var back := TravelSign.new()
	back.target_scene = "chapter0"
	back.title = "Gökkuşağı Köyü"
	back.action = "Köye dön"
	back.position = Vector3(4, 0, 42)
	lv.add_child(back)
	_npc(lv, "dikis", "spider", Vector3(-8, 0, 28), 30)
	# small lanterns, one per area
	var spots := [Vector3(-10, 0, 14), Vector3(10.5, 0, -14), Vector3(-10.5, 0, -42)]
	for i in spots.size():
		var l := SmallLantern.new()
		l.name = "KucukFener%d" % i
		l.lantern_id = "kucuk_fener"
		l.position = spots[i]
		lv.add_child(l)
		l.lit.connect(_on_lantern)
	# the three crossroads
	var junctions: Array = Content.chapter.get("junctions", [])
	for j in junctions.size():
		_junction(lv, junctions[j], j, junctions.size())
	# forest heart: arena, the gate before it, Kıvılcım Feneri
	var heart := TriggerArea.new()
	heart.area_id = "orman_kalbi"
	heart.radius = 2.4
	heart.checkpoint = true
	heart.position = Vector3(8, 0, -63.5)
	lv.add_child(heart)
	var kf := SmallLantern.new()
	kf.name = "KivilcimFeneri"
	kf.big = true
	kf.accent = "spark-green"
	kf.lantern_id = "kivilcim_feneri"
	kf.position = Vector3(0, 0, -82)
	lv.add_child(kf)
	# decoration: friendly trees along the walls, fireflies in each area
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for z in range(42, -84, -7):
		for side in [-1.0, 1.0]:
			if rng.randf() < 0.75:
				ForestKit.face_tree(lv, Vector3(side * (EDGE - 2.2), 0, z + rng.randf_range(-2, 2)), rng.randf_range(0.8, 1.1))
	for zc in [28.0, -14.0, -42.0, -72.0]:
		ForestKit.fireflies(lv, Vector3(0, 0, zc), Vector3(10, 0, 8), 18)
	# mobs
	for spec in [["kirpi_topu", Vector3(-4, 0, -12)], ["kirpi_topu", Vector3(5, 0, -17)],
			["karga", Vector3(-3, 0, -38)], ["karga", Vector3(4, 0, -44)], ["kirpi_topu", Vector3(0, 0, -36)]]:
		Mob.spawn(self, spec[0], spec[1])
	_player.respawn_point = _player.global_position


func _path(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5
	var l := a.distance_to(b)
	var p := Toon.part(parent, "box", Vector3(3.0, 0.05, l), PATH, mid + Vector3.UP * 0.01, Vector3.ZERO, 0.0, 0.0)
	p.rotation.y = atan2(b.x - a.x, b.z - a.z)


func _npc(parent: Node3D, id: String, kind: String, at: Vector3, face: float) -> void:
	var n := Npc.new()
	n.npc_id = id
	n.kind = kind
	n.face_angle_deg = face
	n.position = at
	parent.add_child(n)


## A crossroads: wall with two gaps, a hall split in two; the wrong half is
## Pus fog that sends you back; the next wall has one gap on the right side.
func _junction(parent: Node3D, j: Dictionary, index: int, count: int) -> void:
	var z: float = j["wall"]
	var g := 1.7
	ForestKit.hedge(parent, Vector3(-EDGE, 0, z), Vector3(-8 - g, 0, z))
	ForestKit.hedge(parent, Vector3(-8 + g, 0, z), Vector3(8 - g, 0, z))
	ForestKit.hedge(parent, Vector3(8 + g, 0, z), Vector3(EDGE, 0, z))
	ForestKit.hedge(parent, Vector3(0, 0, z), Vector3(0, 0, z - HALL))
	var right := int(j["right"])
	var z2 := z - HALL
	var gap_x := 8.0 * right
	ForestKit.hedge(parent, Vector3(-EDGE, 0, z2), Vector3(gap_x - g, 0, z2))
	if index == count - 1:
		ForestKit.hedge(parent, Vector3(gap_x + g, 0, z2), Vector3(EDGE, 0, z2))
		_gate = PusGate.new()
		_gate.position = Vector3(gap_x, 0, z2)
		parent.add_child(_gate)
	else:
		ForestKit.hedge(parent, Vector3(gap_x + g, 0, z2), Vector3(EDGE, 0, z2))
	for t: Array in j["trees"]:
		var w := WhisperTree.new()
		w.position = Vector3(t[0], 0, z + 4.5)
		w.grey = t[1]
		w.says = t[2]
		parent.add_child(w)
	# the wrong half: thick fog that turns you around
	var wrong_x := -8.0 * right
	var fog := Node3D.new()
	fog.position = Vector3(wrong_x, 0, z - HALL * 0.5)
	parent.add_child(fog)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Tokens.color("pus")
	mat.albedo_color.a = 0.55
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for k in 6:
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.6
		s.height = 2.4
		mi.mesh = s
		mi.material_override = mat
		mi.position = Vector3(randf_range(-4, 4), 0.8, randf_range(-3, 3))
		fog.add_child(mi)
	var trap := TriggerArea.new()
	trap.radius = 2.6
	trap.once = false
	trap.position = Vector3(wrong_x, 0, z - 2.5)
	parent.add_child(trap)
	var back := Vector3(j["back"][0], j["back"][1], j["back"][2])
	trap.reached.connect(func() -> void: _wrong_turn(back))


func _wrong_turn(back: Vector3) -> void:
	_player.input_enabled = false
	await _hud.flash(0.9, Tokens.color("pus"))
	_player.global_position = back
	_player.velocity = Vector3.ZERO
	_player.input_enabled = true
	GameState.bark("c1_yanlis")


func _on_lantern(l: SmallLantern) -> void:
	var d := GameState.data
	GameState.notify("light", l.lantern_id)
	if l.lantern_id == "orman_feneri" and d.objective_done(QUEST, "fener"):
		Pus.fade_to(self, 0.35, 2.0)
		_hud.clear_hint()
		GameState.bark("c1_fener")
	elif l.lantern_id == "kucuk_fener":
		Pus.fade_to(self, maxf(Pus.amount - 0.05, 0.2), 1.0)
	SaveGame.write(d)


# --- boss (Kütük Kral) -------------------------------------------------------

func _start_boss() -> void:
	var king := KutukKral.new()
	_king = king
	add_child(king)
	king.position = Vector3(0, 0, -76)
	king.hp_changed.connect(func(h: int, m: int) -> void: _hud.set_boss_hp(h, m))
	king.defeated.connect(_on_king_awake)
	var cam: FollowCamera = $Camera
	cam.anchor = Vector3(0, 1, -74)
	cam.anchor_weight = 0.45
	cam.distance = 18.0
	if DevTools.demo == "":
		GameState.bark("c1_kral_basla")
		await GameState.dialogue_closed
	_hud.show_boss("Kütük Kral", king.hp, KingPlan.MAX_HP)
	_hud.show_hint("Köklerin dairelerinden kaç. Halkanın üstünden zıpla!", "Dairelerden kaç, halkada zıpla!")
	king.start()


func _on_king_awake() -> void:
	_hud.hide_boss()
	GameState.notify("defeat", "kutuk_kral")
	await get_tree().create_timer(0.8).timeout
	_hud.show_scene_card("", "Kütük Kral uyandı!", "Sonunda güzel bir uyku çekecek")
	await get_tree().create_timer(3.2).timeout
	GameState.bark("c1_kral_son")
	await GameState.dialogue_closed
	# the Yeşil Kıvılcım flies out to the keeper
	var orb := Toon.part(self, "sphere", Vector3(0.8, 1.1, 0.8), "spark-green", _king.global_position + Vector3.UP * 3.5, Vector3.ZERO, 1.2, 0.04)
	var tw := orb.create_tween()
	tw.tween_property(orb, "global_position", _player.global_position + Vector3.UP * 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(orb.queue_free)
	await tw.finished
	var d := GameState.data
	d.add_spark("green")
	$Level/KivilcimFeneri.light_up()
	Pus.fade_to(self, 0.05, 3.0)
	var cam: FollowCamera = $Camera
	cam.anchor_weight = 0.0
	cam.distance = 14.0
	_hud.show_scene_card("Kıvılcım bulundu!", "Yeşil Kıvılcım", "Fısıltı Ormanı yeniden yeşil")
	await get_tree().create_timer(3.4).timeout
	if d.quest_state(QUEST) == "ready":
		d.complete_quest(Content.quests[QUEST])
	d.set_flag("bolum1_bitti")
	SaveGame.write(d)
	GameState.bark("c1_son")
	await GameState.dialogue_closed
	_hud.show_hint("Köye dönmek için girişteki tabelaya git", "")


func _run_demo(which: String) -> void:
	match which:
		"start":
			pass
		"boss", "bossfight":
			var d := GameState.data
			for o in ["fener", "hu", "fenerler"]:
				d.complete_objective(QUEST, o)
			_restore_progress()
			_player.global_position = Vector3(8, 0, -63.5)
			if which == "boss":
				return
			while _king == null or not (_king as KutukKral).active:
				await get_tree().process_frame
			var king: KutukKral = _king
			var t := 0.0
			var jumps := 0
			while king.active and t < 240.0:
				if king.dazed:
					_player.global_position = king.global_position + Vector3(0, 0.1, 2.6)
					_player._attack_cd = 0.0
					_player.spin_attack()
					if d.mp >= 15:
						_player._attack_cd = 0.0
						_player.use_skill()
				# jump when a stomp ring is about to reach us
				for n in get_children():
					if n is MeshInstance3D and n.mesh is TorusMesh and _player.is_on_floor():
						var r: float = (n as MeshInstance3D).scale.x
						var dist := Vector2(_player.global_position.x - king.global_position.x, _player.global_position.z - king.global_position.z).length()
						if dist - r > 0.0 and dist - r < 1.6:
							_player.velocity.y = _player.jump_velocity
							jumps += 1
				await get_tree().create_timer(0.05).timeout
				t += 0.05
				if _hud._dialog.is_open():
					_hud._dialog.advance()
			print("BOSS hp=%d active=%s phase=%d t=%.1f jumps=%d player_hp=%d" % [king.hp, king.active, king.phase, t, jumps, d.hp])
			for i in 200:
				if _hud._dialog.is_open():
					_hud._dialog.advance()
					_hud._dialog.advance()
				await get_tree().create_timer(0.1).timeout
			print("BOSS2 quest=%s sparks=%s flag=%s level=%d piril=%d" % [d.quest_state(QUEST), d.sparks, d.has_flag("bolum1_bitti"), d.level, d.piril])
			get_tree().quit()
		"mobs":
			for m in get_tree().get_nodes_in_group("mob"):
				m.queue_free()
			_player.global_position = Vector3(0, 0, 30)
			var k := Mob.spawn(self, "kirpi_topu", Vector3(0, 0, 24))
			var states := {}
			var hp0 := GameState.data.hp
			for i in 50:
				states[k.state] = true
				await get_tree().create_timer(0.1).timeout
			print("KIRPI states=%s player_hp %d->%d" % [states.keys(), hp0, GameState.data.hp])
			k.queue_free()
			GameState.data.wake_up()
			_player.global_position = Vector3(0, 0, 30)
			var c := Mob.spawn(self, "karga", Vector3(3, 0, 26))
			var min_y := 99.0
			var max_y := 0.0
			var hit_on_ground := false
			hp0 = GameState.data.hp
			for i in 70:
				await get_tree().create_timer(0.1).timeout
				if not is_instance_valid(c):
					break
				max_y = maxf(max_y, c.global_position.y)
				min_y = minf(min_y, c.global_position.y)
				if c.state == "recover" and not hit_on_ground:
					var before := c.hp
					_player.global_position = c.global_position + Vector3(0, 0, 1.2)
					_player._attack_cd = 0.0
					_player.spin_attack()
					hit_on_ground = c.hp < before
			print("KARGA y %.2f..%.2f yerde_vuruldu=%s player_hp %d->%d" % [min_y, max_y, hit_on_ground, hp0, GameState.data.hp])
			get_tree().quit()
		"junction":
			$Level/OrmanFeneri.light_up(true)
			await get_tree().create_timer(0.3).timeout
			while _hud._dialog.is_open():
				_hud._dialog.advance()
				await get_tree().create_timer(0.05).timeout
			_player.global_position = Vector3(0, 0, 11)
		"wrong":
			_player.global_position = Vector3(-8, 0, 7)
			Input.action_press("move_forward")
			await get_tree().create_timer(1.6).timeout
			Input.action_release("move_forward")
			await get_tree().create_timer(1.4).timeout
			print("WRONG z=%.2f (geri döndü: %s)" % [_player.global_position.z, _player.global_position.z > 8.0])
			for i in 6:
				if _hud._dialog.is_open():
					_hud._dialog.advance()
					_hud._dialog.advance()
				await get_tree().create_timer(0.1).timeout
			_player.global_position = Vector3(8, 0, 7)
			Input.action_press("move_forward")
			await get_tree().create_timer(1.6).timeout
			Input.action_release("move_forward")
			await get_tree().create_timer(0.4).timeout
			print("RIGHT z=%.2f (geçti: %s)" % [_player.global_position.z, _player.global_position.z < 2.0])
			get_tree().quit()

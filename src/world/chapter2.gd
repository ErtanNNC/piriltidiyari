extends Node3D
## Bölüm 2 – Şekerleme Mağaraları. Dark candy-crystal caves, south to north:
## Kazma's mole village and the Mağara Feneri → Parlak Salon (light its
## grey crystals to open the crystal gate) → the syrup river with lantern
## platforms → the Karanlık Tünel (same, in the dark, with bats) → the
## underground lake where Kristal Yengeç Kıskaç guards the Mavi Kıvılcım.

const QUEST := "sekerleme_magaralari"
const FLOOR := Color("#4a4170")
const EDGE := 14.0
const ARENA := Vector3(0, 0, -57)

var _gate_salon: CrystalGate
var _gate_tunel: CrystalGate
var _boss: Kiskac
var _syrup_told := false
@onready var _hud: Hud = $Hud
@onready var _player: Player = $Player


func _ready() -> void:
	WorldLook.add(self, "magara")
	Decor.auto(self, "magara")
	var d := GameState.data
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	Pus.set_amount(0.45)
	_player.carry_light()
	_build()
	d.quest_changed.connect(func(_id: String) -> void: _advance())
	d.flags_changed.connect(_kids_go_home)
	_restore_progress()
	await get_tree().create_timer(1.9, false).timeout
	if DevTools.demo != "":
		_run_demo(DevTools.demo)
		return
	if not d.objective_done(QUEST, "fener"):
		GameState.bark("c2_giris")
		_hud.show_hint("Mağara Feneri'ni yak", "Mağara Feneri'ni yak")


func _advance() -> void:
	var d := GameState.data
	if d.objective_done(QUEST, "fener") and not d.objective_done(QUEST, "kazma"):
		_hud.show_hint("Madenci Kazma ile konuş", "")
	elif d.objective_done(QUEST, "kazma") and not d.objective_done(QUEST, "salon"):
		_hud.show_hint("Gri kristallere vur, parlasınlar!", "Gri kristallere vur!")
	elif d.objective_done(QUEST, "salon"):
		_hud.clear_hint()


func _restore_progress() -> void:
	var d := GameState.data
	if d.objective_done(QUEST, "fener"):
		$Level/MagaraFeneri.light_up(true)
	for g: Array in [["salon", _gate_salon], ["tunel", _gate_tunel]]:
		if d.objective_done(QUEST, g[0]):
			for c in get_tree().get_nodes_in_group("crystal_" + g[0]):
				c.light_up(true)
			(g[1] as CrystalGate).open(true)
	if d.quest_state(QUEST) == "done":
		$Level/KivilcimFeneri.light_up(true)
		Pus.set_amount(0.05)
		_friendly_crab()


# --- level ----------------------------------------------------------------

func _build() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	WorldLook.block(lv, Vector3(0, -0.5, -12), Vector3(EDGE * 2 + 6, 1, 124), FLOOR, 0.0)
	CaveKit.wall(lv, Vector3(-EDGE, 0, 48), Vector3(-EDGE, 0, -74))
	CaveKit.wall(lv, Vector3(EDGE, 0, 48), Vector3(EDGE, 0, -74))
	CaveKit.wall(lv, Vector3(-EDGE, 0, 48), Vector3(EDGE, 0, 48))
	# --- Kazma's village
	var fener := SmallLantern.new()
	fener.name = "MagaraFeneri"
	fener.big = true
	fener.accent = "spark-blue"
	fener.lantern_id = "magara_feneri"
	fener.position = Vector3(0, 0, 36)
	lv.add_child(fener)
	fener.lit.connect(_on_lantern)
	_npc(lv, "kazma", "mole", Vector3(5, 0, 30), -25)
	for at in [Vector3(-9, 0, 33), Vector3(9, 0, 41), Vector3(-8.5, 0, 42)]:
		_hut(lv, at)
	for at in [Vector3(-4, 0, 26), Vector3(4, 0, 24)]:
		var post := Prop.new()
		post.kind = "lantern_post"
		post.accent = "honey"
		post.position = at
		lv.add_child(post)
	var back := TravelSign.new()
	back.target_scene = "chapter0"
	back.title = "Gökkuşağı Köyü"
	back.action = "Köye dön"
	back.position = Vector3(4, 0, 43)
	lv.add_child(back)
	# wall to the Parlak Salon (open passage)
	CaveKit.wall(lv, Vector3(-EDGE, 0, 20), Vector3(-1.8, 0, 20))
	CaveKit.wall(lv, Vector3(1.8, 0, 20), Vector3(EDGE, 0, 20))
	# --- Parlak Salon: 3 crystals open the gate north
	for spec in [[Vector3(-8, 0, 13), "berry"], [Vector3(8.5, 0, 9), "sky"], [Vector3(-5, 0, 4), "spark-purple"]]:
		_crystal(lv, "salon", spec[0], spec[1])
	_gate_salon = _gate(lv, 0.0, 0.0, "Salonun bütün kristallerini yak")
	for spec in [["kristal_bocek", Vector3(5, 0, 14)], ["kristal_bocek", Vector3(-3, 0, 8)]]:
		Mob.spawn(self, spec[0], spec[1])
	# --- syrup river with swaying lantern platforms
	var syr := CaveKit.syrup(lv, Vector3(0, 0, -9), Vector2(EDGE * 2, 8.0))
	syr.body_entered.connect(func(b: Node3D) -> void:
		if b is Player and not _syrup_told:
			_syrup_told = true
			GameState.bark("c2_seker"))
	for i in 3:
		var p := MovingPlatform.new()
		p.travel = Vector3(2.4, 0, 0)
		p.period = 3.4
		p.phase = i * 0.15
		p.accent = ["berry", "sky", "spark-purple"][i]
		p.size = Vector3(2.6, 0.5, 2.4)
		p.position = Vector3(-1.0 + (i % 2) * 2.0, 0.35, -6.2 - i * 2.8)
		lv.add_child(p)
	CaveKit.wall(lv, Vector3(-EDGE, 0, -22), Vector3(4.2, 0, -22))
	CaveKit.wall(lv, Vector3(7.8, 0, -22), Vector3(EDGE, 0, -22))
	Mob.spawn(self, "yarasa", Vector3(4, 0, -17))
	# --- Karanlık Tünel: 4 crystals in the dark
	for spec in [[Vector3(-9, 0, -29), "spark-blue"], [Vector3(9, 0, -31), "berry"], [Vector3(-8, 0, -40), "sky"], [Vector3(8, 0, -39), "spark-purple"]]:
		_crystal(lv, "tunel", spec[0], spec[1])
	_gate_tunel = _gate(lv, -44.0, 0.0, "Tünelin bütün kristallerini yak")
	for spec in [["yarasa", Vector3(-3, 0, -30)], ["yarasa", Vector3(4, 0, -36)], ["kristal_bocek", Vector3(0, 0, -34)]]:
		Mob.spawn(self, spec[0], spec[1])
	# --- the lake shore (boss arena)
	var water := Toon.part(lv, "box", Vector3(EDGE * 2, 0.1, 10), Color("#6fb8e8"), Vector3(0, 0.03, -69), Vector3.ZERO, 0.5, 0.0)
	water.name = "Lake"
	WorldLook.water(water, "lake")
	var shore := StaticBody3D.new()
	var sc := CollisionShape3D.new()
	var sb := BoxShape3D.new()
	sb.size = Vector3(EDGE * 2, 5.0, 1.0)
	sc.shape = sb
	sc.position.y = 2.5
	shore.add_child(sc)
	lv.add_child(shore)
	shore.position = Vector3(0, 0, -64.5)
	var heart := TriggerArea.new()
	heart.area_id = "gol"
	heart.radius = 2.4
	heart.checkpoint = true
	heart.position = Vector3(0, 0, -47.5)
	lv.add_child(heart)
	heart.reached.connect(_start_boss)
	var kf := SmallLantern.new()
	kf.name = "KivilcimFeneri"
	kf.big = true
	kf.accent = "spark-blue"
	kf.lantern_id = "kivilcim_feneri"
	kf.position = Vector3(10, 0, -50)
	lv.add_child(kf)
	# after the boss: a shortcut home next to the Kıvılcım Feneri
	TravelSign.exit_home(lv, kf.position + Vector3(-6, 0, 5), "bolum2_bitti")
	_side_content(lv)
	_player.respawn_point = _player.global_position


func _hut(parent: Node3D, at: Vector3) -> void:
	# a mole-family burrow house: earthen dome with stone rings, a round
	# framed door, a glowing porthole window, a pipe chimney and a lamp
	var earth := Color("#b08a76")
	Toon.part(parent, "sphere", Vector3(4.0, 3.2, 4.0), earth, at + Vector3(0, 0.6, 0))
	Toon.part(parent, "ring", Vector3(4.05, 0.14, 4.05), Color("#8f6f60"), at + Vector3(0, 0.75, 0), Vector3.ZERO, 0.0, 0.02)
	Toon.part(parent, "ellipsoid", Vector3(2.6, 1.2, 2.6), Color("#c79f88"), at + Vector3(0, 1.85, 0), Vector3.ZERO, 0.0, 0.0)
	for i in 6:
		var a2 := TAU * i / 6.0 + 0.4
		Toon.part(parent, "ellipsoid", Vector3(0.5, 0.32, 0.4), Color("#9a8d9e"), at + Vector3(cos(a2) * 1.95, 0.15, sin(a2) * 1.95))
	Toon.part(parent, "ring", Vector3(1.3, 0.12, 1.3), Color("#c98d5e"), at + Vector3(0, 0.85, 1.72), Vector3(90, 0, 0), 0.0, 0.02)
	Toon.part(parent, "capsule", Vector3(1.0, 1.6, 0.4), Color("#4a3a32"), at + Vector3(0, 0.8, 1.85))
	Toon.part(parent, "sphere", Vector3(0.12, 0.12, 0.12), "honey", at + Vector3(0.3, 0.8, 2.05), Vector3.ZERO, 0.6, 0.015)
	Toon.part(parent, "ring", Vector3(0.7, 0.08, 0.7), Color("#c98d5e"), at + Vector3(-1.05, 1.5, 1.42), Vector3(70, -35, 0), 0.0, 0.02)
	Toon.part(parent, "cylinder", Vector3(0.56, 0.05, 0.56), Color("#ffe08a"), at + Vector3(-1.05, 1.5, 1.42), Vector3(70, -35, 0), 1.2, 0.0)
	Toon.part(parent, "cylinder", Vector3(0.3, 1.3, 0.3), Color("#8a8fa8"), at + Vector3(0.9, 2.3, -0.6))
	Toon.part(parent, "cylinder", Vector3(0.42, 0.14, 0.42), Color("#6f738a"), at + Vector3(0.9, 2.98, -0.6))
	Toon.part(parent, "cylinder", Vector3(0.04, 0.5, 0.04), "outline", at + Vector3(1.0, 1.75, 1.75), Vector3.ZERO, 0.0, 0.0)
	Toon.part(parent, "sphere", Vector3(0.5, 0.5, 0.25), "honey", at + Vector3(1.0, 1.4, 1.65), Vector3(0, 35, 0), 1.0, 0.02)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.9
	cyl.height = 3.0
	c.shape = cyl
	c.position.y = 1.5
	body.add_child(c)
	parent.add_child(body)
	body.position = at


func _crystal(parent: Node3D, group: String, at: Vector3, col: String) -> void:
	var c := CaveCrystal.new()
	c.group_id = group
	c.accent = col
	c.position = at
	parent.add_child(c)
	c.lit.connect(_on_crystal)


func _gate(parent: Node3D, z: float, x: float, msg: String) -> CrystalGate:
	CaveKit.wall(parent, Vector3(-EDGE, 0, z), Vector3(x - 1.9, 0, z))
	CaveKit.wall(parent, Vector3(x + 1.9, 0, z), Vector3(EDGE, 0, z))
	var g := CrystalGate.new()
	g.message = msg
	g.position = Vector3(x, 0, z)
	parent.add_child(g)
	return g


func _npc(parent: Node3D, id: String, kind: String, at: Vector3, face: float) -> Npc:
	var n := Npc.new()
	n.npc_id = id
	n.kind = kind
	n.face_angle_deg = face
	n.position = at
	parent.add_child(n)
	return n


func _on_lantern(l: SmallLantern) -> void:
	GameState.notify("light", l.lantern_id)
	if l.lantern_id == "magara_feneri":
		Pus.fade_to(self, 0.35, 2.0)
		_hud.clear_hint()
		GameState.bark("c2_fener")
	SaveGame.write(GameState.data)


func _on_crystal(c: CaveCrystal) -> void:
	for other in get_tree().get_nodes_in_group("crystal_" + c.group_id):
		if not other.is_lit:
			return
	GameState.notify("light", "kristal_" + c.group_id)
	var gate := _gate_salon if c.group_id == "salon" else _gate_tunel
	gate.open()
	Pus.fade_to(self, maxf(Pus.amount - 0.1, 0.15), 1.5)
	GameState.bark("c2_salon")
	SaveGame.write(GameState.data)


# --- boss --------------------------------------------------------------------

func _start_boss() -> void:
	var d := GameState.data
	if _boss != null or d.objective_done(QUEST, "kiskac"):
		return
	_boss = Kiskac.new()
	add_child(_boss)
	_boss.position = Vector3(0, 0, -60)
	_boss.arena_center = ARENA
	_boss.arena_radius = 8.0
	_boss.hp_changed.connect(func(h: int, m: int) -> void: _hud.set_boss_hp(h, m))
	_boss.defeated.connect(_on_crab_friend)
	var cam: FollowCamera = $Camera
	cam.anchor = Vector3(0, 1, -54)
	cam.anchor_weight = 0.5
	cam.distance = 19.0
	if DevTools.demo == "":
		GameState.bark("c2_kiskac_basla")
		await GameState.dialogue_closed
	_hud.show_boss("Kristal Yengeç Kıskaç", _boss.hp, CrabPlan.MAX_HP)
	_hud.show_hint("Baloncuklardan kaç. Kıskacı saplanınca vur!", "Kıskacı saplanınca vur!")
	_boss.start()


func _on_crab_friend() -> void:
	_hud.hide_boss()
	GameState.notify("defeat", "kiskac")
	await get_tree().create_timer(0.8, false).timeout
	_hud.show_scene_card("", "Kıskaç dost oldu!", "Meğer Kıvılcım'ı koruyormuş")
	await get_tree().create_timer(3.2, false).timeout
	GameState.bark("c2_kiskac_son")
	await GameState.dialogue_closed
	var orb := Toon.part(self, "sphere", Vector3(0.8, 1.1, 0.8), "spark-blue", _boss.global_position + Vector3.UP * 3.5, Vector3.ZERO, 1.2, 0.04)
	var tw := orb.create_tween()
	tw.tween_property(orb, "global_position", _player.global_position + Vector3.UP, 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(orb.queue_free)
	await tw.finished
	var d := GameState.data
	d.add_spark("blue")
	$Level/KivilcimFeneri.light_up()
	for g in ["salon", "tunel"]:
		for c in get_tree().get_nodes_in_group("crystal_" + g):
			c.light_up(true)
	Pus.fade_to(self, 0.05, 3.0)
	var cam: FollowCamera = $Camera
	cam.anchor_weight = 0.0
	cam.distance = 14.0
	_hud.show_scene_card("Kıvılcım bulundu!", "Mavi Kıvılcım", "Mağaralar yeniden pırıl pırıl")
	await get_tree().create_timer(3.4, false).timeout
	if d.quest_state(QUEST) == "ready":
		d.complete_quest(Content.quests[QUEST])
	d.set_flag("kazma_dukkan")
	d.set_flag("bolum2_bitti")
	SaveGame.write(d)
	GameState.bark("c2_son")
	await GameState.dialogue_closed
	_hud.show_hint("Kazma'nın dükkânı açıldı! Köye dönebilirsin", "")


## After the fight Kıskaç stays by the lake as a friend (talkable).
func _friendly_crab() -> void:
	if _boss:
		_boss.queue_free()
	var n := _npc($Level, "kiskac", "crab_friend", Vector3(0, 0, -60), 0)
	n.name = "KiskacDost"


# --- side content ----------------------------------------------------------------

func _side_content(lv: Node3D) -> void:
	var d := GameState.data
	var kids := [["kazma_cocuk1", Vector3(-11.5, 0, 2.5)], ["kazma_cocuk2", Vector3(11.5, 0, -18.5)], ["kazma_cocuk3", Vector3(11.5, 0, -42)]]
	for k: Array in kids:
		if d.has_flag(k[0]):
			continue
		var n := _npc(lv, k[0], "mole_kid", k[1], 0)
		n.name = "Cocuk_" + k[0]
	for spec in [[3, Vector3(-10, 0, 25)], [4, Vector3(-11, 0, -34)]]:
		var st := StoryStone.new()
		st.stone = spec[0]
		st.position = spec[1]
		lv.add_child(st)
	var stone := Color("#7d7299")
	# Pati: a tall candy rock in the salon
	WorldLook.block(lv, Vector3(11, 1.15, 16), Vector3(2.2, 2.3, 2.2), stone)
	var c1 := Chest.new()
	c1.chest_id = "c2_sutun"
	c1.position = Vector3(11, 2.3, 16)
	lv.add_child(c1)
	# Bado: an alcove in the village behind a rock
	CaveKit.wall(lv, Vector3(-EDGE, 0, 30), Vector3(-10, 0, 30), 1.2)
	CaveKit.wall(lv, Vector3(-EDGE, 0, 23.6), Vector3(-10, 0, 23.6), 1.2)
	var rock := WorldLook.block(lv, Vector3(-10.4, 1.1, 26.8), Vector3(1.8, 2.2, 3.6), Color("#5e5480"))
	var c2 := Chest.new()
	c2.chest_id = "c2_kaya"
	c2.position = Vector3(-12.6, 0, 26.8)
	c2.rotation_degrees.y = 90
	lv.add_child(c2)
	var s1 := AbilitySpot.new()
	s1.keeper = "bado"
	s1.spot_id = "c2_kaya"
	s1.blocker = rock
	s1.push = Vector3(0, 0, 3.6)
	s1.position = Vector3(-8.9, 0, 26.8)
	lv.add_child(s1)
	# Çıtır: deep syrup cuts off a corner; rope bridge
	CaveKit.wall(lv, Vector3(-7, 0, -15), Vector3(-7, 0, -22), 1.2)
	Toon.part(lv, "box", Vector3(7, 0.1, 1.8), Color("#ff6fa8"), Vector3(-10.5, 0.05, -15.2), Vector3.ZERO, 0.5, 0.0)
	for seg in [[-13.0, 3.0], [-8.0, 2.0]]:
		var w := StaticBody3D.new()
		var wc := CollisionShape3D.new()
		var wb := BoxShape3D.new()
		wb.size = Vector3(seg[1], 4.0, 1.8)
		wc.shape = wb
		wc.position.y = 2.0
		w.add_child(wc)
		lv.add_child(w)
		w.position = Vector3(seg[0], 0, -15.2)
	var bridge := Node3D.new()
	bridge.position = Vector3(-10.5, 0, -15.2)
	lv.add_child(bridge)
	var planks := Node3D.new()
	planks.visible = false
	bridge.add_child(planks)
	for i in 4:
		Toon.part(planks, "box", Vector3(1.8, 0.12, 0.42), Color("#c98d5e"), Vector3(0, 0.14, -0.75 + i * 0.5), Vector3.ZERO, 0.0, 0.02)
	var gap := StaticBody3D.new()
	var gc := CollisionShape3D.new()
	var gb := BoxShape3D.new()
	gb.size = Vector3(2.0, 4.0, 1.8)
	gc.shape = gb
	gc.position.y = 2.0
	gap.add_child(gc)
	bridge.add_child(gap)
	var c3 := Chest.new()
	c3.chest_id = "c2_surup"
	c3.position = Vector3(-11, 0, -19.5)
	lv.add_child(c3)
	var s2 := AbilitySpot.new()
	s2.keeper = "citir"
	s2.spot_id = "c2_surup"
	s2.blocker = bridge
	s2.position = Vector3(-9.2, 0, -13.2)
	lv.add_child(s2)
	# Lumi: dark corner of the tunnel
	CaveKit.wall(lv, Vector3(-EDGE, 0, -27.6), Vector3(-7, 0, -27.6), 1.2)
	var dark := StaticBody3D.new()
	var dc := CollisionShape3D.new()
	var db := BoxShape3D.new()
	db.size = Vector3(1.4, 4.0, 5.6)
	dc.shape = db
	dc.position.y = 2.0
	dark.add_child(dc)
	lv.add_child(dark)
	dark.position = Vector3(-7.2, 0, -24.8)
	for i in 5:
		Toon.part(dark, "sphere", Vector3(1.6, 1.6, 1.6), Color("#1b1630"), Vector3(0, 0.8 + (i % 2) * 0.5, -2.2 + i * 1.1), Vector3.ZERO, 0.0, 0.03)
	var c4 := Chest.new()
	c4.chest_id = "c2_karanlik"
	c4.position = Vector3(-11, 0, -25)
	lv.add_child(c4)
	var s3 := AbilitySpot.new()
	s3.keeper = "lumi"
	s3.spot_id = "c2_karanlik"
	s3.blocker = dark
	s3.position = Vector3(-5.6, 0, -25)
	lv.add_child(s3)


func _kids_go_home() -> void:
	for i in [1, 2, 3]:
		var n := get_node_or_null("Level/Cocuk_kazma_cocuk%d" % i)
		if n and GameState.data.has_flag("kazma_cocuk%d" % i) and not n.has_meta("leaving"):
			n.set_meta("leaving", true)
			Effects.sparkle(self, n.global_position + Vector3.UP, Tokens.color("spark-blue"), 12)
			var tw := n.create_tween()
			tw.tween_interval(0.6)
			tw.tween_property(n, "scale", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.tween_callback(n.queue_free)
	var d := GameState.data
	if d.quest_state("kazma_cocuklari") == "ready":
		d.complete_quest(Content.quests["kazma_cocuklari"])
		d.set_flag("c2_cocuklar")
		GameState.bark("c2_cocuklar")


func _run_demo(which: String) -> void:
	var d := GameState.data
	match which:
		"start":
			pass
		"shop":
			d.set_flag("kazma_dukkan")
			$Level/MagaraFeneri.light_up(true)
			await _close_dialogs()
			_player.global_position = Vector3(4, 0, 32)
			_hud.open_shop("kazma")
		"village":
			$Level/MagaraFeneri.light_up(true)
			_player.global_position = Vector3(2, 0, 30)
			await _close_dialogs()
		"salon":
			$Level/MagaraFeneri.light_up(true)
			_player.global_position = Vector3(-3, 0, 12)
			await _close_dialogs()
			for c in get_tree().get_nodes_in_group("crystal_salon"):
				if c.position.x > 0:
					c.light_up()
		"tunnel":
			for o in ["fener", "kazma", "salon"]:
				d.complete_objective(QUEST, o)
			_restore_progress()
			_player.global_position = Vector3(0, 0, -28)
			await _close_dialogs()
		"crystals":
			# light the salon by hitting crystals, check the gate opens
			$Level/MagaraFeneri.light_up(true)
			await _close_dialogs()
			for m in get_tree().get_nodes_in_group("mob"):
				m.queue_free()
			for c in get_tree().get_nodes_in_group("crystal_salon"):
				_player.global_position = c.global_position + Vector3(0, 0, 1.6)
				await get_tree().create_timer(0.2, false).timeout
				_player._attack_cd = 0.0
				_player.spin_attack()
				await get_tree().create_timer(0.3, false).timeout
				await _close_dialogs()
			print("CRYSTALS salon_done=%s gate_open=%s" % [d.objective_done(QUEST, "salon"), _gate_salon.is_open])
			_player.global_position = Vector3(0, 0, 2.5)
			Input.action_press("move_forward")
			await get_tree().create_timer(1.0, false).timeout
			Input.action_release("move_forward")
			print("GATE passed=%s z=%.1f" % [_player.global_position.z < -1.0, _player.global_position.z])
			# syrup slows
			_player.global_position = Vector3(10, 0, -4.2)
			await get_tree().create_timer(0.3, false).timeout
			Input.action_press("move_forward")
			await get_tree().create_timer(1.0, false).timeout
			Input.action_release("move_forward")
			var syrup_dz := -4.2 - _player.global_position.z
			print("SYRUP moved %.2f m in 1 s (slow=%.1f)" % [syrup_dz, _player.slow])
			get_tree().quit()
		"boss", "bossfight":
			for o in ["fener", "kazma", "salon", "tunel"]:
				d.complete_objective(QUEST, o)
			_restore_progress()
			_player.global_position = Vector3(0, 0, -47.5)
			if which == "boss":
				return
			while _boss == null or not _boss.active:
				await get_tree().process_frame
			var t := 0.0
			while _boss.active and t < 240.0:
				if _boss.open:
					_player.global_position = _boss.global_position + Vector3(0, 0.1, 2.8)
					_player._attack_cd = 0.0
					_player.spin_attack()
				await get_tree().create_timer(0.1, false).timeout
				t += 0.1
				if _hud._dialog.is_open():
					_hud._dialog.advance()
			print("CRAB hp=%d active=%s phase=%d t=%.1f player_hp=%d" % [_boss.hp, _boss.active, _boss.phase, t, d.hp])
			for i in 200:
				if _hud._dialog.is_open():
					_hud._dialog.advance()
					_hud._dialog.advance()
				await get_tree().create_timer(0.1, false).timeout
			print("CRAB2 quest=%s sparks=%s shop=%s flag=%s exit=%s" % [d.quest_state(QUEST), d.sparks, d.has_flag("kazma_dukkan"), d.has_flag("bolum2_bitti"), ($Level/ExitSign as Node3D).visible])
			get_tree().quit()


func _close_dialogs() -> void:
	await get_tree().create_timer(0.3, false).timeout
	while _hud._dialog.is_open():
		_hud._dialog.advance()
		await get_tree().create_timer(0.05, false).timeout

extends Node3D
## Bölüm 3 – Bulut Limanı. Four floating islands over the clouds, joined by
## Kaptan Pırpır's sky ship (the most open part of the world):
##   Liman      – the harbor, Liman Feneri, Pırpır
##   Rüzgâr Gülü – storm gusts (hide by rocks), three storm bells
##   Balon      – bouncy balloons up three floating tiers to Balon Tepesi
##   Fırtına    – Rüzgâr's nest: an island ringed by bobbing cloud platforms
## Falling into the clouds: Pırpır catches you (back to the last checkpoint).

const QUEST := "bulut_limani"
const ISLANDS := {
	"liman": {"name": "Liman", "center": Vector3(0, 0, 0), "radius": 14.0, "land": Vector3(6, 0, -6)},
	"gul": {"name": "Rüzgâr Gülü Adası", "center": Vector3(70, 0, 0), "radius": 14.0, "land": Vector3(70, 0, 10)},
	"balon": {"name": "Balon Adası", "center": Vector3(0, 0, -70), "radius": 11.0, "land": Vector3(0, 0, -61)},
	"firtina": {"name": "Fırtına Adası", "center": Vector3(70, 0, -70), "radius": 7.0, "land": Vector3(70, 0, -64.5)},
}

var _boss: Ruzgar
var _wind: WindZone
var _bounced := false
var _warned := false
var _shadow: Node3D
var _cut_cam: Camera3D
@onready var _hud: Hud = $Hud
@onready var _player: Player = $Player


func _ready() -> void:
	WorldLook.add(self, "liman")
	Decor.auto(self, "liman")
	var d := GameState.data
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	Pus.set_amount(0.5 if not d.objective_done(QUEST, "fener") else 0.35)
	_build()
	d.quest_changed.connect(func(_id: String) -> void: _advance())
	d.flags_changed.connect(_chicks_go_home)
	_player.fell_off.connect(func() -> void: GameState.bark("c3_dustu"))
	_restore_progress()
	await get_tree().create_timer(1.9).timeout
	if DevTools.demo != "":
		_run_demo(DevTools.demo)
		return
	if not d.objective_done(QUEST, "fener"):
		GameState.bark("c3_giris")
		_hud.show_hint("Liman Feneri'ni yak", "Liman Feneri'ni yak")


func _advance() -> void:
	var d := GameState.data
	if d.objective_done(QUEST, "fener") and not d.objective_done(QUEST, "pirpir"):
		_hud.show_hint("Kaptan Pırpır ile konuş", "")
	elif d.objective_done(QUEST, "pirpir") and not _nest_open():
		_hud.show_hint("Gemiye bin: çanlar ve balonlar seni bekliyor", "Gemiye bin!")
	elif _nest_open() and not d.objective_done(QUEST, "ruzgar"):
		_hud.show_hint("Gemiyle Fırtına Adası'na uç", "Fırtına Adası'na uç!")
	if d.objective_done(QUEST, "canlar") and _wind.active:
		_wind.active = false
		_player.wind = Vector3.ZERO
		GameState.bark("c3_canlar")
		Pus.fade_to(self, maxf(Pus.amount - 0.1, 0.2), 1.5)


func _nest_open() -> bool:
	var d := GameState.data
	return d.objective_done(QUEST, "canlar") and d.objective_done(QUEST, "balon")


func _restore_progress() -> void:
	var d := GameState.data
	if d.objective_done(QUEST, "fener"):
		$Level/LimanFeneri.light_up(true)
	if d.objective_done(QUEST, "canlar"):
		_wind.active = false
	if d.quest_state(QUEST) == "done":
		$Level/KivilcimFeneri.light_up(true)
		Pus.set_amount(0.05)


# --- level -------------------------------------------------------------------

func _build() -> void:
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	SkyKit.cloud_sea(lv, Vector3(35, 0, -35), 70)
	for id: String in ISLANDS:
		var i: Dictionary = ISLANDS[id]
		SkyKit.island(lv, i["center"], i["radius"])
		var dock := ShipDock.new()
		dock.name = "Dock_" + id
		var land: Vector3 = i["land"]
		var out: Vector3 = land - (i["center"] as Vector3)
		out.y = 0.0
		# the ship floats just off the island's rim, never over the play area
		var rim: float = i["radius"] + 2.6
		dock.position = (i["center"] as Vector3) + out.normalized() * rim
		dock.rotation.y = atan2(out.x, out.z) + PI / 2
		lv.add_child(dock)
		dock.travel_requested.connect(_travel_menu)
	_harbor(lv)
	_wind_island(lv)
	_balloon_island(lv)
	_storm_island(lv)
	_side_content(lv)
	_player.respawn_point = _player.global_position


func _harbor(lv: Node3D) -> void:
	var f := SmallLantern.new()
	f.name = "LimanFeneri"
	f.big = true
	f.accent = "spark-yellow"
	f.lantern_id = "liman_feneri"
	f.position = Vector3(-3, 0, 2)
	lv.add_child(f)
	f.lit.connect(_on_lantern)
	_npc(lv, "pirpir", "gull_captain", Vector3(4, 0, -4), -30)
	var back := TravelSign.new()
	back.target_scene = "chapter0"
	back.title = "Gökkuşağı Köyü"
	back.action = "Köye dön"
	back.position = Vector3(-6, 0, 8)
	lv.add_child(back)
	for at in [Vector3(-8, 0, -5), Vector3(8, 0, 6)]:
		var post := Prop.new()
		post.kind = "lantern_post"
		post.accent = ["berry", "sky"][int(at.x > 0)]
		post.position = at
		lv.add_child(post)


func _wind_island(lv: Node3D) -> void:
	var c: Vector3 = ISLANDS["gul"]["center"]
	# the big wind rose in the middle
	Toon.part(lv, "cylinder", Vector3(0.6, 7.0, 0.8), Color("#e8d4a8"), c + Vector3(0, 3.5, 0))
	var rose := Node3D.new()
	lv.add_child(rose)
	rose.position = c + Vector3(0, 6.8, 0.6)
	for k in 4:
		var blade := Toon.part(rose, "box", Vector3(0.8, 3.2, 0.12), ["berry", "sky", "spark-yellow", "leaf"][k], Vector3(0, 1.6, 0), Vector3.ZERO, 0.0, 0.02)
		var pivot := Node3D.new()
		rose.add_child(pivot)
		pivot.rotation.z = TAU * k / 4.0
		blade.reparent(pivot, false)
	var spin := rose.create_tween().set_loops()
	spin.tween_property(rose, "rotation:z", -TAU, 4.0).as_relative()
	var body := StaticBody3D.new()
	var bc := CollisionShape3D.new()
	var bs := CylinderShape3D.new()
	bs.radius = 0.6
	bs.height = 7.0
	bc.shape = bs
	bc.position.y = 3.5
	body.add_child(bc)
	lv.add_child(body)
	body.position = c
	_wind = WindZone.new()
	_wind.radius = 13.0
	lv.add_child(_wind)
	_wind.position = c
	_wind.gust_started.connect(func(_d: Vector3) -> void:
		if not _warned and _player.global_position.distance_to(c) < 15.0:
			_warned = true
			GameState.bark("c3_ruzgar_uyari"))
	for at in [Vector3(-6, 0, -3), Vector3(5, 0, 4), Vector3(-2, 0, 7), Vector3(8, 0, -6), Vector3(-9, 0, 5), Vector3(1, 0, -9)]:
		_shelter(lv, c + at)
	for spec in [["can1", Vector3(-7, 0, -8)], ["can2", Vector3(9, 0, -1)], ["can3", Vector3(-5, 0, 10)]]:
		var b := StormBell.new()
		b.bell_id = spec[0]
		b.position = c + spec[1]
		lv.add_child(b)
	for spec in [["firtina_yumagi", Vector3(-3, 0, -6)], ["firtina_yumagi", Vector3(6, 0, 2)], ["korsan_marti", Vector3(0, 0, 5)]]:
		Mob.spawn(self, spec[0], c + spec[1])


func _shelter(lv: Node3D, at: Vector3) -> void:
	var rock := WorldLook.block(lv, at + Vector3.UP * 0.9, Vector3(1.6, 1.8, 1.6), Color("#b9b0c4"))
	rock.add_to_group("shelter")
	rock.set_meta("shelter_radius", 2.3)
	Toon.part(rock, "sphere", Vector3(2.0, 1.2, 2.0), Color("#cfc7d9"), Vector3(0, 0.8, 0))


func _balloon_island(lv: Node3D) -> void:
	var c: Vector3 = ISLANDS["balon"]["center"]
	var tiers := [[c + Vector3(6, 4, -4), 3.4], [c + Vector3(-2, 8, -10), 3.4], [c + Vector3(6, 12, -16), 4.0]]
	for t: Array in tiers:
		SkyKit.island(lv, t[0], t[1], Color("#a7e0a0"))
	var balloons := [[c + Vector3(0, 0, -2), "berry"], [c + Vector3(4.5, 4, -6.8), "sky"], [c + Vector3(-1, 8, -12.6), "spark-purple"]]
	for b: Array in balloons:
		var bb := BounceBalloon.new()
		bb.accent = b[1]
		bb.position = b[0]
		lv.add_child(bb)
		if not _bounced:
			pass
	var top := TriggerArea.new()
	top.area_id = "balon_tepesi"
	top.radius = 2.6
	top.checkpoint = true
	top.position = tiers[2][0]
	lv.add_child(top)
	top.reached.connect(func() -> void:
		GameState.bark("c3_tepe"))
	for i in 3:
		var cp := TriggerArea.new()
		cp.checkpoint = true
		cp.radius = 2.4
		cp.position = tiers[i][0] if i < 2 else c
		lv.add_child(cp)
	Mob.spawn(self, "korsan_marti", c + Vector3(-4, 0, 3))


func _storm_island(lv: Node3D) -> void:
	var c: Vector3 = ISLANDS["firtina"]["center"]
	for k in 6:
		var a := TAU * k / 6.0
		var p := MovingPlatform.new()
		p.travel = Vector3(0, 0.6, 0)
		p.period = 3.0
		p.phase = k * 0.17
		p.style = "cloud"
		p.size = Vector3(3.6, 0.6, 3.6)
		p.position = c + Vector3(sin(a) * 10.5, -0.3, cos(a) * 10.5)
		lv.add_child(p)
	for k in 3:
		var a := TAU * k / 3.0 + 0.5
		var pillar := WorldLook.block(lv, c + Vector3(sin(a) * 4.0, 1.3, cos(a) * 4.0), Vector3(1.2, 2.6, 1.2), Color("#d9cfe6"))
		pillar.add_to_group("shelter")
		pillar.set_meta("shelter_radius", 2.0)
	var kf := SmallLantern.new()
	kf.name = "KivilcimFeneri"
	kf.big = true
	kf.accent = "spark-yellow"
	kf.lantern_id = "kivilcim_feneri"
	kf.position = c + Vector3(-4.5, 0, -3)
	lv.add_child(kf)
	# after the boss: a shortcut home next to the Kıvılcım Feneri
	TravelSign.exit_home(lv, kf.position + Vector3(3.5, 0, 1.5), "bolum3_bitti")
	var nest := TriggerArea.new()
	nest.area_id = "firtina_yuvasi"
	nest.radius = 3.0
	nest.checkpoint = true
	nest.position = ISLANDS["firtina"]["land"]
	lv.add_child(nest)
	nest.reached.connect(_start_boss)


func _npc(parent: Node3D, id: String, kind: String, at: Vector3, face: float) -> Npc:
	var n := Npc.new()
	n.npc_id = id
	n.kind = kind
	n.face_angle_deg = face
	n.position = at
	parent.add_child(n)
	return n


# --- travel ------------------------------------------------------------------

func _travel_menu() -> void:
	var d := GameState.data
	var met := d.objective_done(QUEST, "pirpir")
	var opts := []
	for id: String in ISLANDS:
		var ok := id == "liman" or (met and id != "firtina") or (id == "firtina" and _nest_open())
		var note := "Önce Pırpır ile konuş" if not met else "Önce çanları çal ve Balon Tepesi'ne çık"
		opts.append({"id": id, "label": ISLANDS[id]["name"], "enabled": ok, "note": note})
	var to := await _hud.ask("Nereye uçalım?", opts)
	if to != "":
		travel_to(to)


func travel_to(id: String) -> void:
	_player.input_enabled = false
	await _hud.flash(1.0, Tokens.color("panel@light"))
	var land: Vector3 = ISLANDS[id]["land"]
	_player.global_position = land + Vector3.UP * 0.5
	_player.velocity = Vector3.ZERO
	_player.respawn_point = land
	_player.input_enabled = true
	GameState.toast.emit("Pırpır: %s! Tutun sıkı!" % ISLANDS[id]["name"], "quest")


func _on_lantern(l: SmallLantern) -> void:
	GameState.notify("light", l.lantern_id)
	if l.lantern_id == "liman_feneri":
		Pus.fade_to(self, 0.35, 2.0)
		GameState.bark("c3_fener")
	SaveGame.write(GameState.data)


# --- boss --------------------------------------------------------------------

func _start_boss() -> void:
	var d := GameState.data
	if _boss != null or d.objective_done(QUEST, "ruzgar"):
		return
	var c: Vector3 = ISLANDS["firtina"]["center"]
	# Pırpır's ship waits out of sight during the fight (it blocks the view)
	_set_dock_visible("firtina", false)
	_boss = Ruzgar.new()
	add_child(_boss)
	_boss.center = c
	_boss.global_position = c + Vector3(0, 6, -9)
	_boss.hp_changed.connect(func(h: int, m: int) -> void: _hud.set_boss_hp(h, m))
	_boss.defeated.connect(_on_gull_calm)
	var cam: FollowCamera = $Camera
	cam.anchor = c + Vector3(0, 1, 0)
	cam.anchor_weight = 0.45
	cam.distance = 20.0
	if DevTools.demo == "":
		GameState.bark("c3_ruzgar_basla")
		await GameState.dialogue_closed
	_hud.show_boss("Fırtına Martısı Rüzgâr", _boss.hp, GullPlan.MAX_HP)
	_hud.show_hint("Yıldırım dairelerinden kaç, pikeden sonra vur!", "Pikeden sonra vur!")
	_boss.start()


func _set_dock_visible(id: String, on: bool) -> void:
	var dock: ShipDock = $Level.get_node("Dock_" + id)
	dock.visible = on
	dock.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	for a in dock.find_children("*", "Area3D", true, false):
		(a as Area3D).collision_layer = 4 if on else 0


func _on_gull_calm() -> void:
	_set_dock_visible("firtina", true)
	_hud.hide_boss()
	GameState.notify("defeat", "ruzgar")
	await get_tree().create_timer(0.8).timeout
	_hud.show_scene_card("", "Rüzgâr sakinleşti!", "Fırtına dindi")
	await get_tree().create_timer(3.2).timeout
	GameState.bark("c3_ruzgar_son")
	await GameState.dialogue_closed
	var orb := Toon.part(self, "sphere", Vector3(0.8, 1.1, 0.8), "spark-yellow", _boss.global_position + Vector3.UP * 3.5, Vector3.ZERO, 1.2, 0.04)
	var tw := orb.create_tween()
	tw.tween_property(orb, "global_position", _player.global_position + Vector3.UP, 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(orb.queue_free)
	await tw.finished
	var d := GameState.data
	d.add_spark("yellow")
	$Level/KivilcimFeneri.light_up()
	Pus.fade_to(self, 0.05, 3.0)
	var cam: FollowCamera = $Camera
	cam.anchor_weight = 0.0
	cam.distance = 14.0
	_hud.show_scene_card("Kıvılcım bulundu!", "Sarı Kıvılcım", "Gökyüzü yeniden masmavi")
	await get_tree().create_timer(3.4).timeout
	# the little shadow in the mist (first glimpse of Mırıl)
	var cs := CutscenePlayer.new()
	cs.scene = self
	_cut_cam = Camera3D.new()
	_cut_cam.fov = 45.0
	add_child(_cut_cam)
	_cut_cam.global_transform = cam.global_transform
	cs.camera = _cut_cam
	cs.hud = _hud
	add_child(cs)
	await cs.play("golge")
	if d.quest_state(QUEST) == "ready":
		d.complete_quest(Content.quests[QUEST])
	d.set_flag("pirpir_pazar")
	d.set_flag("bolum3_bitti")
	SaveGame.write(d)
	GameState.bark("c3_son")
	await GameState.dialogue_closed
	_hud.show_hint("Pırpır'ın pazarı açıldı! Gemiyle limana dön", "")


func cut_cam_on() -> void:
	_cut_cam.make_current()


func cut_cam_off() -> void:
	($Camera as Camera3D).make_current()


func show_shadow() -> void:
	_shadow = Node3D.new()
	add_child(_shadow)
	_shadow.global_position = Vector3(96, 2.5, -52)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Tokens.color("pus")
	mat.albedo_color.a = 0.3
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 6:
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.4
		s.height = 2.4
		mi.mesh = s
		mi.material_override = mat
		mi.position = Vector3(randf_range(-2.5, 2.5), randf_range(-0.6, 0.4), randf_range(-1.6, -0.4))
		_shadow.add_child(mi)
	Toon.default_pus = 0.0
	var fig := Node3D.new()
	_shadow.add_child(fig)
	Toon.part(fig, "cone", Vector3(1.0, 1.6, 1.0), Color("#5c5a72"), Vector3(0, 0.3, 0))
	Toon.part(fig, "sphere", Vector3(0.8, 0.8, 0.8), Color("#5c5a72"), Vector3(0, 1.3, 0))
	for sx in [-1.0, 1.0]:
		Toon.part(fig, "sphere", Vector3(0.24, 0.3, 0.12), "spark-purple", Vector3(0.18 * sx, 1.36, 0.38), Vector3.ZERO, 3.0, 0.0)
	Toon.default_pus = 1.0
	fig.scale = Vector3.ZERO
	fig.look_at_from_position(fig.global_position, Vector3(78, 1.3, -48), Vector3.UP)
	fig.rotate_y(PI)
	var tw := fig.create_tween()
	tw.tween_property(fig, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK)


func shadow_flee() -> void:
	if not _shadow:
		return
	var tw := _shadow.create_tween()
	tw.tween_property(_shadow, "global_position", _shadow.global_position + Vector3(14, 1, -10), 1.2).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_shadow, "scale", Vector3.ONE * 0.2, 1.2)
	tw.tween_callback(_shadow.queue_free)


# --- side content ------------------------------------------------------------

func _side_content(lv: Node3D) -> void:
	var d := GameState.data
	var chicks := [["marti_yavru1", Vector3(-9, 0, -7)], ["marti_yavru2", ISLANDS["balon"]["center"] + Vector3(-2, 8, -10)], ["marti_yavru3", ISLANDS["gul"]["center"] + Vector3(9, 0, 8)]]
	for k: Array in chicks:
		if d.has_flag(k[0]):
			continue
		var n := _npc(lv, k[0], "gull_chick", k[1], 0)
		n.name = "Yavru_" + k[0]
	for spec in [[5, ISLANDS["gul"]["center"] + Vector3(-10, 0, 0)], [6, ISLANDS["balon"]["center"] + Vector3(7, 12, -17.5)]]:
		var st := StoryStone.new()
		st.stone = spec[0]
		st.position = spec[1]
		lv.add_child(st)
	# keeper corners on the harbor island's rim
	var stone := Color("#d9cfe6")
	WorldLook.block(lv, Vector3(10, 1.15, -7), Vector3(2.2, 2.3, 2.2), stone)
	var c1 := Chest.new()
	c1.chest_id = "c3_sutun"
	c1.position = Vector3(10, 2.3, -7)
	c1.piril = 60
	lv.add_child(c1)
	# Bado: an alcove well inside the island, its north side closed by a rock
	var A := Vector3(-5.5, 0, -4.5)
	var grey := Color("#b9b0c4")
	WorldLook.block(lv, A + Vector3(-2.3, 1.1, 0), Vector3(1.0, 2.2, 3.6), grey)
	WorldLook.block(lv, A + Vector3(2.3, 1.1, 0), Vector3(1.0, 2.2, 3.6), grey)
	WorldLook.block(lv, A + Vector3(0, 1.1, 2.0), Vector3(5.6, 2.2, 1.0), grey)
	var rock := WorldLook.block(lv, A + Vector3(0, 1.1, -2.1), Vector3(3.6, 2.2, 1.4), Color("#a49c92"))
	var c2 := Chest.new()
	c2.chest_id = "c3_kaya"
	c2.piril = 60
	c2.position = A
	lv.add_child(c2)
	var s1 := AbilitySpot.new()
	s1.keeper = "bado"
	s1.spot_id = "c3_kaya"
	s1.blocker = rock
	s1.push = Vector3(3.8, 0, 0)
	s1.position = A + Vector3(0, 0, -4.0)
	lv.add_child(s1)
	# Çıtır: a little islet off the harbor, a rope bridge spans the gap
	# the gap (5.5 m) is wider than a normal jump (~4.8 m)
	SkyKit.island(lv, Vector3(0, 0, 22.5), 3.0, Color("#a7e0a0"))
	var bridge := Node3D.new()
	bridge.position = Vector3(0, 0, 16.75)
	lv.add_child(bridge)
	var planks := Node3D.new()
	planks.visible = false
	bridge.add_child(planks)
	for i in 10:
		Toon.part(planks, "box", Vector3(1.8, 0.12, 0.42), Color("#c98d5e"), Vector3(0, -0.06, -2.7 + i * 0.6), Vector3.ZERO, 0.0, 0.02)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 0
	var fc := CollisionShape3D.new()
	var fb := BoxShape3D.new()
	fb.size = Vector3(1.8, 0.3, 6.2)
	fc.shape = fb
	fc.position.y = -0.15
	floor_body.add_child(fc)
	planks.add_child(floor_body)
	var c3 := Chest.new()
	c3.chest_id = "c3_adacik"
	c3.piril = 60
	c3.position = Vector3(0, 0, 23.0)
	lv.add_child(c3)
	var s2 := AbilitySpot.new()
	s2.keeper = "citir"
	s2.spot_id = "c3_adacik"
	s2.blocker = bridge
	s2.position = Vector3(1.6, 0, 12.6)
	lv.add_child(s2)
	s2.set_meta("bridge_floor", floor_body)
	# Lumi: a dark storm-cloud nook on the harbor's west rim
	var dark := StaticBody3D.new()
	var dc := CollisionShape3D.new()
	var db := BoxShape3D.new()
	db.size = Vector3(1.4, 4.0, 4.4)
	dc.shape = db
	dc.position.y = 2.0
	dark.add_child(dc)
	lv.add_child(dark)
	dark.position = Vector3(-10.0, 0, 2.5)
	for i in 4:
		Toon.part(dark, "sphere", Vector3(1.6, 1.6, 1.6), Color("#3d3a5c"), Vector3(0, 0.8 + (i % 2) * 0.5, -1.6 + i * 1.1), Vector3.ZERO, 0.0, 0.03)
	WorldLook.block(lv, Vector3(-12.0, 1.0, 0.0), Vector3(3.4, 2.0, 1.0), Color("#b9b0c4"))
	WorldLook.block(lv, Vector3(-12.0, 1.0, 5.0), Vector3(3.4, 2.0, 1.0), Color("#b9b0c4"))
	var c4 := Chest.new()
	c4.chest_id = "c3_bulut"
	c4.piril = 60
	c4.position = Vector3(-12.2, 0, 2.5)
	c4.rotation_degrees.y = 90
	lv.add_child(c4)
	var s3 := AbilitySpot.new()
	s3.keeper = "lumi"
	s3.spot_id = "c3_bulut"
	s3.blocker = dark
	s3.position = Vector3(-8.2, 0, 2.5)
	lv.add_child(s3)


func _chicks_go_home() -> void:
	for i in [1, 2, 3]:
		var n := get_node_or_null("Level/Yavru_marti_yavru%d" % i)
		if n and GameState.data.has_flag("marti_yavru%d" % i) and not n.has_meta("leaving"):
			n.set_meta("leaving", true)
			var tw := n.create_tween()
			tw.tween_interval(0.6)
			tw.tween_property(n, "position:y", n.position.y + 8.0, 1.2).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(n, "scale", Vector3.ZERO, 1.2)
			tw.tween_callback(n.queue_free)
	var d := GameState.data
	if d.quest_state("marti_yavrulari") == "ready":
		d.complete_quest(Content.quests["marti_yavrulari"])
		d.set_flag("c3_yavrular")
		GameState.bark("c3_yavrular")


func _run_demo(which: String) -> void:
	var d := GameState.data
	match which:
		"start":
			pass
		"harbor":
			GameState.notify("light", "liman_feneri")
			$Level/LimanFeneri.light_up(true)
			_player.global_position = Vector3(1, 0, 0)
			await _close_dialogs()
		"wind":
			for m in get_tree().get_nodes_in_group("mob"):
				m.queue_free()
			var c: Vector3 = ISLANDS["gul"]["center"]
			await travel_to("gul")
			_player.global_position = c + Vector3(2, 0, 9)
			var gust: Vector3 = await _wind.gust_started
			await get_tree().create_timer(0.1).timeout
			var p0 := _player.global_position
			await get_tree().create_timer(1.0).timeout
			var open_moved := Vector2(_player.global_position.x - p0.x, _player.global_position.z - p0.z).length()
			await _close_dialogs()
			_player.global_position = c + Vector3(5, 0, 4) + Vector3(0, 0, 1.4)
			await _wind.gust_started
			await get_tree().create_timer(0.1).timeout
			p0 = _player.global_position
			await get_tree().create_timer(1.0).timeout
			var shel_moved := Vector2(_player.global_position.x - p0.x, _player.global_position.z - p0.z).length()
			print("WIND open=%.2f m sheltered=%.2f m" % [open_moved, shel_moved])
			for b in get_tree().get_nodes_in_group("_x"):
				pass
			var bells := []
			for n in $Level.get_children():
				if n is StormBell:
					bells.append(n)
			for b: StormBell in bells:
				b.use(_player)
			await _close_dialogs()
			print("BELLS canlar=%s wind_active=%s" % [d.objective_done(QUEST, "canlar"), _wind.active])
			get_tree().quit()
		"balloon":
			for m in get_tree().get_nodes_in_group("mob"):
				m.queue_free()
			var c: Vector3 = ISLANDS["balon"]["center"]
			await travel_to("balon")
			# [start, balloon, next tier]
			var hops := [[c + Vector3(-2.2, 0, -2), c + Vector3(0, 0, -2), c + Vector3(6, 4, -4)],
				[c + Vector3(6, 4, -4), c + Vector3(4.5, 4, -6.8), c + Vector3(-2, 8, -10)],
				[c + Vector3(-2, 8, -10), c + Vector3(-1, 8, -12.6), c + Vector3(6, 12, -16)]]
			for h: Array in hops:
				await _close_dialogs()
				_player.global_position = h[0] + Vector3.UP * 0.3
				await get_tree().create_timer(0.3).timeout
				var target: Vector3 = h[2]
				var ball: Vector3 = h[1]
				# walk into the balloon, then steer to the next tier while airborne
				for i in 140:
					var airborne := _player.velocity.y > 1.0 or _player.global_position.y > ball.y + 1.6
					var aim: Vector3 = (target - _player.global_position) if airborne else (ball - _player.global_position)
					aim.y = 0
					var dir := aim.normalized() if aim.length() > 0.4 else Vector3.ZERO
					for a in ["move_left", "move_right", "move_forward", "move_back"]:
						Input.action_release(a)
					if dir.x > 0.2: Input.action_press("move_right", dir.x)
					if dir.x < -0.2: Input.action_press("move_left", -dir.x)
					if dir.z > 0.2: Input.action_press("move_back", dir.z)
					if dir.z < -0.2: Input.action_press("move_forward", -dir.z)
					await get_tree().physics_frame
					if _player.is_on_floor() and _player.global_position.y > target.y - 0.5 and Vector2(_player.global_position.x - target.x, _player.global_position.z - target.z).length() < 2.5:
						break
				for a in ["move_left", "move_right", "move_forward", "move_back"]:
					Input.action_release(a)
				print("HOP y=%.2f target_y=%.1f on_floor=%s" % [_player.global_position.y, target.y, _player.is_on_floor()])
			await get_tree().create_timer(0.5).timeout
			print("TOP balon_tepesi=%s" % d.objective_done(QUEST, "balon"))
			get_tree().quit()
		"gul":
			await travel_to("gul")
			_player.global_position = ISLANDS["gul"]["center"] + Vector3(-2, 0, 6)
			await _wind.gust_started
		"balon_view":
			await travel_to("balon")
			_player.global_position = ISLANDS["balon"]["center"] + Vector3(-2, 0, -1)
		"golge":
			var cam: FollowCamera = $Camera
			_cut_cam = Camera3D.new()
			_cut_cam.fov = 45.0
			add_child(_cut_cam)
			_cut_cam.global_position = Vector3(78, 6, -48)
			_cut_cam.look_at(Vector3(96, 3, -52))
			cut_cam_on()
			show_shadow()
		"spots":
			var me := d.character_id
			for m in get_tree().get_nodes_in_group("mob"):
				m.queue_free()
			var spot: Vector3 = {"bado": Vector3(-5.5, 0, -8.5), "citir": Vector3(1.6, 0, 12.6), "lumi": Vector3(-8.2, 0, 2.5), "pati": Vector3(10, 0, -4.6)}[me]
			var chest: Vector3 = {"bado": Vector3(-5.5, 0, -4.5), "citir": Vector3(0, 0, 23.0), "lumi": Vector3(-12.2, 0, 2.5), "pati": Vector3(10, 2.3, -7)}[me]
			# without the ability: try to walk to the chest first
			_player.global_position = {"bado": Vector3(-5.5, 0, -0.5), "citir": Vector3(0, 0, 12.5), "lumi": Vector3(-6.5, 0, 2.5), "pati": Vector3(10, 0, -4.6)}[me]
			await get_tree().create_timer(0.3).timeout
			if me != "pati":
				await _walk_to(chest, 2.5)
				var blocked := _player.global_position.distance_to(chest) > 1.6
				print("SPOT %s blocked_before=%s" % [me, blocked])
				_player.global_position = spot
				await get_tree().create_timer(0.3).timeout
				_player.interact()
				await get_tree().create_timer(1.2).timeout
				await _close_dialogs()
				if me == "bado":
					_player.global_position = Vector3(-5.5, 0, -8.5)
				if me == "citir":
					_player.global_position = Vector3(0, 0, 13.0)
				await _walk_to(chest, 4.0)
			else:
				Input.action_press("move_forward")
				Input.action_press("jump")
				await get_tree().physics_frame
				Input.action_release("jump")
				await get_tree().create_timer(0.3).timeout
				Input.action_press("jump")
				await get_tree().physics_frame
				Input.action_release("jump")
				for i in 30:
					await get_tree().physics_frame
					if _player.global_position.z < -6.4 and _player.global_position.y > 2.0:
						break
				Input.action_release("move_forward")
				await get_tree().create_timer(0.5).timeout
			print("SPOT %s reached_chest=%s dist=%.2f y=%.2f" % [me, _player.global_position.distance_to(chest) < 1.6, _player.global_position.distance_to(chest), _player.global_position.y])
			get_tree().quit()
		"travel":
			var opts_before := d.objective_done(QUEST, "pirpir")
			for id in ["gul", "balon", "liman"]:
				await travel_to(id)
				print("TRAVEL %s at=%s" % [id, _player.global_position.round()])
			get_tree().quit()
		"boss", "bossfight":
			for o in ["fener", "pirpir", "canlar", "balon"]:
				d.complete_objective(QUEST, o)
			_restore_progress()
			await _close_dialogs()
			await travel_to("firtina")
			if which == "boss":
				return
			while _boss == null or not _boss.active:
				await get_tree().process_frame
			var t := 0.0
			while _boss.active and t < 240.0:
				if _boss.dazed:
					_player.global_position = _boss.global_position + Vector3(0, 0.2, 2.2)
					_player._attack_cd = 0.0
					_player.spin_attack()
				if _player.global_position.y < -5.0:
					print("FELL during boss")
				await get_tree().create_timer(0.1).timeout
				t += 0.1
				if _hud._dialog.is_open():
					_hud._dialog.advance()
			print("GULL hp=%d active=%s phase=%d t=%.1f player_hp=%d" % [_boss.hp, _boss.active, _boss.phase, t, d.hp])
			for i in 260:
				if _hud._dialog.is_open():
					_hud._dialog.advance()
					_hud._dialog.advance()
				await get_tree().create_timer(0.1).timeout
			print("GULL2 quest=%s sparks=%s pazar=%s flag=%s cam_current=%s exit=%s" % [d.quest_state(QUEST), d.sparks, d.has_flag("pirpir_pazar"), d.has_flag("bolum3_bitti"), ($Camera as Camera3D).current, ($Level/ExitSign as Node3D).visible])
			get_tree().quit()


func _walk_to(target: Vector3, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		var aim := target - _player.global_position
		aim.y = 0.0
		for a in ["move_left", "move_right", "move_forward", "move_back"]:
			Input.action_release(a)
		if aim.length() < 0.8:
			break
		var dir := aim.normalized()
		if dir.x > 0.2: Input.action_press("move_right", dir.x)
		if dir.x < -0.2: Input.action_press("move_left", -dir.x)
		if dir.z > 0.2: Input.action_press("move_back", dir.z)
		if dir.z < -0.2: Input.action_press("move_forward", -dir.z)
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	for a in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(a)


func _close_dialogs() -> void:
	await get_tree().create_timer(0.3).timeout
	while _hud._dialog.is_open():
		_hud._dialog.advance()
		await get_tree().create_timer(0.05).timeout

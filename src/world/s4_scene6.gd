extends Node3D
## Sezon 4 · Prolog · Sahne 6 – Alkış. Morning in the village square, among
## the Çiçek Yarışması decorations. Fıstık, Mırıl and Hırıl gather the
## keepers: "Bu sefer... başkası için sevinebilen bir kalp." A beat of
## silence (everyone was thinking of who would win the contest), then the
## little rabbit gardener Yonca steps forward. Then the seven-keeper select
## (KeeperSelect with Season 4's order and lines) and the prologue is done.

const KEEPER_Z := 0.0
## The seven keepers stand in a line this wide.
const LINE_WIDTH := 12.6
const GREEN := Color(0.62, 1.1, 0.6)
const START_ITEMS := {"nane_limonata": 3, "bal_surubu": 3}

var _keepers: Dictionary = {}   # id -> model node
var _order: Array = []
var _prev: Dictionary = {}      # Season 3's keeper {"id", "look"}: offered first
var _select: KeeperSelect
var _lv: Node3D
@onready var _hud: Hud = $Hud
@onready var _cam: Camera3D = $Camera
var _cam_home: Transform3D
var _cam_tween: Tween


func _ready() -> void:
	WorldLook.add(self, "sabah")
	Pus.set_color(GREEN)
	Pus.set_amount(0.18)
	_build_square()
	_cam.make_current()
	var d := GameState.data
	_order = (Content.keepers_s4.get("order", KeeperSelect.ORDER) as Array).duplicate()
	_prev = d.s3_keeper
	for i in _order.size():
		var id: String = _order[i]
		var look: Dictionary = _prev.get("look", {}) if _prev.get("id", "") == id else {}
		var m := KeeperModels.build(id, look)
		add_child(m)
		m.position = _slot(i)
		if id == "yonca":
			m.position = Vector3(9.5, 0, -3.2)   # by her flower bed until her beat
			m.rotation.y = -0.8
		_keepers[id] = m
	var f := FistikModel.build()
	add_child(f)
	f.position = Vector3(-8.0, 0, -1.4)
	f.rotation.y = 0.6
	var mi := MirilModel.star_child()
	MobModels._no_pus(mi)
	add_child(mi)
	mi.position = Vector3(-9.2, 0.4, 0.0)
	mi.rotation.y = 0.8
	var hi := HirilModel.build(true)
	MobModels._no_pus(hi)
	add_child(hi)
	hi.position = Vector3(-9.6, 0, -2.2)
	hi.rotation.y = 0.7
	await get_tree().create_timer(1.9, false).timeout
	if DevTools.demo == "select":
		open_select()   # straight to the seven cards (screenshot)
		return
	var cs := CutscenePlayer.new()
	cs.scene = self
	cs.camera = _cam
	cs.hud = _hud
	add_child(cs)
	cs.play("alkis")


## A simple village square dressed for the Çiçek Yarışması: houses and the
## fountain behind (north), stalls and flower beds to the sides, nothing
## tall south of the keepers' line.
func _build_square() -> void:
	_lv = Node3D.new()
	_lv.name = "Level"
	add_child(_lv)
	WorldLook.block(_lv, Vector3(0, -0.5, 0), Vector3(70, 1, 60), Color("#8fcf7a"), 0.0)
	var plaza := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 11.0
	disc.bottom_radius = 11.0
	disc.height = 0.04
	plaza.mesh = disc
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color("#e6d3a8")
	plaza.material_override = pm
	plaza.position = Vector3(0, 0.03, -1.0)
	_lv.add_child(plaza)
	for e: Array in [[-11.0, -10.5, 0.3], [-3.6, -12.5, 0.0], [3.8, -12.5, 0.0], [11.0, -10.5, -0.3]]:
		_prop("prop_house", Vector3(e[0], 0, e[1]), 5.2, e[2])
	_prop("bahar_cesmesi", Vector3(0, 0, -6.5), 3.4)
	_prop("pazar_tezgahi", Vector3(-12.5, 0, -4.5), 3.0, 0.9)
	_prop("pazar_tezgahi", Vector3(13.0, 0, -5.0), 3.0, -0.9)
	_prop("cicek_tarhi", Vector3(10.4, 0, -4.4), 1.2, 0.3)
	_prop("cicek_tarhi", Vector3(-5.2, 0, -5.6), 1.2)
	_prop("cicek_tarhi", Vector3(5.2, 0, -5.6), 1.2)
	var pots := ["lale", "papatya", "ay_cicegi", "saksi"]   # gul reads as a flat card here
	for i in 10:
		var x := -11.25 + i * 2.5
		_prop(pots[i % pots.size()], Vector3(x, 0, -3.6 - 0.25 * absf(x) * 0.3), 1.0 + 0.15 * (i % 3), i * 0.9)
	for x: float in [-16.0, 16.5]:
		_prop("prop_tree", Vector3(x, 0, -8.0), 6.0)
	# bunting between two poles, and the contest's board
	var cols := [Tokens.color("hp"), Tokens.color("honey"), Tokens.color("sky"), Tokens.color("spark-green"), Tokens.color("spark-purple")]
	for side: float in [-1.0, 1.0]:
		Toon.part(_lv, "cylinder", Vector3(0.16, 4.4, 0.16), Color("#a8794f"), Vector3(side * 7.5, 2.2, -8.2))
	for i in 15:
		var k := i / 14.0
		var sag := 0.7 * sin(k * PI)
		Toon.part(_lv, "cone", Vector3(0.42, 0.5, 0.08), cols[i % cols.size()], Vector3(lerpf(-7.5, 7.5, k), 4.1 - sag, -8.2), Vector3(180, 0, 0), 0.0, 0.02, 0.0)
	TravelSign.board(_lv, "Çiçek Yarışması", Vector3(6.8, 0, -4.6), 3.2)


func _prop(id: String, at: Vector3, h: float, yaw := 0.0) -> Node3D:
	var m := ModelImport.prop_copy(id)
	if m == null:
		return null
	var b := ModelImport.static_bounds(id)
	var s := h / maxf(b.size.y, 0.01)
	var holder := Node3D.new()
	_lv.add_child(holder)
	holder.position = at
	holder.rotation.y = yaw
	holder.add_child(m)
	m.scale = Vector3.ONE * s
	m.position = -Vector3(b.position.x + b.size.x * 0.5, b.position.y, b.position.z + b.size.z * 0.5) * s
	return holder


## Where keeper `i` of the line stands.
func _slot(i: int) -> Vector3:
	var n := maxi(_order.size(), 2)
	return Vector3((float(i) / (n - 1) - 0.5) * LINE_WIDTH, 0, KEEPER_Z)


func _process(_delta: float) -> void:
	for id: String in _keepers:
		var m: Node3D = _keepers[id]
		if _select and _select.current == id:
			m.position.y = absf(sin(Time.get_ticks_msec() / 160.0)) * 0.15
		elif is_instance_valid(m):
			m.position.y = move_toward(m.position.y, 0.0, 0.02)


# --- beats -------------------------------------------------------------

## Nobody answers: the keepers look at their feet, then at each other.
func silence() -> void:
	var i := 0
	for id: String in _keepers:
		if id == "yonca":
			continue
		var m: Node3D = _keepers[id]
		var tw := create_tween()
		tw.tween_interval(0.2 + 0.12 * i)
		tw.tween_property(m, "rotation:y", 0.45 if i % 2 == 0 else -0.45, 0.4)
		tw.tween_interval(0.7)
		tw.tween_property(m, "rotation:y", 0.0, 0.4)
		i += 1


## Yonca steps into the line.
func yonca_steps() -> void:
	var i := _order.find("yonca")
	var m: Node3D = _keepers.get("yonca")
	if m == null:
		return
	var to := _slot(i)
	var rig := CharacterRig.of(m)
	if rig:
		rig.speed = 1.0
	var tw := create_tween()
	tw.tween_property(m, "position", to, 1.8)
	tw.tween_callback(func() -> void:
		if rig:
			rig.speed = 0.0
		m.rotation.y = 0.0
		Effects.sparkle(self, to + Vector3.UP, Tokens.color("spark-green"), 10))


func open_select() -> void:
	await get_tree().process_frame  # after the cutscene hands the HUD back
	_hud.cinematic(true)
	var yi := _order.find("yonca")
	if yi >= 0 and _keepers.has("yonca"):
		(_keepers["yonca"] as Node3D).position = _slot(yi)
		(_keepers["yonca"] as Node3D).rotation.y = 0.0
	_cam_home = _cam.global_transform
	_select = KeeperSelect.new()
	_select.order = _order
	_select.lines = Content.keepers_s4.get("lines", {})
	_hud.add_child(_select)
	_select.highlighted.connect(_on_highlight)
	_select.look_changed.connect(_on_look)
	_select.chosen.connect(_on_chosen)
	if DevTools.demo == "select":
		_select.select("yonca")
		return
	if DevTools.demo.begins_with("pick_"):
		var who := DevTools.demo.substr(5)
		_select.select(who)
		await get_tree().create_timer(1.0, false).timeout
		_select.chosen.emit(who, {}, String(Content.keeper(who).get("name", who)))
		return
	var back: String = _prev.get("id", "")
	if back in _order:
		_select.select(back)  # Season 3's keeper is the first one offered


func _on_highlight(id: String) -> void:
	var i := _order.find(id)
	_focus_camera(id)
	for k: String in _keepers:
		var m: Node3D = _keepers[k]
		var t2 := create_tween()
		t2.tween_property(m, "rotation:y", 0.0 if k == id else (0.5 if m.position.x < _slot(i).x else -0.5), 0.3)


func _on_look(id: String, look: Dictionary) -> void:
	var old: Node3D = _keepers[id]
	var m := KeeperModels.build(id, look)
	add_child(m)
	m.position = old.position
	old.queue_free()
	_keepers[id] = m


func _on_chosen(id: String, look: Dictionary, display_name: String) -> void:
	_select.queue_free()
	_select = null
	var d := GameState.data
	if look.is_empty() and _prev.get("id", "") == id:
		look = _prev.get("look", {})
	# the prologue's level-ups were Tırıl's: the keeper sets out fresh
	d.powers = {}
	d.power_picks = 0
	d.level = 1
	d.xp = 0
	d.choose_keeper(id, Content.keeper(id)["stats"], look, display_name)
	d.recompute_stats(Content.items)
	d.hp = d.max_hp
	d.mp = d.max_mp
	if not d.has_flag("s4_prolog_bitti"):
		for item: String in START_ITEMS:
			d.add_item(item, START_ITEMS[item])
	d.set_flag("s4_prolog_bitti")
	d.scene_id = "s4_chapter0"  # Devam et goes on from Sera Kasabası, not this choice again
	SaveGame.write(d)
	var m: Node3D = _keepers[id]
	Effects.ring(self, m.global_position + Vector3.UP * 0.2, 3.0, Tokens.color("spark-green"), 0.5)
	Effects.sparkle(self, m.global_position + Vector3.UP, Tokens.color("honey"), 14)
	Audio.play("fanfare")
	_hud.cinematic(false)
	if Content.barks.has("s4b_sec_" + id):
		GameState.bark("s4b_sec_" + id)
		await GameState.dialogue_closed
	GameState.bark("s4b_sec_son")
	await GameState.dialogue_closed
	if DevTools.demo.begins_with("pick_") and DisplayServer.get_name() == "headless":
		print("S4B6_PICK id=%s name=%s level=%d skill=%s flag=%s season=%d model=%s next=%s items=%d/%d hp=%d/%d cards=%d" % [
			d.character_id, d.character_name, d.level, d.active_skill(), d.has_flag("s4_prolog_bitti"), d.season,
			ModelImport.path_for(d.character_id).get_file(), d.scene_id, d.item_count("nane_limonata"), d.item_count("bal_surubu"),
			d.hp, d.max_hp, _order.size()])
		get_tree().quit()
		return
	var panel := PrologueDone.new()
	_hud.add_child(panel)
	var to: String = await panel.chosen
	SceneFlow.go_to(to, to != "title")


func _focus_camera(id: String) -> void:
	var m: Node3D = _keepers.get(id)
	if m == null:
		return
	var at := m.global_position
	var home := _cam_home
	var from := home.origin + Vector3((at.x - home.origin.x) * 0.35, 0.5, -1.2)
	var look := Transform3D(Basis(), from).looking_at(at + Vector3(0, -0.6, 0), Vector3.UP)
	var target := Transform3D(home.basis.slerp(look.basis, 0.45), from)
	if _cam_tween:
		_cam_tween.kill()
	_cam_tween = create_tween()
	_cam_tween.tween_property(_cam, "global_transform", target, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

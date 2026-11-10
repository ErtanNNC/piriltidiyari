extends Node3D
## Sezon 3 · Prolog · Sahne 6 – El Ele. Morning on the beach; the Fener's
## light can't get through the Mavi Titreme. Fıstık and Mırıl gather the
## keepers by the Kabuk Kayık: "This time... a hand is needed." Tosbi steps
## forward, trembling but sure. Then the six-keeper select (KeeperSelect
## with Season 3's order and lines) and the prologue is done.

const KEEPER_X := [-5.5, -3.3, -1.1, 1.1, 3.3, 5.5]
const KEEPER_Z := 0.0
const BLUE := Color(0.7, 0.86, 1.25)

var _keepers: Dictionary = {}   # id -> model node
var _order: Array = []
var _select: KeeperSelect
@onready var _hud: Hud = $Hud
@onready var _cam: Camera3D = $Camera
var _cam_home: Transform3D
var _cam_tween: Tween


func _ready() -> void:
	WorldLook.add(self, "sabah")
	Pus.set_color(BLUE)
	Pus.set_amount(0.25)
	S3Beach.build_beach(self)
	_cam.make_current()
	_order = Content.keepers_s3.get("order", KeeperSelect.ORDER)
	var d := GameState.data
	for i in _order.size():
		var id: String = _order[i]
		var look: Dictionary = d.s2_keeper.get("look", {}) if d.s2_keeper.get("id", "") == id else {}
		var m := KeeperModels.build(id, look)
		add_child(m)
		m.position = Vector3(KEEPER_X[i], 0, KEEPER_Z)
		if id == "tosbi":
			m.position = Vector3(8.0, 0, -3.0)   # hangs back until his beat
			m.rotation.y = -0.8
		_keepers[id] = m
	var f := FistikModel.build()
	add_child(f)
	f.position = Vector3(-7.4, 0, -1.6)
	f.rotation.y = 0.6
	var mi := MirilModel.star_child()
	MobModels._no_pus(mi)
	add_child(mi)
	mi.position = Vector3(-8.6, 0.4, -0.2)
	mi.rotation.y = 0.8
	var nine := NpcModels.build("turtle")
	add_child(nine)
	nine.position = Vector3(8.4, 0, -0.8)
	nine.rotation.y = -0.7
	# the drum Hırıl left, still beating slowly
	var drum := Node3D.new()
	Toon.part(drum, "cylinder", Vector3(0.9, 0.6, 0.9), Color("#c9452f"), Vector3(0, 0.3, 0))
	Toon.part(drum, "cylinder", Vector3(0.95, 0.08, 0.95), Color("#fff1dc"), Vector3(0, 0.62, 0))
	add_child(drum)
	drum.position = Vector3(0, 0, -5.5)
	_beat(drum)
	await get_tree().create_timer(1.9).timeout
	var cs := CutscenePlayer.new()
	cs.scene = self
	cs.camera = _cam
	cs.hud = _hud
	add_child(cs)
	cs.play("el_ele")


func _beat(drum: Node3D) -> void:
	while is_inside_tree():
		Effects.ring(self, drum.position + Vector3.UP * 0.4, 2.2, Tokens.color("hp"), 0.6)
		var tw := create_tween()
		tw.tween_property(drum, "scale", Vector3(1.1, 0.9, 1.1), 0.08)
		tw.tween_property(drum, "scale", Vector3.ONE, 0.2)
		await get_tree().create_timer(1.1).timeout


func _process(_delta: float) -> void:
	for id: String in _keepers:
		var m: Node3D = _keepers[id]
		if _select and _select.current == id:
			m.position.y = absf(sin(Time.get_ticks_msec() / 160.0)) * 0.15
		elif is_instance_valid(m):
			m.position.y = move_toward(m.position.y, 0.0, 0.02)


# --- beats -------------------------------------------------------------

## Tosbi steps into the line: trembling, but he steps.
func tosbi_steps() -> void:
	var i := _order.find("tosbi")
	var m: Node3D = _keepers["tosbi"]
	var to := Vector3(KEEPER_X[i], 0, KEEPER_Z)
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
	_cam_home = _cam.global_transform
	_select = KeeperSelect.new()
	_select.order = _order
	_select.lines = Content.keepers_s3.get("lines", {})
	_hud.add_child(_select)
	_select.highlighted.connect(_on_highlight)
	_select.look_changed.connect(_on_look)
	_select.chosen.connect(_on_chosen)
	var back: String = GameState.data.s2_keeper.get("id", "")
	if DevTools.demo.begins_with("pick_"):
		var who := DevTools.demo.substr(5)
		_select.select(who)
		await get_tree().create_timer(1.0).timeout
		_select.chosen.emit(who, {}, String(Content.keeper(who).get("name", who)))
		return
	if back in _order:
		_select.select(back)  # Season 2's keeper is the first one offered


func _on_highlight(id: String) -> void:
	var i := _order.find(id)
	_focus_camera(id)
	for k: String in _keepers:
		var m: Node3D = _keepers[k]
		var t2 := create_tween()
		t2.tween_property(m, "rotation:y", 0.0 if k == id else (0.5 if m.position.x < KEEPER_X[i] else -0.5), 0.3)


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
	if look.is_empty() and d.s2_keeper.get("id", "") == id:
		look = d.s2_keeper.get("look", {})
	# the prologue's level-ups were Hırıl's: the keeper sets out fresh
	d.powers = {}
	d.power_picks = 0
	d.choose_keeper(id, Content.keeper(id)["stats"], look, display_name)
	d.recompute_stats(Content.items)
	d.hp = d.max_hp
	d.set_flag("s3_prolog_bitti")
	SaveGame.write(d)
	var m: Node3D = _keepers[id]
	Effects.ring(self, m.global_position + Vector3.UP * 0.2, 3.0, Tokens.color("sky"), 0.5)
	Effects.sparkle(self, m.global_position + Vector3.UP, Tokens.color("honey"), 14)
	_hud.cinematic(false)
	GameState.bark("s6c_son")
	await GameState.dialogue_closed
	if DevTools.demo.begins_with("pick_") and DisplayServer.get_name() == "headless":
		print("S6C_PICK id=%s name=%s level=%d skill=%s flag=%s season=%d" % [d.character_id, d.character_name, d.level, d.active_skill(), d.has_flag("s3_prolog_bitti"), d.season])
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

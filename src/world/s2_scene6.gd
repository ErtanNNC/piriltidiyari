extends Node3D
## Sezon 2 · Prolog · Sahne 6 – Kulak Bekçileri. Morning in the village;
## the Fener has lost its sixth color. Fıstık (awake now) gathers the
## keepers: their Sparks stay in the Fener, so they set out without their
## power (level 1). Tıpış, a little red panda, runs in from the mountain
## road: they know the way. Four village friends join the trip
## (`companions_arrive`). Then the five-keeper select (KeeperSelect with
## Season 2's order and lines) and the prologue is done.

const KEEPER_X := [-4.4, -2.2, 0.0, 2.2, 4.4]
const KEEPER_Z := -8.0
## The friends who come along: Tospik Nine, Madenci Kazma, Terzi Dikiş, Pırpır.
const COMPANIONS := ["turtle", "mole", "spider", "gull_captain"]

var _keepers: Dictionary = {}   # id -> model node
var _order: Array = []
var _select: KeeperSelect
var _tipis: Node3D
@onready var _hud: Hud = $Hud
@onready var _cam: Camera3D = $Camera
var _cam_home: Transform3D
var _cam_tween: Tween


func _ready() -> void:
	Pus.set_color(Pus.RED)
	Pus.set_amount(0.1)
	_cam.make_current()
	_order = Content.keepers_s2.get("order", KeeperSelect.ORDER)
	var d := GameState.data
	for i in _order.size():
		var id: String = _order[i]
		if id == "tipis_panda":
			continue  # arrives during the scene
		var look: Dictionary = d.s1_keeper.get("look", {}) if d.s1_keeper.get("id", "") == id else {}
		var m := KeeperModels.build(id, look)
		add_child(m)
		m.position = Vector3(KEEPER_X[i], 0, KEEPER_Z)
		_keepers[id] = m
	var f := FistikModel.build()
	add_child(f)
	f.position = Vector3(-6.4, 0, -10.6)
	f.rotation.y = 0.5
	await get_tree().create_timer(1.9, false).timeout
	var cs := CutscenePlayer.new()
	cs.scene = self
	cs.camera = _cam
	cs.hud = _hud
	add_child(cs)
	cs.play("kulak_bekcileri")


func _process(_delta: float) -> void:
	for id: String in _keepers:
		var m: Node3D = _keepers[id]
		if _select and _select.current == id:
			m.position.y = absf(sin(Time.get_ticks_msec() / 160.0)) * 0.15
		elif is_instance_valid(m):
			m.position.y = move_toward(m.position.y, 0.0, 0.02)


# --- beats -------------------------------------------------------------

## Tıpış runs in from the road and joins the line.
func tipis_arrives() -> void:
	var i := _order.find("tipis_panda")
	_tipis = KeeperModels.build("tipis_panda")
	add_child(_tipis)
	_tipis.position = Vector3(6.0, 0, 6.0)
	_tipis.rotation.y = PI
	_keepers["tipis_panda"] = _tipis
	var to := Vector3(KEEPER_X[i], 0, KEEPER_Z)
	var rig := CharacterRig.of(_tipis)
	if rig:
		rig.speed = 1.0
	var tw := create_tween()
	tw.tween_property(_tipis, "position", to, 2.2)
	tw.tween_callback(func() -> void:
		if rig:
			rig.speed = 0.0
		_tipis.rotation.y = 0.0
		Effects.sparkle(self, to + Vector3.UP, Tokens.color("hp"), 10))


## The village friends who travel along (Season 2's helpers in Kor Vadisi):
## Tospik Nine, Madenci Kazma, Terzi Dikiş and Kaptan Pırpır walk up behind.
func companions_arrive() -> void:
	for i in COMPANIONS.size():
		var kind: String = COMPANIONS[i]
		var m := NpcModels.build(kind)
		add_child(m)
		var to := Vector3(-5.6 + i * 2.6, 0, -12.6)
		m.position = to + Vector3(-7.0, 0, 3.0)
		m.rotation.y = PI * 0.5
		var rig := CharacterRig.of(m)
		if rig:
			rig.speed = 1.0
		var tw := create_tween()
		tw.tween_interval(i * 0.25)
		tw.tween_property(m, "position", to, 1.6)
		tw.tween_callback(func() -> void:
			if rig:
				rig.speed = 0.0
			m.rotation.y = 0.0)


func open_select() -> void:
	await get_tree().process_frame  # after the cutscene hands the HUD back
	_hud.cinematic(true)
	_cam_home = _cam.global_transform
	_select = KeeperSelect.new()
	_select.order = _order
	_select.lines = Content.keepers_s2.get("lines", {})
	_hud.add_child(_select)
	_select.highlighted.connect(_on_highlight)
	_select.look_changed.connect(_on_look)
	_select.chosen.connect(_on_chosen)
	var back: String = GameState.data.s1_keeper.get("id", "")
	if DevTools.demo.begins_with("pick_"):
		var who := DevTools.demo.substr(5)
		_select.select(who)
		await get_tree().create_timer(1.0, false).timeout
		_select.chosen.emit(who, {}, String(Content.keeper(who).get("name", who)))
		return
	if back in _order:
		_select.select(back)  # Season 1's keeper is the first one offered


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
	# Season 1's keeper keeps their old colors unless new ones were picked
	if look.is_empty() and d.s1_keeper.get("id", "") == id:
		look = d.s1_keeper.get("look", {})
	# the prologue's level-ups were Mırıl's: the keeper sets out fresh
	d.powers = {}
	d.power_picks = 0
	d.choose_keeper(id, Content.keeper(id)["stats"], look, display_name)
	d.recompute_stats(Content.items)
	d.hp = d.max_hp
	d.set_flag("s2_prolog_bitti")
	SaveGame.write(d)
	var m: Node3D = _keepers[id]
	Effects.ring(self, m.global_position + Vector3.UP * 0.2, 3.0, Tokens.color("hp"), 0.5)
	Effects.sparkle(self, m.global_position + Vector3.UP, Tokens.color("honey"), 14)
	_hud.cinematic(false)
	GameState.bark("s6b_son")
	await GameState.dialogue_closed
	if DevTools.demo.begins_with("pick_") and DisplayServer.get_name() == "headless":
		print("S6B_PICK id=%s name=%s level=%d skill=%s flag=%s look=%s" % [d.character_id, d.character_name, d.level, d.active_skill(), d.has_flag("s2_prolog_bitti"), d.character_look])
		get_tree().quit()
		return
	_prologue_done()


## The prologue is over; Bölüm 0 (Buharlı Kaplıca Köyü) comes next.
func _prologue_done() -> void:
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

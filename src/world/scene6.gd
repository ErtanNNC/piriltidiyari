extends Node3D
## Prolog · Sahne 6 – Fener'in Seçimi. Morning; the village is grey but
## safe. Tospik Nine speaks, the last little spark picks its keeper: the
## character select (KeeperSelect), then customization and the main story.

const KEEPER_X := [-3.3, -1.1, 1.1, 3.3]
const KEEPER_Z := -8.0

var _keepers: Dictionary = {}   # id -> model node
var _spark: MeshInstance3D
var _select: KeeperSelect
@onready var _hud: Hud = $Hud
@onready var _cam: Camera3D = $Camera


func _ready() -> void:
	Pus.set_amount(0.3)
	_cam.make_current()
	for i in KeeperSelect.ORDER.size():
		var id: String = KeeperSelect.ORDER[i]
		var m := KeeperModels.build(id)
		add_child(m)
		m.position = Vector3(KEEPER_X[i], 0, KEEPER_Z)
		_keepers[id] = m
	_spark = Toon.part(self, "sphere", Vector3(0.45, 0.6, 0.45), "honey", Vector3(0, 0.6, -11.2), Vector3.ZERO, 2.0, 0.03)
	var l := OmniLight3D.new()
	l.light_color = Tokens.color("honey")
	l.omni_range = 3.0
	l.light_energy = 1.5
	_spark.add_child(l)
	var statue := FistikModel.build(true)
	add_child(statue)
	statue.position = Vector3(-4.6, 1.0, -12.6)
	statue.rotation.y = 0.35
	Toon.part(self, "cylinder", Vector3(1.6, 1.0, 1.8), Color("#b9b0a4"), Vector3(-4.6, 0.5, -12.6))
	await get_tree().create_timer(1.9).timeout
	var cs := CutscenePlayer.new()
	cs.scene = self
	cs.camera = _cam
	cs.hud = _hud
	add_child(cs)
	cs.play("fenerin_secimi")


func _process(delta: float) -> void:
	if _spark:
		_spark.rotation.y += delta * 2.0
	for id: String in _keepers:
		var m: Node3D = _keepers[id]
		if _select and _select.current == id:
			m.position.y = absf(sin(Time.get_ticks_msec() / 160.0)) * 0.15
		else:
			m.position.y = move_toward(m.position.y, 0.0, delta)


# --- beats -------------------------------------------------------------

func spark_wakes() -> void:
	var tw := create_tween()
	tw.tween_property(_spark, "position", Vector3(0, 2.2, -9.6), 1.2).set_trans(Tween.TRANS_BACK)
	Effects.sparkle(self, _spark.global_position, Tokens.color("honey"), 12)


func open_select() -> void:
	await get_tree().process_frame  # after the cutscene hands the HUD back
	_hud.cinematic(true)
	_select = KeeperSelect.new()
	_hud.add_child(_select)
	_select.highlighted.connect(_on_highlight)
	_select.look_changed.connect(_on_look)
	_select.chosen.connect(_on_chosen)
	if DevTools.demo == "choose":
		_select.select("lumi")
		await get_tree().create_timer(0.5).timeout
		_select.chosen.emit("lumi", {"variant": 1, "accessory": "atki"}, "Işıltı")
		return
	if DevTools.demo.begins_with("pick_"):
		_select.select(DevTools.demo.substr(5).trim_suffix("_cards"))
		if DevTools.auto_dialogue and not DevTools.demo.ends_with("_cards"):
			await get_tree().create_timer(1.0).timeout
			_select._open_custom()


func _on_highlight(id: String) -> void:
	var i := KeeperSelect.ORDER.find(id)
	var to := Vector3(KEEPER_X[i], 2.6, KEEPER_Z)
	var tw := create_tween()
	tw.tween_property(_spark, "position", to, 0.45).set_trans(Tween.TRANS_BACK)
	Effects.sparkle(self, to, Tokens.color("honey"), 8)
	for k: String in _keepers:
		var m: Node3D = _keepers[k]
		var t2 := create_tween()
		t2.tween_property(m, "rotation:y", 0.0 if k == id else (0.5 if m.position.x < to.x else -0.5), 0.3)


func _on_look(id: String, look: Dictionary) -> void:
	var old: Node3D = _keepers[id]
	var m := KeeperModels.build(id, look)
	add_child(m)
	m.position = old.position
	old.queue_free()
	_keepers[id] = m


func _on_chosen(id: String, look: Dictionary, display_name: String) -> void:
	_select.queue_free()
	var d := GameState.data
	d.choose_keeper(id, Content.keepers[id]["stats"], look, display_name)
	d.set_flag("prolog_bitti")
	# the chosen keeper takes the spark in their hands
	var tw := create_tween()
	tw.tween_property(_spark, "global_position", (_keepers[id] as Node3D).global_position + Vector3(0, 0.75, 0.45), 0.6)
	await tw.finished
	Effects.ring(self, _spark.global_position, 3.0, Tokens.color("honey"), 0.5)
	_spark.visible = false
	_hud.cinematic(false)
	_hud.show_scene_card("Yeni bekçi", display_name, "Kıvılcım avucunda. Macera başlıyor!")
	await get_tree().create_timer(3.4).timeout
	SceneFlow.go_to("chapter0")

class_name ShiverVeil
extends Node3D
## Season 3: a Titreme Perdesi, a wall of thick blue mist across a path. It
## opens for good (`open_flag`) when you walk up to it hand in hand
## (`hand_only`), or when the scene calls `open()` (a flare, a quest).

signal opened

@export var open_flag := ""
@export var width := 8.0
@export var hand_only := true
@export var hint := "Sis çok koyu. El ele tutuşunca geçilir."
var is_open := false
var _body: StaticBody3D
var _mist: Node3D
var _told := 0.0


func _ready() -> void:
	_mist = Node3D.new()
	add_child(_mist)
	var n := int(width / 1.6) + 1
	for i in n:
		var x := -width * 0.5 + width * i / float(maxi(n - 1, 1))
		var puff := Toon.part(_mist, "sphere", Vector3(2.4, 3.4, 2.0), Color(0.55, 0.72, 1.0), Vector3(x, 1.5 + (i % 2) * 0.4, 0), Vector3.ZERO, 0.5, 0.0)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.6, 0.78, 1.0, 0.55)
		puff.material_override = mat
		puff.set_meta("phase", randf() * TAU)
	_body = StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(width, 6.0, 1.0)
	c.shape = b
	c.position.y = 3.0
	_body.add_child(c)
	add_child(_body)
	if open_flag != "" and GameState.data.has_flag(open_flag):
		_clear()


func _process(delta: float) -> void:
	if is_open:
		return
	var t := Time.get_ticks_msec() / 1000.0
	for puff: Node3D in _mist.get_children():
		puff.position.y = 1.6 + sin(t * 0.9 + float(puff.get_meta("phase"))) * 0.25
	_told = maxf(_told - delta, 0.0)
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null:
		return
	var local := to_local(p.global_position)
	if absf(local.x) < width * 0.5 + 0.5 and absf(local.z) < 2.4:
		if hand_only and p.ring and p.ring.holding_hands:
			open()
		elif _told <= 0.0 and not GameState.in_dialogue:
			_told = 6.0
			GameState.toast.emit(hint, "spark")


func open() -> void:
	if is_open:
		return
	if open_flag != "":
		GameState.data.set_flag(open_flag)
	Audio.play("whoosh")
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.3, width * 0.6, Color(1.0, 0.85, 0.5), 0.6)
	var tw := create_tween()
	tw.tween_property(_mist, "scale", Vector3(1.0, 0.02, 1.0), 1.0)
	tw.tween_callback(_clear)
	is_open = true
	_body.queue_free()
	opened.emit()


func _clear() -> void:
	is_open = true
	if is_instance_valid(_body):
		_body.queue_free()
	_mist.queue_free()

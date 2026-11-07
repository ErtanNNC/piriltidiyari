class_name PusGate
extends Node3D
## A Pus curtain across a gap. While closed you can't pass and get the
## design system's line "Fener henüz yanmadı". open() lifts it smoothly.

@export var width := 3.4
@export var message := "Fener henüz yanmadı"
var is_open := false
var _body: StaticBody3D
var _puffs: Array[MeshInstance3D] = []
var _last_msg := -10.0


func _ready() -> void:
	_body = StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(width, 5.0, 0.8)
	c.shape = b
	c.position.y = 2.5
	_body.add_child(c)
	add_child(_body)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Tokens.color("pus")
	mat.albedo_color.a = 0.75
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 5:
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.9
		s.height = 1.8
		mi.mesh = s
		mi.material_override = mat
		mi.position = Vector3(-width * 0.5 + (i + 0.5) * width / 5.0, 0.8 + (i % 2) * 0.9, 0)
		mi.scale = Vector3(1.0, 1.4, 0.8)
		add_child(mi)
		_puffs.append(mi)
		var tw := mi.create_tween().set_loops()
		tw.tween_property(mi, "position:y", mi.position.y + 0.3, 1.6 + i * 0.2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(mi, "position:y", mi.position.y, 1.6 + i * 0.2).set_trans(Tween.TRANS_SINE)
	var sense := Area3D.new()
	sense.collision_layer = 0
	sense.collision_mask = 1
	var sc := CollisionShape3D.new()
	var sb := BoxShape3D.new()
	sb.size = Vector3(width + 1.0, 4.0, 3.0)
	sc.shape = sb
	sc.position.y = 2.0
	sense.add_child(sc)
	add_child(sense)
	sense.body_entered.connect(func(body: Node3D) -> void:
		if not is_open and body.is_in_group("player") and Time.get_ticks_msec() / 1000.0 - _last_msg > 3.0:
			_last_msg = Time.get_ticks_msec() / 1000.0
			GameState.toast.emit(message, "lantern"))


func open() -> void:
	if is_open:
		return
	is_open = true
	_body.queue_free()
	for mi in _puffs:
		var tw := mi.create_tween()
		tw.tween_property(mi, "scale", Vector3.ZERO, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(mi.queue_free)

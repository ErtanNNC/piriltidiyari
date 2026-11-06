class_name FollowCamera
extends Camera3D
## 3rd-person follow camera from the design doc: about 50° from above and
## slightly behind. The player never rotates it.

@export var target_path: NodePath
@export_range(20.0, 80.0) var pitch_degrees := 50.0
@export var distance := 14.0
@export var look_height := 0.8
@export var smoothing := 6.0

var _target: Node3D


func _ready() -> void:
	_target = get_node_or_null(target_path)
	fov = 45.0
	if _target:
		global_position = _desired_position()
		look_at(_target.global_position + Vector3.UP * look_height)


func _physics_process(delta: float) -> void:
	if not _target:
		return
	var t := 1.0 - exp(-smoothing * delta)
	global_position = global_position.lerp(_desired_position(), t)
	look_at(global_position + _offset() * -1.0)


func _offset() -> Vector3:
	var p := deg_to_rad(pitch_degrees)
	return Vector3(0.0, sin(p), cos(p)) * distance


func _desired_position() -> Vector3:
	return _target.global_position + Vector3.UP * look_height + _offset()

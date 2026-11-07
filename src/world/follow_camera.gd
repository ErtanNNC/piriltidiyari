class_name FollowCamera
extends Camera3D
## 3rd-person follow camera from the design doc: about 50° from above and
## slightly behind. The player never rotates it.

@export var target_path: NodePath
@export_range(20.0, 80.0) var pitch_degrees := 50.0
@export var distance := 14.0
@export var look_height := 0.8
@export var smoothing := 6.0
## Boss fights: look between the player and this point to keep both in view.
@export var anchor := Vector3.ZERO
@export_range(0.0, 1.0) var anchor_weight := 0.0

var _target: Node3D
var _shake := 0.0


## Small screen shake (hits, landings); fades by itself.
func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = move_toward(_shake, 0.0, delta * 1.2)
		h_offset = randf_range(-1.0, 1.0) * _shake
		v_offset = randf_range(-1.0, 1.0) * _shake
	elif h_offset != 0.0 or v_offset != 0.0:
		h_offset = 0.0
		v_offset = 0.0


func _ready() -> void:
	_target = get_node_or_null(target_path)
	fov = 45.0
	if _target:
		global_position = _desired_position()
		look_at(global_position - _offset())


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
	var focus := _target.global_position.lerp(anchor, anchor_weight)
	return focus + Vector3.UP * look_height + _offset()

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
## Screen shake as decaying "trauma" (0..1); the shake is trauma², so small
## bumps barely move the view and big hits really punch (game-feel skill).
var trauma := 0.0
var _shake_t := 0.0
const SHAKE_MAX := 0.32       # meters of offset at full trauma
const MIN_DISTANCE := 3.5     # never closer than this when a wall is in the way
## Turn around the keeper (Q / R keys, "Çevir" button) to see behind walls.
var yaw := 0.0
var _yaw_target := 0.0


## Turn the view by 90° steps (dir -1 / +1), smoothly.
func turn(dir: int) -> void:
	_yaw_target += dir * PI * 0.5


## Touch drag: turn around the keeper freely and tilt the view a little.
func drag(d_yaw: float, d_pitch: float) -> void:
	_yaw_target -= d_yaw
	yaw = _yaw_target
	pitch_degrees = clampf(pitch_degrees + d_pitch, 32.0, 72.0)


## Add screen shake (hits add up; it fades by itself).
func shake(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	yaw = lerp_angle(yaw, _yaw_target, 1.0 - exp(-8.0 * delta))
	if trauma > 0.0:
		trauma = maxf(trauma - 1.6 * delta, 0.0)
		var amt := trauma * trauma * SHAKE_MAX
		_shake_t += delta * 32.0
		# smooth wobble (sines), not a random buzz every frame
		h_offset = amt * sin(_shake_t * 1.7)
		v_offset = amt * sin(_shake_t * 2.3 + 1.0)
	elif h_offset != 0.0 or v_offset != 0.0:
		h_offset = 0.0
		v_offset = 0.0


func _ready() -> void:
	_target = get_node_or_null(target_path)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--turn="):  # screenshot helper: start turned by N × 90°
			_yaw_target = int(arg.get_slice("=", 1)) * PI * 0.5
			yaw = _yaw_target
	fov = 45.0
	if _target:
		global_position = _desired_position()
		look_at(global_position - _offset())


func _physics_process(delta: float) -> void:
	if not _target:
		return
	var want := _desired_position()
	var focus := want - _offset()
	# a wall between the keeper and the camera: slide in front of it
	var clear := _clear_point(focus, want)
	var blocked := clear.distance_to(want) > 0.05
	var t := 1.0 - exp(-(smoothing * 2.5 if blocked else smoothing) * delta)
	global_position = global_position.lerp(clear, t)
	look_at(focus)


## Walls only (layer 1). Invisible guide walls, world edges and anything
## marked "camera_ignore" don't push the camera.
func _clear_point(focus: Vector3, want: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var exclude: Array[RID] = []
	if _target is CollisionObject3D:
		exclude.append((_target as CollisionObject3D).get_rid())
	for i in 4:
		var q := PhysicsRayQueryParameters3D.create(focus, want, 1, exclude)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return want
		var col: Object = hit["collider"]
		if col is CollisionObject3D and (col.has_meta("camera_ignore") or _is_boundary(col)):
			exclude.append(hit["rid"])
			continue
		var dir := (want - focus).normalized()
		var dist := maxf(focus.distance_to(hit["position"]) - 0.4, MIN_DISTANCE)
		return focus + dir * dist
	return want


static func _is_boundary(col: CollisionObject3D) -> bool:
	for c in col.get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape is WorldBoundaryShape3D:
			return true
	return false


func _offset() -> Vector3:
	var p := deg_to_rad(pitch_degrees)
	return (Vector3(0.0, sin(p), cos(p)) * distance).rotated(Vector3.UP, yaw)


func _desired_position() -> Vector3:
	var focus := _target.global_position.lerp(anchor, anchor_weight)
	return focus + Vector3.UP * look_height + _offset()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cam_left"):
		turn(-1)
	elif event.is_action_pressed("cam_right"):
		turn(1)

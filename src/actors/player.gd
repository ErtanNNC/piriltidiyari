class_name Player
extends CharacterBody3D
## Fıstık in the prologue (later: the chosen keeper). Moves on the ground
## plane relative to the fixed camera, jumps, does a quill spin and talks.

signal focus_changed(target: Node)

@export var speed := 6.0
@export var acceleration := 40.0
@export var jump_velocity := 7.5
@export var gravity := 22.0

var input_enabled := true
var model: Node3D
var _focus: Node = null
var _spin_tween: Tween
var _bob_time := 0.0
var _nearby: Array[Area3D] = []


func _ready() -> void:
	add_to_group("player")
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.3
	col.shape = cap
	col.position.y = 0.65
	add_child(col)
	model = FistikModel.build()
	add_child(model)
	var sensor := Area3D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 4  # interactables
	sensor.monitorable = false
	var sc := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.8
	sc.shape = sphere
	sensor.add_child(sc)
	add_child(sensor)
	sensor.area_entered.connect(func(a: Area3D) -> void: _nearby.append(a))
	sensor.area_exited.connect(func(a: Area3D) -> void: _nearby.erase(a))


func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	if input_enabled:
		var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		dir = Vector3(v.x, 0.0, v.y)
	var target := dir * speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	if is_on_floor():
		if input_enabled and Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	else:
		velocity.y -= gravity * delta
	move_and_slide()
	if dir.length() > 0.1:
		var want := atan2(-dir.x, -dir.z) + PI  # model's face points +Z
		model.rotation.y = lerp_angle(model.rotation.y, want, 1.0 - exp(-14.0 * delta))
		_bob_time += delta * 14.0
		model.position.y = abs(sin(_bob_time)) * 0.12
	else:
		model.position.y = move_toward(model.position.y, 0.0, delta)
	_update_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event.is_action_pressed("interact") and _focus:
		interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("attack"):
		spin_attack()


func current_focus() -> Node:
	return _focus


func interact() -> void:
	if _focus and _focus.has_method("interact"):
		_focus.interact(self)


## Basic quill attack: a quick spin. Damage arrives with the first mobs (Sahne 2).
func spin_attack() -> void:
	if _spin_tween and _spin_tween.is_running():
		return
	_spin_tween = create_tween()
	var start := model.rotation.y
	_spin_tween.tween_property(model, "rotation:y", start + TAU, 0.32).set_trans(Tween.TRANS_QUAD)


func _update_focus() -> void:
	var best: Node = null
	var best_d := INF
	for a in _nearby:
		if not is_instance_valid(a):
			continue
		var owner_node: Node = a.get_meta("interactable", null)
		if owner_node == null:
			continue
		var d := global_position.distance_squared_to(a.global_position)
		if d < best_d:
			best_d = d
			best = owner_node
	if best != _focus:
		_focus = best
		focus_changed.emit(_focus)

class_name HandFriend
extends Node3D
## Season 3: someone to hold hands with (Tosbi, a scared villager, a lost
## starfish, Pamuk...). "El tut" and they walk beside you: while you hold
## hands your light ring is bigger and the Titreme barı does not fill
## (`LightRing.holding_hands`). When the friend gets to `goal` (if set) they
## let go and `arrived` fires (event "el"/`friend_id`).

signal held
signal arrived

const FOLLOW := 1.3

@export var friend_id := "tosbi"
@export var model_id := "tosbi"
var goal := Vector3.INF
var goal_radius := 2.5
var holding := false
var done := false
var _model: Node3D
var _area: Area3D
var _t := 0.0


func _ready() -> void:
	if _model == null:
		_model = NpcModels.build(model_id)
	add_child(_model)
	_area = Area3D.new()
	_area.collision_layer = 4
	_area.collision_mask = 0
	_area.monitoring = false
	_area.set_meta("interactable", self)
	var c := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.9
	c.shape = s
	c.position.y = 0.7
	_area.add_child(c)
	add_child(_area)
	set_meta("action_label", "El tut")
	Beacon.attach(self, 2.3, Tokens.color("spark-yellow"))


func set_model(m: Node3D) -> void:
	_model = m


func interact(by: Node) -> void:
	if done or holding:
		return
	var p := by as Player
	if p == null:
		return
	holding = true
	_area.collision_layer = 0
	if has_node("Beacon"):
		get_node("Beacon").queue_free()
	if p.ring:
		p.ring.holding_hands = true
	Audio.play("calm")
	Effects.sparkle(get_parent(), global_position + Vector3.UP, Tokens.color("spark-yellow"), 10)
	held.emit()


func _process(delta: float) -> void:
	_t += delta
	if done:
		return
	if not holding:
		# waiting, frozen with fear: a small tremble
		_model.position.x = sin(_t * 50.0) * 0.03
		return
	_model.position.x = 0.0
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null:
		return
	# walk at the keeper's side
	var side := Vector3(cos(p.model.rotation.y), 0, -sin(p.model.rotation.y)) * FOLLOW
	var want := p.global_position + side
	var to := want - global_position
	var rig := CharacterRig.of(_model)
	if to.length() > 0.15:
		global_position = global_position.lerp(want, 1.0 - exp(-7.0 * delta))
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(to.x, to.z), minf(delta * 8.0, 1.0))
		if rig:
			rig.speed = 1.0
	elif rig:
		rig.speed = 0.0
	if goal != Vector3.INF and Vector2(global_position.x - goal.x, global_position.z - goal.z).length() < goal_radius:
		release(true)


## Let go. `at_goal` = they made it (stays there, happy).
func release(at_goal := false) -> void:
	if not holding:
		return
	holding = false
	var p := get_tree().get_first_node_in_group("player") as Player
	if p and p.ring:
		p.ring.holding_hands = false
	var rig := CharacterRig.of(_model)
	if rig:
		rig.speed = 0.0
	if at_goal:
		done = true
		_area.queue_free()
		Effects.sparkle(get_parent(), global_position + Vector3.UP, Tokens.color("leaf"), 12)
		Audio.play("quest")
		GameState.notify("el", friend_id)
		arrived.emit()
	else:
		_area.collision_layer = 4


func _exit_tree() -> void:
	if holding:
		var p := get_tree().get_first_node_in_group("player") as Player
		if p and is_instance_valid(p) and p.ring:
			p.ring.holding_hands = false

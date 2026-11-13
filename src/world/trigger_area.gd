class_name TriggerArea
extends Area3D
## Fires once when the player walks in: sends a "reach" quest event with
## `area_id`, and (if `checkpoint`) becomes the place you wake up.

signal reached

@export var area_id := ""
@export var radius := 2.0
@export var checkpoint := false
@export var once := true

var _done := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var c := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = radius
	s.height = 4.0
	c.shape = s
	c.position.y = 2.0
	add_child(c)
	body_entered.connect(_on_body)
	# standing here when the step becomes due counts too
	GameState.data.quest_changed.connect(func(_id: String) -> void: _resend.call_deferred())


var _resending := false


func _resend() -> void:
	if area_id == "" or _resending or not is_inside_tree():
		return
	for b in get_overlapping_bodies():
		if b.is_in_group("player"):
			_resending = true
			GameState.notify("reach", area_id)
			_resending = false
			return


func _on_body(b: Node3D) -> void:
	if not b.is_in_group("player"):
		return
	# the quest step is told every time: a visit before its turn (an earlier
	# step still open) used to spend the trigger and the step never came
	if _done and once:
		if area_id != "":
			GameState.notify("reach", area_id)
		return
	_done = true
	if checkpoint:
		(b as Player).respawn_point = global_position
	if area_id != "":
		GameState.notify("reach", area_id)
	reached.emit()

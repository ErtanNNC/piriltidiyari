class_name FallingBeam
extends Node3D
## A loose beam from the tower that keeps dropping on the same spot:
## honey warning circle 0.8 s first, then it falls. Kids learn to wait
## and pass between drops.

@export var interval := 3.0
@export var delay := 0.0
@export var radius := 1.4
@export var damage := 10

var _t := 0.0
var _beam: Node3D


func _ready() -> void:
	_t = -delay
	_beam = Node3D.new()
	add_child(_beam)
	Toon.part(_beam, "cylinder", Vector3(0.6, 2.6, 0.6), Color("#a86b45"), Vector3.ZERO, Vector3(0, 0, 90))
	_beam.visible = false
	# a crack mark on the ground where it lands
	Toon.part(self, "cylinder", Vector3(radius * 1.6, 0.03, radius * 1.6), Color("#c9b9a4"), Vector3(0, 0.02, 0), Vector3.ZERO, 0.0, 0.0)


func _process(delta: float) -> void:
	_t += delta
	if _t >= interval:
		_t = 0.0
		_drop()


func _drop() -> void:
	Effects.warning(self, global_position, radius, Mob.TELEGRAPH)
	await get_tree().create_timer(Mob.TELEGRAPH, false).timeout
	_beam.visible = true
	_beam.position = Vector3(0, 9, 0)
	_beam.rotation.y = randf() * TAU
	var tw := create_tween()
	tw.tween_property(_beam, "position:y", 0.3, 0.22).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tw.finished
	Effects.ring(self, global_position + Vector3.UP * 0.2, radius * 1.3, Tokens.color("panel"), 0.3)
	var p: Player = get_tree().get_first_node_in_group("player")
	if p and Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length() < radius + 0.3 \
			and p.global_position.y < global_position.y + 2.0:
		p.hurt(damage, global_position)
	await get_tree().create_timer(0.6, false).timeout
	var out := create_tween()
	out.tween_property(_beam, "scale", Vector3.ZERO, 0.2)
	await out.finished
	_beam.visible = false
	_beam.scale = Vector3.ONE

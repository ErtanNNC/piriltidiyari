class_name Feather
extends Node3D
## A grey feather the owl throws. Flies flat along the ground; rolling or
## stepping aside avoids it.

var direction := Vector3.FORWARD
var speed := 9.0
var damage := OwlPlan.FEATHER_DAMAGE
var _life := 2.6


func _ready() -> void:
	Toon.default_pus = 0.0
	Toon.part(self, "capsule", Vector3(0.28, 1.1, 0.28), Color("#a19db2"), Vector3.ZERO, Vector3(90, 0, 0))
	Toon.part(self, "box", Vector3(0.05, 0.05, 1.0), "outline", Vector3(0, 0.12, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.default_pus = 1.0
	look_at(global_position + direction, Vector3.UP)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_life -= delta
	var p: Player = get_tree().get_first_node_in_group("player")
	if p and p.global_position.distance_to(global_position - Vector3.UP * 0.8) < 0.85:
		if p.hurt(damage, global_position - direction):
			queue_free()
			return
	if _life <= 0.0:
		queue_free()

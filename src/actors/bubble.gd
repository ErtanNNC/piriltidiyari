class_name Bubble
extends Node3D
## A slow soap-crystal bubble from Kıskaç. Easy to dodge; rolling passes.

var direction := Vector3.FORWARD
var _life := 4.0


func _ready() -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.4
	s.height = 0.8
	mi.mesh = s
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Tokens.color("sky")
	m.albedo_color.a = 0.55
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	add_child(mi)
	Toon.part(self, "sphere", Vector3(0.14, 0.14, 0.14), Color.WHITE, Vector3(-0.14, 0.16, 0.2), Vector3.ZERO, 0.0, 0.0)


func _physics_process(delta: float) -> void:
	global_position += direction * CrabPlan.BUBBLE_SPEED * delta
	position.y = 0.8 + sin(_life * 6.0) * 0.12
	_life -= delta
	var p: Player = get_tree().get_first_node_in_group("player")
	if p and p.global_position.distance_to(global_position - Vector3.UP * 0.8) < 0.8:
		if p.hurt(CrabPlan.BUBBLE_DAMAGE, global_position - direction):
			Effects.ring(get_parent(), global_position, 0.8, Tokens.color("sky"), 0.2)
			queue_free()
			return
	if _life <= 0.0:
		queue_free()

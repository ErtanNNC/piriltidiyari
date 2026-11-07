class_name LightSeed
extends Node3D
## A glowing seed flung by the Işık Sapanı: flies straight, lights up the
## first Pus-touched thing it touches (hit), stops at walls.

const SPEED := 16.0
const RANGE := 13.0

var dir := Vector3.FORWARD
var damage := 5
var color_token := "spark-yellow"
var max_range := RANGE
var size := 1.0
var _travelled := 0.0


static func fire(parent: Node, at: Vector3, direction: Vector3, dmg: int, col := "spark-yellow", reach := RANGE, scale_f := 1.0) -> LightSeed:
	var s := LightSeed.new()
	s.dir = direction.normalized()
	s.damage = dmg
	s.color_token = col
	s.max_range = reach
	s.size = scale_f
	parent.add_child(s)
	s.global_position = at
	return s


func _ready() -> void:
	Toon.part(self, "sphere", Vector3(0.26, 0.26, 0.26) * size, color_token, Vector3.ZERO, Vector3.ZERO, 2.2, 0.02)
	Toon.part(self, "sphere", Vector3(0.12, 0.12, 0.12) * size, Color.WHITE, Vector3(0, 0, 0.05), Vector3.ZERO, 2.0, 0.0)


func _physics_process(delta: float) -> void:
	var step := SPEED * delta
	var q := PhysicsRayQueryParameters3D.create(global_position, global_position + dir * step)
	q.collision_mask = Player.LAYER_WORLD
	var wall := get_world_3d().direct_space_state.intersect_ray(q)
	for m in get_tree().get_nodes_in_group("hittable"):
		var n := m as Node3D
		if n == null:
			continue
		var to := n.global_position + Vector3.UP * 0.8 - global_position
		if to.length() < 0.8 + float(n.get_meta("hit_radius", 0.5)):
			n.hit(damage, global_position - dir, 3.0)
			Effects.sparkle(get_parent(), global_position, Tokens.color(color_token), 8)
			queue_free()
			return
	if not wall.is_empty():
		Effects.sparkle(get_parent(), wall["position"], Tokens.color(color_token), 6)
		queue_free()
		return
	global_position += dir * step
	_travelled += step
	if _travelled > max_range:
		Effects.sparkle(get_parent(), global_position, Tokens.color(color_token), 5)
		queue_free()

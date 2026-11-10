class_name InkPuddle
extends Node3D
## Season 3: a dark puddle (Mürekkep's ink, a shadow of fear). Standing in
## it the Titreme barı fills fast (`LightRing.extra_cold`); a light over it
## makes it harmless. Fades after `seconds` (0 = stays).

var radius := 2.2
var seconds := 7.0
var cold := 4.0
var _mesh: MeshInstance3D


static func spawn(parent: Node, at: Vector3, r := 2.2, time := 7.0) -> InkPuddle:
	var p := InkPuddle.new()
	p.radius = r
	p.seconds = time
	parent.add_child(p)
	p.global_position = Vector3(at.x, at.y + 0.04, at.z)
	return p


func _ready() -> void:
	add_to_group("ink")
	_mesh = Toon.part(self, "cylinder", Vector3(radius * 2.0, 0.05, radius * 2.0), Color("#1a1838"), Vector3.ZERO, Vector3.ZERO, 0.0, 0.0)
	scale = Vector3(0.1, 1, 0.1)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if seconds > 0.0:
		tw.tween_interval(seconds)
		tw.tween_property(self, "scale", Vector3(0.05, 1, 0.05), 0.5)
		tw.tween_callback(queue_free)


func _process(_delta: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null or p.ring == null:
		return
	var d := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
	if d < radius * scale.x and not LightRing.torch_near(get_tree(), global_position):
		p.ring.extra_cold = maxf(p.ring.extra_cold, cold)

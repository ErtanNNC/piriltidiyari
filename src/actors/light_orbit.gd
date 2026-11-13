class_name LightOrbit
extends Node3D
## Işık Dönencesi: glowing balls circle the keeper for a while and light up
## (hit) whatever Pus-touched thing they touch, each target every 0.6 s.

var count := 2
var damage := 5
var seconds := 6.0
var _t := 0.0
var _orbs: Array[MeshInstance3D] = []
var _last_hit: Dictionary = {}


func _ready() -> void:
	for i in count:
		_orbs.append(Toon.part(self, "sphere", Vector3(0.4, 0.4, 0.4), "spark-purple", Vector3.ZERO, Vector3.ZERO, 2.0, 0.02))


func _process(delta: float) -> void:
	_t += delta
	if _t > seconds:
		queue_free()
		return
	var now := GameState.clock
	for i in _orbs.size():
		var a := _t * 3.2 + TAU * i / _orbs.size()
		var o := _orbs[i]
		o.position = Vector3(cos(a) * 1.9, 0.9 + sin(_t * 4.0 + i) * 0.15, sin(a) * 1.9)
		for m in get_tree().get_nodes_in_group("hittable"):
			var n := m as Node3D
			if n == null:
				continue
			var key := n.get_instance_id()
			if now - float(_last_hit.get(key, -9.0)) < 0.6:
				continue
			if (n.global_position + Vector3.UP * 0.7).distance_to(o.global_position) < 0.9 + float(n.get_meta("hit_radius", 0.5)):
				_last_hit[key] = now
				n.hit(damage, o.global_position, 3.0)

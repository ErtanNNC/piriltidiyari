class_name CaveKit
extends RefCounted
## Building blocks of Şekerleme Mağaraları: rock walls with candy crystal
## clusters, syrup pools.

const ROCK := Color("#6b5f8a")
const ROCK_LIGHT := Color("#8a7fae")
const CANDY := ["berry", "sky", "spark-purple", "spark-blue"]


## A solid rock wall from a to b, height 3 m, with crystal clusters.
static func wall(parent: Node3D, a: Vector3, b: Vector3, thickness := 1.8) -> void:
	var mid := (a + b) * 0.5
	var length := a.distance_to(b)
	if length < 0.1:
		return
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 5.0, thickness)
	c.shape = box
	c.position.y = 2.5
	body.add_child(c)
	parent.add_child(body)
	body.position = mid
	body.rotation.y = atan2(-(b.z - a.z), b.x - a.x)
	Toon.part(body, "box", Vector3(length, 2.0, thickness), ROCK, Vector3(0, 1.0, 0), Vector3.ZERO, 0.0, 0.03)
	var n := maxi(1, int(length / 2.4))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(mid.x * 13.0 + mid.z * 7.0)
	for i in n:
		var x := -length * 0.5 + (i + 0.5) * length / n
		Toon.part(body, "sphere", Vector3(2.6, 1.8, thickness + 0.4), ROCK_LIGHT if i % 2 == 0 else ROCK, Vector3(x, 2.1, 0), Vector3.ZERO, 0.0, 0.03)
		if rng.randf() < 0.45:
			var col: String = CANDY[rng.randi() % CANDY.size()]
			for k in 3:
				var p := Vector3(x + rng.randf_range(-0.6, 0.6), 2.6 + rng.randf_range(0, 0.4), rng.randf_range(-0.3, 0.3))
				Toon.part(body, "cone", Vector3(0.36, 0.9 + k * 0.2, 0.36), col, p, Vector3(rng.randf_range(-25, 25), 0, rng.randf_range(-25, 25)), 0.6, 0.02)


## A pool of sticky pink syrup: walking through it is slow (never harmful).
static func syrup(parent: Node3D, center: Vector3, size: Vector2) -> Area3D:
	WorldLook.water(Toon.part(parent, "box", Vector3(size.x, 0.1, size.y), Color("#ff9ec4"), center + Vector3.UP * 0.05, Vector3.ZERO, 0.35, 0.0), "syrup")
	for i in int(size.x * size.y / 6.0):
		var b := Toon.part(parent, "sphere", Vector3(0.3, 0.2, 0.3), Color("#ffc4dc"),
			center + Vector3(randf_range(-size.x * 0.45, size.x * 0.45), 0.12, randf_range(-size.y * 0.45, size.y * 0.45)), Vector3.ZERO, 0.4, 0.0)
		var tw := b.create_tween().set_loops()
		tw.tween_property(b, "scale", Vector3(1.3, 1.6, 1.3), randf_range(0.8, 1.4)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(b, "scale", Vector3.ONE, randf_range(0.8, 1.4)).set_trans(Tween.TRANS_SINE)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	var c := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 2.0, size.y)
	c.shape = box
	c.position.y = 1.0
	area.add_child(c)
	parent.add_child(area)
	area.position = center
	area.body_entered.connect(func(b: Node3D) -> void:
		if b is Player:
			(b as Player).slow = 0.4)
	area.body_exited.connect(func(b: Node3D) -> void:
		if b is Player:
			(b as Player).slow = 1.0)
	return area

class_name MountainKit
extends RefCounted
## Building blocks of Uyku Dağı: snowy terraces, ramps, ice, sleepy fog,
## rolling snowballs.

const SNOW := Color("#c8d3ea")
const SNOW_SHADE := Color("#a9b6d6")
const ROCK := Color("#a9a3bd")
const ICE := Color("#bfe6ff")


## A flat snowy terrace: top at `top_y`, from z0 (south) to z1 (north).
static func terrace(parent: Node3D, x_half: float, z0: float, z1: float, top_y: float) -> void:
	var h := top_y + 1.0
	WorldLook.block(parent, Vector3(0, top_y - h * 0.5, (z0 + z1) * 0.5), Vector3(x_half * 2, h, absf(z0 - z1)), SNOW, 0.03)
	# a darker rocky lip along the south edge so each step reads clearly
	if top_y > 0.0:
		Toon.part(parent, "box", Vector3(x_half * 2, 0.5, 0.8), ROCK, Vector3(0, top_y - 0.2, maxf(z0, z1) - 0.4), Vector3.ZERO, 0.0, 0.03)


## A walkable ramp from (z0, y0) to (z1, y1), `width` wide, centered on x.
static func ramp(parent: Node3D, x: float, width: float, z0: float, y0: float, z1: float, y1: float, col: Variant = SNOW_SHADE) -> void:
	var length := Vector2(z1 - z0, y1 - y0).length()
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(width, 0.6, length)
	c.shape = b
	body.add_child(c)
	parent.add_child(body)
	body.position = Vector3(x, (y0 + y1) * 0.5 - 0.3, (z0 + z1) * 0.5)
	body.rotation.x = atan2(y1 - y0, -(z1 - z0))
	Toon.part(body, "box", Vector3(width, 0.6, length), col, Vector3.ZERO, Vector3.ZERO, 0.0, 0.03)


## A rocky wall segment (keeps you on the path).
static func wall(parent: Node3D, a: Vector3, b: Vector3, height := 3.0) -> void:
	var mid := (a + b) * 0.5
	var length := a.distance_to(b)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 6.0, 1.4)
	c.shape = box
	c.position.y = 3.0
	body.add_child(c)
	parent.add_child(body)
	body.position = mid
	body.rotation.y = atan2(-(b.z - a.z), b.x - a.x)
	Toon.part(body, "box", Vector3(length, height, 1.4), ROCK, Vector3(0, height * 0.5, 0), Vector3.ZERO, 0.0, 0.03)
	var n := maxi(1, int(length / 2.2))
	for i in n:
		Toon.part(body, "sphere", Vector3(2.0, 0.8, 1.8), SNOW, Vector3(-length * 0.5 + (i + 0.5) * length / n, height, 0))


## Slippery ice: you slide (low grip) while on it.
static func ice(parent: Node3D, center: Vector3, size: Vector2) -> Area3D:
	var sheet := Toon.part(parent, "box", Vector3(size.x, 0.06, size.y), ICE, center + Vector3.UP * 0.03, Vector3.ZERO, 0.25, 0.0)
	WorldLook.water(sheet, "ice")
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	var c := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 1.5, size.y)
	c.shape = box
	c.position.y = 0.75
	area.add_child(c)
	parent.add_child(area)
	area.position = center
	area.body_entered.connect(func(b: Node3D) -> void:
		if b is Player:
			(b as Player).ice = true)
	area.body_exited.connect(func(b: Node3D) -> void:
		if b is Player:
			(b as Player).ice = false)
	return area


## Sleepy fog: soft lilac mist that makes you slow and yawny.
static func sleepy_fog(parent: Node3D, center: Vector3, size: Vector2) -> Area3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("#c9c2e6")
	mat.albedo_color.a = 0.3
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var area := Area3D.new()
	for i in int(size.x * size.y / 10.0):
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.0
		s.height = 1.0
		mi.mesh = s
		mi.material_override = mat
		mi.position = Vector3(randf_range(-size.x * 0.5, size.x * 0.5), 0.5, randf_range(-size.y * 0.5, size.y * 0.5))
		mi.scale = Vector3(2.4, 1.2, 2.4)
		area.add_child(mi)  # freeing the area clears the mist too
	area.collision_layer = 0
	area.collision_mask = 1
	var c := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 3.0, size.y)
	c.shape = box
	c.position.y = 1.5
	area.add_child(c)
	parent.add_child(area)
	area.position = center
	area.body_entered.connect(func(b: Node3D) -> void:
		if b is Player:
			(b as Player).slow = 0.55)
	area.body_exited.connect(func(b: Node3D) -> void:
		if b is Player:
			(b as Player).slow = 1.0)
	return area

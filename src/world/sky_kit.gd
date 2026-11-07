class_name SkyKit
extends RefCounted
## Building blocks of Bulut Limanı: floating islands, cloud sea, docks.

const GRASS := Color("#8fd38a")
const EARTH := Color("#c79a6e")


## A round floating island: grass top at `center.y`, earthy cone below.
static func island(parent: Node3D, center: Vector3, radius: float, grass := GRASS) -> StaticBody3D:
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = 1.0
	c.shape = cyl
	c.position.y = -0.5
	body.add_child(c)
	parent.add_child(body)
	body.position = center
	Toon.part(body, "cylinder", Vector3(radius * 2, 1.0, radius * 2), grass, Vector3(0, -0.5, 0))
	Toon.part(body, "cone", Vector3(radius * 2, radius * 1.1, radius * 2), EARTH, Vector3(0, -1.0 - radius * 0.55, 0), Vector3(180, 0, 0))
	for i in int(radius / 2.0):
		var a := TAU * i / int(radius / 2.0)
		Toon.part(body, "sphere", Vector3(1.4, 1.0, 1.4), Color("#b38558"), Vector3(sin(a) * radius * 0.6, -radius * 0.7, cos(a) * radius * 0.6))
	# a soft grassy lip, rock layers, hanging roots and vines, little floating stones
	Toon.part(body, "ring", Vector3(radius * 2.05, 0.28, radius * 2.05), grass.darkened(0.12), Vector3(0, -0.55, 0), Vector3.ZERO, 0.0, 0.02)
	Toon.part(body, "cylinder", Vector3(radius * 1.9, 0.5, radius * 1.85), EARTH.darkened(0.1), Vector3(0, -1.25, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(center.x * 31.0 + center.z * 17.0)
	for i in maxi(4, int(radius * 1.2)):
		var a := rng.randf() * TAU
		var r := radius * rng.randf_range(0.55, 0.9)
		var vlen := rng.randf_range(1.0, 2.6)
		Toon.part(body, "cylinder", Vector3(0.12, vlen, 0.12), Color("#8a5a3c") if i % 2 == 0 else Color("#5fae5c"),
			Vector3(cos(a) * r, -1.4 - vlen * 0.5, sin(a) * r), Vector3(rng.randf_range(-10, 10), 0, rng.randf_range(-10, 10)), 0.0, 0.015)
		if i % 2 == 1:
			Toon.part(body, "sphere", Vector3(0.3, 0.3, 0.3), "berry" if i % 4 == 1 else "spark-yellow", Vector3(cos(a) * r, -1.4 - vlen, sin(a) * r), Vector3.ZERO, 0.2, 0.015)
	for i in 3:
		var a := rng.randf() * TAU
		var fr := Toon.part(body, "ellipsoid", Vector3(0.9, 0.7, 0.8) * rng.randf_range(0.6, 1.2), EARTH,
			Vector3(cos(a) * (radius + 1.5), -2.0 - rng.randf() * 2.0, sin(a) * (radius + 1.5)))
		Toon.part(fr, "ellipsoid", Vector3(1.0, 0.25, 0.9), grass, Vector3(0, 0.35, 0), Vector3.ZERO, 0.0, 0.02)
	return body


## Soft white clouds far below the islands.
static func cloud_sea(parent: Node3D, center: Vector3, extent: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("#ffffff")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 40:
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.0
		s.height = 2.0
		s.radial_segments = 12
		s.rings = 6
		mi.mesh = s
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		mi.position = center + Vector3(rng.randf_range(-extent, extent), rng.randf_range(-16, -12), rng.randf_range(-extent, extent))
		mi.scale = Vector3(rng.randf_range(6, 12), rng.randf_range(2, 3.5), rng.randf_range(6, 12))
		# slow drift and breathing so the sea of clouds feels alive
		var tw := mi.create_tween().set_loops()
		var drift := Vector3(rng.randf_range(2.0, 4.0), rng.randf_range(-0.4, 0.4), 0)
		var dur := rng.randf_range(9.0, 15.0)
		tw.tween_property(mi, "position", mi.position + drift, dur).set_trans(Tween.TRANS_SINE)
		tw.tween_property(mi, "position", mi.position, dur).set_trans(Tween.TRANS_SINE)


## A wooden dock sticking out of an island edge.
static func dock(parent: Node3D, at: Vector3, yaw_deg: float) -> void:
	var d := Node3D.new()
	parent.add_child(d)
	d.position = at
	d.rotation_degrees.y = yaw_deg
	WorldLook.block(d, Vector3(0, -0.15, 2.5), Vector3(3.2, 0.3, 5.0), Color("#c98d5e"))
	for x in [-1.4, 1.4]:
		Toon.part(d, "cylinder", Vector3(0.3, 2.4, 0.3), Color("#a86b45"), Vector3(x, -0.6, 4.8))
	# plank seams, rope railing on short posts, a lamp and a life ring at the end
	for k in 6:
		Toon.part(d, "box", Vector3(3.15, 0.02, 0.05), Color("#a86b45"), Vector3(0, 0.005, 0.4 + k * 0.8), Vector3.ZERO, 0.0, 0.0)
	for x in [-1.5, 1.5]:
		for k in 3:
			Toon.part(d, "cylinder", Vector3(0.14, 0.8, 0.14), Color("#a86b45"), Vector3(x, 0.4, 0.6 + k * 2.0), Vector3.ZERO, 0.0, 0.02)
		Toon.part(d, "cylinder", Vector3(0.05, 4.0, 0.05), Color("#e8d3a8"), Vector3(x, 0.72, 2.6), Vector3(90, 0, 0), 0.0, 0.0)
	Toon.part(d, "cylinder", Vector3(0.05, 0.9, 0.05), "outline", Vector3(1.5, 1.25, 4.6), Vector3.ZERO, 0.0, 0.0)
	Toon.part(d, "sphere", Vector3(0.3, 0.38, 0.3), "honey", Vector3(1.5, 1.75, 4.6), Vector3.ZERO, 1.3, 0.02)
	Toon.part(d, "ring", Vector3(0.7, 0.12, 0.7), "hp", Vector3(-1.62, 0.55, 4.4), Vector3(0, 0, 90), 0.0, 0.02)

class_name Toon
extends RefCounted
## Builds toy-like placeholder geometry with the shared toon + outline look.
## Colors are design-system token names (see design/tokens.json) or Colors.

const TOON_SHADER := preload("res://src/world/toon.gdshader")
const OUTLINE_SHADER := preload("res://src/world/outline.gdshader")

static var _cache: Dictionary = {}


static func material(col: Variant, outline := 0.035, glow := 0.0) -> ShaderMaterial:
	var c := _resolve(col)
	var key := "%s|%s|%s" % [c.to_html(), outline, glow]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = TOON_SHADER
	m.set_shader_parameter("albedo", c)
	m.set_shader_parameter("shade_color", c.lerp(Color("#6b5f80"), 0.45))
	if glow > 0.0:
		m.set_shader_parameter("emission_color", c)
		m.set_shader_parameter("emission_strength", glow)
	if outline > 0.0:
		var o := ShaderMaterial.new()
		o.shader = OUTLINE_SHADER
		o.set_shader_parameter("outline_color", Tokens.color("outline"))
		o.set_shader_parameter("thickness", outline)
		m.next_pass = o
	_cache[key] = m
	return m


## Adds a primitive mesh child. `shape` is "sphere", "capsule", "cylinder",
## "cone", "box" or "torus"; `size` is the bounding size in meters.
static func part(parent: Node3D, shape: String, size: Vector3, col: Variant,
		pos := Vector3.ZERO, rot_deg := Vector3.ZERO, glow := 0.0, outline := 0.035) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	match shape:
		"sphere":
			var s := SphereMesh.new()
			s.radius = size.x * 0.5
			s.height = size.y
			s.radial_segments = 24
			s.rings = 12
			mi.mesh = s
		"capsule":
			var c := CapsuleMesh.new()
			c.radius = size.x * 0.5
			c.height = size.y
			mi.mesh = c
		"cylinder", "cone":
			var cy := CylinderMesh.new()
			cy.top_radius = 0.0 if shape == "cone" else size.x * 0.5
			cy.bottom_radius = size.z * 0.5 if shape == "cylinder" else size.x * 0.5
			cy.height = size.y
			cy.radial_segments = 20
			mi.mesh = cy
		"torus":
			var t := TorusMesh.new()
			t.inner_radius = size.y
			t.outer_radius = size.x * 0.5
			mi.mesh = t
		_:
			var b := BoxMesh.new()
			b.size = size
			mi.mesh = b
	mi.material_override = material(col, outline, glow)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


static func _resolve(col: Variant) -> Color:
	if col is Color:
		return col
	return Tokens.color(String(col))

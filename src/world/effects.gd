class_name Effects
extends RefCounted
## Small one-shot visual effects built from primitives.


## A flat glowing ring that expands and fades (attack shock, potion, hit).
static func ring(parent: Node, at: Vector3, radius: float, col: Color, seconds := 0.4) -> void:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.85
	t.outer_radius = 1.0
	t.rings = 32
	mi.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	mi.scale = Vector3(0.3, 0.3, 0.3)
	parent.add_child(mi)
	mi.global_position = at
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3(radius, 1.0, radius), seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 0.0, seconds).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(mi.queue_free)


## A burst of little light sparks flying out (mob turning back into light).
static func sparkle(parent: Node, at: Vector3, col: Color, count := 10) -> void:
	for i in count:
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.09
		s.height = 0.18
		mi.mesh = s
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = col
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 2.0
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = m
		parent.add_child(mi)
		mi.global_position = at
		var dir := Vector3(randf_range(-1, 1), randf_range(0.6, 1.6), randf_range(-1, 1)).normalized()
		var tw := mi.create_tween().set_parallel()
		tw.tween_property(mi, "global_position", at + dir * randf_range(1.0, 2.0), 0.6).set_ease(Tween.EASE_OUT)
		tw.tween_property(m, "albedo_color:a", 0.0, 0.6).set_delay(0.2)
		tw.chain().tween_callback(mi.queue_free)


## A ground warning that fills up over `seconds` — the 0.8 s attack tell.
static func warning(parent: Node, at: Vector3, radius: float, seconds := 0.8) -> MeshInstance3D:
	Audio.play("warn")  # every attack is announced by sound too
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 1.0
	c.bottom_radius = 1.0
	c.height = 0.04
	mi.mesh = c
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Tokens.color("honey")
	m.albedo_color.a = 0.25
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	parent.add_child(mi)
	mi.global_position = at + Vector3.UP * 0.05
	mi.scale = Vector3(radius * 0.2, 1, radius * 0.2)
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3(radius, 1, radius), seconds)
	tw.tween_property(m, "albedo_color:a", 0.6, seconds)
	tw.chain().tween_callback(mi.queue_free)
	return mi

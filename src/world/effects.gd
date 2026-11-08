class_name Effects
extends RefCounted
## Small one-shot visual effects built from primitives.


# Shared meshes and materials: effects fire on every hit, so they reuse one
# mesh + one material per color and fade with the per-instance `transparency`
# (no new resources per spark — fewer allocations, fewer stutters).
static var _ring_mesh: TorusMesh
static var _spark_mesh: SphereMesh
static var _mats: Dictionary = {}


static func _flat_mat(col: Color, glow := false) -> StandardMaterial3D:
	var key := "%s|%s" % [col.to_html(), glow]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	if glow:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 2.0
	_mats[key] = m
	return m


## A flat glowing ring that expands and fades (attack shock, potion, hit).
static func ring(parent: Node, at: Vector3, radius: float, col: Color, seconds := 0.4) -> void:
	if _ring_mesh == null:
		_ring_mesh = TorusMesh.new()
		_ring_mesh.inner_radius = 0.85
		_ring_mesh.outer_radius = 1.0
		_ring_mesh.rings = 32
	var mi := MeshInstance3D.new()
	mi.mesh = _ring_mesh
	mi.material_override = _flat_mat(Color(col.r, col.g, col.b))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.transparency = 1.0 - col.a
	mi.scale = Vector3(0.3, 0.3, 0.3)
	parent.add_child(mi)
	mi.global_position = at
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3(radius, 1.0, radius), seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mi, "transparency", 1.0, seconds).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(mi.queue_free)


## A burst of little light sparks flying out (mob turning back into light).
static func sparkle(parent: Node, at: Vector3, col: Color, count := 10) -> void:
	if _spark_mesh == null:
		_spark_mesh = SphereMesh.new()
		_spark_mesh.radius = 0.09
		_spark_mesh.height = 0.18
		_spark_mesh.radial_segments = 8
		_spark_mesh.rings = 4
	var mat := _flat_mat(col, true)
	for i in count:
		var mi := MeshInstance3D.new()
		mi.mesh = _spark_mesh
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		mi.global_position = at
		var dir := Vector3(randf_range(-1, 1), randf_range(0.6, 1.6), randf_range(-1, 1)).normalized()
		var tw := mi.create_tween().set_parallel()
		tw.tween_property(mi, "global_position", at + dir * randf_range(1.0, 2.0), 0.6).set_ease(Tween.EASE_OUT)
		tw.tween_property(mi, "transparency", 1.0, 0.4).set_delay(0.2)
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


## Everything a landed hit does: sound, a "pow" star, a little camera shake
## and a 45 ms hit-stop so the blow feels solid.
static func hit(target: Node3D, strong := false) -> void:
	Audio.play("hit")
	if target == null or not target.is_inside_tree():
		return
	var parent := target.get_parent()
	var at := target.global_position + Vector3.UP * (1.2 if not strong else 2.0)
	impact(parent, at, 1.4 if strong else 1.0)
	shake(target.get_viewport(), 0.35 if not strong else 0.55)
	hitstop(target.get_tree(), 0.045)


## A white-gold star that pops up and fades where a hit lands.
static func impact(parent: Node, at: Vector3, size := 1.0) -> void:
	var mi := sprite(parent, at, "star", Color(1.0, 0.95, 0.7), 0.9 * size)
	mi.scale = Vector3.ONE * 0.3
	mi.rotation_degrees.z = randf_range(0, 72)
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3.ONE * 1.1, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "transparency", 1.0, 0.16).set_delay(0.08)
	tw.chain().tween_callback(mi.queue_free)


## Soft dust puffs at the feet (steps, landing).
static func dust(parent: Node, at: Vector3, col: Color, count := 2, size := 0.5) -> void:
	for i in count:
		var p := at + Vector3(randf_range(-0.2, 0.2), 0.15, randf_range(-0.2, 0.2))
		var mi := sprite(parent, p, "soft", col, size)
		mi.scale = Vector3.ONE * randf_range(0.7, 1.1)
		var tw := mi.create_tween().set_parallel()
		var drift := Vector3(randf_range(-0.4, 0.4), randf_range(0.2, 0.45), randf_range(-0.4, 0.4))
		tw.tween_property(mi, "global_position", p + drift, 0.5).set_ease(Tween.EASE_OUT)
		tw.tween_property(mi, "scale", Vector3.ONE * 1.6, 0.5)
		tw.tween_property(mi, "transparency", 1.0, 0.5)
		tw.chain().tween_callback(mi.queue_free)


## A paw print pressed into snow; fades after a few seconds.
static func footprint(parent: Node, at: Vector3, yaw: float, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.26, 0.34)
	q.orientation = PlaneMesh.FACE_Y
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = Weather.texture("dot")
	m.albedo_color = col
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = at + Vector3.UP * 0.03
	mi.rotation.y = yaw
	var tw := mi.create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(m, "albedo_color:a", 0.0, 1.5)
	tw.tween_callback(mi.queue_free)


## A camera-facing textured quad (Weather's procedural sprites). Shared quad
## and material per (texture, color); fade it with `transparency`.
static var _quads: Dictionary = {}


static func sprite(parent: Node, at: Vector3, tex: String, col: Color, size: float) -> MeshInstance3D:
	var key := "%s|%s|%s" % [tex, Color(col.r, col.g, col.b).to_html(), snappedf(size, 0.05)]
	if not _quads.has(key):
		var q := QuadMesh.new()
		q.size = Vector2(size, size)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.albedo_texture = Weather.texture(tex)
		m.albedo_color = Color(col.r, col.g, col.b)
		m.no_depth_test = tex == "star"
		q.material = m
		_quads[key] = q
	var mi := MeshInstance3D.new()
	mi.mesh = _quads[key]
	mi.transparency = 1.0 - col.a
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = at
	return mi


static func shake(vp: Viewport, amount: float) -> void:
	var cam := vp.get_camera_3d() if vp else null
	if cam and cam.has_method("shake"):
		cam.call("shake", amount)


static var _stop_depth := 0


## Freezes the game for a blink (real time, so it always ends).
static func hitstop(tree: SceneTree, seconds: float) -> void:
	if tree == null or tree.paused:
		return
	_stop_depth += 1
	Engine.time_scale = 0.06
	await tree.create_timer(seconds, true, false, true).timeout
	_stop_depth -= 1
	if _stop_depth <= 0:
		_stop_depth = 0
		Engine.time_scale = 1.0

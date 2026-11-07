class_name Weather
extends Node3D
## Per-mood weather around what the camera looks at (CPU particles, cheap on
## phones): dandelion seeds, fireflies, falling leaves, glowing cave motes,
## wind streaks and rain, snow, castle mist. Plus grey Pus wisps near the
## ground that fade as the Pus goes down, and the sky's rainbow and sun when
## Bulut Limanı clears. Added by WorldLook.add for every scene.

const FOLLOW_DIST := 14.0

var mood := ""
var env: Environment

var _wisps: CPUParticles3D
var _wisp_mat: StandardMaterial3D
var _storm: Array[CPUParticles3D] = []
var _sky: ShaderMaterial
var _rainbow := 0.0

static var _textures: Dictionary = {}


static func add(parent: Node3D, mood_id: String, environment: Environment) -> Weather:
	var w := Weather.new()
	w.name = "Weather"
	w.mood = mood_id
	w.env = environment
	parent.add_child(w)
	return w


func _ready() -> void:
	_sky = WorldLook.sky_material(env)
	match mood:
		"sabah":
			_seeds(22)
		"aksam":
			_fireflies(40, Color(2.4, 2.1, 0.9))
			_seeds(8)
		"pus", "kule":
			_flakes(40, Color(0.75, 0.73, 0.82, 0.6))
		"orman":
			_leaves(40)
			_fireflies(14, Color(1.9, 2.4, 1.0))
		"magara":
			_motes(70)
		"liman":
			_wind(16)
			_storm.append(_rain(170))
		"dag":
			_snow(70, 0.06)
			_storm.append(_snow(160, 0.1))
		"kale":
			_mist(14, Color(0.55, 0.42, 0.85, 0.22))
			_motes(30, true)
	if mood != "magara":
		_pus_wisps()
	_follow()


func _process(delta: float) -> void:
	_follow()
	var pus := Pus.amount
	if _wisp_mat:
		var a := clampf((pus - 0.12) * 1.0, 0.0, 0.42)
		_wisp_mat.albedo_color.a = a
		_wisps.visible = a > 0.01
	for p in _storm:
		p.emitting = pus > 0.3
	if mood == "liman" and _sky:
		_rainbow = move_toward(_rainbow, 1.0 if pus < 0.15 else 0.0, delta * 0.4)
		_sky.set_shader_parameter("rainbow", _rainbow)


## Keeps the emitters around the point the camera looks at.
func _follow() -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var focus := cam.global_position - cam.global_basis.z * FOLLOW_DIST
	global_position = focus


# --- particle kinds -----------------------------------------------------------

func _seeds(n: int) -> void:
	var p := _particles(n, 9.0, "seed", 0.28, Vector3(14, 2.5, 11), Vector3(0, 1.5, 0))
	p.direction = Vector3(1, 0.3, 0.2)
	p.spread = 50.0
	p.gravity = Vector3(0, 0.04, 0)
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.7
	p.angular_velocity_min = -40.0
	p.angular_velocity_max = 40.0
	p.color_ramp = _fade(Color(1, 1, 1, 0.9))


func _fireflies(n: int, glow: Color) -> void:
	var p := _particles(n, 6.0, "dot", 0.13, Vector3(13, 1.6, 10), Vector3(0, 1.2, 0))
	p.spread = 180.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.1
	p.initial_velocity_max = 0.45
	p.color_ramp = _fade(glow, true)


func _leaves(n: int) -> void:
	var p := _particles(n, 8.0, "leaf", 0.26, Vector3(14, 1.0, 11), Vector3(0, 6.0, 0))
	p.direction = Vector3(1, -0.4, 0.3)
	p.spread = 35.0
	p.gravity = Vector3(0, -0.35, 0)
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 0.9
	p.angle_min = -180.0
	p.angle_max = 180.0
	p.angular_velocity_min = -120.0
	p.angular_velocity_max = 120.0
	p.damping_min = 0.05
	p.damping_max = 0.15
	p.color_initial_ramp = _palette([Color("#f29a3c"), Color("#f7c548"), Color("#d9643a"), Color("#9bd36a")])
	p.color_ramp = _fade(Color.WHITE)


func _motes(n: int, purple := false) -> void:
	var p := _particles(n, 7.0, "dot", 0.09, Vector3(14, 3.0, 11), Vector3(0, 1.8, 0))
	p.spread = 180.0
	p.gravity = Vector3(0, 0.03, 0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.25
	if purple:
		p.color_initial_ramp = _palette([Color(1.6, 1.0, 2.4), Color(1.2, 0.9, 2.2)])
	else:
		p.color_initial_ramp = _palette([Color(2.4, 1.2, 1.9), Color(1.0, 2.2, 2.4), Color(2.2, 2.0, 1.1)])
	p.color_ramp = _fade(Color.WHITE, true)


func _flakes(n: int, col: Color) -> void:
	var p := _particles(n, 7.0, "dot", 0.1, Vector3(14, 1.0, 11), Vector3(0, 6.0, 0))
	p.direction = Vector3(0.5, -1, 0)
	p.spread = 25.0
	p.gravity = Vector3(0, -0.2, 0)
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 0.8
	p.color_ramp = _fade(col)


func _snow(n: int, size: float) -> CPUParticles3D:
	var p := _particles(n, 6.0, "dot", size * 1.6, Vector3(15, 1.0, 12), Vector3(0, 7.0, 0))
	p.direction = Vector3(0.3, -1, 0.1)
	p.spread = 15.0
	p.gravity = Vector3(0, -0.6, 0)
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.1
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	p.color_ramp = _fade(Color(1, 1, 1, 0.95))
	return p


func _wind(n: int) -> void:
	var p := _particles(n, 1.6, "streak_h", 1.0, Vector3(16, 3.0, 11), Vector3(-6, 1.5, 0))
	p.direction = Vector3(1, 0, 0.05)
	p.spread = 3.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 9.0
	p.initial_velocity_max = 13.0
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.4
	p.color_ramp = _fade(Color(1, 1, 1, 0.55))


func _rain(n: int) -> CPUParticles3D:
	var p := _particles(n, 0.9, "streak_v", 0.9, Vector3(14, 0.5, 11), Vector3(0, 9.0, 0))
	p.direction = Vector3(0.25, -1, 0)
	p.spread = 3.0
	p.gravity = Vector3(0, -6.0, 0)
	p.initial_velocity_min = 11.0
	p.initial_velocity_max = 13.0
	p.color_ramp = _fade(Color(0.86, 0.92, 1.0, 0.8))
	return p


func _mist(n: int, col: Color) -> void:
	var p := _particles(n, 10.0, "soft", 4.0, Vector3(14, 0.3, 11), Vector3(0, 0.6, 0))
	p.direction = Vector3(1, 0, 0.2)
	p.spread = 30.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.5
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	p.color_ramp = _fade(col)


## Grey wisps of the Pus hanging near the ground; their alpha follows Pus.amount.
func _pus_wisps() -> void:
	_wisps = _particles(16, 11.0, "soft", 4.5, Vector3(14, 0.4, 11), Vector3(0, 0.7, 0))
	_wisps.direction = Vector3(-1, 0, 0.3)
	_wisps.spread = 30.0
	_wisps.gravity = Vector3.ZERO
	_wisps.initial_velocity_min = 0.15
	_wisps.initial_velocity_max = 0.4
	_wisps.scale_amount_min = 0.7
	_wisps.scale_amount_max = 1.4
	_wisps.color_ramp = _fade(Color(0.82, 0.8, 0.9, 1.0))
	_wisp_mat = _wisps.mesh.surface_get_material(0) as StandardMaterial3D
	_wisp_mat.albedo_color = Color(1, 1, 1, 0.0)


# --- helpers ------------------------------------------------------------------

func _particles(n: int, life: float, tex: String, size: float, extents: Vector3, offset: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = life
	p.preprocess = life
	p.lifetime_randomness = 0.3
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.position = offset
	var q := QuadMesh.new()
	q.size = Vector2(size, size) if not tex.begins_with("streak") else (Vector2(size * 1.6, size * 0.08) if tex == "streak_h" else Vector2(size * 0.09, size))
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES if not tex.begins_with("streak") else BaseMaterial3D.BILLBOARD_FIXED_Y
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = texture(tex)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	q.material = m
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	return p


## Fade in, hold, fade out over a particle's life. `glow` pulses for fireflies.
func _fade(col: Color, glow := false) -> Gradient:
	var g := Gradient.new()
	var clear := Color(col.r, col.g, col.b, 0.0)
	g.offsets = PackedFloat32Array([0.0, 0.15, 0.5, 0.85, 1.0]) if not glow else PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 1.0])
	var dim := Color(col.r * 0.5, col.g * 0.5, col.b * 0.5, col.a * 0.5)
	g.colors = PackedColorArray([clear, col, col if not glow else dim, col, clear])
	return g


func _palette(cols: Array) -> Gradient:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cs := PackedColorArray()
	for i in cols.size():
		offs.append(float(i) / maxf(cols.size() - 1, 1))
		cs.append(cols[i])
	g.offsets = offs
	g.colors = cs
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	return g


## Small procedural sprites (no image files): soft blob, dot, leaf, seed, streaks.
static func texture(kind: String) -> ImageTexture:
	if _textures.has(kind):
		return _textures[kind]
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (x + 0.5) / n * 2.0 - 1.0
			var v := (y + 0.5) / n * 2.0 - 1.0
			var r := sqrt(u * u + v * v)
			var a := 0.0
			var c := Color.WHITE
			match kind:
				"soft":
					a = pow(clampf(1.0 - r, 0.0, 1.0), 1.6)
				"dot":
					a = clampf((1.0 - r) * 3.0, 0.0, 1.0)
				"leaf":
					var w := 0.5 * (1.0 - v * v)
					a = 1.0 if w > 0.0 and absf(u) < w else 0.0
					if absf(u) < 0.05 and absf(v) < 0.85:
						c = Color(0.8, 0.8, 0.8)
				"seed":
					a = clampf((0.22 - r) * 8.0, 0.0, 1.0)
					var ang := atan2(v, u)
					var ray := absf(sin(ang * 6.0))
					if r < 0.95 and ray < 0.12:
						a = maxf(a, 0.7 * (1.0 - r))
				"star":
					# five-point star with a soft glow
					var ang := atan2(v, u)
					var k := 0.55 + 0.45 * pow(absf(cos(ang * 2.5)), 6.0)
					a = clampf((k * 0.95 - r) * 10.0, 0.0, 1.0) + clampf(0.35 - r, 0.0, 0.35)
				"streak_h", "streak_v":
					var along := u if kind == "streak_h" else v
					a = clampf(1.0 - absf(along), 0.0, 1.0)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
	var t := ImageTexture.create_from_image(img)
	_textures[kind] = t
	return t

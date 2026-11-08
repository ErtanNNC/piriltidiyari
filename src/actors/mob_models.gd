class_name MobModels
extends RefCounted
## Placeholder mobs. `pus` = true builds the grey, grumpy Pus-touched look;
## false builds the animal's own colors with a happy face. Faces +Z.


static func build(kind: String, pus: bool) -> Node3D:
	var root := Node3D.new()
	Toon.default_pus = 0.0
	var imported := ModelImport.load_model(kind)
	if imported:
		# a real model: the Pus look drains its colors to the grey-violet
		# (a faint trace of its own color stays), calm shows its own colors
		_no_pus(imported)
		if pus and MobStats.breathes(kind):
			# Kızıl Sis: hot-tempered, a warm red cast and steam from the head
			_each_material(imported, func(m: ShaderMaterial) -> void:
				m.set_shader_parameter("desat", 0.5)
				m.set_shader_parameter("desat_tint", Vector3(1.3, 0.66, 0.56)))
			var hb := ModelImport._bounds(imported, Transform3D.IDENTITY)
			_pus_wisps(imported, maxf(1.0, hb.end.y), Color(1, 1, 1), 8, 0.9)
		elif pus:
			_drain(imported, 0.86)
			var box := ModelImport._bounds(imported, Transform3D.IDENTITY)
			_pus_wisps(imported, maxf(1.4, box.end.y + 0.2))
		Toon.default_pus = 1.0
		return imported
	match kind:
		"sumuklu":
			_slug(root, pus)
		"mantar":
			_mushroom(root, pus, 1.0)
		"dev_mantar":
			_mushroom(root, pus, 2.2)
		"kirpi_topu":
			_hedgehog_ball(root, pus)
		"karga":
			_crow(root, pus)
		"kristal_bocek":
			_beetle(root, pus)
		"firtina_yumagi":
			_storm_ball(root, pus)
		"kar_tavsani":
			_snow_bunny(root, pus)
		"golge_kopya":
			_shadow_copy(root, pus)
		"buz_dikeni":
			_ice_spike(root, pus)
		"korsan_marti":
			_pirate_gull(root, pus)
		"yarasa":
			_bat(root, pus)
		"kapici_rakun":
			_raccoon(root, pus)
		"somurtkan_sincap":
			_sulky_squirrel(root, pus)
		"balon_balik":
			_pufferfish(root, pus)
		"laf_kesen_ordek":
			_cutting_duck(root, pus)
		"patlayan_misir":
			_popcorn(root, pus)
		"kiskanc_civciv":
			_jealous_chick(root, pus)
	Toon.default_pus = 1.0
	if kind != "golge_kopya":
		if pus and MobStats.breathes(kind):
			# Kızıl Sis creatures keep their colors and puff steam instead
			_pus_wisps(root, 1.5, Color(1, 1, 1), 8, 0.9)
		elif pus:
			var top := 1.4
			for mi in root.find_children("*", "MeshInstance3D", true, false):
				top = maxf(top, (mi as MeshInstance3D).position.y + 0.3)
			_pus_wisps(root, top)
		CharacterRig.attach(root)
	return root


## Mobs ignore the scene's Pus amount (their own look tells it).
static func _no_pus(n: Node) -> void:
	_each_material(n, func(m: ShaderMaterial) -> void: m.set_shader_parameter("pus_affect", 0.0))


static func _drain(n: Node, amount: float) -> void:
	_each_material(n, func(m: ShaderMaterial) -> void: m.set_shader_parameter("desat", amount))


static func _each_material(n: Node, f: Callable) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			var m := mi.get_surface_override_material(i)
			if m is ShaderMaterial:
				f.call(m)
	for c in n.get_children():
		_each_material(c, f)


const GREY := Color("#77738a")
const GREY_LIGHT := Color("#a19db2")


## Pus-touched colors keep a faint hint of the mob's own color (so each
## mob still reads as itself) under a cool grey-violet.
static func _c(pus: bool, own: Variant, light := false) -> Variant:
	if pus:
		var c := Toon._resolve(own)
		var g := (GREY_LIGHT if light else GREY).lerp(c, 0.22)
		return g.lightened(0.05) if light else g
	return own


static func _face(root: Node3D, at: Vector3, s: float, pus: bool) -> void:
	for side: float in [-1.0, 1.0]:
		var eye := Node3D.new()
		eye.add_to_group("rig_eye")
		eye.position = at + Vector3(0.13 * side, 0.04, 0) * s
		root.add_child(eye)
		Toon.part(eye, "ellipsoid", Vector3(0.13, 0.17, 0.06) * s, "outline", Vector3.ZERO, Vector3.ZERO, 0.0, 0.0)
		Toon.part(eye, "ellipsoid", Vector3(0.05, 0.055, 0.02) * s, Color.WHITE, Vector3(0.022 * side, 0.04, 0.028) * s, Vector3.ZERO, 0.7, 0.0)
		if pus:
			# grumpy: a heavy lid over the top of the eye and a slanted brow
			Toon.part(eye, "ellipsoid", Vector3(0.16, 0.08, 0.07) * s, GREY.darkened(0.15), Vector3(0, 0.06, 0.012) * s, Vector3(0, 0, 14 * side), 0.0, 0.0)
			Toon.part(root, "capsule", Vector3(0.035, 0.17, 0.035) * s, "outline", at + Vector3(0.13 * side, 0.17, 0.015) * s, Vector3(0, 0, 70 * side), 0.0, 0.0)
		else:
			Toon.part(eye, "ellipsoid", Vector3(0.08, 0.07, 0.025) * s, Color("#6a55a8"), Vector3(0, -0.04, 0.02) * s, Vector3.ZERO, 0.0, 0.0)
			Toon.part(eye, "ellipsoid", Vector3(0.025, 0.025, 0.015) * s, Color.WHITE, Vector3(-0.03 * side, -0.045, 0.03) * s, Vector3.ZERO, 0.7, 0.0)
			var blush := Toon.part(root, "ellipsoid", Vector3(0.12, 0.06, 0.03) * s, "berry", at + Vector3(0.25 * side, -0.07, -0.01) * s, Vector3.ZERO, 0.0, 0.0)
			blush.transparency = 0.3
	# mouth: a little frown in the Pus, a smile once calm
	var my := at + Vector3(0, -0.11, 0.01) * s
	for side: float in [-1.0, 1.0]:
		Toon.part(root, "capsule", Vector3(0.024, 0.075, 0.024) * s, "outline", my + Vector3(0.026 * side, 0, 0) * s,
			Vector3(0, 0, (60.0 if pus else -60.0) * side), 0.0, 0.0)


## Grey wisps drifting off a Pus-touched mob (or white steam: `col`, `speed`).
static func _pus_wisps(root: Node3D, height: float, col := Color(0.55, 0.52, 0.66), amount := 5, speed := 0.45) -> void:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = 2.2
	p.preprocess = 2.2
	p.local_coords = true
	p.position = Vector3(0, height, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.35
	p.direction = Vector3(0, 1, 0)
	p.spread = 40.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = speed
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	g.colors = PackedColorArray([Color(col, 0.0), Color(col, 0.55), Color(col, 0.0)])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.45, 0.45)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = Weather.texture("soft")
	q.material = m
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(p)


## Kapıcı Rakun (Season 2): a round grey raccoon with a black mask, a
## striped tail and a little sack of grabbed things on its back.
static func _raccoon(root: Node3D, pus: bool) -> void:
	var fur := Color("#8d8a99")
	var dark := Color("#3c3a48")
	Toon.part(root, "ellipsoid", Vector3(0.95, 0.85, 0.9), fur, Vector3(0, 0.48, 0))
	Toon.part(root, "ellipsoid", Vector3(0.6, 0.55, 0.3), Color("#d9d6e2"), Vector3(0, 0.42, 0.32), Vector3.ZERO, 0.0, 0.0)
	Toon.part(root, "ellipsoid", Vector3(0.8, 0.68, 0.72), fur, Vector3(0, 1.08, 0.08))
	Toon.part(root, "ellipsoid", Vector3(0.72, 0.22, 0.2), dark, Vector3(0, 1.12, 0.38), Vector3.ZERO, 0.0, 0.0)
	Toon.part(root, "ellipsoid", Vector3(0.3, 0.2, 0.22), Color("#e8e4ee"), Vector3(0, 0.98, 0.42), Vector3.ZERO, 0.0, 0.0)
	Toon.part(root, "sphere", Vector3(0.1, 0.08, 0.08), "outline", Vector3(0, 1.0, 0.54), Vector3.ZERO, 0.0, 0.0)
	for side: float in [-1.0, 1.0]:
		Toon.part(root, "cone", Vector3(0.24, 0.26, 0.14), fur, Vector3(0.26 * side, 1.46, 0.02), Vector3(0, 0, -18 * side))
	for i in 4:
		Toon.part(root, "sphere", Vector3(0.3, 0.3, 0.3) * (1.0 - i * 0.1), dark if i % 2 == 0 else fur, Vector3(0, 0.3 + i * 0.12, -0.45 - i * 0.22))
	Toon.part(root, "sphere", Vector3(0.45, 0.42, 0.42), Color("#c9a06a"), Vector3(0.25, 0.85, -0.38))
	_face(root, Vector3(0, 1.12, 0.42), 0.85, pus)


## Somurtkan Sincap (Season 2): a russet squirrel with a big curled tail and
## an acorn to throw.
static func _sulky_squirrel(root: Node3D, pus: bool) -> void:
	var fur := Color("#c66a3a")
	Toon.part(root, "ellipsoid", Vector3(0.8, 0.85, 0.75), fur, Vector3(0, 0.45, 0))
	Toon.part(root, "ellipsoid", Vector3(0.48, 0.55, 0.28), Color("#f1d2a8"), Vector3(0, 0.42, 0.26), Vector3.ZERO, 0.0, 0.0)
	Toon.part(root, "ellipsoid", Vector3(0.72, 0.66, 0.66), fur, Vector3(0, 1.02, 0.05))
	for side: float in [-1.0, 1.0]:
		Toon.part(root, "cone", Vector3(0.2, 0.3, 0.12), fur, Vector3(0.22 * side, 1.42, 0.0), Vector3(0, 0, -10 * side))
	for i in 5:
		var a := i * 0.5
		Toon.part(root, "sphere", Vector3(0.5, 0.5, 0.5) * (1.0 - i * 0.08), fur.lightened(0.05 * i), Vector3(0, 0.45 + sin(a) * 0.7, -0.45 - cos(a) * 0.35 + i * 0.02))
	Toon.part(root, "ellipsoid", Vector3(0.22, 0.26, 0.22), Color("#8a5a3c"), Vector3(0.3, 0.6, 0.35))
	Toon.part(root, "ellipsoid", Vector3(0.24, 0.12, 0.24), Color("#5a3a28"), Vector3(0.3, 0.74, 0.35))
	_face(root, Vector3(0, 1.05, 0.36), 0.8, pus)


## Kaynar Balon Balık (Season 2): a round coral pufferfish hopping on its fins,
## soft spikes all round.
static func _pufferfish(root: Node3D, pus: bool) -> void:
	var skin := Color("#ff8c6a")
	Toon.part(root, "sphere", Vector3(1.1, 1.0, 1.05), skin, Vector3(0, 0.6, 0))
	Toon.part(root, "ellipsoid", Vector3(0.75, 0.55, 0.4), Color("#ffe0c8"), Vector3(0, 0.45, 0.36), Vector3.ZERO, 0.0, 0.0)
	for i in 10:
		var a := TAU * i / 10.0
		var p := Vector3(sin(a) * 0.55, 0.6 + cos(a * 2.0) * 0.15, cos(a) * 0.5)
		var c := Toon.part(root, "cone", Vector3(0.14, 0.24, 0.14), Color("#f2b33d"), p)
		c.look_at_from_position(p, p * 2.0 - Vector3(0, 0.6, 0), Vector3.UP)
		c.rotate_object_local(Vector3.RIGHT, -PI / 2)
	for side: float in [-1.0, 1.0]:
		Toon.part(root, "ellipsoid", Vector3(0.12, 0.35, 0.3), Color("#f27a5a"), Vector3(0.55 * side, 0.45, 0.0), Vector3(0, 0, 30 * side))
	Toon.part(root, "cone", Vector3(0.4, 0.4, 0.15), Color("#f27a5a"), Vector3(0, 0.65, -0.62), Vector3(-90, 0, 0))
	Toon.part(root, "ellipsoid", Vector3(0.18, 0.12, 0.1), Color("#c9452f"), Vector3(0, 0.45, 0.55), Vector3.ZERO, 0.0, 0.0)
	_face(root, Vector3(0, 0.75, 0.5), 0.85, pus)


## Laf Kesen Ördek (Season 2): a quick white duck with an orange bill, who
## always cuts in.
static func _cutting_duck(root: Node3D, pus: bool) -> void:
	var white := Color("#f4f1ea")
	Toon.part(root, "ellipsoid", Vector3(0.95, 0.8, 1.15), white, Vector3(0, 0.5, -0.05))
	Toon.part(root, "ellipsoid", Vector3(0.7, 0.7, 0.68), white, Vector3(0, 1.15, 0.2))
	Toon.part(root, "ellipsoid", Vector3(0.45, 0.16, 0.42), Color("#ff9a3c"), Vector3(0, 1.02, 0.55))
	Toon.part(root, "cone", Vector3(0.35, 0.3, 0.2), white, Vector3(0, 0.6, -0.65), Vector3(-70, 0, 0))
	for side: float in [-1.0, 1.0]:
		Toon.part(root, "ellipsoid", Vector3(0.15, 0.42, 0.62), Color("#dcd6c8"), Vector3(0.48 * side, 0.55, -0.05), Vector3(0, 0, 15 * side))
		Toon.part(root, "ellipsoid", Vector3(0.24, 0.08, 0.32), Color("#ff9a3c"), Vector3(0.2 * side, 0.04, 0.12))
	Toon.part(root, "torus", Vector3(0.55, 0.12, 0.55), "sky", Vector3(0, 0.88, 0.15))
	_face(root, Vector3(0, 1.22, 0.5), 0.8, pus)


## Patlayan Mısır Tanesi (Season 2): a puffy popcorn kernel on little feet.
static func _popcorn(root: Node3D, pus: bool) -> void:
	var cream := Color("#fff4d6")
	Toon.part(root, "sphere", Vector3(1.0, 0.9, 0.95), cream, Vector3(0, 0.55, 0))
	for i in 7:
		var a := TAU * i / 7.0
		Toon.part(root, "sphere", Vector3(0.45, 0.42, 0.45), cream, Vector3(sin(a) * 0.42, 0.75 + cos(a * 3.0) * 0.12, cos(a) * 0.38))
	Toon.part(root, "ellipsoid", Vector3(0.55, 0.35, 0.4), Color("#f2b33d"), Vector3(0, 0.25, -0.1))
	for side: float in [-1.0, 1.0]:
		Toon.part(root, "ellipsoid", Vector3(0.18, 0.1, 0.24), Color("#f2b33d"), Vector3(0.2 * side, 0.04, 0.1))
	_face(root, Vector3(0, 0.62, 0.46), 0.8, pus)


## Kıskanç Civciv (Season 2): a fluffy yellow chick with a tuft.
static func _jealous_chick(root: Node3D, pus: bool) -> void:
	var yellow := Color("#ffd94a")
	Toon.part(root, "sphere", Vector3(0.9, 0.85, 0.85), yellow, Vector3(0, 0.45, 0))
	Toon.part(root, "sphere", Vector3(0.7, 0.66, 0.66), yellow, Vector3(0, 1.0, 0.1))
	Toon.part(root, "cone", Vector3(0.22, 0.22, 0.16), Color("#ff9a3c"), Vector3(0, 0.95, 0.5), Vector3(90, 0, 0))
	Toon.part(root, "cone", Vector3(0.14, 0.3, 0.1), yellow, Vector3(0, 1.42, 0.05), Vector3(0, 0, 15))
	for side: float in [-1.0, 1.0]:
		Toon.part(root, "ellipsoid", Vector3(0.12, 0.3, 0.4), Color("#f2c53d"), Vector3(0.44 * side, 0.5, 0.0), Vector3(0, 0, 25 * side))
		Toon.part(root, "ellipsoid", Vector3(0.16, 0.06, 0.22), Color("#ff9a3c"), Vector3(0.16 * side, 0.03, 0.1))
	_face(root, Vector3(0, 1.05, 0.38), 0.75, pus)


## Puslu Sümüklü: a round slug with two eye stalks.
static func _slug(root: Node3D, pus: bool) -> void:
	var body: Variant = _c(pus, "berry")
	Toon.part(root, "capsule", Vector3(0.8, 1.5, 0.8), body, Vector3(0, 0.32, -0.1), Vector3(90, 0, 0))
	Toon.part(root, "sphere", Vector3(0.75, 0.7, 0.7), body, Vector3(0, 0.55, 0.45))
	Toon.part(root, "sphere", Vector3(0.8, 0.55, 0.9), _c(pus, "spark-purple", true), Vector3(0, 0.62, -0.35))
	# spiral shell on its back
	var shell: Variant = _c(pus, Color("#ffb86b"), true)
	Toon.part(root, "ellipsoid", Vector3(0.75, 0.75, 0.42), shell, Vector3(0, 0.95, -0.35), Vector3(0, 90, 0))
	Toon.part(root, "ring", Vector3(0.52, 0.06, 0.52), _c(pus, Color("#d9823a")), Vector3(0.2, 0.95, -0.35), Vector3(0, 0, 90), 0.0, 0.0)
	Toon.part(root, "ring", Vector3(0.28, 0.05, 0.28), _c(pus, Color("#d9823a")), Vector3(0.22, 0.98, -0.32), Vector3(0, 0, 90), 0.0, 0.0)
	for side in [-1.0, 1.0]:
		Toon.part(root, "cylinder", Vector3(0.07, 0.4, 0.07), body, Vector3(0.15 * side, 1.0, 0.5), Vector3(0, 0, -12 * side))
		Toon.part(root, "sphere", Vector3(0.16, 0.16, 0.16), body, Vector3(0.19 * side, 1.2, 0.5))
	_face(root, Vector3(0, 0.58, 0.78), 1.0, pus)


## Somurtkan Mantar: cream stem with a big spotted cap.
static func _mushroom(root: Node3D, pus: bool, s: float) -> void:
	Toon.part(root, "cylinder", Vector3(0.55, 0.7, 0.7) * s, _c(pus, Color("#fff3dc"), true), Vector3(0, 0.35, 0) * s)
	Toon.part(root, "sphere", Vector3(1.3, 0.85, 1.3) * s, _c(pus, "berry"), Vector3(0, 0.9, 0) * s)
	for i in 5:
		var a := deg_to_rad(i * 72.0)
		Toon.part(root, "sphere", Vector3(0.22, 0.12, 0.22) * s, _c(pus, Color("#fff8ec")) if pus else Color("#fff8ec"),
			Vector3(sin(a) * 0.4, 1.22, cos(a) * 0.4) * s, Vector3(cos(a) * -35, 0, sin(a) * 35), 0.0, 0.0)
	for side in [-1.0, 1.0]:
		Toon.part(root, "sphere", Vector3(0.2, 0.18, 0.24) * s, _c(pus, Color("#fff3dc"), true), Vector3(0.18 * side, 0.08, 0.15) * s)
		# little stubby arms
		Toon.part(root, "capsule", Vector3(0.14, 0.32, 0.14) * s, _c(pus, Color("#fff3dc"), true), Vector3(0.36 * side, 0.4, 0.05) * s, Vector3(0, 0, 50 * side))
	# a gill frill under the cap
	Toon.part(root, "cylinder", Vector3(1.1, 0.08, 1.1) * s, _c(pus, Color("#ffd9c4"), true), Vector3(0, 0.72, 0) * s, Vector3.ZERO, 0.0, 0.0)
	_face(root, Vector3(0, 0.45, 0.34) * s, s, pus)


## Huysuz Kirpi Topu: a little round hedgehog, quills all around.
static func _hedgehog_ball(root: Node3D, pus: bool) -> void:
	var quill: Variant = _c(pus, Color("#8a5a3c"))
	Toon.part(root, "sphere", Vector3(1.0, 0.95, 1.0), quill, Vector3(0, 0.5, 0))
	for i in 10:
		var a := TAU * i / 10.0
		var p := Vector3(sin(a) * 0.42, 0.7, cos(a) * 0.42 - 0.08)
		var c := Toon.part(root, "cone", Vector3(0.2, 0.36, 0.2), quill, p)
		c.look_at_from_position(p, p + Vector3(sin(a), 0.6, cos(a) - 0.3), Vector3.UP)
		c.rotate_object_local(Vector3.RIGHT, -PI / 2)
	Toon.part(root, "sphere", Vector3(0.62, 0.55, 0.4), _c(pus, Color("#f3dcb4"), true), Vector3(0, 0.45, 0.36))
	Toon.part(root, "sphere", Vector3(0.12, 0.1, 0.1), "outline", Vector3(0, 0.42, 0.58), Vector3.ZERO, 0.0, 0.0)
	_face(root, Vector3(0, 0.55, 0.5), 0.9, pus)


## Gıcık Karga: a round crow with a big beak and a tuft.
static func _crow(root: Node3D, pus: bool) -> void:
	var body: Variant = _c(pus, Color("#3d3a5c"))
	Toon.part(root, "sphere", Vector3(0.9, 0.85, 1.0), body, Vector3(0, 0.55, 0))
	Toon.part(root, "sphere", Vector3(0.7, 0.65, 0.65), body, Vector3(0, 1.05, 0.25))
	Toon.part(root, "cone", Vector3(0.26, 0.42, 0.26), _c(pus, "honey", true), Vector3(0, 1.0, 0.68), Vector3(90, 0, 0))
	Toon.part(root, "cone", Vector3(0.2, 0.3, 0.2), body, Vector3(0, 1.45, 0.15), Vector3(-20, 0, 0))
	for side in [-1.0, 1.0]:
		var w := Toon.part(root, "sphere", Vector3(0.9, 0.18, 0.6), body, Vector3(0.62 * side, 0.7, -0.05), Vector3(0, 0, -20 * side))
		w.name = "Wing%s" % ("L" if side < 0 else "R")
		Toon.part(root, "sphere", Vector3(0.12, 0.1, 0.16), _c(pus, "honey", true), Vector3(0.18 * side, 0.08, 0.1))
		for k in 3:
			Toon.part(root, "capsule", Vector3(0.05, 0.18, 0.05), _c(pus, "honey", true), Vector3(0.18 * side + (k - 1) * 0.05, 0.04, 0.2), Vector3(80, (k - 1) * 25, 0), 0.0, 0.0)
	# tail feathers
	for k in 3:
		Toon.part(root, "ellipsoid", Vector3(0.2, 0.5, 0.08), body, Vector3((k - 1) * 0.14, 0.62, -0.55), Vector3(-55, 0, (k - 1) * 20))
	_face(root, Vector3(0, 1.12, 0.52), 0.9, pus)


## Gri Kristal Böceği: a round beetle with crystal spikes on its shell.
static func _beetle(root: Node3D, pus: bool) -> void:
	var shell: Variant = _c(pus, "spark-purple")
	Toon.part(root, "sphere", Vector3(1.2, 0.8, 1.4), shell, Vector3(0, 0.5, -0.1))
	Toon.part(root, "sphere", Vector3(0.7, 0.55, 0.6), _c(pus, Color("#4a3f6b")), Vector3(0, 0.45, 0.62))
	for i in 3:
		Toon.part(root, "cone", Vector3(0.3, 0.6 - i * 0.1, 0.3), _c(pus, "sky", true), Vector3((i - 1) * 0.32, 0.95, -0.1 - absf(i - 1) * 0.15), Vector3(0, 0, (i - 1) * -20), 0.0 if pus else 0.8, 0.02)
	for side in [-1.0, 1.0]:
		for k in 3:
			Toon.part(root, "capsule", Vector3(0.1, 0.5, 0.1), _c(pus, Color("#4a3f6b")), Vector3(0.55 * side, 0.2, 0.3 - k * 0.35), Vector3(0, 0, 60 * side), 0.0, 0.0)
		Toon.part(root, "cylinder", Vector3(0.04, 0.4, 0.04), "outline", Vector3(0.15 * side, 0.85, 0.85), Vector3(40, 0, -20 * side), 0.0, 0.0)
	_face(root, Vector3(0, 0.5, 0.88), 0.8, pus)


## Yarasa Fısıltısı: a round bat with big ears and wide wings.
static func _bat(root: Node3D, pus: bool) -> void:
	var fur: Variant = _c(pus, Color("#5a4a8a"))
	Toon.part(root, "sphere", Vector3(0.8, 0.8, 0.75), fur, Vector3(0, 0.6, 0))
	for side in [-1.0, 1.0]:
		Toon.part(root, "cone", Vector3(0.32, 0.5, 0.2), fur, Vector3(0.24 * side, 1.08, 0), Vector3(0, 0, -15 * side))
		Toon.part(root, "cone", Vector3(0.16, 0.28, 0.08), _c(pus, "berry", true), Vector3(0.24 * side, 1.04, 0.08), Vector3(0, 0, -15 * side), 0.0, 0.0)
		var w := Toon.part(root, "sphere", Vector3(1.2, 0.12, 0.7), _c(pus, Color("#3d3266")), Vector3(0.8 * side, 0.7, -0.05), Vector3(0, 0, 15 * side))
		w.name = "Wing%s" % ("L" if side < 0 else "R")
		Toon.part(root, "cone", Vector3(0.08, 0.12, 0.08), Color.WHITE, Vector3(0.1 * side, 0.42, 0.36), Vector3(180, 0, 0), 0.0, 0.0)
	_face(root, Vector3(0, 0.66, 0.36), 0.8, pus)


## Fırtına Yumağı: a round puffy storm cloud with a grumpy face.
static func _storm_ball(root: Node3D, pus: bool) -> void:
	var cloud: Variant = _c(pus, Color("#e8f0ff"), true)
	Toon.part(root, "sphere", Vector3(1.3, 1.1, 1.2), cloud, Vector3(0, 0.75, 0))
	for i in 5:
		var a := TAU * i / 5.0
		Toon.part(root, "sphere", Vector3(0.7, 0.6, 0.7), cloud, Vector3(sin(a) * 0.55, 0.95 + (i % 2) * 0.25, cos(a) * 0.5))
	Toon.part(root, "cone", Vector3(0.3, 0.6, 0.1), _c(pus, "spark-yellow", true), Vector3(0.1, 0.2, 0.5), Vector3(0, 0, 160), 0.0 if pus else 0.8, 0.02)
	_face(root, Vector3(0, 0.85, 0.6), 0.9, pus)


## Korsan Martı: a round gull with a pirate bandana.
static func _pirate_gull(root: Node3D, pus: bool) -> void:
	var body: Variant = _c(pus, Color("#ffffff"), true)
	Toon.part(root, "sphere", Vector3(0.9, 0.85, 1.0), body, Vector3(0, 0.55, 0))
	Toon.part(root, "sphere", Vector3(0.7, 0.65, 0.65), body, Vector3(0, 1.05, 0.25))
	Toon.part(root, "cone", Vector3(0.24, 0.45, 0.24), _c(pus, "honey"), Vector3(0, 0.98, 0.7), Vector3(90, 0, 0))
	Toon.part(root, "sphere", Vector3(0.74, 0.3, 0.7), _c(pus, "hp"), Vector3(0, 1.32, 0.2))
	for side in [-1.0, 1.0]:
		var w := Toon.part(root, "sphere", Vector3(1.0, 0.16, 0.6), _c(pus, Color("#9aa7b8")), Vector3(0.66 * side, 0.7, -0.05), Vector3(0, 0, -20 * side))
		w.name = "Wing%s" % ("L" if side < 0 else "R")
	_face(root, Vector3(0, 1.1, 0.52), 0.9, pus)


## Kar Topu Tavşanı: a fluffy snow bunny holding a snowball.
static func _snow_bunny(root: Node3D, pus: bool) -> void:
	var fur: Variant = _c(pus, Color("#f7faff"), true)
	Toon.part(root, "sphere", Vector3(0.9, 0.95, 0.85), fur, Vector3(0, 0.5, 0))
	Toon.part(root, "sphere", Vector3(0.85, 0.75, 0.8), fur, Vector3(0, 1.15, 0.05))
	for side in [-1.0, 1.0]:
		Toon.part(root, "capsule", Vector3(0.2, 0.7, 0.14), fur, Vector3(0.15 * side, 1.7, -0.02), Vector3(0, 0, -12 * side))
		Toon.part(root, "capsule", Vector3(0.1, 0.45, 0.06), _c(pus, "sky", true), Vector3(0.15 * side, 1.7, 0.05), Vector3(0, 0, -12 * side), 0.0, 0.0)
	Toon.part(root, "sphere", Vector3(0.45, 0.45, 0.45), MountainKit.SNOW, Vector3(0.45, 0.7, 0.4))
	_face(root, Vector3(0, 1.15, 0.42), 0.9, pus)


## Buz Dikeni: a little plant of ice spikes with a grumpy face.
static func _ice_spike(root: Node3D, pus: bool) -> void:
	var ice: Variant = _c(pus, MountainKit.ICE, true)
	Toon.part(root, "sphere", Vector3(1.1, 0.7, 1.1), ice, Vector3(0, 0.35, 0))
	for i in 6:
		var a := TAU * i / 6.0
		Toon.part(root, "cone", Vector3(0.35, 1.0, 0.35), ice, Vector3(sin(a) * 0.4, 0.9, cos(a) * 0.4), Vector3(cos(a) * -25, 0, sin(a) * 25), 0.0 if pus else 0.5, 0.02)
	Toon.part(root, "cone", Vector3(0.45, 1.3, 0.45), ice, Vector3(0, 1.1, 0), Vector3.ZERO, 0.0 if pus else 0.5, 0.02)
	_face(root, Vector3(0, 0.45, 0.5), 0.8, pus)


## Gölge Kopya: the player's own shape, grey and misty (Pus's copy of you).
## When calmed it turns into a soft light version and fades.
static func _shadow_copy(root: Node3D, pus: bool) -> void:
	var d: PlayerData = Engine.get_main_loop().root.get_node("GameState").data
	var model := FistikModel.build() if d.character_id == "fistik" else KeeperModels.build(d.character_id, d.character_look)
	root.add_child(model)
	var tint := Toon.material(Color("#6e6a86") if pus else Color("#e8e2ff"), 0.035, 0.0 if pus else 0.6, 0.0)
	var rig := CharacterRig.of(model)
	if rig and not rig.materials.is_empty():
		# a real model: drain its texture to shadow grey (or a pale glow once
		# calm) so it still walks, swings and blinks
		for m: ShaderMaterial in rig.materials:
			if m.shader == Toon.TOON_SHADER:
				m.set_shader_parameter("desat", 1.0)
				m.set_shader_parameter("pus_affect", 0.0)
				m.set_shader_parameter("albedo", Color("#8a85a8") if pus else Color("#ffffff"))
				if not pus:
					m.set_shader_parameter("emission_color", Color("#e8e2ff"))
					m.set_shader_parameter("emission_strength", 0.35)
		# hats and tools on it take the flat shadow tint
		var fit := model.get_node_or_null("Pose/Fit")
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			if fit == null or not fit.is_ancestor_of(mi):
				(mi as MeshInstance3D).material_override = tint
		return
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = tint
	for side in [-1.0, 1.0]:
		Toon.part(root, "sphere", Vector3(0.16, 0.2, 0.08), "spark-purple" if pus else "spark-white", Vector3(0.17 * side, 1.34, 0.46), Vector3.ZERO, 2.0, 0.0)

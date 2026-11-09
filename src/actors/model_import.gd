class_name ModelImport
extends RefCounted
## Real 3D models drop in here: put `assets/models/<id>.glb` (pati, bado,
## citir, lumi, fistik, an NPC kind like "turtle", or a mob id) into the
## project and it replaces the primitive placeholder, no code change.
## The model is
##   - turned to face +Z (glTF faces +Z already; set "facing" in the json to fix others)
##   - scaled so it is `height` meters tall (default from HEIGHTS) and stands on y=0
##   - given the toon look: each material's color/texture goes into
##     toon.gdshader with the dark outline as next pass
## Optional `assets/models/<id>.json`: {"height": 2.0, "facing": 180, "outline": 0.03,
## "model": "other_id" (reuse that model's file), "glow": 0.5 (shines a little),
## "lift": 0.2 (floats above the ground, e.g. flying mobs),
## "tint": [r, g, b]} (tint multiplies the texture, e.g. to take out light that
## was baked into an AI-made texture)
## Animations named idle / walk / run / jump / attack (any case, any prefix)
## are played by CharacterRig.

const DIR := "res://assets/models/"
const HEIGHTS := {"pati": 2.0, "bado": 2.1, "citir": 2.0, "lumi": 2.05, "fistik": 1.95}


static func path_for(id: String) -> String:
	for ext: String in [".glb", ".gltf"]:
		var p := DIR + id + ext
		if ResourceLoader.exists(p):
			return p
	# "model": another id's file, e.g. mole_kid uses mole.glb at a smaller height
	var other := String(_options(id).get("model", ""))
	if other != "" and other != id:
		return path_for(other)
	return ""


## Returns a ready model root (with Pose + Rig) or null if there is no file.
static func load_model(id: String) -> Node3D:
	var path := path_for(id)
	if path == "":
		return null
	var scene := load(path) as PackedScene
	if scene == null:
		push_warning("Model yüklenemedi: " + path)
		return null
	return from_scene(scene.instantiate() as Node3D, id)


## A boss drawn from a real model: the imported mesh plus empty nodes named
## like the parts the boss code looks up (faces it shows or hides, a tail it
## turns), so the same fight code runs on either look. Null without a file.
static func boss(id: String, names: Array) -> Node3D:
	var m := load_model(id)
	if m == null:
		return null
	var root := Node3D.new()
	root.add_child(m)
	for n: String in names:
		var e := Node3D.new()
		e.name = n
		root.add_child(e)
	return root


## A model for a prop: toon look and facing, no fit and no rig.
static func load_static(id: String) -> Node3D:
	var path := path_for(id)
	if path == "":
		return null
	var scene := load(path) as PackedScene
	if scene == null:
		return null
	var opts := _options(id)
	var model := scene.instantiate() as Node3D
	var root := Node3D.new()
	root.name = id.capitalize()
	root.add_child(model)
	model.rotation_degrees.y = float(opts.get("facing", 0.0))
	var tint := Color.WHITE
	var t: Variant = opts.get("tint")
	if t is Array and (t as Array).size() >= 3:
		tint = Color(float(t[0]), float(t[1]), float(t[2]))
	toonify(model, float(opts.get("outline", 0.03)), tint, float(opts.get("glow", 0.0)))
	return root


static var _static_bounds := {}


## Bounds of a prop model's file at scale 1 (to fit `load_static` copies).
static func static_bounds(id: String) -> AABB:
	if not _static_bounds.has(id):
		# the raw file, not a toon copy (freeing one outside the tree spams
		# "material is null" from its shader instance parameters)
		var box := AABB(Vector3(-0.5, 0, -0.5), Vector3.ONE)
		var path := path_for(id)
		var scene := load(path) as PackedScene if path != "" else null
		if scene:
			var raw := scene.instantiate() as Node3D
			var turn := Transform3D(Basis(Vector3.UP, deg_to_rad(float(_options(id).get("facing", 0.0)))), Vector3.ZERO)
			box = _bounds(raw, turn)
			raw.free()
		_static_bounds[id] = box
	return _static_bounds[id]


static func static_height(id: String) -> float:
	return maxf(static_bounds(id).size.y, 0.01)


## Dress a WorldLook.block (StaticBody3D with a box shape) in a prop model:
## the model is stretched over the box (`grow` widens x/z so neighbours
## meet), the box keeps its collider and hides its own mesh. False without
## the file (the box keeps its look).
static func cover_block(body: StaticBody3D, id: String, grow := Vector3(1.0, 1.0, 1.0), yaw := 0.0) -> bool:
	var shape: BoxShape3D = null
	for c in body.get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape is BoxShape3D:
			shape = (c as CollisionShape3D).shape
	if shape == null or body.get_parent() == null:
		return false
	var m := fit_static(id, body.get_parent() as Node3D, body.position, shape.size * grow, yaw)
	if m == null:
		return false
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visible = false
	return true


## Like cover_block for a long wall: a row of pieces (ids in turn) along
## the box's longer side, each about `step` long, slightly overlapping.
static func cover_row(body: StaticBody3D, ids: Array, step := 6.0, grow := Vector3(1.3, 1.08, 1.3)) -> bool:
	var shape: BoxShape3D = null
	for c in body.get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape is BoxShape3D:
			shape = (c as CollisionShape3D).shape
	if shape == null or body.get_parent() == null or path_for(String(ids[0])) == "":
		return false
	var along_x := shape.size.x >= shape.size.z
	var length := shape.size.x if along_x else shape.size.z
	var n := maxi(1, int(round(length / step)))
	var seg := length / n
	for i in n:
		var off := -length * 0.5 + seg * (i + 0.5)
		var at := body.position + (Vector3(off, 0, 0) if along_x else Vector3(0, 0, off))
		var size := Vector3(seg, shape.size.y, shape.size.z) if along_x else Vector3(shape.size.x, shape.size.y, seg)
		fit_static(String(ids[i % ids.size()]), body.get_parent() as Node3D, at, size * grow, PI * float(i % 2))
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visible = false
	return true


## A prop model stretched over a box (center, size): the box keeps its
## collider and loses its look. Null without the file.
static func fit_static(id: String, parent: Node3D, center: Vector3, size: Vector3, yaw := 0.0) -> Node3D:
	var m := load_static(id)
	if m == null:
		return null
	var b := static_bounds(id)
	var s := Vector3(size.x / maxf(b.size.x, 0.01), size.y / maxf(b.size.y, 0.01), size.z / maxf(b.size.z, 0.01))
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.position = center
	holder.rotation.y = yaw
	holder.add_child(m)
	m.scale = s
	m.position = -(b.position + b.size * 0.5) * s
	return holder


## Wraps any loaded model (fit, toon look, rig). Also used by the import check.
static func from_scene(model: Node3D, id: String) -> Node3D:
	var opts := _options(id)
	var root := Node3D.new()
	root.name = id.capitalize()
	var pose := Node3D.new()
	pose.name = "Pose"
	root.add_child(pose)
	var fit := Node3D.new()
	fit.name = "Fit"
	pose.add_child(fit)
	fit.add_child(model)
	model.rotation_degrees.y = float(opts.get("facing", 0.0))
	var tint := Color.WHITE
	var t: Variant = opts.get("tint")
	if t is Array and (t as Array).size() >= 3:
		tint = Color(float(t[0]), float(t[1]), float(t[2]))
	toonify(model, float(opts.get("outline", 0.03)), tint, float(opts.get("glow", 0.0)))
	if opts.has("pus"):
		# how much the scene's Pus greys it (bosses keep their own look)
		for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			for i in mi.get_surface_override_material_count():
				var sm := mi.get_surface_override_material(i) as ShaderMaterial
				if sm:
					sm.set_shader_parameter("pus_affect", float(opts["pus"]))
	var box := _bounds(model, Transform3D.IDENTITY)
	if box.size.y > 0.001:
		var s := float(opts.get("height", HEIGHTS.get(id, 2.0))) / box.size.y
		fit.scale = Vector3.ONE * s
		fit.position = Vector3(-(box.position.x + box.size.x * 0.5) * s, -box.position.y * s + float(opts.get("lift", 0.0)), -(box.position.z + box.size.z * 0.5) * s)
	var rig := CharacterRig.new()
	rig.name = "Rig"
	rig.pose = pose
	rig.materials = _rig_setup(model, pose, id, opts)
	root.add_child(rig)
	return root


## Body-region shapes (fractions of the height, see rig.gdshaderinc).
## "rig" in the json overrides: legs, arm_x, arm_y [low, high], neck,
## tail (z behind, negative; 0 = none), wings (0..1), stride.
const RIG_DEFAULT := {"legs": 0.14, "arm_x": 0.17, "arm_y": [0.14, 0.42], "neck": 0.46, "tail": 0.0, "wings": 0.0, "stride": 1.0}
static var _eye_cache: Dictionary = {}


## Gives every material of the model the shape rig (and eyes to blink);
## returns the materials so CharacterRig can drive them.
static func _rig_setup(model: Node3D, pose: Node3D, id: String, opts: Dictionary) -> Array:
	var r: Dictionary = RIG_DEFAULT.duplicate()
	var over: Variant = opts.get("rig")
	if over is Dictionary:
		r.merge(over, true)
	var h := float(opts.get("height", HEIGHTS.get(id, 2.0)))
	var ay: Array = r["arm_y"]
	var shape := Vector4(float(r["legs"]), float(r["arm_x"]), float(ay[0]), float(ay[1]))
	var shape2 := Vector4(float(r["neck"]), float(r["tail"]), float(r["wings"]), float(r["stride"]))
	var eyes := _eyes(model, pose, id, opts, h)
	var lid_hex: Variant = opts.get("lid")
	if lid_hex == null and opts.has("model"):
		lid_hex = _options(String(opts["model"])).get("lid")
	var lid := Color(String(lid_hex)) if lid_hex != null else Color.BLACK
	var mats: Array = []
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var xf := _rel(mi, pose)
		for i in mi.mesh.get_surface_count():
			var m := mi.get_surface_override_material(i) as ShaderMaterial
			if m == null:
				continue
			var pair: Array = [m]
			if m.next_pass is ShaderMaterial:
				m.next_pass = m.next_pass.duplicate()
				pair.append(m.next_pass)
			for sm: ShaderMaterial in pair:
				sm.set_shader_parameter("rig_on", 1.0)
				sm.set_shader_parameter("rig_to", Projection(xf))
				sm.set_shader_parameter("rig_from", Projection(xf.affine_inverse()))
				sm.set_shader_parameter("rig_h", h)
				sm.set_shader_parameter("rig_shape", shape)
				sm.set_shader_parameter("rig_shape2", shape2)
				mats.append(sm)
			if eyes.size() == 2:
				m.set_shader_parameter("rig_eye_l", eyes[0])
				m.set_shader_parameter("rig_eye_r", eyes[1])
				m.set_shader_parameter("rig_lid", lid)
	return mats


## `node`'s transform relative to `top` (one of its ancestors).
static func _rel(node: Node3D, top: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != top:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


## Eye centers (character space, w = radius) from "eyes" [[x, y, r, z], ...]
## (fractions of the height, found by tools/find_eyes.py on the model's own
## file); without z the depth is the front-most surface there. Cached per id.
static func _eyes(model: Node3D, pose: Node3D, id: String, opts: Dictionary, h: float) -> Array:
	if _eye_cache.has(id):
		return _eye_cache[id]
	var src: Variant = opts.get("eyes")
	if src == null:
		var other := String(opts.get("model", ""))
		if other != "":
			var o2 := _options(other)
			src = o2.get("eyes")
	var out: Array = []
	if src is Array and (src as Array).size() == 2:
		var meshes := model.find_children("*", "MeshInstance3D", true, false)
		for e: Array in src:
			var c := Vector3(float(e[0]), float(e[1]), 0.0) * h
			var rad := float(e[2]) * h
			if e.size() >= 4:
				# depth stored by --demo=eyes (no mesh read-back on phones)
				out.append(Vector4(c.x, c.y, float(e[3]) * h, rad))
				continue
			var front := -INF
			for mi: MeshInstance3D in meshes:
				if mi.mesh == null:
					continue
				var xf := _rel(mi, pose)
				for si in mi.mesh.get_surface_count():
					var verts: PackedVector3Array = mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
					for v in verts:
						var p := xf * v
						if absf(p.x - c.x) < rad * 0.5 and absf(p.y - c.y) < rad * 0.5 and p.z > front:
							front = p.z
			if front > -INF:
				out.append(Vector4(c.x, c.y, front - rad * 0.15, rad))
	if out.size() != 2:
		out = []
	_eye_cache[id] = out
	return out


## A real model for a boss whose code turns named parts: each name in
## `parts` (e.g. {"WingL": Vector3(-1, 2, 0)}) becomes an empty node at that
## place; turning it bends that side of the model (see CharacterRig.proxies).
## Returns null if there is no file.
static func with_parts(id: String, parts: Dictionary) -> Node3D:
	var root := load_model(id)
	if root == null:
		return null
	var rig := CharacterRig.of(root)
	for n: String in parts:
		var at: Vector3 = parts[n]
		var p := Node3D.new()
		p.name = n
		p.position = at
		root.add_child(p)
		if rig and absf(at.x) > 0.01:
			rig.proxies.append([p, signf(at.x)])
	return root


static func _options(id: String) -> Dictionary:
	var p := DIR + id + ".json"
	if not FileAccess.file_exists(p):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	return data if data is Dictionary else {}


## Replaces every material under `node` with the toon shader (+ outline).
static func toonify(node: Node, outline := 0.03, tint := Color.WHITE, glow := 0.0) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				var src := mi.get_active_material(i)
				mi.set_surface_override_material(i, _toon_from(src, outline, tint, glow))
	for c in node.get_children():
		toonify(c, outline, tint, glow)


static func _toon_from(src: Material, outline: float, tint := Color.WHITE, extra_glow := 0.0) -> ShaderMaterial:
	var col := Color.WHITE
	var tex: Texture2D = null
	var glow := extra_glow
	if src is BaseMaterial3D:
		var b := src as BaseMaterial3D
		col = b.albedo_color
		tex = b.albedo_texture
		if b.emission_enabled:
			glow = b.emission_energy_multiplier
	col *= tint
	var m := Toon.material(col, outline, glow).duplicate() as ShaderMaterial
	if tex:
		m.set_shader_parameter("albedo_tex", tex)
		# the shade band is tinted from the flat color; keep it neutral for textures
		m.set_shader_parameter("shade_color", Color.WHITE.lerp(Color("#6b5f80"), 0.45) * col)
	return m


static func _bounds(node: Node, xf: Transform3D) -> AABB:
	var box := AABB()
	var first := true
	var t := xf
	if node is Node3D:
		t = xf * (node as Node3D).transform
	if node is VisualInstance3D:
		var vt := t
		if node is MeshInstance3D and (node as MeshInstance3D).skin != null:
			# a skinned mesh is placed by its bones, not by the (often 0.01)
			# armature scale above it: its rest pose is in its own units
			vt = Transform3D(t.basis.orthonormalized(), t.origin)
		var b := vt * (node as VisualInstance3D).get_aabb()
		if node is MeshInstance3D and (node as MeshInstance3D).skin != null and (node as MeshInstance3D).mesh:
			b = vt * (node as MeshInstance3D).mesh.get_aabb()
		box = b
		first = false
	for c in node.get_children():
		var cb := _bounds(c, t)
		if cb.size == Vector3.ZERO:
			continue
		box = cb if first else box.merge(cb)
		first = false
	return box

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
	var box := _bounds(model, Transform3D.IDENTITY)
	if box.size.y > 0.001:
		var s := float(opts.get("height", HEIGHTS.get(id, 2.0))) / box.size.y
		fit.scale = Vector3.ONE * s
		fit.position = Vector3(-(box.position.x + box.size.x * 0.5) * s, -box.position.y * s + float(opts.get("lift", 0.0)), -(box.position.z + box.size.z * 0.5) * s)
	var rig := CharacterRig.new()
	rig.name = "Rig"
	rig.pose = pose
	root.add_child(rig)
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
		var b := t * (node as VisualInstance3D).get_aabb()
		box = b
		first = false
	for c in node.get_children():
		var cb := _bounds(c, t)
		if cb.size == Vector3.ZERO:
			continue
		box = cb if first else box.merge(cb)
		first = false
	return box

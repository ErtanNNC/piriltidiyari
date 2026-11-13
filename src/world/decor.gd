class_name Decor
extends RefCounted
## Ground decor: grass, flowers, pebbles, ferns, mushrooms, crystals, snow
## tufts. `Decor.auto(scene, style)` finds the walkable floors of a scene
## (upright box/cylinder meshes with a collider right under their top) and
## scatters little MultiMesh props on them, chosen by the floor's color
## (green, snow, or stone/earth) and the chapter style. Thin flat meshes
## (paths) stay clear. Nothing collides, so routes never change.
## Floors also get soft world-space color blotches (toon patch_strength).

const DECOR_SHADER := preload("res://src/world/decor.gdshader")
const CHUNK := 16.0
const MAX_PER_MESH := {"grass": 4200, "grass_short": 2000, "flower": 700, "tulip": 400,
	"pebble": 900, "rock": 200, "mushroom": 260, "fern": 400, "crystal": 260,
	"leaf": 700, "tuft": 500}

## style -> floor class -> [[mesh, per m², palette, scale min, scale max, glow]]
const STYLES := {
	"koy": {
		"green": [["grass", 1.1, [], 0.9, 1.3, 0.0],
			["flower", 0.05, ["#ffd24a", "#ff7aa8", "#7cc8ff", "#ffffff", "#c9a6ff"], 1.3, 1.7, 0.0],
			["tulip", 0.025, ["#ff7aa8", "#ff9a52", "#ffd24a"], 1.4, 1.8, 0.0],
			["pebble", 0.02, ["#a99f94", "#9a90a6", "#b8ad9d"], 1.2, 2.2, 0.0],
			["mushroom", 0.006, ["#ff6b6b", "#ff9a52"], 0.9, 1.4, 0.0]],
		"earth": [["pebble", 0.1, ["#b8a793", "#a99a8f", "#c9bca9"], 1.0, 1.9, 0.0]],
	},
	"orman": {
		"green": [["grass", 1.25, [], 0.9, 1.5, 0.0],
			["fern", 0.05, ["#3f9f58", "#4fb468"], 0.9, 1.5, 0.0],
			["mushroom", 0.03, ["#ff6b6b", "#ff9a52", "#c99bff"], 0.8, 1.6, 0.0],
			["flower", 0.02, ["#ffffff", "#ffd24a", "#c9a6ff"], 0.9, 1.2, 0.0],
			["leaf", 0.06, ["#e88a3c", "#f2b33d", "#c4643a"], 0.9, 1.4, 0.0],
			["pebble", 0.02, ["#a9a39a", "#8f9a8c"], 0.8, 1.8, 0.0]],
		"earth": [["pebble", 0.08, ["#a99a8f", "#8f8478"], 1.0, 2.0, 0.0],
			["leaf", 0.05, ["#e88a3c", "#f2b33d"], 0.9, 1.3, 0.0]],
	},
	"magara": {
		"green": [["grass_short", 0.6, [], 0.9, 1.2, 0.0],
			["mushroom", 0.03, ["#7ce8ff", "#c99bff"], 0.8, 1.5, 0.8]],
		"earth": [["pebble", 0.12, ["#8d7fb0", "#a596c9", "#6f6394"], 1.2, 2.4, 0.0],
			["rock", 0.01, ["#7d6fa3", "#9384ba"], 0.9, 1.6, 0.0],
			["crystal", 0.04, ["#ff8fd8", "#7ce8ff", "#c99bff", "#ffd27a"], 1.6, 2.8, 0.9],
			["mushroom", 0.02, ["#7ce8ff", "#c99bff"], 1.4, 2.2, 0.8]],
	},
	"liman": {
		"green": [["grass", 1.0, [], 0.9, 1.3, 0.0],
			["flower", 0.05, ["#ffffff", "#7cc8ff", "#ffd24a", "#ff7aa8"], 0.9, 1.2, 0.0],
			["pebble", 0.015, ["#d8cdbd", "#c9c0b4"], 0.8, 1.5, 0.0]],
	},
	"dag": {
		"snow": [["tuft", 0.07, ["#ffffff", "#eef3ff"], 0.7, 1.6, 0.0],
			["pebble", 0.04, ["#b9c6e6", "#9fb0d6", "#c9d0f0"], 1.0, 2.0, 0.0],
			["grass_short", 0.12, ["#c6dccb", "#b7cfc0"], 0.8, 1.2, 0.0]],
		"green": [["grass", 0.8, [], 0.9, 1.3, 0.0],
			["flower", 0.02, ["#ffffff", "#c9a6ff"], 0.9, 1.2, 0.0]],
		"earth": [["pebble", 0.08, ["#a3a8c2", "#8f94b0"], 1.0, 2.0, 0.0],
			["rock", 0.008, ["#a3a8c2", "#b9bdd6"], 0.7, 1.3, 0.0]],
	},
	"kale": {
		"green": [["grass_short", 0.5, [], 0.9, 1.2, 0.0]],
		"earth": [["pebble", 0.1, ["#7d769c", "#8f88ad", "#6a6488"], 1.2, 2.4, 0.0],
			["rock", 0.015, ["#7d769c", "#8f88ad"], 1.0, 1.8, 0.0],
			["crystal", 0.012, ["#b08cff", "#8f6bff"], 1.5, 2.4, 0.7]],
	},
	"kumsal": {
		"earth": [["pebble", 0.06, ["#f4e6d0", "#f7c6c0", "#e8d2b0", "#ffffff"], 0.9, 1.7, 0.0],
			["rock", 0.004, ["#b8a58a", "#a8967e"], 0.7, 1.3, 0.0]],
		"green": [["grass_short", 0.3, [], 0.9, 1.2, 0.0]],
	},
	"kule": {
		"earth": [["pebble", 0.05, ["#a6a2b4", "#8e8aa0"], 1.0, 2.0, 0.0]],
	},
}

static var _patched: Dictionary = {}


## Waits for physics, then decorates every floor under `root`.
static func auto(root: Node3D, style: String, seed_value := 0) -> void:
	if not STYLES.has(style):
		return
	var tree := root.get_tree()
	await tree.physics_frame
	await tree.physics_frame
	if not is_instance_valid(root):
		return
	scatter(root, style, seed_value)


## Synchronous version (needs bodies already in the physics space).
## Returns the number of placed props per mesh.
static func scatter(root: Node3D, style: String, seed_value := 0) -> Dictionary:
	_patched.clear()  # last scene's floor materials must not stay alive
	var rules: Dictionary = STYLES[style]
	var floors: Array = []
	var paths: Array = []
	_collect(root, floors, paths)
	var space := root.get_world_3d().direct_space_state
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(style) + seed_value
	# area per mesh first, so dense styles thin out evenly under the caps
	var wanted: Dictionary = {}
	for f: Dictionary in floors:
		for r: Array in rules.get(f["class"], []):
			wanted[r[0]] = float(wanted.get(r[0], 0.0)) + f["area"] * float(r[1])
	var thin: Dictionary = {}
	for m: String in wanted:
		thin[m] = minf(1.0, float(MAX_PER_MESH.get(m, 500)) / maxf(float(wanted[m]), 1.0))
	var chunks: Dictionary = {}  # "mesh|cx|cz" -> Array of [Transform3D, Color]
	for f: Dictionary in floors:
		var list: Array = rules.get(f["class"], [])
		if list.is_empty():
			continue
		_patch(f)
		for r: Array in list:
			var mesh_id: String = r[0]
			var count := int(f["area"] * float(r[1]) * float(thin[mesh_id]) + rng.randf())
			var palette: Array = r[2]
			for i in count:
				var p := _random_point(f, rng)
				if p == Vector3.INF or _on_path(p, paths) or not _clear(space, p):
					continue
				var col: Color
				if palette.is_empty():
					# grass takes the floor color, a little lighter and greener
					var fc: Color = f["color"]
					col = Color.from_hsv(fc.h + rng.randf_range(-0.02, 0.03), minf(fc.s * 1.35 + 0.08, 1.0), fc.v * rng.randf_range(0.78, 0.9))
				else:
					col = Color(String(palette[rng.randi() % palette.size()]))
				col.a = float(r[5])
				var s := rng.randf_range(float(r[3]), float(r[4]))
				var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s))
				if mesh_id == "rock" or mesh_id == "pebble" or mesh_id == "tuft":
					basis = basis * Basis(Vector3.RIGHT, rng.randf_range(-0.15, 0.15))
				var key := "%s|%d|%d" % [mesh_id, floori(p.x / CHUNK), floori(p.z / CHUNK)]
				if not chunks.has(key):
					chunks[key] = []
				chunks[key].append([Transform3D(basis, p), col])
	var holder := Node3D.new()
	holder.name = "Decor"
	root.add_child(holder)
	var placed: Dictionary = {}
	for key: String in chunks:
		var mesh_id := key.get_slice("|", 0)
		var items: Array = chunks[key]
		placed[mesh_id] = int(placed.get(mesh_id, 0)) + items.size()
		holder.add_child(_multimesh(mesh_id, items))
	return placed


static func _multimesh(mesh_id: String, items: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	# the Compatibility renderer multiplies vertex COLOR by the instance color
	mm.use_colors = true
	mm.mesh = DecorMeshes.get_mesh(mesh_id)
	mm.instance_count = items.size()
	for i in items.size():
		mm.set_instance_transform(i, items[i][0])
		mm.set_instance_custom_data(i, items[i][1])
		mm.set_instance_color(i, Color.WHITE)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = _material(mesh_id)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# small props fade out far away (the camera mostly looks down nearby)
	mi.visibility_range_end = 70.0
	return mi


static var _materials: Dictionary = {}


static func _material(mesh_id: String) -> ShaderMaterial:
	if _materials.has(mesh_id):
		return _materials[mesh_id]
	var m := ShaderMaterial.new()
	m.shader = DECOR_SHADER
	match mesh_id:
		"grass", "grass_short":
			m.set_shader_parameter("sway", 0.11)
			m.set_shader_parameter("tip_light", 1.0)
		"flower", "tulip", "fern":
			m.set_shader_parameter("sway", 0.07)
			m.set_shader_parameter("tip_light", 0.3 if mesh_id == "fern" else 0.0)
	if mesh_id in ["pebble", "rock", "mushroom", "crystal", "tuft"]:
		var o := ShaderMaterial.new()
		o.shader = Toon.OUTLINE_SHADER
		o.set_shader_parameter("outline_color", Tokens.color("outline"))
		o.set_shader_parameter("thickness", 0.012 if mesh_id != "rock" else 0.02)
		m.next_pass = o
	_materials[mesh_id] = m
	return m


## Finds floors and paths among upright box/cylinder meshes.
static func _collect(node: Node, floors: Array, paths: Array) -> void:
	for child in node.get_children():
		if child is CharacterBody3D or child is Area3D or child is AnimatableBody3D:
			continue
		if child is MultiMeshInstance3D:
			continue
		if child is MeshInstance3D:
			var f := _floor_of(child)
			if not f.is_empty():
				if f["thin"]:
					paths.append(f)
				elif f["area"] >= 2.5:
					floors.append(f)
		_collect(child, floors, paths)


static func _floor_of(mi: MeshInstance3D) -> Dictionary:
	if not mi.is_visible_in_tree():
		return {}
	var mesh := mi.mesh
	var t := mi.global_transform
	if t.basis.y.normalized().dot(Vector3.UP) < 0.995:
		return {}
	var sx := t.basis.x.length()
	var sy := t.basis.y.length()
	var sz := t.basis.z.length()
	var shape := ""
	var half := Vector2.ZERO
	var height := 0.0
	if mesh is BoxMesh:
		shape = "box"
		half = Vector2(mesh.size.x * sx, mesh.size.z * sz) * 0.5
		height = mesh.size.y * sy
	elif mesh is CylinderMesh and absf(mesh.top_radius - mesh.bottom_radius) < 0.01 * maxf(mesh.top_radius, 0.01) + 0.001:
		shape = "disc"
		half = Vector2(mesh.top_radius * sx, mesh.top_radius * sz)
		height = mesh.height * sy
	else:
		return {}
	if minf(half.x, half.y) < 0.7:
		return {}
	var thin := height < 0.15
	var area := half.x * half.y * (4.0 if shape == "box" else PI)
	var col := Color.WHITE
	var mat := mi.material_override
	if mat is ShaderMaterial and mat.get_shader_parameter("albedo") != null:
		col = mat.get_shader_parameter("albedo")
	elif not thin:
		return {}
	return {"mi": mi, "shape": shape, "half": half, "top": t.origin.y + height * 0.5,
		"xform": t, "area": area, "thin": thin, "color": col, "class": _classify(col)}


static func _classify(c: Color) -> String:
	if c.s < 0.16 and c.v > 0.82:
		return "snow"
	if c.g > c.r * 1.08 and c.g > c.b * 1.02 and c.s > 0.2:
		return "green"
	return "earth"


static func _random_point(f: Dictionary, rng: RandomNumberGenerator) -> Vector3:
	var half: Vector2 = f["half"]
	var local := Vector2.ZERO
	if f["shape"] == "box":
		local = Vector2(rng.randf_range(-half.x + 0.2, half.x - 0.2), rng.randf_range(-half.y + 0.2, half.y - 0.2))
	else:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 0.97
		local = Vector2(cos(a) * half.x * r, sin(a) * half.y * r)
	var t: Transform3D = f["xform"]
	var dir_x := t.basis.x.normalized()
	var dir_z := t.basis.z.normalized()
	var p := Vector3(t.origin.x, f["top"], t.origin.z) + dir_x * local.x + dir_z * local.y
	return p


static func _on_path(p: Vector3, paths: Array) -> bool:
	for f: Dictionary in paths:
		if absf(p.y - float(f["top"])) > 0.35:
			continue
		var t: Transform3D = f["xform"]
		var d := p - t.origin
		var lx := d.dot(t.basis.x.normalized())
		var lz := d.dot(t.basis.z.normalized())
		var half: Vector2 = f["half"]
		var m := 0.25
		if f["shape"] == "box":
			if absf(lx) < half.x + m and absf(lz) < half.y + m:
				return true
		elif pow(lx / (half.x + m), 2) + pow(lz / (half.y + m), 2) < 1.0:
			return true
	return false


## True if nothing stands on this spot and a floor collider is right below it.
static func _clear(space: PhysicsDirectSpaceState3D, p: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 3.0, 0), p - Vector3(0, 0.5, 0))
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return false
	return absf(float(hit["position"].y) - p.y) < 0.12 and float(hit["normal"].y) > 0.9


## Gives a floor soft color blotches (once per material).
static func _patch(f: Dictionary) -> void:
	if f["area"] < 12.0:
		return
	var mi: MeshInstance3D = f["mi"]
	var mat := mi.material_override as ShaderMaterial
	if mat == null:
		return
	if not _patched.has(mat):
		var m2 := mat.duplicate() as ShaderMaterial
		m2.set_shader_parameter("patch_strength", 0.1 if f["class"] != "snow" else 0.05)
		var c: Color = f["color"]
		m2.set_shader_parameter("patch_color", c.lerp(Color("#fff2b0"), 0.5) if f["class"] == "green" else c.lightened(0.3))
		_patched[mat] = m2
	mi.material_override = _patched[mat]

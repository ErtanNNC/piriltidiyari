class_name KeeperModels
extends RefCounted
## The four keeper candidates, built from primitives with a proper part
## hierarchy (Body, Head, HandL/R, FootL/R, Tail, EarL/R, WingL/R) so a
## CharacterRig can animate them. Each has one signature color
## (karakterler.md) on the costume and a small honey spark on the chest.
## Faces +Z. `look` = {"variant": 0..2, "accessory": "..."}.
## If assets/models/<id>.glb exists, ModelImport uses that instead.

const INFO := {
	"pati": {"name": "Pati", "species": "Kedi", "color": "berry", "line": "Ben hazırım!",
		"variants": [Color("#f4b26b"), Color("#ffffff"), Color("#7a6a63")]},
	"bado": {"name": "Bado", "species": "Ayı yavrusu", "color": "leaf", "line": "Ben... deneyebilirim.",
		"variants": [Color("#a8744f"), Color("#e9d2b0"), Color("#5a4038")]},
	"citir": {"name": "Çıtır", "species": "Sincap", "color": "sky", "line": "Haritamı aldım, gidelim!",
		"variants": [Color("#d9773a"), Color("#b6aaa0"), Color("#8a4b2e")]},
	"lumi": {"name": "Lumi", "species": "Ateşböceği", "color": "xp", "line": "Işık bizi çağırıyor.",
		"variants": [Color("#9b6bff"), Color("#4cc3ff"), Color("#ff6b8a")]},
}
const ACCESSORIES := ["yok", "sapka", "atki", "gozluk"]
const ACCESSORY_NAMES := {"yok": "Yok", "sapka": "Şapka", "atki": "Atkı", "gozluk": "Gözlük"}
const CREAM := Color("#fff1dc")
const HEADWEAR := ["cicek_taci", "kasif_sapkasi", "minik_migfer"]
const PAD := Color("#ff9db4")


static func build(id: String, look := {}) -> Node3D:
	var imported := ModelImport.load_model(id)
	if imported:
		# a real model: hats, capes, scarves and tools still go on, at anchor
		# points (defaults per keeper, or "anchors" in assets/models/<id>.json)
		var ap := _anchors(imported, id)
		var a2 := String(look.get("accessory", "yok"))
		if String(look.get("outfit", "")) in HEADWEAR and a2 == "sapka":
			a2 = "yok"
		_accessory(ap, a2, id)
		_outfit(ap, String(look.get("outfit", "")))
		_tool(ap, String(look.get("weapon", "")), id)
		_fur(imported, id, int(look.get("variant", 0)))
		return imported
	var root := Node3D.new()
	var info: Dictionary = INFO.get(id, INFO["pati"])
	var fur: Color = info["variants"][clampi(int(look.get("variant", 0)), 0, 2)]
	var sig: String = info["color"]
	var parts := {}
	match id:
		"pati": parts = _cat(root, fur, sig)
		"bado": parts = _bear(root, fur, sig)
		"citir": parts = _squirrel(root, fur, sig)
		"lumi": parts = _firefly(root, fur, sig)
		_: parts = _cat(root, fur, sig)
	var outfit := String(look.get("outfit", ""))
	var acc := String(look.get("accessory", "yok"))
	if outfit in HEADWEAR and acc == "sapka":
		acc = "yok"  # one hat at a time
	_accessory(parts, acc, id)
	_outfit(parts, outfit)
	_tool(parts, String(look.get("weapon", "")), id)
	CharacterRig.attach(root)
	return root


## The color shown on swatch `i` (variant 0 of a real model is its own fur).
static func swatch(id: String, i: int) -> Color:
	var info: Dictionary = INFO.get(id, INFO["pati"])
	if i == 0 and ModelImport.path_for(id) != "":
		var own := String(ModelImport._options(id).get("fur", ""))
		if own != "":
			return Color(own)
	return info["variants"][clampi(i, 0, 2)]


## Fur color on a textured model: its own fur ("fur" in the json) is shifted
## to the variant's color in the toon shader (stripes and shading stay).
static func _fur(model: Node3D, id: String, variant: int) -> void:
	var own := String(ModelImport._options(id).get("fur", ""))
	if variant <= 0 or own == "":
		return
	var info: Dictionary = INFO.get(id, INFO["pati"])
	var to: Color = info["variants"][clampi(variant, 0, 2)]
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or not mi.get_parent() or mi.get_parent().name.begins_with("Anchor"):
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.get_surface_override_material(i) as ShaderMaterial
			if m and m.get_shader_parameter("rig_on") == 1.0:
				m.set_shader_parameter("fur_on", 1.0)
				m.set_shader_parameter("fur_from", Color(own))
				m.set_shader_parameter("fur_to", to)


## Where the procedural keepers have their head/body/hands (meters, model
## standing on y=0 facing +Z). Head: center and half size of the head.
const ANCHORS := {
	"pati": {"Head": [0, 1.32, 0.02], "head_r": [0.48, 0.42, 0.43], "Body": [0, 0.5, 0], "HandL": [0.43, 0.55, 0.1], "HandR": [-0.43, 0.55, 0.1]},
	"bado": {"Head": [0, 1.38, 0.02], "head_r": [0.5, 0.44, 0.44], "Body": [0, 0.5, 0], "HandL": [0.53, 0.55, 0.1], "HandR": [-0.53, 0.55, 0.1]},
	"citir": {"Head": [0, 1.32, 0.02], "head_r": [0.46, 0.42, 0.42], "Body": [0, 0.5, 0], "HandL": [0.41, 0.55, 0.1], "HandR": [-0.41, 0.55, 0.1]},
	"lumi": {"Head": [0, 1.3, 0.02], "head_r": [0.46, 0.42, 0.42], "Body": [0, 0.5, 0], "HandL": [0.4, 0.55, 0.1], "HandR": [-0.4, 0.55, 0.1]},
}


## Empty anchor nodes on an imported model (under its Pose, so they breathe
## and bob with it). "anchors" in the model's json overrides any of them.
static func _anchors(model: Node3D, id: String) -> Dictionary:
	var def: Dictionary = ANCHORS.get(id, ANCHORS["pati"]).duplicate()
	var over: Variant = ModelImport._options(id).get("anchors")
	if over is Dictionary:
		def.merge(over, true)
	var pose: Node3D = model.get_node_or_null("Pose") if model.has_node("Pose") else model
	var p := {}
	for k: String in ["Head", "Body", "HandL", "HandR"]:
		var v: Array = def[k]
		var n := Node3D.new()
		n.name = "Anchor" + k
		n.position = Vector3(float(v[0]), float(v[1]), float(v[2]))
		pose.add_child(n)
		p[k] = n
	var r: Array = def["head_r"]
	p["head_r"] = Vector3(float(r[0]), float(r[1]), float(r[2]))
	# hats and crowns are sized for the procedural head (half width ~0.48)
	p["hat_scale"] = float(def.get("hat_scale", 1.0))
	_follow_bones(pose, p)
	return p


## A rigged model: hats ride the head bone and tools the hand bones, so they
## move with the animation. The anchor keeps its place (the bind pose).
static func _follow_bones(pose: Node3D, p: Dictionary) -> void:
	var found := pose.find_children("*", "Skeleton3D", true, false)
	if found.is_empty():
		return
	var sk: Skeleton3D = found[0]
	for pair: Array in [["Head", "Head"], ["HandL", "LeftHand"], ["HandR", "RightHand"], ["Body", "Spine"]]:
		var bone := sk.find_bone(pair[1])
		var anchor: Node3D = p.get(pair[0])
		if bone < 0 or anchor == null:
			continue
		var att := BoneAttachment3D.new()
		att.bone_name = pair[1]
		sk.add_child(att)
		# where the anchor sits relative to the bone in the rest pose
		var bone_rest := pose.global_transform.affine_inverse() * sk.global_transform * sk.get_bone_global_rest(bone) if pose.is_inside_tree() else _rest_in(pose, sk, bone)
		var local := bone_rest.affine_inverse() * anchor.transform
		anchor.get_parent().remove_child(anchor)
		att.add_child(anchor)
		anchor.transform = local


static func _rest_in(pose: Node3D, sk: Skeleton3D, bone: int) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = sk
	while n != null and n != pose:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t * sk.get_bone_global_rest(bone)


static func _node(parent: Node3D, n: String, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = n
	node.position = pos
	parent.add_child(node)
	return node


## Shared chibi body: round torso with a costume, belly patch, paws, feet and
## the honey spark. Returns the part nodes.
static func _base(root: Node3D, fur: Color, cloth: Variant, belly: Color, head_y: float,
		head_size: Vector3, torso := Vector3(0.78, 0.8, 0.7)) -> Dictionary:
	var body := _node(root, "Body", Vector3(0, 0.5, 0))
	Toon.part(body, "ellipsoid", torso, fur, Vector3.ZERO)
	# costume: a soft tunic over the lower torso
	Toon.part(body, "ellipsoid", Vector3(torso.x * 1.06, torso.y * 0.72, torso.z * 1.06), cloth, Vector3(0, -0.1, 0))
	Toon.part(body, "ring", Vector3(torso.x * 0.98, 0.07, torso.x * 0.98), cloth, Vector3(0, 0.12, 0), Vector3.ZERO, 0.0, 0.025)
	Toon.part(body, "ellipsoid", Vector3(torso.x * 0.5, torso.y * 0.5, 0.12), belly, Vector3(0, 0.08, torso.z * 0.44), Vector3.ZERO, 0.0, 0.0)
	# the spark every keeper carries, as a pendant
	Toon.part(body, "cylinder", Vector3(0.02, 0.14, 0.02), "outline", Vector3(0, 0.27, torso.z * 0.47), Vector3(20, 0, 0), 0.0, 0.0)
	Toon.part(body, "ellipsoid", Vector3(0.15, 0.17, 0.1), "honey", Vector3(0, 0.18, torso.z * 0.5 + 0.03), Vector3.ZERO, 2.0, 0.02)
	var parts := {"Body": body}
	for s: float in [1.0, -1.0]:
		var side := "L" if s > 0 else "R"
		var hand := _node(root, "Hand" + side, Vector3(0.43 * s * torso.x / 0.78, 0.55, 0.1))
		Toon.part(hand, "ellipsoid", Vector3(0.22, 0.24, 0.22), fur, Vector3.ZERO)
		Toon.part(hand, "ellipsoid", Vector3(0.1, 0.08, 0.05), PAD, Vector3(0, -0.03, 0.1), Vector3.ZERO, 0.0, 0.0)
		var foot := _node(root, "Foot" + side, Vector3(0.2 * s, 0.1, 0.06))
		Toon.part(foot, "ellipsoid", Vector3(0.27, 0.2, 0.36), fur, Vector3(0, 0, 0.04))
		Toon.part(foot, "ellipsoid", Vector3(0.17, 0.06, 0.16), belly, Vector3(0, 0.05, 0.14), Vector3.ZERO, 0.0, 0.0)
		parts["Hand" + side] = hand
		parts["Foot" + side] = foot
	var head := _node(root, "Head", Vector3(0, head_y, 0.02))
	Toon.part(head, "ellipsoid", head_size, fur, Vector3.ZERO)
	parts["Head"] = head
	parts["head_r"] = head_size * 0.5
	return parts


static func _cat(root: Node3D, fur: Color, sig: String) -> Dictionary:
	var hs := Vector3(0.96, 0.84, 0.86)
	var p := _base(root, fur, sig, CREAM, 1.32, hs)
	var head: Node3D = p["Head"]
	var r: Vector3 = p["head_r"]
	# cheek fluff and muzzle
	for s: float in [-1.0, 1.0]:
		Toon.part(head, "ellipsoid", Vector3(0.26, 0.2, 0.24), fur, Vector3(0.38 * s, -0.16, 0.12), Vector3(0, 0, 30 * s))
		Toon.part(head, "ellipsoid", Vector3(0.17, 0.13, 0.12), CREAM, Vector3(0.06 * s, -0.15, r.z - 0.06), Vector3.ZERO, 0.0, 0.0)
		for k in 2:
			Toon.part(head, "cylinder", Vector3(0.012, 0.26, 0.012), "outline", Vector3(0.24 * s, -0.12 - k * 0.05, r.z - 0.08), Vector3(0, 0, (80 + k * 14) * s), 0.0, 0.0)
		var ear := _node(head, "Ear" + ("L" if s > 0 else "R"), Vector3(0.27 * s, 0.33, -0.02))
		ear.rotation_degrees = Vector3(0, 0, -16 * s)
		Toon.part(ear, "cone", Vector3(0.32, 0.36, 0.32), fur, Vector3(0, 0.12, 0))
		Toon.part(ear, "cone", Vector3(0.17, 0.22, 0.17), PAD, Vector3(0, 0.09, 0.08), Vector3(8, 0, 0), 0.0, 0.0)
		p["Ear" + ("L" if s > 0 else "R")] = ear
	Toon.part(head, "ellipsoid", Vector3(0.09, 0.065, 0.06), PAD, Vector3(0, -0.08, r.z + 0.01), Vector3.ZERO, 0.0, 0.015)
	Face.add(head, Vector3.ZERO, r, "cat", false, 0.4, 0.12)
	# striped forehead
	for i in 3:
		Toon.part(head, "ellipsoid", Vector3(0.05, 0.14, 0.05), fur.darkened(0.25), Vector3((i - 1) * 0.08, 0.3, r.z * 0.62), Vector3(-35, 0, (i - 1) * -12), 0.0, 0.0)
	# curled tail: three beads rising up, last one lighter
	var tail := _node(root, "Tail", Vector3(0, 0.38, -0.36))
	var pts := [Vector3(0, 0.0, 0), Vector3(0, 0.15, -0.16), Vector3(0, 0.38, -0.24), Vector3(0.0, 0.6, -0.2)]
	for i in pts.size():
		Toon.part(tail, "ellipsoid", Vector3(0.17, 0.2, 0.17) * (1.0 - i * 0.06), fur if i < 3 else fur.lightened(0.35), pts[i])
	p["Tail"] = tail
	return p


static func _bear(root: Node3D, fur: Color, sig: String) -> Dictionary:
	var hs := Vector3(1.04, 0.94, 0.94)
	var p := _base(root, fur, sig, fur.lightened(0.35), 1.38, hs, Vector3(0.96, 0.92, 0.84))
	var body: Node3D = p["Body"]
	# overall straps and buttons
	for s: float in [-1.0, 1.0]:
		Toon.part(body, "box", Vector3(0.1, 0.42, 0.06), sig, Vector3(0.22 * s, 0.22, 0.36), Vector3(-12, 0, 0), 0.0, 0.02)
		Toon.part(body, "ellipsoid", Vector3(0.08, 0.08, 0.05), "honey", Vector3(0.22 * s, 0.08, 0.42), Vector3.ZERO, 0.0, 0.015)
	var head: Node3D = p["Head"]
	var r: Vector3 = p["head_r"]
	for s: float in [-1.0, 1.0]:
		var ear := _node(head, "Ear" + ("L" if s > 0 else "R"), Vector3(0.36 * s, 0.36, -0.02))
		Toon.part(ear, "ellipsoid", Vector3(0.3, 0.3, 0.18), fur, Vector3.ZERO)
		Toon.part(ear, "ellipsoid", Vector3(0.16, 0.16, 0.06), fur.lightened(0.35), Vector3(0, -0.01, 0.07), Vector3.ZERO, 0.0, 0.0)
		p["Ear" + ("L" if s > 0 else "R")] = ear
	Toon.part(head, "ellipsoid", Vector3(0.42, 0.3, 0.22), fur.lightened(0.38), Vector3(0, -0.18, r.z - 0.08), Vector3.ZERO, 0.0, 0.0)
	Toon.part(head, "ellipsoid", Vector3(0.14, 0.1, 0.08), "outline", Vector3(0, -0.11, r.z + 0.02), Vector3.ZERO, 0.0, 0.0)
	Toon.part(head, "ellipsoid", Vector3(0.05, 0.03, 0.02), Color.WHITE, Vector3(-0.025, -0.09, r.z + 0.06), Vector3.ZERO, 0.4, 0.0)
	# shy worried brows
	Face.add(head, Vector3(0, 0.02, 0), r, "smile", true, 0.4, 0.12)
	# wooden pot-lid shield in the right paw
	var hand: Node3D = p["HandR"]
	Toon.part(hand, "cylinder", Vector3(0.78, 0.1, 0.78), Color("#c98d5e"), Vector3(-0.14, 0.05, 0.05), Vector3(0, 0, 80))
	Toon.part(hand, "ellipsoid", Vector3(0.16, 0.16, 0.16), Color("#8a5a3c"), Vector3(-0.21, 0.05, 0.05))
	var tail := _node(root, "Tail", Vector3(0, 0.35, -0.42))
	Toon.part(tail, "ellipsoid", Vector3(0.22, 0.2, 0.2), fur, Vector3.ZERO)
	p["Tail"] = tail
	return p


static func _squirrel(root: Node3D, fur: Color, sig: String) -> Dictionary:
	var hs := Vector3(0.92, 0.84, 0.84)
	var p := _base(root, fur, sig, CREAM, 1.32, hs, Vector3(0.74, 0.8, 0.68))
	var head: Node3D = p["Head"]
	var r: Vector3 = p["head_r"]
	for s: float in [-1.0, 1.0]:
		var ear := _node(head, "Ear" + ("L" if s > 0 else "R"), Vector3(0.25 * s, 0.36, -0.04))
		ear.rotation_degrees = Vector3(0, 0, -8 * s)
		Toon.part(ear, "cone", Vector3(0.22, 0.34, 0.22), fur, Vector3(0, 0.1, 0))
		Toon.part(ear, "cone", Vector3(0.1, 0.18, 0.1), fur.lightened(0.4), Vector3(0, 0.29, 0), Vector3.ZERO, 0.0, 0.0)  # tuft
		p["Ear" + ("L" if s > 0 else "R")] = ear
		Toon.part(head, "ellipsoid", Vector3(0.26, 0.2, 0.22), CREAM, Vector3(0.13 * s, -0.16, r.z - 0.1), Vector3.ZERO, 0.0, 0.0)
	Toon.part(head, "ellipsoid", Vector3(0.08, 0.06, 0.06), Color("#5a3a2e"), Vector3(0, -0.07, r.z + 0.01), Vector3.ZERO, 0.0, 0.015)
	Face.add(head, Vector3.ZERO, r, "teeth", false, 0.4, 0.13)
	# satchel strap and map scroll
	var body: Node3D = p["Body"]
	Toon.part(body, "box", Vector3(0.08, 0.86, 0.06), Color("#8a5a3c"), Vector3(0.02, 0.06, 0.34), Vector3(-10, 0, 38), 0.0, 0.02)
	var hand: Node3D = p["HandL"]
	Toon.part(hand, "cylinder", Vector3(0.16, 0.5, 0.16), Color("#fff3dc"), Vector3(0.05, 0.08, 0.06), Vector3(0, 0, 70))
	Toon.part(hand, "cylinder", Vector3(0.2, 0.06, 0.2), "sky", Vector3(0.27, 0.17, 0.06), Vector3(0, 0, 70), 0.0, 0.015)
	# big fluffy S tail
	var tail := _node(root, "Tail", Vector3(0, 0.45, -0.4))
	var beads := [[Vector3(0, 0.0, 0), 0.38], [Vector3(0, 0.3, -0.25), 0.5], [Vector3(0, 0.72, -0.3), 0.56], [Vector3(0, 1.08, -0.12), 0.48], [Vector3(0, 1.28, 0.08), 0.34]]
	for i in beads.size():
		var b: Array = beads[i]
		Toon.part(tail, "ellipsoid", Vector3(b[1], b[1], b[1] * 0.9), fur if i < 3 else fur.lightened(0.22 + i * 0.05), b[0])
	p["Tail"] = tail
	return p


static func _firefly(root: Node3D, body_col: Color, _sig: String) -> Dictionary:
	var hs := Vector3(0.88, 0.82, 0.82)
	var p := _base(root, body_col, body_col.darkened(0.25), body_col.lightened(0.45), 1.3, hs, Vector3(0.72, 0.78, 0.66))
	var head: Node3D = p["Head"]
	var r: Vector3 = p["head_r"]
	Face.add(head, Vector3.ZERO, r, "smile", false, 0.38, 0.06, 1.05)
	for s: float in [-1.0, 1.0]:
		var ant := _node(head, "Ear" + ("L" if s > 0 else "R"), Vector3(0.14 * s, 0.34, 0.02))
		ant.rotation_degrees = Vector3(0, 0, -16 * s)
		Toon.part(ant, "cylinder", Vector3(0.04, 0.42, 0.04), "outline", Vector3(0, 0.2, 0), Vector3.ZERO, 0.0, 0.0)
		Toon.part(ant, "ellipsoid", Vector3(0.14, 0.14, 0.14), "spark-yellow", Vector3(0, 0.44, 0), Vector3.ZERO, 1.5, 0.02)
		p["Ear" + ("L" if s > 0 else "R")] = ant
		var wing := _node(root, "Wing" + ("L" if s > 0 else "R"), Vector3(0.16 * s, 0.95, -0.34))
		wing.rotation_degrees = Vector3(10, 25 * s, 30 * s)
		var w := Toon.part(wing, "ellipsoid", Vector3(0.5, 0.78, 0.05), Color("#9fd2ff"), Vector3(0.2 * s, 0.12, 0), Vector3.ZERO, 0.12, 0.015)
		w.transparency = 0.5
		var w2 := Toon.part(wing, "ellipsoid", Vector3(0.34, 0.46, 0.04), Color("#9fd2ff"), Vector3(0.18 * s, -0.3, 0.02), Vector3(0, 0, 30 * s), 0.12, 0.015)
		w2.transparency = 0.55
		p["Wing" + ("L" if s > 0 else "R")] = wing
	# glowing lantern abdomen with stripes
	var tail := _node(root, "Tail", Vector3(0, 0.48, -0.46))
	Toon.part(tail, "ellipsoid", Vector3(0.6, 0.58, 0.62), "spark-yellow", Vector3.ZERO, Vector3.ZERO, 2.2, 0.03)
	Toon.part(tail, "ring", Vector3(0.58, 0.05, 0.58), body_col.darkened(0.3), Vector3(0, 0, 0.12), Vector3(80, 0, 0), 0.0, 0.0)
	p["Tail"] = tail
	return p


static func _accessory(p: Dictionary, acc: String, _id: String) -> void:
	var head: Node3D = p["Head"]
	var r: Vector3 = p["head_r"]
	match acc:
		"sapka":
			var top := r.y - 0.02
			Toon.part(head, "cylinder", Vector3(0.74, 0.07, 0.74), "honey-deep", Vector3(0, top, -0.02), Vector3(-6, 0, 0))
			Toon.part(head, "cylinder", Vector3(0.44, 0.3, 0.48), "honey", Vector3(0, top + 0.17, -0.03), Vector3(-6, 0, 0))
			Toon.part(head, "ring", Vector3(0.48, 0.05, 0.48), "berry", Vector3(0, top + 0.06, -0.03), Vector3(-6, 0, 0), 0.0, 0.015)
		"atki":
			var body: Node3D = p["Body"]
			Toon.part(body, "torus", Vector3(0.74, 0.2, 0.74), "sky", Vector3(0, 0.42, 0))
			Toon.part(body, "box", Vector3(0.17, 0.42, 0.08), "sky", Vector3(0.2, 0.26, 0.34), Vector3(-15, 0, 12))
			for i in 3:
				Toon.part(body, "box", Vector3(0.175, 0.04, 0.085), Color.WHITE, Vector3(0.2 + i * 0.0, 0.36 - i * 0.12, 0.35 + i * 0.03), Vector3(-15, 0, 12), 0.0, 0.0)
		"gozluk":
			for s: float in [-1.0, 1.0]:
				Toon.part(head, "ring", Vector3(0.24, 0.03, 0.24), "outline", Face._on(Vector3.ZERO, r, 0.4 * r.x * s, 0.12 * r.y, 0.03), Vector3(90, 0, 0), 0.0, 0.0)
			Toon.part(head, "cylinder", Vector3(0.02, 0.12, 0.02), "outline", Face._on(Vector3.ZERO, r, 0.0, 0.16 * r.y, 0.03), Vector3(0, 0, 90), 0.0, 0.0)


# --- shop outfits and tools ---------------------------------------------------

## Terzi Dikiş's outfits, worn on the keeper's head or back.
static func _outfit(p: Dictionary, outfit: String) -> void:
	if outfit == "":
		return
	var head: Node3D = p["Head"]
	var r: Vector3 = p["head_r"]
	if outfit == "yildiz_pelerini":
		_cape(p["Body"] as Node3D)
	else:
		var piece := outfit_piece(outfit)
		piece.scale = Vector3.ONE * float(p.get("hat_scale", 1.0))
		piece.position = Vector3(0, r.y - 0.04, -0.02)
		piece.rotation_degrees.x = -6
		head.add_child(piece)


## A wearable piece built on its own (also used on the shop shelves).
static func outfit_piece(outfit: String) -> Node3D:
	var n := Node3D.new()
	match outfit:
		"cicek_taci":
			Toon.part(n, "ring", Vector3(0.62, 0.07, 0.62), Color("#58b86a"), Vector3(0, 0.02, 0), Vector3.ZERO, 0.0, 0.015)
			for i in 7:
				var a := TAU * i / 7.0
				var col: Variant = ["berry", "spark-yellow", "sky", Color.WHITE, "spark-purple", "berry", "honey"][i]
				Toon.part(n, "sphere", Vector3(0.15, 0.12, 0.15), col, Vector3(cos(a) * 0.3, 0.07, sin(a) * 0.3), Vector3.ZERO, 0.15, 0.015)
				Toon.part(n, "sphere", Vector3(0.06, 0.06, 0.06), "honey", Vector3(cos(a) * 0.3, 0.12, sin(a) * 0.3), Vector3.ZERO, 0.0, 0.0)
		"kasif_sapkasi":
			Toon.part(n, "cylinder", Vector3(0.95, 0.06, 0.95), Color("#b98a52"), Vector3(0, 0.02, 0))
			Toon.part(n, "cylinder", Vector3(0.5, 0.3, 0.56), Color("#c99a5e"), Vector3(0, 0.18, 0))
			Toon.part(n, "ring", Vector3(0.56, 0.07, 0.56), Color("#7a5236"), Vector3(0, 0.1, 0), Vector3.ZERO, 0.0, 0.015)
			Toon.part(n, "ellipsoid", Vector3(0.1, 0.32, 0.04), "berry", Vector3(0.24, 0.24, -0.05), Vector3(0, 30, -25), 0.0, 0.015)
		"minik_migfer":
			Toon.part(n, "ellipsoid", Vector3(0.72, 0.5, 0.72), Color("#c9d3e6"), Vector3(0, 0.12, 0))
			Toon.part(n, "ring", Vector3(0.74, 0.06, 0.74), "honey-deep", Vector3(0, -0.04, 0), Vector3.ZERO, 0.0, 0.015)
			Toon.part(n, "box", Vector3(0.06, 0.4, 0.62), "honey-deep", Vector3(0, 0.2, 0), Vector3.ZERO, 0.0, 0.015)
			for k in 3:
				Toon.part(n, "ellipsoid", Vector3(0.16, 0.4, 0.12), "berry", Vector3(0, 0.5 + k * 0.05, -0.1 - k * 0.12), Vector3(-30 - k * 20, 0, 0), 0.0, 0.015)
		"yildiz_pelerini":
			_cape(n)
	return n


static func _cape(body: Node3D) -> void:
	var cape := Node3D.new()
	cape.name = "Cape"
	cape.position = Vector3(0, 0.05, -0.34)
	cape.rotation_degrees.x = 10
	body.add_child(cape)
	Toon.part(cape, "ellipsoid", Vector3(0.82, 0.95, 0.12), "spark-purple", Vector3(0, -0.05, 0))
	Toon.part(cape, "ring", Vector3(0.5, 0.06, 0.5), "honey", Vector3(0, 0.38, 0.22), Vector3(70, 0, 0), 0.3, 0.015)
	for pos: Vector3 in [Vector3(-0.18, 0.1, -0.07), Vector3(0.2, -0.15, -0.07), Vector3(-0.05, -0.3, -0.07), Vector3(0.12, 0.25, -0.07)]:
		Toon.part(cape, "sphere", Vector3(0.09, 0.09, 0.04), "spark-yellow", pos, Vector3.ZERO, 1.2, 0.0)


## Usta Tıkır's tools, held in a paw (Bado's other paw holds his shield).
static func _tool(p: Dictionary, tool: String, id: String) -> void:
	if tool == "":
		return
	var hand: Node3D = p["HandL" if id == "bado" else "HandR"]
	var piece := tool_piece(tool)
	piece.position = Vector3(0, -0.02, 0.06)
	piece.rotation_degrees = Vector3(35, 0, 0)
	piece.name = "HeldTool"
	piece.add_to_group("held_tool")
	hand.add_child(piece)


static func tool_piece(tool: String) -> Node3D:
	var n := Node3D.new()
	match tool:
		"isik_degnegi":
			Toon.part(n, "cylinder", Vector3(0.06, 0.7, 0.06), Color("#c98d5e"), Vector3(0, 0.25, 0))
			Toon.part(n, "sphere", Vector3(0.2, 0.2, 0.2), "spark-yellow", Vector3(0, 0.64, 0), Vector3.ZERO, 1.6, 0.02)
		"yildiz_asasi":
			Toon.part(n, "cylinder", Vector3(0.07, 1.2, 0.07), Color("#8a5a3c"), Vector3(0, 0.4, 0))
			Toon.part(n, "ring", Vector3(0.36, 0.05, 0.36), "honey", Vector3(0, 1.04, 0), Vector3(90, 0, 0), 0.4, 0.015)
			Toon.part(n, "cone", Vector3(0.22, 0.34, 0.22), "spark-purple", Vector3(0, 1.08, 0), Vector3.ZERO, 1.4, 0.02)
			Toon.part(n, "cone", Vector3(0.22, 0.2, 0.22), "spark-purple", Vector3(0, 0.93, 0), Vector3(180, 0, 0), 1.4, 0.02)
		"kivilcim_kilici":
			Toon.part(n, "cylinder", Vector3(0.07, 0.24, 0.07), Color("#7a5236"), Vector3(0, 0.05, 0))
			Toon.part(n, "box", Vector3(0.36, 0.06, 0.1), "honey", Vector3(0, 0.19, 0))
			Toon.part(n, "box", Vector3(0.12, 0.7, 0.05), "sky", Vector3(0, 0.57, 0), Vector3.ZERO, 1.0, 0.02)
			Toon.part(n, "cone", Vector3(0.12, 0.14, 0.05), "sky", Vector3(0, 0.98, 0), Vector3.ZERO, 1.0, 0.02)
		"isik_sapani":
			Toon.part(n, "cylinder", Vector3(0.06, 0.32, 0.06), Color("#a86b45"), Vector3(0, 0.1, 0))
			for sd: float in [-1.0, 1.0]:
				Toon.part(n, "cylinder", Vector3(0.05, 0.26, 0.05), Color("#a86b45"), Vector3(0.08 * sd, 0.34, 0), Vector3(0, 0, -22 * sd))
			Toon.part(n, "sphere", Vector3(0.12, 0.12, 0.12), "spark-yellow", Vector3(0, 0.46, 0), Vector3.ZERO, 1.2, 0.015)
	return n

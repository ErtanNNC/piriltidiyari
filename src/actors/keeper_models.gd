class_name KeeperModels
extends RefCounted
## The four keeper candidates (placeholders). Each has one signature color
## (karakterler.md) on the biggest costume area and a small honey spark on
## the chest. Faces +Z. `look` = {"variant": 0..2, "accessory": "..."}.

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


static func build(id: String, look := {}) -> Node3D:
	var root := Node3D.new()
	var info: Dictionary = INFO.get(id, INFO["pati"])
	var fur: Color = info["variants"][clampi(int(look.get("variant", 0)), 0, 2)]
	var sig: String = info["color"]
	match id:
		"pati": _cat(root, fur, sig)
		"bado": _bear(root, fur, sig)
		"citir": _squirrel(root, fur, sig)
		"lumi": _firefly(root, fur, sig)
	_accessory(root, String(look.get("accessory", "yok")), id)
	# the spark every keeper carries
	Toon.part(root, "sphere", Vector3(0.16, 0.16, 0.12), "honey", Vector3(0, 0.75, 0.42), Vector3.ZERO, 2.0, 0.02)
	return root


static func _head(root: Node3D, fur: Variant, y := 1.3, size := 0.9) -> void:
	Toon.part(root, "sphere", Vector3(size, size * 0.9, size * 0.88), fur, Vector3(0, y, 0.02))
	for s in [-1.0, 1.0]:
		Toon.part(root, "sphere", Vector3(0.14, 0.19, 0.07), "outline", Vector3(0.17 * s, y + 0.04, size * 0.43), Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "sphere", Vector3(0.05, 0.06, 0.03), Color.WHITE, Vector3(0.15 * s + 0.02, y + 0.09, size * 0.47), Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "sphere", Vector3(0.15, 0.08, 0.05), "berry", Vector3(0.29 * s, y - 0.12, size * 0.4), Vector3.ZERO, 0.0, 0.0)
	Toon.part(root, "sphere", Vector3(0.09, 0.07, 0.06), "outline", Vector3(0, y - 0.06, size * 0.47), Vector3.ZERO, 0.0, 0.0)


static func _body(root: Node3D, fur: Variant, cloth: Variant) -> void:
	Toon.part(root, "sphere", Vector3(0.8, 0.85, 0.72), cloth, Vector3(0, 0.55, 0))
	for s in [-1.0, 1.0]:
		Toon.part(root, "sphere", Vector3(0.26, 0.2, 0.34), fur, Vector3(0.2 * s, 0.1, 0.1))
		Toon.part(root, "sphere", Vector3(0.2, 0.2, 0.2), fur, Vector3(0.42 * s, 0.6, 0.12))


static func _cat(root: Node3D, fur: Color, sig: String) -> void:
	_body(root, fur, sig)
	_head(root, fur)
	for s in [-1.0, 1.0]:
		Toon.part(root, "cone", Vector3(0.32, 0.38, 0.32), fur, Vector3(0.28 * s, 1.75, 0), Vector3(0, 0, -18 * s))
		Toon.part(root, "cone", Vector3(0.16, 0.22, 0.16), "berry", Vector3(0.27 * s, 1.72, 0.07), Vector3(0, 0, -18 * s), 0.0, 0.0)
	Toon.part(root, "capsule", Vector3(0.14, 0.9, 0.14), fur, Vector3(0, 0.6, -0.5), Vector3(-50, 0, 0))
	Toon.part(root, "torus", Vector3(0.62, 0.2, 0.62), sig, Vector3(0, 0.93, 0))


static func _bear(root: Node3D, fur: Color, sig: String) -> void:
	Toon.part(root, "sphere", Vector3(1.0, 1.0, 0.9), sig, Vector3(0, 0.58, 0))
	for s in [-1.0, 1.0]:
		Toon.part(root, "sphere", Vector3(0.3, 0.22, 0.38), fur, Vector3(0.24 * s, 0.1, 0.1))
		Toon.part(root, "sphere", Vector3(0.24, 0.24, 0.24), fur, Vector3(0.5 * s, 0.62, 0.12))
		Toon.part(root, "sphere", Vector3(0.3, 0.3, 0.2), fur, Vector3(0.36 * s, 1.72, 0))
	_head(root, fur, 1.35, 1.0)
	Toon.part(root, "sphere", Vector3(0.36, 0.26, 0.2), fur.lightened(0.35), Vector3(0, 1.22, 0.42), Vector3.ZERO, 0.0, 0.0)
	Toon.part(root, "cylinder", Vector3(0.8, 0.12, 0.8), Color("#c98d5e"), Vector3(-0.62, 0.6, 0.1), Vector3(0, 0, 80))


static func _squirrel(root: Node3D, fur: Color, sig: String) -> void:
	_body(root, fur, sig)
	_head(root, fur)
	for s in [-1.0, 1.0]:
		Toon.part(root, "cone", Vector3(0.2, 0.34, 0.2), fur, Vector3(0.26 * s, 1.78, -0.02))
	# big fluffy tail
	Toon.part(root, "sphere", Vector3(0.7, 1.3, 0.6), fur, Vector3(0, 1.0, -0.62), Vector3(-15, 0, 0))
	Toon.part(root, "sphere", Vector3(0.55, 0.6, 0.5), fur.lightened(0.25), Vector3(0, 1.62, -0.55))
	Toon.part(root, "cylinder", Vector3(0.18, 0.55, 0.18), Color("#fff3dc"), Vector3(0.32, 0.75, -0.3), Vector3(0, 0, 70))


static func _firefly(root: Node3D, body: Color, _sig: String) -> void:
	Toon.part(root, "sphere", Vector3(0.75, 0.8, 0.7), body, Vector3(0, 0.62, 0))
	_head(root, body, 1.3, 0.85)
	Toon.part(root, "sphere", Vector3(0.62, 0.6, 0.6), "spark-yellow", Vector3(0, 0.45, -0.5), Vector3.ZERO, 2.2, 0.03)
	for s in [-1.0, 1.0]:
		var wing := Toon.part(root, "sphere", Vector3(0.7, 0.9, 0.08), Color("#e8f1ff"), Vector3(0.38 * s, 1.0, -0.3), Vector3(10, 25 * s, 30 * s), 0.3, 0.02)
		wing.transparency = 0.35
		Toon.part(root, "cylinder", Vector3(0.04, 0.4, 0.04), "outline", Vector3(0.14 * s, 1.85, 0.05), Vector3(0, 0, -15 * s), 0.0, 0.0)
		Toon.part(root, "sphere", Vector3(0.12, 0.12, 0.12), "spark-yellow", Vector3(0.2 * s, 2.05, 0.05), Vector3.ZERO, 1.5, 0.02)
		Toon.part(root, "sphere", Vector3(0.2, 0.16, 0.26), body, Vector3(0.18 * s, 0.12, 0.1))


static func _accessory(root: Node3D, acc: String, id: String) -> void:
	var top := 2.0 if id == "bado" else 1.85
	match acc:
		"sapka":
			Toon.part(root, "cylinder", Vector3(0.7, 0.08, 0.7), "honey-deep", Vector3(0, top - 0.12, 0))
			Toon.part(root, "cylinder", Vector3(0.42, 0.32, 0.46), "honey", Vector3(0, top + 0.05, 0))
		"atki":
			Toon.part(root, "torus", Vector3(0.7, 0.22, 0.7), "sky", Vector3(0, 0.98, 0))
			Toon.part(root, "box", Vector3(0.18, 0.4, 0.08), "sky", Vector3(0.18, 0.8, 0.32), Vector3(0, 0, 10))
		"gozluk":
			for s in [-1.0, 1.0]:
				Toon.part(root, "torus", Vector3(0.28, 0.035, 0.28), "outline", Vector3(0.17 * s, 1.34, 0.45), Vector3(90, 0, 0), 0.0, 0.0)

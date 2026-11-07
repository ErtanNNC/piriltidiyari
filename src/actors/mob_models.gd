class_name MobModels
extends RefCounted
## Placeholder mobs. `pus` = true builds the grey, grumpy Pus-touched look;
## false builds the animal's own colors with a happy face. Faces +Z.


static func build(kind: String, pus: bool) -> Node3D:
	var root := Node3D.new()
	Toon.default_pus = 0.0
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
		"buz_dikeni":
			_ice_spike(root, pus)
		"korsan_marti":
			_pirate_gull(root, pus)
		"yarasa":
			_bat(root, pus)
	Toon.default_pus = 1.0
	return root


const GREY := Color("#77738a")
const GREY_LIGHT := Color("#a19db2")


static func _c(pus: bool, own: Variant, light := false) -> Variant:
	if pus:
		return GREY_LIGHT if light else GREY
	return own


static func _face(root: Node3D, at: Vector3, s: float, pus: bool) -> void:
	for side in [-1.0, 1.0]:
		Toon.part(root, "sphere", Vector3(0.12, 0.16, 0.06) * s, "outline", at + Vector3(0.13 * side, 0.04, 0) * s, Vector3.ZERO, 0.0, 0.0)
		Toon.part(root, "sphere", Vector3(0.045, 0.05, 0.03) * s, Color.WHITE, at + Vector3(0.12 * side + 0.015, 0.08, 0.03) * s, Vector3.ZERO, 0.0, 0.0)
		if pus:
			# grumpy slanted brows
			Toon.part(root, "box", Vector3(0.16, 0.035, 0.03) * s, "outline", at + Vector3(0.13 * side, 0.15, 0.01) * s, Vector3(0, 0, 18 * side), 0.0, 0.0)
		else:
			Toon.part(root, "sphere", Vector3(0.12, 0.07, 0.04) * s, "berry", at + Vector3(0.24 * side, -0.07, -0.01) * s, Vector3.ZERO, 0.0, 0.0)


## Puslu Sümüklü: a round slug with two eye stalks.
static func _slug(root: Node3D, pus: bool) -> void:
	var body: Variant = _c(pus, "berry")
	Toon.part(root, "capsule", Vector3(0.8, 1.5, 0.8), body, Vector3(0, 0.32, -0.1), Vector3(90, 0, 0))
	Toon.part(root, "sphere", Vector3(0.75, 0.7, 0.7), body, Vector3(0, 0.55, 0.45))
	Toon.part(root, "sphere", Vector3(0.8, 0.55, 0.9), _c(pus, "spark-purple", true), Vector3(0, 0.62, -0.35))
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

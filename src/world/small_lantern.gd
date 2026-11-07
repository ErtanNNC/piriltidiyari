class_name SmallLantern
extends Node3D
## A small region lantern (Fener Yakma). Walk up and press Yak: it lights,
## becomes a checkpoint, and pushes the Pus back a little.

signal lit(lantern: SmallLantern)

@export var lantern_id := "kucuk_fener"
@export var accent := "spark-green"
@export var big := false   ## the region's Kıvılcım Feneri
@export_enum("lantern", "campfire") var style := "lantern"
var is_lit := false
var _flame: MeshInstance3D
var _light: OmniLight3D
var _area: Area3D


func _ready() -> void:
	var s := 1.6 if big else 1.0
	if style == "campfire":
		# a ring of stones, crossed logs and a fire that is out
		for i in 7:
			var a := TAU * i / 7.0
			Toon.part(self, "sphere", Vector3(0.45, 0.32, 0.45), Color("#a9a3bd"), Vector3(cos(a), 0.12, sin(a)) * 0.9)
		for k in 3:
			Toon.part(self, "cylinder", Vector3(0.24, 1.4, 0.24), Color("#8a5a3c"), Vector3(0, 0.3, 0), Vector3(70, k * 60.0, 0))
		# two log seats and a little kettle on a tripod
		for sd: float in [-1.0, 1.0]:
			Toon.part(self, "capsule", Vector3(0.45, 1.5, 0.45), Color("#8a5a3c"), Vector3(sd * 1.9, 0.22, 0.3), Vector3(90, 0, 70 * sd))
			Toon.part(self, "cylinder", Vector3(0.36, 0.04, 0.36), Color("#d9b38a"), Vector3(sd * 1.9 + sd * 0.27, 0.36, 0.3 + 0.62), Vector3(90, 0, 0), 0.0, 0.0)
		for k in 3:
			var a := TAU * k / 3.0
			Toon.part(self, "cylinder", Vector3(0.06, 1.9, 0.06), Color("#6e4a33"), Vector3(cos(a) * 0.55, 0.85, sin(a) * 0.55), Vector3(cos(a + PI * 0.5) * 18, 0, sin(a + PI * 0.5) * -18), 0.0, 0.0)
		Toon.part(self, "cylinder", Vector3(0.02, 0.3, 0.02), "outline", Vector3(0, 1.98, 0), Vector3.ZERO, 0.0, 0.0)
		Toon.part(self, "ellipsoid", Vector3(0.42, 0.34, 0.42), "ink-muted", Vector3(0, 1.72, 0))
		_flame = Toon.part(self, "cone", Vector3(0.8, 1.1, 0.8), "spark-off", Vector3(0, 0.8, 0), Vector3.ZERO, 0.0, 0.03)
	else:
		# stepped stone base, a post with a ribbon, a cage around the flame,
		# a roof with a finial; the big region lantern also flies a pennant
		Toon.part(self, "cylinder", Vector3(1.2, 0.2, 1.3) * s, Color("#a49b90"), Vector3(0, 0.1, 0) * s)
		Toon.part(self, "cylinder", Vector3(0.9, 0.3, 1.1) * s, Color("#b9b0a4"), Vector3(0, 0.3, 0) * s)
		Toon.part(self, "cylinder", Vector3(0.22, 2.2, 0.28) * s, Color("#8a5a3c"), Vector3(0, 1.3, 0) * s)
		for k in 4:
			Toon.part(self, "ring", Vector3(0.32, 0.035, 0.32) * s, accent, Vector3(0, 0.8 + k * 0.32, 0) * s, Vector3(0, k * 40.0, 12), 0.0, 0.0)
		Toon.part(self, "cylinder", Vector3(0.9, 0.12, 0.9) * s, "outline", Vector3(0, 2.4, 0) * s, Vector3.ZERO, 0.0, 0.0)
		for k in 4:
			var a := TAU * k / 4.0 + PI * 0.25
			Toon.part(self, "cylinder", Vector3(0.05, 0.85, 0.05) * s, "ink-muted", Vector3(cos(a) * 0.38, 2.85, sin(a) * 0.38) * s, Vector3.ZERO, 0.0, 0.0)
		Toon.part(self, "cylinder", Vector3(1.0, 0.1, 1.0) * s, "honey-deep", Vector3(0, 3.28, 0) * s, Vector3.ZERO, 0.0, 0.02)
		Toon.part(self, "cone", Vector3(0.9, 0.5, 0.9) * s, "honey-deep", Vector3(0, 3.55, 0) * s)
		Toon.part(self, "sphere", Vector3(0.2, 0.2, 0.2) * s, "honey", Vector3(0, 3.88, 0) * s, Vector3.ZERO, 0.5, 0.015)
		if big:
			Toon.part(self, "cylinder", Vector3(0.04, 0.9, 0.04) * s, "outline", Vector3(0, 4.3, 0) * s, Vector3.ZERO, 0.0, 0.0)
			Toon.part(self, "cone", Vector3(0.28, 0.4, 0.04) * s, accent, Vector3(0.18, 4.6, 0) * s, Vector3(0, 0, -90), 0.0, 0.015)
		_flame = Toon.part(self, "sphere", Vector3(0.62, 0.78, 0.62) * s, "spark-off", Vector3(0, 2.85, 0) * s, Vector3.ZERO, 0.0, 0.03)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.45 * s
	cyl.height = 3.0 * s
	c.shape = cyl
	c.position.y = 1.5 * s
	body.add_child(c)
	add_child(body)
	_area = Area3D.new()
	_area.collision_layer = 4
	_area.collision_mask = 0
	_area.monitoring = false
	var ac := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 0.9
	ac.shape = sp
	ac.position.y = 1.0
	_area.add_child(ac)
	add_child(_area)
	if not is_lit:
		Beacon.attach(self, (4.8 if big else 4.3) if style != "campfire" else 2.4, Tokens.color("honey").lightened(0.2))
	set_meta("action_label", "Yak")
	_area.set_meta("interactable", self)


func interact(by: Node) -> void:
	if is_lit:
		return
	light_up()
	if by is Player:
		(by as Player).respawn_point = global_position + Vector3(0, 0, 1.6)


func light_up(silent := false) -> void:
	if is_lit:
		return
	is_lit = true
	if get_node_or_null("Beacon"):
		get_node("Beacon").queue_free()
	_area.queue_free()
	_flame.material_override = Toon.material(accent, 0.03, 1.6, 0.0)
	_light = OmniLight3D.new()
	_light.light_color = Tokens.color(accent)
	_light.light_energy = 2.4 if big else 1.6
	_light.omni_range = 9.0 if big else 6.0
	_light.position.y = 1.0 if style == "campfire" else 2.85 * (1.6 if big else 1.0)
	add_child(_light)
	if not silent:
		Effects.sparkle(get_parent(), _flame.global_position, Tokens.color(accent), 16)
		Effects.ring(get_parent(), global_position + Vector3.UP * 0.2, 7.0, Tokens.color(accent), 0.7)
		Audio.play("lantern")
		GameState.toast.emit("Fener yandı!", "lantern")
		lit.emit(self)  # silent = restoring a save: nothing new happened

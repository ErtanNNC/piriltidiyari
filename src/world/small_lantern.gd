class_name SmallLantern
extends Node3D
## A small region lantern (Fener Yakma). Walk up and press Yak: it lights,
## becomes a checkpoint, and pushes the Pus back a little.

signal lit(lantern: SmallLantern)

@export var lantern_id := "kucuk_fener"
@export var accent := "spark-green"
@export var big := false   ## the region's Kıvılcım Feneri
var is_lit := false
var _flame: MeshInstance3D
var _light: OmniLight3D
var _area: Area3D


func _ready() -> void:
	var s := 1.6 if big else 1.0
	Toon.part(self, "cylinder", Vector3(0.9, 0.3, 1.1) * s, Color("#b9b0a4"), Vector3(0, 0.15, 0) * s)
	Toon.part(self, "cylinder", Vector3(0.22, 2.2, 0.28) * s, Color("#8a5a3c"), Vector3(0, 1.3, 0) * s)
	Toon.part(self, "cylinder", Vector3(0.9, 0.12, 0.9) * s, "outline", Vector3(0, 2.4, 0) * s, Vector3.ZERO, 0.0, 0.0)
	Toon.part(self, "cone", Vector3(0.9, 0.5, 0.9) * s, "honey-deep", Vector3(0, 3.35, 0) * s)
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
	_area.queue_free()
	_flame.material_override = Toon.material(accent, 0.03, 1.6, 0.0)
	_light = OmniLight3D.new()
	_light.light_color = Tokens.color(accent)
	_light.light_energy = 2.4 if big else 1.6
	_light.omni_range = 9.0 if big else 6.0
	_light.position.y = 2.85 * (1.6 if big else 1.0)
	add_child(_light)
	if not silent:
		Effects.sparkle(get_parent(), _flame.global_position, Tokens.color(accent), 16)
		Effects.ring(get_parent(), global_position + Vector3.UP * 0.2, 7.0, Tokens.color(accent), 0.7)
		GameState.toast.emit("Fener yandı!", "lantern")
		lit.emit(self)  # silent = restoring a save: nothing new happened

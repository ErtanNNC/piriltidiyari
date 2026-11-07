class_name CaveCrystal
extends Node3D
## A grey crystal the Pus has dulled. Hit it (any attack) and it lights up
## in candy colors. A room's crystals share a `group_id`; when all of a
## group are lit, the level opens that room's crystal gate.

signal lit(crystal: CaveCrystal)

@export var group_id := "salon"
@export var accent := "spark-blue"
var is_lit := false
var _shards: Array[MeshInstance3D] = []


func _ready() -> void:
	add_to_group("hittable")
	add_to_group("crystal_" + group_id)
	set_meta("hit_radius", 0.8)
	Toon.default_pus = 0.0
	Toon.part(self, "cylinder", Vector3(1.4, 0.4, 1.6), CaveKit.ROCK, Vector3(0, 0.2, 0))
	for spec in [[Vector3(0, 1.1, 0), Vector3(0.7, 2.2, 0.7), Vector3.ZERO], [Vector3(0.45, 0.7, 0.2), Vector3(0.45, 1.3, 0.45), Vector3(0, 0, -25)],
			[Vector3(-0.4, 0.6, -0.15), Vector3(0.4, 1.1, 0.4), Vector3(0, 0, 25)]]:
		# a faint grey glow so kids can find unlit crystals in the dark
		_shards.append(Toon.part(self, "cone", spec[1], Color("#a7a2c2"), spec[0], spec[2], 0.35, 0.03))
	Toon.default_pus = 1.0
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.6
	cyl.height = 2.2
	c.shape = cyl
	c.position.y = 1.1
	body.add_child(c)
	add_child(body)


func hit(_damage: int, _from: Vector3, _push: float) -> void:
	if is_lit:
		return
	light_up()


func light_up(silent := false) -> void:
	if is_lit:
		return
	is_lit = true
	remove_from_group("hittable")
	for s in _shards:
		s.material_override = Toon.material(accent, 0.03, 1.4, 0.0)
	var l := OmniLight3D.new()
	l.light_color = Tokens.color(accent)
	l.light_energy = 1.4
	l.omni_range = 6.5
	l.position.y = 1.6
	add_child(l)
	if not silent:
		Effects.sparkle(get_parent(), global_position + Vector3.UP * 1.4, Tokens.color(accent), 14)
		Effects.ring(get_parent(), global_position + Vector3.UP * 0.3, 2.4, Tokens.color(accent), 0.4)
		Audio.play("crystal")
		lit.emit(self)  # silent = restoring a save

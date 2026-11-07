class_name Beacon
extends Node3D
## A small bobbing star over something a kid has to find (an unlit crystal or
## lantern, a memory). Drawn on top of everything, so it shows through walls
## and trees. Remove it (queue_free) once the thing is done.

var color := Color(1.0, 0.9, 0.45)
var _t := randf() * TAU
var _sprite: MeshInstance3D


static func attach(target: Node3D, height := 2.6, col := Color(1.0, 0.9, 0.45)) -> Beacon:
	var b := Beacon.new()
	b.name = "Beacon"
	b.color = col
	b.position = Vector3(0, height, 0)
	target.add_child(b)
	return b


func _ready() -> void:
	var q := QuadMesh.new()
	q.size = Vector2(0.75, 0.75)
	_sprite = MeshInstance3D.new()
	_sprite.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.no_depth_test = true
	m.render_priority = 10
	m.albedo_texture = Weather.texture("star")
	m.albedo_color = color
	_sprite.material_override = m
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sprite)


func _process(delta: float) -> void:
	_t += delta
	_sprite.position.y = sin(_t * 2.2) * 0.15
	var s := 1.0 + sin(_t * 3.0) * 0.12
	_sprite.scale = Vector3(s, s, s)

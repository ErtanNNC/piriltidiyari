class_name TempLight
extends Node3D
## Season 3: a light that stays for a while (Fener Fındığı, Gece Lambası,
## Önden Giden's trail). Counts as a torch (group "light_ring" with
## `radius`/`lit`): the Titreme barı empties in it and Titrekler calm down.

var radius := 3.5
var seconds := 10.0
var lit := true
var color := Color(1.0, 0.85, 0.5)
var _glow: MeshInstance3D
var _light: OmniLight3D


static func spawn(parent: Node, at: Vector3, r: float, time: float, col := Color(1.0, 0.85, 0.5)) -> TempLight:
	var t := TempLight.new()
	t.radius = r
	t.seconds = time
	t.color = col
	parent.add_child(t)
	t.global_position = at
	return t


func _ready() -> void:
	add_to_group("light_ring")
	Toon.part(self, "sphere", Vector3(0.3, 0.3, 0.3), color, Vector3(0, 0.5, 0), Vector3.ZERO, 2.0, 0.0)
	_glow = MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = 0.02
	m.radial_segments = 40
	_glow.mesh = m
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(color.r, color.g, color.b, 0.07)
	_glow.material_override = mat
	_glow.position.y = 0.05
	add_child(_glow)
	_light = OmniLight3D.new()
	_light.light_color = color
	_light.light_energy = 1.4
	_light.omni_range = radius * 1.5
	_light.position.y = 1.2
	add_child(_light)
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.1, radius, color, 0.4)
	var tw := create_tween()
	tw.tween_interval(maxf(seconds - 1.0, 0.1))
	tw.tween_property(_light, "light_energy", 0.0, 1.0)
	tw.tween_callback(queue_free)

class_name MemoryShell
extends Interactable
## Mercan Bahçesi: an Anı Kabuğu. "Aç" opens the shell and plays one of
## Tırıl's memories (a bark); it can be read again any time. The first
## opening sets `flag` and emits `opened`: the scene counts the quest step.

signal opened(shell: MemoryShell)

var bark_id := ""
var flag := ""
var color := Color(1.0, 0.8, 0.9)
var _lid: Node3D
var _pearl: MeshInstance3D
var _light: OmniLight3D


func _init() -> void:
	action_label = "Aç"
	reach = 1.3


func is_found() -> bool:
	return flag != "" and GameState.data.has_flag(flag)


func _build() -> void:
	var shell_col := Color("#f6e3ee")
	# the lower half, a pearl in it, the lid hinged at the back
	Toon.part(self, "ellipsoid", Vector3(1.5, 0.5, 1.3), shell_col, Vector3(0, 0.25, 0))
	Toon.part(self, "ellipsoid", Vector3(1.2, 0.2, 1.0), color.darkened(0.15), Vector3(0, 0.44, 0), Vector3.ZERO, 0.0, 0.0)
	_pearl = Toon.part(self, "sphere", Vector3(0.42, 0.42, 0.42), color.lightened(0.5), Vector3(0, 0.62, 0.05), Vector3.ZERO, 0.4, 0.02)
	_lid = Node3D.new()
	_lid.position = Vector3(0, 0.42, -0.6)
	add_child(_lid)
	Toon.part(_lid, "ellipsoid", Vector3(1.5, 0.55, 1.3), shell_col, Vector3(0, 0.1, 0.6))
	for k in 5:
		Toon.part(_lid, "capsule", Vector3(0.09, 1.0, 0.09), color, Vector3((k - 2) * 0.26, 0.38 - absf(k - 2) * 0.05, 0.6), Vector3(90, 0, (k - 2) * 14.0), 0.0, 0.0)
	_light = OmniLight3D.new()
	_light.light_color = color
	_light.omni_range = 4.0
	_light.light_energy = 0.0
	_light.position.y = 1.0
	add_child(_light)
	# you bump into it instead of walking through
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = 0.6
	s.height = 0.6
	c.shape = s
	c.position.y = 0.3
	body.add_child(c)
	add_child(body)
	if is_found():
		_show_open(true)


func _show_open(instant: bool) -> void:
	var tw := create_tween().set_parallel()
	var t := 0.01 if instant else 0.5
	tw.tween_property(_lid, "rotation_degrees:x", -62.0, t).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_light, "light_energy", 1.4, t)
	_pearl.material_override = Toon.material(color.lightened(0.5), 0.02, 2.2)


func use(_by: Node) -> void:
	if GameState.in_dialogue:
		return
	var first := not is_found()
	if first:
		_show_open(false)
		Audio.play("memory")
		Effects.sparkle(get_parent(), global_position + Vector3.UP * 0.8, color.lightened(0.3), 14)
		if get_node_or_null("Beacon"):
			get_node("Beacon").queue_free()
	else:
		Audio.play("blip")
	GameState.bark(bark_id)
	if first:
		GameState.data.set_flag(flag)
		opened.emit(self)

class_name SittingFriend
extends Node3D
## Someone sitting alone, caught by the Kızıl Sis (Minnoş on Kükreyen Dağ).
## You don't chase them: walk up quietly and hold Sakinleş beside them
## (group "dazed", `breathe_calm`). Then they stand up and `calmed` fires.

signal calmed

## The event sent when calmed ("breathe" + this).
@export var calm_event := "minnos"
var model: Node3D
var is_calm := false


func _ready() -> void:
	set_meta("calm_reach", 2.6)
	if not is_calm:
		add_to_group("dazed")
		MobModels._pus_wisps(self, 1.6, Tokens.color("hp"), 5, 0.5)


func set_model(m: Node3D) -> void:
	model = m
	add_child(m)


func breathe_calm() -> void:
	if is_calm:
		return
	is_calm = true
	remove_from_group("dazed")
	for c in get_children():
		if c is GPUParticles3D or c is CPUParticles3D:
			c.queue_free()
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 1.2, Tokens.color("spark-green"), 16)
	if model:
		var tw := model.create_tween()
		tw.tween_property(model, "position:y", 0.25, 0.15)
		tw.tween_property(model, "position:y", 0.0, 0.2)
	GameState.notify("breathe", calm_event)
	calmed.emit()

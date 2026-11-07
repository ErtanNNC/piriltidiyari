class_name Chest
extends Interactable
## A little treasure chest full of Pırıl. Opens once (saved as a flag).

@export var chest_id := "sandik"
@export var piril := 40
var _lid: Node3D


func _build() -> void:
	action_label = "Aç"
	Toon.part(self, "box", Vector3(1.1, 0.6, 0.8), Color("#c98d5e"), Vector3(0, 0.3, 0))
	Toon.part(self, "box", Vector3(1.15, 0.1, 0.85), "honey-deep", Vector3(0, 0.45, 0), Vector3.ZERO, 0.0, 0.0)
	_lid = Node3D.new()
	_lid.position = Vector3(0, 0.6, -0.4)
	add_child(_lid)
	Toon.part(_lid, "cylinder", Vector3(0.82, 1.1, 0.82), Color("#c98d5e"), Vector3(0, 0, 0.4), Vector3(0, 0, 90))
	Toon.part(self, "box", Vector3(0.2, 0.25, 0.08), "honey", Vector3(0, 0.55, 0.42), Vector3.ZERO, 0.6, 0.0)
	if GameState.data.has_flag("sandik_" + chest_id):
		_lid.rotation_degrees.x = -70
		_ready_opened.call_deferred()


func _ready_opened() -> void:
	done()


func use(_by: Node) -> void:
	if GameState.data.has_flag("sandik_" + chest_id):
		return
	GameState.data.set_flag("sandik_" + chest_id)
	var tw := create_tween()
	tw.tween_property(_lid, "rotation_degrees:x", -70.0, 0.3).set_trans(Tween.TRANS_BACK)
	Effects.sparkle(get_parent(), global_position + Vector3.UP, Tokens.color("piril"), 14)
	GameState.data.add_piril(piril)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 1.6, "+%d" % piril, Tokens.color("piril"))
	done()

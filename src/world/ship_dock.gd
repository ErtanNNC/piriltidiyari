class_name ShipDock
extends Interactable
## Pırpır's ship waiting at an island. "Uç" opens the travel menu.

signal travel_requested


func _build() -> void:
	action_label = "Uç"
	reach = 3.6
	var ship := ShipModel.build()
	ship.scale = Vector3.ONE * 0.8
	add_child(ship)
	var tw := ship.create_tween().set_loops()
	tw.tween_property(ship, "position:y", 0.3, 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(ship, "position:y", 0.0, 1.6).set_trans(Tween.TRANS_SINE)


func use(_by: Node) -> void:
	Audio.play("whoosh")
	travel_requested.emit()

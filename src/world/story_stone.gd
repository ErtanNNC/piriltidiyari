class_name StoryStone
extends Interactable
## Hikâye Taşı: one of 20 stones telling Mırıl's past, piece by piece.
## Reads a bark ("tas_<n>") and counts toward the 20.

const TOTAL := 20
@export var stone := 1


func _build() -> void:
	action_label = "Oku"
	Toon.part(self, "capsule", Vector3(0.9, 1.6, 0.5), Color("#b3aca2"), Vector3(0, 0.75, 0))
	Toon.part(self, "sphere", Vector3(0.36, 0.5, 0.1), "spark-purple", Vector3(0, 0.95, 0.24), Vector3.ZERO, 1.0, 0.02)
	if GameState.data.has_flag("tas_%d" % stone):
		(func() -> void: done()).call_deferred()


func use(_by: Node) -> void:
	var first := not GameState.data.has_flag("tas_%d" % stone)
	GameState.bark("tas_%d" % stone)
	if first:
		GameState.data.set_flag("tas_%d" % stone)
		GameState.data.add_item("hikaye_tasi")
		GameState.toast.emit("Hikâye Taşı %d/%d" % [GameState.data.item_count("hikaye_tasi"), TOTAL], "star")

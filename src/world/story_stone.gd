class_name StoryStone
extends Interactable
## Hikâye Taşı: stones telling Mırıl's past, piece by piece. Reads a bark
## ("tas_<n>"). Season 1 has 10; the next season adds 10 more (design: 20).

const TOTAL := PlayerData.STORY_STONES
@export var stone := 1


func _build() -> void:
	action_label = "Oku"
	Toon.part(self, "capsule", Vector3(0.9, 1.6, 0.5), Color("#b3aca2"), Vector3(0, 0.75, 0))
	Toon.part(self, "sphere", Vector3(0.36, 0.5, 0.1), "spark-purple", Vector3(0, 0.95, 0.24), Vector3.ZERO, 1.0, 0.02)
	if GameState.data.has_flag("tas_%d" % stone):
		(func() -> void: done()).call_deferred()
	else:
		Beacon.attach(self, 2.3, Tokens.color("spark-purple").lightened(0.35))


func use(_by: Node) -> void:
	var first := not GameState.data.has_flag("tas_%d" % stone)
	GameState.bark("tas_%d" % stone)
	Audio.play("stone")
	if first:
		if get_node_or_null("Beacon"):
			get_node("Beacon").queue_free()
		GameState.data.set_flag("tas_%d" % stone)
		GameState.data.add_item("hikaye_tasi")
		GameState.toast.emit(TranslationServer.translate("Hikâye Taşı %d/%d") % [GameState.data.item_count("hikaye_tasi"), TOTAL], "star")

class_name HouseDoor
extends Interactable
## The door of a village house you can go into: "Gir" takes you inside
## (scenes/chapter0/ev.tscn shows the house `house_id`). A sign above the
## door says what's inside.

@export var house_id := "dukkan"
@export var title := "Dükkân"


func _build() -> void:
	action_label = "Gir"
	reach = 1.2
	TravelSign.board(self, title, Vector3(0, 2.75, 0.35), 2.2, 0.62)


func use(_by: Node) -> void:
	SceneFlow.house_id = house_id
	SceneFlow.house_from = _scene_id()
	# come back out in front of this door (whichever way it faces)
	SceneFlow.return_point = global_position + global_transform.basis.z * 1.4 + Vector3(0, 0.05, 0)
	Audio.play("door")
	SceneFlow.go_to("house", false, false)


## The id of the scene this door stands in (also when a scene was opened
## directly, e.g. with --scene).
func _scene_id() -> String:
	var path := get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	for id: String in SceneFlow.SCENES:
		if SceneFlow.SCENES[id] == path:
			return id
	return SceneFlow.current if SceneFlow.current != "" else "chapter0"

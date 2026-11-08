class_name FairStall
extends Interactable
## A fair stall (Patpat Tarlaları): a striped awning on poles and a sign.
## "Oyna" starts its game (the scene listens to `played`).

signal played(game_id: String)

@export var game_id := "balon"
@export var title := "Balon Patlat"
@export var accent := "berry"


func _build() -> void:
	action_label = "Oyna"
	reach = 1.6
	var wood := Color("#a86b45")
	for x: float in [-1.2, 1.2]:
		Toon.part(self, "cylinder", Vector3(0.16, 2.4, 0.16), wood, Vector3(x, 1.2, -0.6))
		Toon.part(self, "cylinder", Vector3(0.16, 2.4, 0.16), wood, Vector3(x, 1.2, 0.6))
	for i in 5:
		Toon.part(self, "box", Vector3(0.52, 0.12, 1.5), accent if i % 2 == 0 else "panel", Vector3(-1.04 + i * 0.52, 2.45, 0), Vector3(0, 0, 0))
	Toon.part(self, "box", Vector3(2.6, 0.9, 0.5), Color("#f4e2c0"), Vector3(0, 0.45, 0.4))
	TravelSign.board(self, title, Vector3(0, 1.55, 0.7), 2.2, 0.6)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.6, 1.0, 0.6)
	c.shape = b
	c.position = Vector3(0, 0.5, 0.4)
	body.add_child(c)
	add_child(body)


func use(_by: Node) -> void:
	played.emit(game_id)

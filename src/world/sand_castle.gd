class_name SandCastle
extends Node3D
## Season 3, Sahne 1: a sand castle on the beach. Play a steady rhythm on
## Hırıl's drum next to it (four even beats) and it dances: flag waving,
## towers bobbing, a puff of sparkles. Event "ritim"/"kale".

const REACH := 4.5
const STREAK := 4

var danced := false
var _model: Node3D


func _ready() -> void:
	add_to_group("rhythm_listener")
	_model = ModelImport.load_model("kum_kalesi")
	if _model == null:
		_model = Node3D.new()
		var sand := Color("#e8c98a")
		Toon.part(_model, "cylinder", Vector3(2.0, 0.3, 2.0), sand, Vector3(0, 0.15, 0))
		Toon.part(_model, "box", Vector3(1.2, 0.7, 1.0), sand, Vector3(0, 0.6, 0))
		for x: float in [-0.7, 0.7]:
			Toon.part(_model, "cylinder", Vector3(0.45, 1.2, 0.45), sand, Vector3(x, 0.75, 0))
			Toon.part(_model, "cone", Vector3(0.5, 0.4, 0.5), Color("#d9b06a"), Vector3(x, 1.55, 0))
		Toon.part(_model, "box", Vector3(0.03, 0.6, 0.03), Color("#8a5a3a"), Vector3(0, 1.25, 0))
		Toon.part(_model, "box", Vector3(0.3, 0.18, 0.02), "berry", Vector3(0.16, 1.45, 0))
	add_child(_model)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.9
	cyl.height = 1.0
	col.shape = cyl
	col.position.y = 0.5
	body.add_child(col)
	add_child(body)
	Beacon.attach(self, 2.4, Tokens.color("spark-yellow"))


func hear_rhythm(from: Vector3, streak: int) -> void:
	if danced or streak < STREAK or from.distance_to(global_position) > REACH:
		return
	danced = true
	if has_node("Beacon"):
		get_node("Beacon").queue_free()
	Audio.play("fanfare")
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 1.5, Tokens.color("spark-yellow"), 16)
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.1, 2.0, Tokens.color("spark-yellow"), 0.5)
	GameState.notify("ritim", "kale")
	dance()


## A happy wiggle in time with the drum (also on reload, softly).
func dance(times := 4) -> void:
	var tw := create_tween()
	for i in times:
		tw.tween_property(_model, "scale", Vector3(1.12, 0.86, 1.12), 0.14).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(_model, "rotation:z", 0.12 * (1 if i % 2 == 0 else -1), 0.14)
		tw.tween_property(_model, "scale", Vector3(0.94, 1.12, 0.94), 0.16).set_trans(Tween.TRANS_BACK)
		tw.tween_property(_model, "scale", Vector3.ONE, 0.12)
	tw.tween_property(_model, "rotation:z", 0.0, 0.15)


func set_done() -> void:
	danced = true
	if has_node("Beacon"):
		get_node("Beacon").queue_free()

class_name FairBalloon
extends Node3D
## A fair balloon on a string: one hit pops it (Balon Patlat).

signal popped

var _ball: MeshInstance3D


func _ready() -> void:
	add_to_group("hittable")
	set_meta("hit_radius", 0.6)
	var cols := ["berry", "sky", "spark-yellow", "leaf", "spark-purple"]
	_ball = Toon.part(self, "ellipsoid", Vector3(0.7, 0.85, 0.7), cols[randi() % cols.size()], Vector3(0, 1.4, 0), Vector3.ZERO, 0.3, 0.03)
	Toon.part(self, "cylinder", Vector3(0.03, 1.0, 0.03), Color("#ffffff"), Vector3(0, 0.5, 0), Vector3.ZERO, 0.0, 0.0)
	var tw := create_tween().set_loops()
	tw.tween_property(_ball, "position:y", 1.55, 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_ball, "position:y", 1.4, 0.9).set_trans(Tween.TRANS_SINE)


func hit(_damage: int, _from: Vector3, _push: float) -> void:
	remove_from_group("hittable")
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 1.4, Tokens.color("spark-yellow"), 10)
	Audio.play("pop")
	popped.emit()
	queue_free()

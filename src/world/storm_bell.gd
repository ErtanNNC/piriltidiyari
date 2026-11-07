class_name StormBell
extends Interactable
## A storm bell on Rüzgâr Gülü Adası. Ring all three to calm the storm.

signal rung(bell: StormBell)

@export var bell_id := "can1"
var _bell: Node3D


func _build() -> void:
	action_label = "Çal"
	Toon.part(self, "cylinder", Vector3(0.3, 3.0, 0.3), Color("#a86b45"), Vector3(-1.0, 1.5, 0))
	Toon.part(self, "cylinder", Vector3(0.3, 3.0, 0.3), Color("#a86b45"), Vector3(1.0, 1.5, 0))
	Toon.part(self, "box", Vector3(2.6, 0.3, 0.3), Color("#a86b45"), Vector3(0, 3.0, 0))
	_bell = Node3D.new()
	_bell.position.y = 2.85
	add_child(_bell)
	Toon.part(_bell, "cone", Vector3(1.2, 1.2, 1.2), "honey-deep", Vector3(0, -0.5, 0))
	Toon.part(_bell, "sphere", Vector3(0.3, 0.3, 0.3), "outline", Vector3(0, -1.1, 0), Vector3.ZERO, 0.0, 0.0)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.6, 3.2, 0.5)
	c.shape = b
	c.position.y = 1.6
	body.add_child(c)
	add_child(body)
	if GameState.data.has_flag("can_" + bell_id):
		_bell.get_child(0).material_override = Toon.material("spark-yellow", 0.035, 0.8, 0.0)
		(func() -> void: done()).call_deferred()


func use(_by: Node) -> void:
	if GameState.data.has_flag("can_" + bell_id):
		return
	GameState.data.set_flag("can_" + bell_id)
	Audio.play("bell")
	var tw := create_tween()
	for i in 3:
		tw.tween_property(_bell, "rotation:z", 0.5, 0.12)
		tw.tween_property(_bell, "rotation:z", -0.5, 0.12)
	tw.tween_property(_bell, "rotation:z", 0.0, 0.1)
	_bell.get_child(0).material_override = Toon.material("spark-yellow", 0.035, 0.8, 0.0)
	Effects.ring(get_parent(), global_position + Vector3.UP * 2.5, 6.0, Tokens.color("spark-yellow"), 0.7)
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 2.5, Tokens.color("spark-yellow"), 14)
	GameState.notify("ring", "firtina_cani")
	done()
	rung.emit(self)

class_name EchoBell
extends Interactable
## A Ses Çanı (Season 2): each region of Kor Vadisi has one. It rings only
## once the region's quest allows it (`ready_flag`, or no flag needed); then
## the Kızıl Sis lifts there and the bell stays lit (a travel point later).

signal rung(bell: EchoBell)

@export var bell_id := "s2_can0"
## The bell rings only when this objective is done ("quest/objective"; "" = always).
@export var needs := ""
var _bell: Node3D


func _build() -> void:
	action_label = "Çal"
	var wood := Color("#8a5a3c")
	Toon.part(self, "cylinder", Vector3(0.3, 3.4, 0.3), wood, Vector3(-1.1, 1.7, 0))
	Toon.part(self, "cylinder", Vector3(0.3, 3.4, 0.3), wood, Vector3(1.1, 1.7, 0))
	Toon.part(self, "box", Vector3(2.9, 0.34, 0.34), wood, Vector3(0, 3.4, 0))
	Toon.part(self, "cone", Vector3(3.3, 0.8, 1.4), Color("#c9452f"), Vector3(0, 3.95, 0))
	_bell = Node3D.new()
	_bell.position.y = 3.2
	add_child(_bell)
	Toon.part(_bell, "cone", Vector3(1.3, 1.3, 1.3), Color("#c98a3a"), Vector3(0, -0.55, 0))
	Toon.part(_bell, "sphere", Vector3(0.3, 0.3, 0.3), "outline", Vector3(0, -1.2, 0), Vector3.ZERO, 0.0, 0.0)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.9, 3.6, 0.5)
	c.shape = b
	c.position.y = 1.8
	body.add_child(c)
	add_child(body)
	if GameState.data.has_flag(bell_id):
		_lit()
		(func() -> void: done()).call_deferred()


func _lit() -> void:
	_bell.get_child(0).material_override = Toon.material("spark-yellow", 0.035, 0.8, 0.0)


func use(_by: Node) -> void:
	var d := GameState.data
	if d.has_flag(bell_id):
		return
	if needs != "" and not d.objective_done(needs.get_slice("/", 0), needs.get_slice("/", 1)):
		GameState.bark("s2c0_kilit")
		return
	d.set_flag(bell_id)
	Audio.play("bell")
	var tw := create_tween()
	for i in 3:
		tw.tween_property(_bell, "rotation:z", 0.5, 0.12)
		tw.tween_property(_bell, "rotation:z", -0.5, 0.12)
	tw.tween_property(_bell, "rotation:z", 0.0, 0.1)
	_lit()
	for i in 3:
		Effects.ring(get_parent(), global_position + Vector3.UP * 2.5, 6.0 + i * 4.0, Tokens.color("spark-yellow"), 0.7 + i * 0.2)
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 2.8, Tokens.color("spark-yellow"), 16)
	GameState.notify("ring", "ses_cani")
	done()
	rung.emit(self)

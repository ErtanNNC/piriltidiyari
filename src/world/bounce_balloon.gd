class_name BounceBalloon
extends Node3D
## A big bouncy balloon: land on it and it throws you up (about 4.5 m).

@export var accent := "berry"
@export var power := 14.0
var _ball: Node3D


func _ready() -> void:
	_ball = Node3D.new()
	add_child(_ball)
	Toon.part(_ball, "sphere", Vector3(2.2, 1.4, 2.2), accent, Vector3(0, 0.7, 0), Vector3.ZERO, 0.15)
	Toon.part(_ball, "sphere", Vector3(0.5, 0.25, 0.3), Color.WHITE, Vector3(-0.5, 1.2, 0.5), Vector3.ZERO, 0.0, 0.0)
	Toon.part(self, "cylinder", Vector3(0.5, 0.2, 0.5), "outline", Vector3(0, 0.05, 0), Vector3.ZERO, 0.0, 0.0)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	var c := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.0
	cyl.height = 1.6
	c.shape = cyl
	c.position.y = 0.9
	area.add_child(c)
	add_child(area)
	area.body_entered.connect(_on_body)


func _on_body(b: Node3D) -> void:
	if not (b is Player):
		return
	var p := b as Player
	p.velocity.y = power
	p.global_position.y = maxf(p.global_position.y, global_position.y + 1.4)
	var tw := _ball.create_tween()
	tw.tween_property(_ball, "scale", Vector3(1.3, 0.6, 1.3), 0.08)
	tw.tween_property(_ball, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC)
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.4, 2.0, Tokens.color(accent), 0.3)

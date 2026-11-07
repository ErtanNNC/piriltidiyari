class_name Interactable
extends Node3D
## Base for things you press a button at (Aç, Oku, Halat at...). The
## player's sensor finds the Area3D on layer 4; the HUD button shows
## `action_label`. Subclasses override _build() and use().

@export var action_label := "Bak"
@export var reach := 1.1
var _area: Area3D


func _ready() -> void:
	_build()
	_area = Area3D.new()
	_area.collision_layer = 4
	_area.collision_mask = 0
	_area.monitoring = false
	var c := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = reach
	c.shape = s
	c.position.y = 0.8
	_area.add_child(c)
	add_child(_area)
	_area.set_meta("interactable", self)
	set_meta("action_label", action_label)


func _build() -> void:
	pass


func interact(by: Node) -> void:
	use(by)


func use(_by: Node) -> void:
	pass


## Stop being interactable (opened chest, read stone...).
func done() -> void:
	if _area:
		_area.queue_free()
		_area = null

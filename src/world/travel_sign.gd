class_name TravelSign
extends Node3D
## A wooden signpost. Press Git to travel to another region (scene).
## Hidden until `requires_flag` is set (e.g. the forest after Bölüm 0).

@export var target_scene := "chapter1"
@export var title := "Fısıltı Ormanı"
@export var requires_flag := ""
@export var action := "Git"

var _area: Area3D


func _ready() -> void:
	var wood := Color("#c98d5e")
	Toon.part(self, "cylinder", Vector3(0.22, 2.2, 0.26), wood, Vector3(0, 1.1, 0))
	var board := Toon.part(self, "box", Vector3(2.0, 0.6, 0.14), wood, Vector3(0.5, 1.9, 0))
	board.rotation_degrees.z = -4
	var l := Label3D.new()
	l.text = title
	l.font = Tokens.font_for("text-label")
	l.font_size = 48
	l.pixel_size = 0.005
	l.modulate = Tokens.color("on-color")
	l.position = Vector3(0.5, 1.9, 0.09)
	add_child(l)
	_area = Area3D.new()
	_area.collision_layer = 4
	_area.collision_mask = 0
	_area.monitoring = false
	var c := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 1.0
	c.shape = s
	c.position.y = 1.0
	_area.add_child(c)
	add_child(_area)
	set_meta("action_label", action)
	_area.set_meta("interactable", self)
	_refresh()
	GameState.data.flags_changed.connect(_refresh)


func _refresh() -> void:
	var ok := requires_flag == "" or GameState.data.has_flag(requires_flag)
	visible = ok
	_area.collision_layer = 4 if ok else 0


func interact(_by: Node) -> void:
	if visible:
		SceneFlow.go_to(target_scene)

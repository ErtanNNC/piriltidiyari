class_name Npc
extends Node3D
## A villager you can talk to. Its conversation comes from
## content/<chapter>/dialogue/<npc_id>.json. A sky "!" floats above it
## while it has something new for you (a quest to give or take).

@export var npc_id := "tospik_nine"
@export_enum("turtle", "bunny", "duckling", "frog", "statue") var kind := "turtle"
@export var face_angle_deg := 0.0

var _marker: Label3D
var _model: Node3D


func _ready() -> void:
	var speaker := Content.speaker(npc_id)
	_model = NpcModels.build(kind)
	_model.rotation_degrees.y = face_angle_deg
	add_child(_model)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.55 if kind != "turtle" else 0.9
	cyl.height = 1.6
	col.shape = cyl
	col.position.y = 0.8
	body.add_child(col)
	add_child(body)
	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 0
	area.monitoring = false
	area.set_meta("interactable", self)
	var ac := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.6
	ac.shape = s
	ac.position.y = 0.8
	area.add_child(ac)
	add_child(area)
	var top := 2.3 if kind == "turtle" else (3.2 if kind == "statue" else 1.9)
	var name_label := _label(speaker["name"], "text-heading", 64, Tokens.color("panel"))
	name_label.position.y = top
	add_child(name_label)
	_marker = _label("!", "text-hero", 160, Tokens.color("sky"))
	_marker.position.y = top + 0.65
	add_child(_marker)
	GameState.data.quest_changed.connect(func(_id: String) -> void: _refresh_marker())
	GameState.data.items_changed.connect(_refresh_marker)
	_refresh_marker()


func _process(delta: float) -> void:
	if _marker.visible:
		_marker.position.y += sin(Time.get_ticks_msec() / 220.0) * delta * 0.4


func interact(_by: Node) -> void:
	GameState.talk_to(npc_id)


func _refresh_marker() -> void:
	var v := DialogueRules.pick_variant(Content.npc(npc_id), GameState.data)
	var then: Dictionary = v.get("then", {})
	_marker.visible = then.has("start_quest") or then.has("complete_quest") or then.has("deliver")


func _label(t: String, style: String, size: int, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = t
	l.font = Tokens.font_for(style)
	l.font_size = size
	l.pixel_size = 0.005
	l.modulate = col
	l.outline_size = 18
	l.outline_modulate = Tokens.color("outline")
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return l

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
	board(self, title, Vector3(0.3, 2.05, 0.1), 2.6)
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
	var appeared := ok and not visible and is_inside_tree() and _ready_done
	visible = ok
	_area.collision_layer = 4 if ok else 0
	if appeared:
		# shows up right now (the boss just woke up): pop in with a star
		scale = Vector3(0.2, 0.2, 0.2)
		create_tween().tween_property(self, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Beacon.attach(self, 3.4)
		GameState.toast.emit("Köye dönüş tabelası çıktı", "star")
	_ready_done = true


var _ready_done := false


## The shortcut home after a boss: a "Köye dön" sign by the Kıvılcım Feneri
## that appears once the chapter is done, so nobody walks the whole way back.
static func exit_home(parent: Node3D, at: Vector3, done_flag: String, face_deg := 0.0) -> TravelSign:
	var t := TravelSign.new()
	t.name = "ExitSign"
	t.target_scene = "chapter0"
	t.title = "Gökkuşağı Köyü"
	t.action = "Köye dön"
	t.requires_flag = done_flag
	t.position = at
	t.rotation_degrees.y = face_deg
	parent.add_child(t)
	return t


func interact(_by: Node) -> void:
	if visible:
		SceneFlow.go_to(target_scene)


## A readable sign board: cream face with dark text (on-color), a wooden
## frame, tilted back so the top-down camera reads it straight on. The text
## shrinks to fit the board.
static func board(parent: Node3D, text: String, at: Vector3, width := 2.6, height := 0.8) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = at
	pivot.rotation_degrees.x = -32
	parent.add_child(pivot)
	Toon.part(pivot, "box", Vector3(width + 0.16, height + 0.16, 0.1), Color("#a86b45"), Vector3(0, 0, -0.02))
	Toon.part(pivot, "box", Vector3(width, height, 0.12), Color("#fff3dc"), Vector3.ZERO, Vector3.ZERO, 0.0, 0.0)
	var l := Label3D.new()
	l.text = text
	l.font = Tokens.font_for("text-heading")
	l.font_size = 72
	l.outline_size = 0
	l.modulate = Tokens.color("on-color")
	l.double_sided = false
	var w := l.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.font_size).x
	l.pixel_size = minf(0.0065, (width - 0.25) / maxf(w, 1.0))
	l.position = Vector3(0, -0.02, 0.07)
	pivot.add_child(l)
	return pivot

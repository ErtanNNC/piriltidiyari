class_name WhisperTree
extends Node3D
## A tree that whispers the way at a crossroads. A green tree tells the
## truth; a Pus-grey tree says the opposite (Baykuş Öğretmen Hu's rule).
## Its words float above it while you are near.

@export var says := "Sağa git..."
@export var grey := false
@export var hear_radius := 5.5

var _bubble: Label3D
var _player: Node3D


func _ready() -> void:
	ForestKit.face_tree(self, Vector3.ZERO, 1.0, grey)
	_bubble = Label3D.new()
	_bubble.text = "“%s”" % says
	_bubble.font = Tokens.font_for("text-heading")
	_bubble.font_size = 64
	_bubble.pixel_size = 0.006
	_bubble.modulate = Tokens.color("panel@light") if not grey else Tokens.color("pus").lightened(0.35)
	_bubble.outline_size = 18
	_bubble.outline_modulate = Tokens.color("outline")
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.no_depth_test = true
	_bubble.position = Vector3(0, 2.9, 1.4)
	_bubble.modulate.a = 0.0
	add_child(_bubble)
	if not grey:
		Effects.sparkle(self, global_position + Vector3.UP * 4.0, Tokens.color("spark-green"), 4)


func _process(delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		return
	var near := _player.global_position.distance_to(global_position) < hear_radius
	_bubble.modulate.a = move_toward(_bubble.modulate.a, 1.0 if near else 0.0, delta * 3.0)
	_bubble.position.y = 2.9 + sin(Time.get_ticks_msec() / 400.0) * 0.08

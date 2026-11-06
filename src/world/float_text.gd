class_name FloatText
extends Label3D
## "+1"-style number that pops up in the scene and floats away
## (text-number style: Baloo 2 ExtraBold with a dark outline).


static func spawn(parent: Node, at: Vector3, text_value: String, col: Color) -> void:
	var f := FloatText.new()
	f.text = text_value
	f.modulate = col
	parent.add_child(f)
	f.global_position = at


func _ready() -> void:
	font = Tokens.font_for("text-number")
	font_size = 96
	pixel_size = 0.006
	outline_size = 24
	outline_modulate = Tokens.color("outline")
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "position:y", position.y + 1.4, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.5)
	tw.chain().tween_callback(queue_free)

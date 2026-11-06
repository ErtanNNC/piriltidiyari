class_name SparkTracker
extends HBoxContainer
## The five Kıvılcım slots, top center. Unfound sparks are spark-off.

const ORDER := ["green", "blue", "yellow", "white", "purple"]


func _ready() -> void:
	add_theme_constant_override("separation", int(Tokens.px("space-2")))
	for c in ORDER:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(48, 48)
		slot.add_theme_stylebox_override("panel", UiKit.box(Tokens.color("panel"), "radius-pill", 3.0))
		var icon := GameIcon.new()
		icon.kind = "spark"
		icon.name = c
		icon.outline_color = Tokens.color("outline")
		slot.add_child(icon)
		add_child(slot)
	refresh()
	GameState.data.stats_changed.connect(refresh)


func refresh() -> void:
	for i in ORDER.size():
		var icon: GameIcon = get_child(i).get_child(0)
		var found := GameState.data.sparks.has(ORDER[i])
		icon.fill = Tokens.color("spark-" + ORDER[i]) if found else Tokens.color("spark-off")

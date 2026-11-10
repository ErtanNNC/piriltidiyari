class_name PearlTracker
extends HBoxContainer
## Season 3: the five pearls of the Yaşlı Deniz Feneri, top center (like
## KorTracker). A pearl is found when its flag ("inci_<id>") is set. Colors
## are the pearls' own world colors.

const COLORS := {"lacivert": Color("#3a4fb0"), "turkuaz": Color("#3ac8c0"), "kum": Color("#e8c98a"),
	"gumus": Color("#c9d4e8"), "beyaz": Color("#fff7ea")}


func _ready() -> void:
	add_theme_constant_override("separation", int(Tokens.px("space-2")))
	for c: String in ShoreTravel.PEARLS:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(48, 48)
		slot.add_theme_stylebox_override("panel", UiKit.box(Tokens.color("panel"), "radius-pill", 3.0))
		var icon := GameIcon.new()
		icon.kind = "drop"
		icon.name = c
		icon.outline_color = Tokens.color("outline")
		slot.add_child(icon)
		add_child(slot)
	refresh()
	GameState.data.flags_changed.connect(refresh)


func refresh() -> void:
	for i in ShoreTravel.PEARLS.size():
		var id: String = ShoreTravel.PEARLS[i]
		var icon: GameIcon = get_child(i).get_child(0)
		icon.fill = COLORS[id] if GameState.data.has_flag("inci_" + id) else Tokens.color("spark-off")

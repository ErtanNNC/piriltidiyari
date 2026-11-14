class_name SeedTracker
extends HBoxContainer
## Season 4: the five Bahar Tohumu of the Bahar Çeşmesi, top center (like
## PearlTracker). A seed is found when its flag ("tohum_<id>") is set.

const COLORS := {"lale": Color("#e8604a"), "papatya": Color("#fff1b0"), "gul": Color("#f08ab0"),
	"nilufer": Color("#9fd8ff"), "ay_cicegi": Color("#dfe8ff")}


func _ready() -> void:
	add_theme_constant_override("separation", int(Tokens.px("space-2")))
	for c: String in GardenTravel.SEEDS:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(48, 48)
		slot.add_theme_stylebox_override("panel", UiKit.box(Tokens.color("panel"), "radius-pill", 3.0))
		var icon := GameIcon.new()
		icon.kind = "star"
		icon.name = c
		icon.outline_color = Tokens.color("outline")
		slot.add_child(icon)
		add_child(slot)
	refresh()
	GameState.data.flags_changed.connect(refresh)


func refresh() -> void:
	for i in GardenTravel.SEEDS.size():
		var id: String = GardenTravel.SEEDS[i]
		var icon: GameIcon = get_child(i).get_child(0)
		icon.fill = COLORS[id] if GameState.data.has_flag("tohum_" + id) else Tokens.color("spark-off")

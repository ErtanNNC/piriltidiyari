class_name KorTracker
extends HBoxContainer
## Season 2: the five Kor slots, top center (like SparkTracker). A Kor is
## found when its flag ("kor_<id>") is set. Colors are the Kor's own (world
## colors, not UI tokens: they match the glowing embers in the scenes).

const ORDER := ["turuncu", "mercan", "kehribar", "bakir", "al"]
const COLORS := {"turuncu": Color("#ff8a3a"), "mercan": Color("#ff7f8f"), "kehribar": Color("#f2b33d"),
	"bakir": Color("#c87a4a"), "al": Color("#e8463a")}


func _ready() -> void:
	add_theme_constant_override("separation", int(Tokens.px("space-2")))
	for c in ORDER:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(48, 48)
		slot.add_theme_stylebox_override("panel", UiKit.box(Tokens.color("panel"), "radius-pill", 3.0))
		var icon := GameIcon.new()
		icon.kind = "heart"
		icon.name = c
		icon.outline_color = Tokens.color("outline")
		slot.add_child(icon)
		add_child(slot)
	refresh()
	GameState.data.flags_changed.connect(refresh)


static func found(d: PlayerData) -> int:
	var n := 0
	for c in ORDER:
		if d.has_flag("kor_" + c):
			n += 1
	return n


func refresh() -> void:
	for i in ORDER.size():
		var icon: GameIcon = get_child(i).get_child(0)
		icon.fill = COLORS[ORDER[i]] if GameState.data.has_flag("kor_" + ORDER[i]) else Tokens.color("spark-off")

class_name PotionSlot
extends PanelContainer
## ItemSlot for the 4 potion slots: icon, count badge, key number. 64px
## (> 48px touch target); tap or press 1–4 to drink.

var index := 0
var _hud: Node
var _icon: GameIcon
var _count: Label
var _key: Label


func _init(i: int, hud: Node) -> void:
	index = i
	_hud = hud
	custom_minimum_size = Vector2(68, 68)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var s := UiKit.box(Tokens.color("panel"), "radius-sm", 4.0)
	add_theme_stylebox_override("panel", s)
	_icon = GameIcon.new()
	_icon.custom_minimum_size = Vector2(36, 36)
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(_icon)
	_count = UiKit.outlined(UiKit.label("", "text-number", "panel@light"), 8)
	_count.add_theme_font_size_override("font_size", 22)
	_count.position = Vector2(44, 28)
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_count)
	add_child(holder)
	_key = UiKit.label(str(index + 1), "text-caption", "ink-muted")
	_key.position = Vector2(6, 0)
	holder.add_child(_key)
	refresh()


func refresh() -> void:
	if not is_node_ready():
		return
	var id: String = GameState.data.potions[index]
	var n := GameState.data.item_count(id) if id != "" else 0
	var def: Dictionary = Content.items.get(id, {})
	_icon.visible = id != ""
	# an empty slot isn't shown: the bar only has things you can use
	visible = id != "" and n > 0
	_icon.kind = def.get("icon", "heart")
	_icon.fill = Tokens.color(def.get("color", "hp")) if n > 0 else Tokens.color("spark-off")
	_count.text = str(n) if id != "" else ""
	_key.visible = not _hud.touch


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed):
		var p: Player = _hud.player()
		if p:
			p.drink_potion(index)
		accept_event()

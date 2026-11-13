class_name ToolSlot
extends PanelContainer
## Quick bar slot for a tool you bought (Işık Değneği, Yıldız Asası,
## Kıvılcım Kılıcı). Tap or press 5–7 to hold it; the held one glows.

const TOOLS := ["isik_degnegi", "yildiz_asasi", "kivilcim_kilici"]

var index := 0
var _hud: Node
var _icon: GameIcon
var _name: Label
var _key: Label


## Tools you own, in shop order.
static func owned_tools() -> Array:
	var out := []
	for id: String in TOOLS:
		if GameState.data.has_flag("owned_" + id):
			out.append(id)
	return out


func _init(i: int, hud: Node) -> void:
	index = i
	_hud = hud
	custom_minimum_size = Vector2(68, 68)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	_icon = GameIcon.new()
	_icon.kind = "spark"
	_icon.custom_minimum_size = Vector2(34, 34)
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(_icon)
	_name = UiKit.label("", "text-caption", "ink")
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_name)
	_key = UiKit.label(str(index + 5), "text-caption", "ink-muted")
	_key.position = Vector2(6, 0)
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_key)
	add_child(holder)
	refresh()


func refresh() -> void:
	if not is_node_ready():
		return
	var owned := owned_tools()
	visible = index < owned.size()
	if not visible:
		return
	var id: String = owned[index]
	var def: Dictionary = Content.items.get(id, {})
	var held: bool = GameState.data.equipped.get("weapon", "") == id
	_icon.fill = Tokens.color(def.get("color", "honey"))
	_name.text = String(def.get("name", id)).split(" ")[0]
	_key.visible = not _hud.touch
	# the held tool sits on a honey slot with a thick border
	var s := UiKit.box(Tokens.color("honey" if held else "panel"), "radius-sm", 4.0 if held else 2.0)
	add_theme_stylebox_override("panel", s)
	_name.add_theme_color_override("font_color", Tokens.color("on-color" if held else "ink"))


func _gui_input(event: InputEvent) -> void:
	# a tap arrives as a touch AND as a mouse click: take one, or it fires twice
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Player = _hud.player()
		if p:
			p.switch_tool(index)
		accept_event()

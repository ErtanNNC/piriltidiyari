class_name SaveSlotsPanel
extends Control
## "Kayıtlar": the three save slots side by side. In "load" mode a slot is
## picked to continue (or deleted); in "new" mode a slot is picked for a new
## adventure (a full slot asks before it is written over).
##   var p := SaveSlotsPanel.new("load"); p.chosen.connect(...); add_child(p)

signal chosen(slot: int)
signal closed

var mode := "load"
var _row: HBoxContainer


func _init(m := "load") -> void:
	mode = m


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.color = Tokens.color("scrim")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", int(Tokens.px("space-4")))
	add_child(v)
	var title := UiKit.outlined(UiKit.label("Yeni macera: bir yuva seç" if mode == "new" else "Kayıtlar", "text-title", "panel@light"), 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", int(Tokens.px("space-4")))
	v.add_child(_row)
	var back := UiKit.button("Geri", false)
	back.custom_minimum_size = Vector2(200, 56)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	v.add_child(back)
	_fill()


func _fill() -> void:
	for c in _row.get_children():
		c.queue_free()
	for s in range(1, SaveGame.SLOTS + 1):
		_row.add_child(_card(s))


func _card(s: int) -> Control:
	var info := SaveGame.summary(s)
	var card := PanelContainer.new()
	card.name = TranslationServer.translate("Slot%d") % s
	card.custom_minimum_size = Vector2(300, 300)
	card.add_theme_stylebox_override("panel", UiKit.panel_style())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	card.add_child(v)
	var head := UiKit.label(TranslationServer.translate("Kayıt %d") % s, "text-heading", "ink")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	if info.is_empty():
		var e := UiKit.label("Boş yuva", "text-body", "ink-muted")
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e.size_flags_vertical = Control.SIZE_EXPAND_FILL
		e.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		v.add_child(e)
	else:
		var name: String = info["name"] if String(info["name"]) != "" else "Bekçi"
		v.add_child(_line(TranslationServer.translate("%s · Seviye %d") % [TranslationServer.translate(name), info["level"]], "text-body", "ink"))
		var place: Array = SceneFlow.CARDS.get(info["scene_id"], ["", "Yolculukta"])
		v.add_child(_line(place[1], "text-body", "ink"))
		v.add_child(_line(TranslationServer.translate("Kıvılcım %d/5 · %d Pırıl") % [info["sparks"], info["piril"]], "text-caption", "ink-muted"))
		v.add_child(_line(_when(float(info["saved_at"])), "text-caption", "ink-muted"))
		var gap := Control.new()
		gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(gap)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	v.add_child(actions)
	_actions(actions, s, info.is_empty())
	return card


func _line(text: String, style: String, col: String) -> Label:
	var l := UiKit.label(text, style, col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(260, 0)
	return l


func _actions(box: VBoxContainer, s: int, empty: bool) -> void:
	for c in box.get_children():
		c.queue_free()
	if mode == "new":
		var b := UiKit.button("Burada başla" if empty else "Üstüne yaz", empty)
		b.custom_minimum_size = Vector2(0, 56)
		b.name = "Pick"
		box.add_child(b)
		if empty:
			b.pressed.connect(func() -> void: chosen.emit(s))
		else:
			b.pressed.connect(func() -> void: _confirm(box, s, "Eski kayıt silinsin mi?", func() -> void: chosen.emit(s)))
			box.add_child(_delete_button(box, s))
		return
	if empty:
		return
	var load := UiKit.button("Devam et")
	load.name = "Pick"
	load.custom_minimum_size = Vector2(0, 56)
	load.pressed.connect(func() -> void: chosen.emit(s))
	box.add_child(load)
	box.add_child(_delete_button(box, s))


## "Sil": empties the slot (after an "Emin misin?").
func _delete_button(box: VBoxContainer, s: int) -> Button:
	var del := UiKit.button("Sil", false)
	del.name = "Delete"
	del.custom_minimum_size = Vector2(0, 48)
	del.pressed.connect(func() -> void: _confirm(box, s, "Bu kayıt silinsin mi?", func() -> void:
		SaveGame.clear(s)
		_fill()))
	return del


## Swap a card's buttons for "Emin misin?" Evet / Vazgeç.
func _confirm(box: VBoxContainer, s: int, question: String, yes: Callable) -> void:
	for c in box.get_children():
		c.queue_free()
	var q := UiKit.label(question, "text-label", "ink")
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(q)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	box.add_child(h)
	var y := UiKit.button("Evet")
	var n := UiKit.button("Vazgeç", false)
	for b: Button in [y, n]:
		b.custom_minimum_size = Vector2(0, 52)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(b)
	y.pressed.connect(yes)
	n.pressed.connect(func() -> void: _actions(box, s, false))


static func _when(t: float) -> String:
	if t <= 0.0:
		return ""
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(int(t) + bias)
	return TranslationServer.translate("%02d.%02d.%d  %02d:%02d") % [d["day"], d["month"], d["year"], d["hour"], d["minute"]]

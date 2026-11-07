class_name Hud
extends CanvasLayer
## In-game HUD laid out per the design system's screen rules:
## top-left portrait + level + HP/MP/XP, top-center Kıvılcım tracker,
## top-right Pırıl + quest tracker, bottom the dialog box, 24px safe area.

var _player: Player
var _hp: StatBar
var _mp: StatBar
var _xp: StatBar
var _level: Label
var _piril: Label
var _quest_panel: PanelContainer
var _quest_title: Label
var _quest_lines: VBoxContainer
var _talk: Button
var _dialog: DialogBox
var _toast: PanelContainer
var _toast_label: Label
var _toast_icon: GameIcon
var _toast_tween: Tween
var _root: Control
var _potion_bar: HBoxContainer
var _hint: PanelContainer
var _hint_label: Label
var _sparks: SparkTracker
var _boss: VBoxContainer
var _boss_name: Label
var _boss_bar: StatBar
var touch := false


func _ready() -> void:
	add_to_group("hud")
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var m := Tokens.px("space-6")

	# top-left: portrait, level badge, bars
	var tl := PanelContainer.new()
	tl.add_theme_stylebox_override("panel", UiKit.panel_style())
	tl.position = Vector2(m, m)
	_root.add_child(tl)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	tl.add_child(row)
	var portrait := Panel.new()
	portrait.custom_minimum_size = Vector2(72, 72)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.add_theme_stylebox_override("panel", UiKit.box(Tokens.color("honey"), "radius-pill", 3.0))
	row.add_child(portrait)
	var letter := UiKit.label("F", "text-title", "on-color")
	letter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait.add_child(letter)
	var badge := PanelContainer.new()
	var bs := UiKit.box(Tokens.color("xp"), "radius-pill", 0.0)
	bs.content_margin_left = 8
	bs.content_margin_right = 8
	badge.add_theme_stylebox_override("panel", bs)
	badge.position = Vector2(46, 50)
	portrait.add_child(badge)
	_level = UiKit.label("1", "text-caption", "on-color")
	badge.add_child(_level)
	var bars := VBoxContainer.new()
	bars.add_theme_constant_override("separation", 2)
	row.add_child(bars)
	bars.add_child(UiKit.label("Fıstık", "text-heading", "ink"))
	_hp = StatBar.new(); _hp.stat = "hp"; bars.add_child(_hp)
	_mp = StatBar.new(); _mp.stat = "mp"; bars.add_child(_mp)
	_xp = StatBar.new(); _xp.stat = "xp"; bars.add_child(_xp)

	# top-center: spark tracker
	var tc := CenterContainer.new()
	tc.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tc.offset_top = m
	tc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tc)
	var top_center := VBoxContainer.new()
	top_center.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	top_center.alignment = BoxContainer.ALIGNMENT_BEGIN
	tc.add_child(top_center)
	_sparks = SparkTracker.new()
	_sparks.alignment = BoxContainer.ALIGNMENT_CENTER
	top_center.add_child(_sparks)
	_boss = VBoxContainer.new()
	_boss.visible = false
	_boss.add_theme_constant_override("separation", 2)
	top_center.add_child(_boss)
	_boss_name = UiKit.outlined(UiKit.label("", "text-heading", "panel"), 8)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss.add_child(_boss_name)
	_boss_bar = StatBar.new()
	_boss_bar.stat = "hp"
	_boss_bar.custom_minimum_size = Vector2(460, 34)
	_boss.add_child(_boss_bar)
	_hint = PanelContainer.new()
	var hs := UiKit.box(Tokens.color("panel"), "radius-pill", 4.0)
	hs.content_margin_left = 16
	hs.content_margin_right = 20
	hs.content_margin_top = 6
	hs.content_margin_bottom = 6
	_hint.add_theme_stylebox_override("panel", hs)
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint.custom_minimum_size.x = 0
	_hint.visible = false
	top_center.add_child(_hint)
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	_hint.add_child(hrow)
	var hicon := GameIcon.new()
	hicon.kind = "quest"
	hicon.fill = Tokens.color("sky")
	hrow.add_child(hicon)
	_hint_label = UiKit.label("", "text-label", "ink")
	_hint_label.add_theme_font_size_override("font_size", 20)
	hrow.add_child(_hint_label)

	# top-right: Pırıl pill + quest tracker
	var tr := VBoxContainer.new()
	tr.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tr.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tr.offset_right = -m
	tr.offset_top = m
	tr.alignment = BoxContainer.ALIGNMENT_BEGIN
	tr.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	_root.add_child(tr)
	var pill := PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_SHRINK_END
	var ps := UiKit.box(Tokens.color("panel"), "radius-pill", 4.0)
	ps.content_margin_left = 12
	ps.content_margin_right = 18
	ps.content_margin_top = 4
	ps.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", ps)
	tr.add_child(pill)
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", int(Tokens.px("space-1")) + 2)
	pill.add_child(prow)
	var picon := GameIcon.new()
	picon.kind = "piril"
	picon.fill = Tokens.color("piril")
	picon.custom_minimum_size = Vector2(32, 32)
	prow.add_child(picon)
	_piril = UiKit.label("0", "text-number", "ink")
	_piril.add_theme_font_override("font", Tokens.font_for("text-number"))
	prow.add_child(_piril)

	_quest_panel = PanelContainer.new()
	_quest_panel.add_theme_stylebox_override("panel", UiKit.panel_style())
	_quest_panel.custom_minimum_size = Vector2(300, 0)
	tr.add_child(_quest_panel)
	var qv := VBoxContainer.new()
	qv.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	_quest_panel.add_child(qv)
	var qh := HBoxContainer.new()
	qh.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	qv.add_child(qh)
	var qicon := GameIcon.new()
	qicon.kind = "quest"
	qicon.fill = Tokens.color("sky")
	qh.add_child(qicon)
	_quest_title = UiKit.label("", "text-heading", "ink")
	qh.add_child(_quest_title)
	_quest_lines = VBoxContainer.new()
	qv.add_child(_quest_lines)

	# bottom-center: talk button (shown near an NPC)
	_talk = UiKit.button("Konuş")
	_talk.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_talk.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_talk.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_talk.offset_bottom = -m - 96
	_talk.custom_minimum_size = Vector2(160, 60)
	_talk.offset_left = -80
	_talk.offset_right = 80
	_talk.visible = false
	_talk.pressed.connect(func() -> void:
		if _player:
			_player.interact())
	_root.add_child(_talk)

	# toast
	_toast = PanelContainer.new()
	var ts := UiKit.box(Tokens.color("panel"), "radius-pill", 4.0)
	ts.content_margin_left = 16
	ts.content_margin_right = 20
	ts.content_margin_top = 8
	ts.content_margin_bottom = 8
	_toast.add_theme_stylebox_override("panel", ts)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_top = 100
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_toast)
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	_toast.add_child(trow)
	_toast_icon = GameIcon.new()
	_toast_icon.custom_minimum_size = Vector2(28, 28)
	trow.add_child(_toast_icon)
	_toast_label = UiKit.label("", "text-label", "ink")
	_toast_label.add_theme_font_size_override("font_size", 20)
	trow.add_child(_toast_label)

	var tcs := TouchControls.new()
	_root.add_child(tcs)
	touch = tcs.visible

	_potion_bar = HBoxContainer.new()
	_potion_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_potion_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_potion_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_potion_bar.offset_bottom = -m
	_potion_bar.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	_root.add_child(_potion_bar)
	for i in PlayerData.POTION_SLOTS:
		_potion_bar.add_child(PotionSlot.new(i, self))

	_dialog = DialogBox.new()
	_root.add_child(_dialog)
	_dialog.finished.connect(_on_dialog_finished)

	var d := GameState.data
	d.stats_changed.connect(_refresh_stats)
	d.piril_changed.connect(_on_piril)
	d.quest_changed.connect(func(_id: String) -> void: _refresh_quest())
	d.items_changed.connect(_refresh_potions)
	d.leveled_up.connect(func(lv: int) -> void: show_scene_card("Seviye atladın!", "Seviye %d" % lv, ""))
	GameState.dialogue_requested.connect(_open_dialogue)
	GameState.toast.connect(show_toast)
	_refresh_stats()
	_refresh_quest()
	_on_piril(d.piril, 0)
	_refresh_potions()
	_bind_player.call_deferred()


func _bind_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_player.focus_changed.connect(func(t: Node) -> void: _talk.visible = t != null and not _dialog.is_open())


func _refresh_stats() -> void:
	var d := GameState.data
	_hp.set_values(d.hp, d.max_hp)
	_mp.set_values(d.mp, d.max_mp)
	_xp.set_values(d.xp, Progression.xp_to_next(d.level))
	_level.text = str(d.level)


func _on_piril(total: int, delta: int) -> void:
	_piril.text = str(total)
	if delta > 0:
		var tw := _piril.create_tween()
		_piril.pivot_offset = _piril.size * 0.5
		tw.tween_property(_piril, "scale", Vector2.ONE * 1.25, 0.08)
		tw.tween_property(_piril, "scale", Vector2.ONE, 0.15)


func _refresh_quest() -> void:
	var id := GameState.tracked_quest()
	_quest_panel.visible = id != ""
	if id == "":
		return
	var def: Dictionary = Content.quests[id]
	var p := GameState.data.objective_progress(id)
	_quest_title.text = "%s  %d/%d" % [def["title"], p.x, p.y]
	for c in _quest_lines.get_children():
		c.queue_free()
	if GameState.data.quest_state(id) == "ready":
		_quest_lines.add_child(_objective_row(def.get("turn_in", "Görevi teslim et"), false))
		return
	for o: Dictionary in def["objectives"]:
		_quest_lines.add_child(_objective_row(o["text"], GameState.data.objective_done(id, o["id"])))


func _objective_row(text: String, done: bool) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	var ic := GameIcon.new()
	ic.kind = "check" if done else "lantern"
	ic.fill = Tokens.color("leaf") if done else Tokens.color("spark-off")
	ic.custom_minimum_size = Vector2(22, 22)
	r.add_child(ic)
	var l := UiKit.label(text, "text-caption", "ink-muted" if done else "ink")
	r.add_child(l)
	return r


func _open_dialogue(npc_id: String) -> void:
	var v := DialogueRules.pick_variant(Content.npc(npc_id), GameState.data)
	if v.is_empty():
		return
	if _player:
		_player.input_enabled = false
	_talk.visible = false
	_potion_bar.visible = false
	_dialog.open(v.get("lines", []), v.get("then", {}))


func _on_dialog_finished() -> void:
	_refresh_potions()
	if _player:
		_player.input_enabled = true
		_talk.visible = _player.current_focus() != null


func show_toast(text: String, icon := "star") -> void:
	_toast_label.text = text
	_toast_icon.kind = icon
	_toast_icon.fill = Tokens.color({"quest": "sky", "lantern": "honey", "star": "xp"}.get(icon, "honey"))
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast.modulate.a = 0.0
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.15)
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.3)


## Full-screen title card: chapter titles, "Seviye atladın!" and the like.
func show_scene_card(small: String, big: String, sub: String) -> void:
	var card := Control.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = Tokens.color("scrim")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(bg)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(v)
	for spec in [[small, "text-heading", "honey"], [big, "text-hero", "panel"], [sub, "text-body", "panel"]]:
		if spec[0] == "":
			continue
		var l := UiKit.outlined(UiKit.label(spec[0], spec[1], spec[2]), 12 if spec[1] == "text-hero" else 8)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	_root.add_child(card)
	card.modulate.a = 0.0
	var tw := card.create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.5)
	tw.tween_property(card, "modulate:a", 0.0, 0.5)
	tw.tween_callback(card.queue_free)


func player() -> Player:
	return _player


func _refresh_potions() -> void:
	var any := false
	for p in GameState.data.potions:
		if p != "":
			any = true
	_potion_bar.visible = any and not _dialog.is_open()
	for c in _potion_bar.get_children():
		(c as PotionSlot).refresh()


## Persistent tutorial bubble under the spark tracker until cleared.
func show_hint(desktop_text: String, touch_text := "") -> void:
	_hint_label.text = touch_text if touch and touch_text != "" else desktop_text
	_hint.visible = true
	_hint.pivot_offset = _hint.size * 0.5
	var tw := _hint.create_tween()
	_hint.scale = Vector2(0.8, 0.8)
	tw.tween_property(_hint, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func clear_hint() -> void:
	_hint.visible = false


## Boss fights put the boss's name and HP bar where the spark tracker sits.
func show_boss(boss_name: String, hp: int, max_hp: int) -> void:
	_sparks.visible = false
	_boss.visible = true
	_boss_name.text = boss_name
	set_boss_hp(hp, max_hp)


func set_boss_hp(hp: int, max_hp: int) -> void:
	_boss_bar.set_values(hp, max_hp, " ")


func hide_boss() -> void:
	_boss.visible = false
	_sparks.visible = true

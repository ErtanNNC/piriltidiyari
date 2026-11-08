class_name Hud
extends CanvasLayer
## In-game HUD laid out per the design system's screen rules:
## top-left portrait + level + HP/MP/XP, top-center Kıvılcım tracker,
## top-right Pırıl + quest tracker, bottom the dialog box, 24px safe area.

var _player: Player
var _hp: StatBar
var _mp: StatBar
var _xp: StatBar
var _anger: StatBar
var _kors: KorTracker
var _level: Label
var _piril: Label
var _pause_btn: Button
var _name_label: Label
var _power_bar: VBoxContainer
var _power_buttons: Array[Button] = []
var _level_panel: LevelUpPanel
var _touch_controls: TouchControls
var _pause_panel: Control
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
var _cinematic := false


func _ready() -> void:
	add_to_group("hud")
	if DevTools.demo == "pause":
		get_tree().create_timer(3.5).timeout.connect(toggle_pause)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)
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
	var info: Dictionary = Content.keeper(GameState.data.character_id)
	if not info.is_empty():
		portrait.add_theme_stylebox_override("panel", UiKit.box(Tokens.color(Content.text_safe(info["color"])), "radius-pill", 3.0))
	var letter := UiKit.label(TranslationServer.translate(GameState.data.character_name).left(1), "text-title", "on-color")
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
	_name_label = UiKit.label(GameState.data.character_name, "text-heading", "ink")
	bars.add_child(_name_label)
	_hp = StatBar.new(); _hp.stat = "hp"; bars.add_child(_hp)
	_mp = StatBar.new(); _mp.stat = "mp"; bars.add_child(_mp)
	_xp = StatBar.new(); _xp.stat = "xp"; bars.add_child(_xp)
	# Season 2: the Öfke barı, shown while the Kızıl Sis heats the keeper up
	_anger = StatBar.new(); _anger.stat = "anger"; _anger.visible = false; bars.add_child(_anger)

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
	_sparks.visible = GameState.data.season < 2  # Season 2 has its own Kor
	top_center.add_child(_sparks)
	_kors = KorTracker.new()
	_kors.alignment = BoxContainer.ALIGNMENT_CENTER
	# the Kor slots show once Season 2's keeper is on the road
	_kors.visible = GameState.data.has_flag("s2_prolog_bitti")
	top_center.add_child(_kors)
	_boss = VBoxContainer.new()
	_boss.visible = false
	_boss.add_theme_constant_override("separation", 2)
	top_center.add_child(_boss)
	_boss_name = UiKit.outlined(UiKit.label("", "text-heading", "panel@light"), 8)
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
	# pause button left of the Pırıl pill
	var top_row := HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	top_row.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	tr.add_child(top_row)
	_pause_btn = UiKit.button("II", false)
	_pause_btn.custom_minimum_size = Vector2(52, 52)
	_pause_btn.focus_mode = Control.FOCUS_NONE
	_pause_btn.pressed.connect(toggle_pause)
	var turn_btn := UiKit.button("Çevir", false)
	turn_btn.custom_minimum_size = Vector2(88, 52)
	turn_btn.focus_mode = Control.FOCUS_NONE
	turn_btn.button_down.connect(func() -> void: TouchControls._send("cam_right", true))
	turn_btn.button_up.connect(func() -> void: TouchControls._send("cam_right", false))
	top_row.add_child(turn_btn)
	top_row.add_child(_pause_btn)
	top_row.add_child(pill)
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
	_touch_controls = tcs
	# on phones: drag the screen to turn the camera, powers sit on the arc
	turn_btn.visible = not touch

	# level-up powers: buttons on the left edge (O / P keys)
	_power_bar = VBoxContainer.new()
	_power_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	_power_bar.grow_vertical = Control.GROW_DIRECTION_BOTH
	_power_bar.offset_left = m
	_power_bar.offset_top = 40
	_power_bar.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	_root.add_child(_power_bar)
	for i in Powers.ACTIVE_SLOTS:
		var b := UiKit.button("", true)
		b.custom_minimum_size = Vector2(150, 60)
		b.focus_mode = Control.FOCUS_NONE
		var action := "power_%d" % (i + 1)
		b.button_down.connect(func() -> void: TouchControls._send(action, true))
		b.button_up.connect(func() -> void: TouchControls._send(action, false))
		b.visible = false
		_power_bar.add_child(b)
		_power_buttons.append(b)
	if touch:
		_power_bar.visible = false
		_power_buttons.assign(tcs.power_buttons)
	_potion_bar = HBoxContainer.new()
	_potion_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_potion_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_potion_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_potion_bar.offset_bottom = -m
	_potion_bar.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	_root.add_child(_potion_bar)
	for i in PlayerData.POTION_SLOTS:
		_potion_bar.add_child(PotionSlot.new(i, self))
	# bought tools sit next to the potions: tap (or 5–7) to switch
	for i in ToolSlot.TOOLS.size():
		_potion_bar.add_child(ToolSlot.new(i, self))

	_dialog = DialogBox.new()
	_root.add_child(_dialog)
	_dialog.finished.connect(_on_dialog_finished)

	var d := GameState.data
	d.stats_changed.connect(_refresh_stats)
	d.piril_changed.connect(_on_piril)
	d.quest_changed.connect(func(_id: String) -> void: _refresh_quest())
	d.items_changed.connect(_refresh_potions)
	d.skills_changed.connect(_refresh_powers)
	d.stats_changed.connect(_refresh_potions)
	d.flags_changed.connect(_refresh_potions)
	GameState.dialogue_requested.connect(_open_dialogue)
	GameState.lines_requested.connect(_open_lines)
	GameState.shop_requested.connect(open_shop)
	GameState.toast.connect(show_toast)
	_refresh_stats()
	_refresh_quest()
	_on_piril(d.piril, 0)
	_refresh_potions()
	_refresh_powers()
	_bind_player.call_deferred()


func _bind_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_player.focus_changed.connect(func(t: Node) -> void:
			_talk.visible = t != null and not _dialog.is_open()
			if t:
				_talk.text = String(t.get_meta("action_label", "Konuş")))


func _refresh_stats() -> void:
	var d := GameState.data
	_hp.set_values(d.hp, d.max_hp)
	_mp.set_values(d.mp, d.max_mp)
	var nxt := Progression.xp_to_next(d.level)
	_xp.set_values(d.xp, nxt, (TranslationServer.translate("%d / %d XP") % [d.xp, nxt]) if nxt > 0 else "En yüksek seviye")
	_level.text = str(d.level)
	_name_label.text = TranslationServer.translate("%s · Seviye %d") % [TranslationServer.translate(d.character_name), d.level]


func _on_piril(total: int, delta: int) -> void:
	_piril.text = str(total)
	if delta > 0:
		var tw := _piril.create_tween()
		_piril.pivot_offset = _piril.size * 0.5
		tw.tween_property(_piril, "scale", Vector2.ONE * 1.25, 0.08)
		tw.tween_property(_piril, "scale", Vector2.ONE, 0.15)


func _refresh_quest() -> void:
	var id := GameState.tracked_quest()
	_quest_panel.visible = id != "" and not _boss.visible
	if id == "":
		return
	var def: Dictionary = Content.quests[id]
	var p := GameState.data.objective_progress(id)
	_quest_title.text = TranslationServer.translate("%s  %d/%d") % [TranslationServer.translate(def["title"]), p.x, p.y]
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
	_open_lines(GameState.resolve_speakers(v.get("lines", [])), v.get("then", {}))


func _open_lines(lines: Array, then: Dictionary) -> void:
	if _dialog.is_open():
		await _dialog.finished
	if _player:
		_player.input_enabled = false
	_talk.visible = false
	_potion_bar.visible = false
	GameState.in_dialogue = true
	_dialog.open(lines, then)


func _on_dialog_finished() -> void:
	GameState.in_dialogue = false
	_refresh_potions()
	GameState.dialogue_closed.emit()
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
	if small.begins_with("Kıvılcım"):
		Audio.play("fanfare")
	elif big.ends_with("uyandı!"):
		Audio.play("boss_calm")
	elif not big.begins_with("Uykuya") and not big.begins_with("Seviye"):
		Audio.play("card")
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
	for spec in [[small, "text-heading", "honey"], [big, "text-hero", "panel@light"], [sub, "text-body", "panel@light"]]:
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
	var any := not ToolSlot.owned_tools().is_empty()
	for p: String in GameState.data.potions:
		if p != "" and GameState.data.item_count(p) > 0:
			any = true
	_potion_bar.visible = any and not _dialog.is_open() and not _cinematic
	for c in _potion_bar.get_children():
		c.call("refresh")


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
	_kors.visible = false
	_quest_panel.visible = false
	_boss.visible = true
	Audio.boss(true)
	_boss_name.text = boss_name
	set_boss_hp(hp, max_hp)


func set_boss_hp(hp: int, max_hp: int) -> void:
	_boss_bar.set_values(hp, max_hp, " ")


func hide_boss() -> void:
	Audio.boss(false)
	_boss.visible = false
	_sparks.visible = GameState.data.season < 2
	_kors.visible = GameState.data.has_flag("s2_prolog_bitti")
	_refresh_quest()


## Cutscenes hide the HUD (bars, quest, buttons); dialogue still shows.
var _was_visible: Dictionary = {}


func cinematic(on: bool) -> void:
	if on == _cinematic:
		return
	_cinematic = on
	for c in _root.get_children():
		if c == _dialog or c == _toast:
			continue
		if on:
			_was_visible[c] = c.visible
			c.visible = false
		else:
			c.visible = _was_visible.get(c, true)
	if not on:
		_refresh_potions()
		_refresh_quest()
		_boss.visible = false
		_hint.visible = false
		_talk.visible = false


## A white flash over everything (the Kıvılcım bursting).
func flash(seconds: float, col := Color(1, 1, 0.94, 1)) -> void:
	var f := ColorRect.new()
	f.color = col
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(f)
	var tw := f.create_tween()
	tw.tween_interval(seconds * 0.25)
	tw.tween_property(f, "modulate:a", 0.0, seconds * 0.75)
	await tw.finished
	f.queue_free()


func _exit_tree() -> void:
	GameState.in_dialogue = false


func open_shop(shop_id: String) -> void:
	if _player:
		_player.input_enabled = false
	GameState.in_dialogue = true
	var sp := ShopPanel.new(shop_id)
	_root.add_child(sp)
	sp.closed.connect(func() -> void:
		GameState.in_dialogue = false
		_refresh_potions()
		if _player:
			_player.input_enabled = true)


## Modal choice (e.g. Pırpır's travel menu). Returns the chosen id or "".
func ask(title: String, options: Array) -> String:
	if _player:
		_player.input_enabled = false
	GameState.in_dialogue = true
	var cp := ChoicePanel.new(title, options)
	_root.add_child(cp)
	var id: String = await cp.chosen
	GameState.in_dialogue = false
	if _player:
		_player.input_enabled = true
	return id


# --- pause ("Mola") -----------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _cinematic and not _dialog.is_open():
		toggle_pause()
		get_viewport().set_input_as_handled()


## Mola: stops the game; music/sound toggles and the way back to the title.
func toggle_pause() -> void:
	if _pause_panel:
		_pause_panel.queue_free()
		_pause_panel = null
		_release_touch()
		get_tree().paused = false
		return
	if _cinematic or _dialog.is_open() or SceneFlow.busy:
		return
	_release_touch()
	get_tree().paused = true
	var p := Control.new()
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Tokens.color("scrim")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_child(bg)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style())
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	panel.add_child(v)
	var title := UiKit.label("Mola", "text-title", "ink")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var cont := UiKit.button("Devam et")
	var mus := UiKit.button("", false)
	var sfx := UiKit.button("", false)
	for spec: Array in [["Müzik sesi", "music"], ["Efekt sesi", "sfx"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", int(Tokens.px("space-2")))
		var l := UiKit.label(spec[0], "text-label", "ink")
		l.custom_minimum_size = Vector2(110, 0)
		row.add_child(l)
		var sl := HSlider.new()
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.05
		sl.value = Audio.music_volume if spec[1] == "music" else Audio.sfx_volume
		sl.custom_minimum_size = Vector2(170, 48)
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var kind: String = spec[1]
		sl.value_changed.connect(func(val: float) -> void:
			if kind == "music":
				Audio.set_volumes(val, Audio.sfx_volume)
			else:
				Audio.set_volumes(Audio.music_volume, val)
				Audio.play("coin"))
		row.add_child(sl)
		v.add_child(row)
	var save := UiKit.button(TranslationServer.translate("Kaydet (Kayıt %d)") % SaveGame.slot, false)
	save.name = "SaveButton"
	var stuck := UiKit.button("Takıldım: son fenere dön", false)
	var menu := UiKit.button("Ana menü", false)
	var lang := UiKit.button("Language: English" if Audio.language == "en" else "Dil: Türkçe", false)
	lang.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	lang.pressed.connect(func() -> void:
		Audio.set_language("tr" if Audio.language == "en" else "en")
		# rebuild the menu (and the HUD texts) in the new language
		toggle_pause()
		_refresh_powers()
		_refresh_stats()
		toggle_pause())
	for b: Button in [cont, save, mus, sfx, lang, stuck, menu]:
		b.custom_minimum_size = Vector2(280, 56)
		v.add_child(b)
	var refresh := func() -> void:
		mus.text = TranslationServer.translate("Müzik: %s") % TranslationServer.translate("Açık" if Audio.music_on else "Kapalı")
		sfx.text = TranslationServer.translate("Sesler: %s") % TranslationServer.translate("Açık" if Audio.sfx_on else "Kapalı")
	refresh.call()
	cont.pressed.connect(toggle_pause)
	mus.pressed.connect(func() -> void:
		Audio.set_music_on(not Audio.music_on)
		refresh.call())
	sfx.pressed.connect(func() -> void:
		Audio.set_sfx_on(not Audio.sfx_on)
		refresh.call())
	stuck.pressed.connect(func() -> void:
		toggle_pause()
		if _player and is_instance_valid(_player):
			_player.unstick())
	save.pressed.connect(func() -> void:
		var ok := SaveGame.write(GameState.data) == OK
		save.text = "Kaydedildi!" if ok else "Kaydedilemedi"
		Audio.play("coin" if ok else "warn"))
	menu.pressed.connect(func() -> void:
		toggle_pause()
		SceneFlow.go_to("title", false))
	var note := UiKit.label(TranslationServer.translate("Bölüm başlarında kendiliğinden de kaydedilir. · %d FPS") % Engine.get_frames_per_second(), "text-caption", "ink-muted")
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(note)
	_root.add_child(p)
	_pause_panel = p


# --- level-up powers ------------------------------------------------------------

## Nothing stays held across a pause: the stick, held buttons, and keys
## whose release may have been missed.
func _release_touch() -> void:
	if _touch_controls:
		_touch_controls.release_all()
	for a in ["move_left", "move_right", "move_forward", "move_back", "jump", "attack", "roll", "skill"]:
		Input.action_release(a)
	if _player and is_instance_valid(_player):
		_player._move = Vector3.ZERO


func _refresh_powers() -> void:
	var list := Powers.actives(GameState.data.powers)
	var keys := ["O", "P"]
	for i in _power_buttons.size():
		var b := _power_buttons[i]
		b.visible = i < list.size() and not _cinematic
		if i < list.size():
			var def: Dictionary = Powers.DEFS[list[i]]
			b.set_meta("power", list[i])
			b.text = TranslationServer.translate("%s (%s)") % [TranslationServer.translate(def["short"]), keys[i]] if not touch else TranslationServer.translate(String(def["short"]))


func _process(_delta: float) -> void:
	if SaveGame.last_error != OK:
		SaveGame.last_error = OK
		show_toast("Oyun kaydedilemedi. Telefonda yer var mı?", "drop")
	# power buttons: dim while cooling down or short of energy
	if _player and is_instance_valid(_player):
		for b in _power_buttons:
			if b.visible and b.has_meta("power"):
				var id: String = b.get_meta("power")
				var wait: float = _player.power_wait(id)
				var mp_ok := GameState.data.mp >= int(Powers.DEFS[id]["mp"])
				b.modulate.a = 1.0 if wait <= 0.0 and mp_ok else 0.45
	_update_anger()
	_maybe_level_up()


func _update_anger() -> void:
	var c: BreathCalm = _player.calm if _player and is_instance_valid(_player) else null
	_anger.visible = c != null and (c.anger > 0.01 or c.is_angry())
	if _anger.visible:
		_anger.set_values(c.anger * 100.0, 100.0, TranslationServer.translate("Kızgın!") if c.is_angry() else TranslationServer.translate("Öfke"))


## A waiting level-up opens the power cards once nothing else is on screen.
func _maybe_level_up() -> void:
	var d := GameState.data
	if d.power_picks <= 0 or _level_panel or _pause_panel or _cinematic or _dialog.is_open() \
			or GameState.in_dialogue or SceneFlow.busy or get_tree().paused:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s%d%d" % [d.character_id, d.level, d.power_picks])
	var choices := Powers.choices(d.powers, rng)
	if DevTools.demo != "" and DevTools.demo != "levelup":
		# automated checks keep running: take the first card
		Powers.pick(d, choices[0]["id"])
		return
	_release_touch()
	get_tree().paused = true
	_level_panel = LevelUpPanel.new(choices)
	_root.add_child(_level_panel)
	_level_panel.picked.connect(func(id: String) -> void:
		Powers.pick(d, id)
		_level_panel.queue_free()
		_level_panel = null
		_release_touch()
		get_tree().paused = false
		_refresh_powers()
		_refresh_stats()
		if id != Powers.FALLBACK:
			var def: Dictionary = Powers.DEFS[id]
			var how: String = TranslationServer.translate(" (%s tuşu / düğmesi)") % ["O", "P"][Powers.actives(d.powers).find(id)] if def["kind"] == "active" else ""
			show_toast(TranslationServer.translate("%s: kademe %d%s") % [TranslationServer.translate(def["name"]), Powers.rank(d.powers, id), how], "star"))


## Keep the HUD out of notches and rounded corners (Android/iOS report a real
## safe area; on desktop it's the whole window, so the inset is 0).
func _apply_safe_area() -> void:
	if not OS.has_feature("mobile"):
		return
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var win := Rect2(Vector2(DisplayServer.window_get_position()), Vector2(DisplayServer.window_get_size()))
	var inner := safe.intersection(win)
	if inner.size.x <= 0.0 or win.size.x <= 0.0:
		return
	var to_ui := get_viewport().get_visible_rect().size / win.size
	_root.offset_left = (inner.position.x - win.position.x) * to_ui.x
	_root.offset_top = (inner.position.y - win.position.y) * to_ui.y
	_root.offset_right = -(win.end.x - inner.end.x) * to_ui.x
	_root.offset_bottom = -(win.end.y - inner.end.y) * to_ui.y

extends Node3D
## Opening: "Just A Game Studios" splash, then the title over the evening
## village with a slowly circling camera. Başla / Yeni oyun starts a new game
## in a save slot, Devam et loads the newest save, Kayıtlar picks any slot.

@onready var _cam: Camera3D = $Camera
var _t := 0.0
var _ui: CanvasLayer


func _ready() -> void:
	Pus.set_amount(0.0)
	Audio.scene_changed("title")
	_cam.make_current()
	_ui = CanvasLayer.new()
	add_child(_ui)
	await _splash()
	_build_menu()


func _process(delta: float) -> void:
	_t += delta * 0.06
	_cam.position = Vector3(sin(_t) * 24.0, 11.0, cos(_t) * 24.0)
	_cam.look_at(Vector3(0, 4, -4))


func _splash() -> void:
	if DevTools.demo == "menu":
		return
	var bg := ColorRect.new()
	bg.color = Tokens.color("bg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(bg)
	var l := UiKit.label("Just A Game Studios", "text-title", "ink")
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.modulate.a = 0.0
	bg.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.6)
	tw.tween_interval(1.2)
	tw.tween_property(bg, "modulate:a", 0.0, 0.7)
	await tw.finished
	bg.queue_free()


func _build_menu() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	_ui.add_child(root)
	var title := UiKit.outlined(UiKit.label("Pırıltı Diyarı", "text-hero", "honey"), 16)
	title.add_theme_font_size_override("font_size", 84)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	var series := UiKit.outlined(UiKit.label("Kıvılcım Bekçileri", "text-heading", "panel@light"), 8)
	series.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(series)
	var gap := Control.new()
	gap.custom_minimum_size.y = Tokens.px("space-8")
	root.add_child(gap)
	var has_save := SaveGame.exists()
	var start := UiKit.button("Başla", not has_save)
	start.custom_minimum_size = Vector2(260, 64)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(func() -> void:
		if SaveGame.exists():
			_open_slots("new")
		else:
			_start_in(1))
	if has_save:
		var cont := UiKit.button("Devam et")
		cont.custom_minimum_size = Vector2(260, 64)
		cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cont.pressed.connect(func() -> void: _continue(SaveGame.latest_slot()))
		root.add_child(cont)
		# Season 1 finished in the newest save: Season 2 can begin from here too
		var latest := PlayerData.new()
		var read_ok := SaveGame.read_into(latest, SaveGame.path_for(maxi(SaveGame.latest_slot(), 1)))
		if read_ok and latest.can_start_season2():
			var s2 := UiKit.button("Sezon 2'ye başla")
			s2.name = "Season2"
			s2.custom_minimum_size = Vector2(260, 64)
			s2.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			s2.pressed.connect(func() -> void:
				SaveGame.slot = maxi(SaveGame.latest_slot(), 1)
				latest.recompute_stats(Content.items)
				GameState.data = latest
				SeasonFlow.start_season2())
			root.add_child(s2)
		# Season 2 finished in the newest save: Season 3 can begin from here too
		if read_ok and latest.can_start_season3():
			var s3 := UiKit.button("Sezon 3'e başla")
			s3.name = "Season3"
			s3.custom_minimum_size = Vector2(260, 64)
			s3.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			s3.pressed.connect(func() -> void:
				SaveGame.slot = maxi(SaveGame.latest_slot(), 1)
				latest.recompute_stats(Content.items)
				GameState.data = latest
				SeasonFlow.start_season3())
			root.add_child(s3)
		start.text = "Yeni oyun"
	root.add_child(start)
	if has_save:
		var saves := UiKit.button("Kayıtlar", false)
		saves.custom_minimum_size = Vector2(260, 56)
		saves.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		saves.pressed.connect(func() -> void: _open_slots("load"))
		root.add_child(saves)
		if not ChapterSelect.open_seasons().is_empty():
			var pick := UiKit.button("Bölüm seç", false)
			pick.name = "ChapterSelect"
			pick.custom_minimum_size = Vector2(260, 56)
			pick.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			pick.pressed.connect(_open_chapters)
			root.add_child(pick)
	# sound settings: two small toggles under the menu
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(Tokens.px("space-3")))
	root.add_child(row)
	var mus := UiKit.button("", false)
	var sfx := UiKit.button("", false)
	for b: Button in [mus, sfx]:
		b.custom_minimum_size = Vector2(170, 52)
		row.add_child(b)
	var refresh := func() -> void:
		mus.text = TranslationServer.translate("Müzik: %s") % TranslationServer.translate("Açık" if Audio.music_on else "Kapalı")
		sfx.text = TranslationServer.translate("Sesler: %s") % TranslationServer.translate("Açık" if Audio.sfx_on else "Kapalı")
	refresh.call()
	var lang := UiKit.button("Language: English" if Audio.language == "en" else "Dil: Türkçe", false)
	lang.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	lang.custom_minimum_size = Vector2(220, 52)
	row.add_child(lang)
	lang.pressed.connect(func() -> void:
		Audio.set_language("tr" if Audio.language == "en" else "en")
		_menu.queue_free()
		_build_menu())
	mus.pressed.connect(func() -> void:
		Audio.set_music_on(not Audio.music_on)
		refresh.call())
	sfx.pressed.connect(func() -> void:
		Audio.set_sfx_on(not Audio.sfx_on)
		refresh.call())
	# sound credit (CC BY 4.0): tiny and quiet in the bottom-right corner,
	# there for those who look (smaller than text-caption on purpose)
	var old := _ui.get_node_or_null("Credit")
	if old:
		old.queue_free()
	var credit := UiKit.label("Sesler: Meta Oculus Audio Pack · CC BY 4.0", "text-caption", "panel@light")
	credit.name = "Credit"
	credit.add_theme_font_size_override("font_size", 11)
	credit.modulate.a = 0.55
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	credit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(credit)
	credit.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	credit.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	credit.grow_vertical = Control.GROW_DIRECTION_BEGIN
	credit.offset_right = -Tokens.px("space-2")
	credit.offset_bottom = -Tokens.px("space-1")
	root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 1.0, 0.6)
	_menu = root
	if DevTools.demo.begins_with("chapters") and not _demo_shown:
		_demo_shown = true
		_open_chapters()
	if DevTools.demo in ["slots", "slotsnew"] and not _demo_shown:
		_demo_shown = true
		_open_slots("new" if DevTools.demo == "slotsnew" else "load")


var _menu: Control
var _demo_shown := false


func _open_chapters() -> void:
	var p := ChapterSelect.new()
	p.closed.connect(func() -> void: _menu.visible = true)
	_menu.visible = false
	_ui.add_child(p)


func _open_slots(mode: String) -> void:
	var p := SaveSlotsPanel.new(mode)
	p.chosen.connect(func(s: int) -> void:
		if mode == "new":
			_start_in(s)
		else:
			_continue(s))
	p.closed.connect(func() -> void:
		# rebuild: a deleted save may change Devam et / Kayıtlar
		_menu.queue_free()
		_build_menu())
	_menu.visible = false
	_ui.add_child(p)


## A new adventure in slot `s` (its old save is cleared first).
func _start_in(s: int) -> void:
	SaveGame.slot = maxi(s, 1)
	SaveGame.clear(SaveGame.slot)
	GameState.data = PlayerData.new()
	SceneFlow.go_to("scene1")


func _continue(s: int) -> void:
	SaveGame.slot = maxi(s, 1)
	var d := PlayerData.new()
	if not SaveGame.read_into(d):
		_start_in(SaveGame.slot)
		return
	d.recompute_stats(Content.items)  # derived stats, never drifting
	d.catch_up()  # saves from before mob levels
	GameState.data = d
	SceneFlow.go_to(d.scene_id, false)

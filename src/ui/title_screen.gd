extends Node3D
## Opening: "Just A Game Studios" splash, then the title over the evening
## village with a slowly circling camera. Başla starts a new game, Devam et
## loads the checkpoint save.

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
	start.pressed.connect(_new_game)
	if has_save:
		var cont := UiKit.button("Devam et")
		cont.custom_minimum_size = Vector2(260, 64)
		cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cont.pressed.connect(_continue)
		root.add_child(cont)
		start.text = "Yeni oyun"
	root.add_child(start)
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
		mus.text = "Müzik: " + ("Açık" if Audio.music_on else "Kapalı")
		sfx.text = "Sesler: " + ("Açık" if Audio.sfx_on else "Kapalı")
	refresh.call()
	mus.pressed.connect(func() -> void:
		Audio.set_music_on(not Audio.music_on)
		refresh.call())
	sfx.pressed.connect(func() -> void:
		Audio.set_sfx_on(not Audio.sfx_on)
		refresh.call())
	root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 1.0, 0.6)


func _new_game() -> void:
	GameState.data = PlayerData.new()
	SceneFlow.go_to("scene1")


func _continue() -> void:
	var d := PlayerData.new()
	if not SaveGame.read_into(d):
		_new_game()
		return
	d.catch_up()  # saves from before mob levels
	GameState.data = d
	SceneFlow.go_to(d.scene_id, false)

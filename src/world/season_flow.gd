class_name SeasonFlow
extends RefCounted
## Moving between seasons. Season 2 (Kor Vadisi) opens after Season 1's
## ending (flag "sezon1_bitti"), Season 3 (Titrek Kıyılar) after Season 2's
## ("sezon2_bitti"): from the season summary or the title.


static func start_season2() -> void:
	var d := GameState.data
	d.start_season2(Content.items)
	SaveGame.write(d)
	SceneFlow.go_to("s2_scene1")


static func start_season3() -> void:
	var d := GameState.data
	d.start_season3(Content.items)
	SaveGame.write(d)
	SceneFlow.go_to("s3_scene1")


## Season 3's story packs: Yeni Oyun+ forgets their quests.
const S3_STORY_PACKS := ["s3_prologue", "s3_chapter0", "s3_chapter1", "s3_chapter2", "s3_chapter3", "s3_chapter4", "s3_chapter5"]


## The ids of every quest in Season 3's story packs.
static func s3_story_quests() -> Array:
	var ids := []
	for pack: String in S3_STORY_PACKS:
		var root := "res://content/%s" % pack
		for q: String in Content.read_json("%s/chapter.json" % root).get("quests", []):
			var id := String(Content.read_json("%s/quests/%s.json" % [root, q]).get("id", ""))
			if id != "" and not ids.has(id):
				ids.append(id)
	return ids


## Yeni Oyun+ (after Season 3's ending): level and belongings stay, the
## story starts again at the keeper choice, where Hırıl and Tırıl wait too.
static func start_new_game_plus() -> void:
	var d := GameState.data
	d.start_new_game_plus(Content.items, s3_story_quests())
	SaveGame.write(d)
	SceneFlow.go_to("s3_scene6")


## "Are you sure?" before Yeni Oyun+ (a kid must not reset the story by a
## stray tap). Add it to a CanvasLayer/Control and `await panel.answered`.
static func ng_confirm() -> NgConfirm:
	return NgConfirm.new()


class NgConfirm extends Control:
	signal answered(yes: bool)

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var scrim := ColorRect.new()
		scrim.color = Tokens.color("scrim")
		scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(scrim)
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UiKit.panel_style())
		panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		panel.grow_vertical = Control.GROW_DIRECTION_BOTH
		panel.custom_minimum_size = Vector2(520, 0)
		add_child(panel)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", int(Tokens.px("space-3")))
		panel.add_child(v)
		v.add_child(UiKit.label("Yeni Oyun+", "text-title", "ink"))
		var body := UiKit.label("Seviyen ve eşyaların kalır, hikâye baştan başlar. Hırıl ve Tırıl da seçilebilir!", "text-body", "ink")
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(480, 0)
		v.add_child(body)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", int(Tokens.px("space-3")))
		v.add_child(row)
		var no := UiKit.button("Vazgeç", false)
		no.name = "No"
		no.custom_minimum_size = Vector2(180, 60)
		no.pressed.connect(func() -> void: _answer(false))
		row.add_child(no)
		var yes := UiKit.button("Evet")
		yes.name = "Yes"
		yes.custom_minimum_size = Vector2(180, 60)
		yes.pressed.connect(func() -> void: _answer(true))
		row.add_child(yes)

	func _answer(yes: bool) -> void:
		answered.emit(yes)
		queue_free()

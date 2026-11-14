class_name ChapterSelect
extends Control
## "Bölüm seç" on the title: once a season is finished in any save, every
## scene of it can be played again from its start, with the progress a player
## has there (DevTools.preset) and a keeper of your choice. It plays in the
## practice slot (SaveGame.PRACTICE), so the real saves never change.

signal closed

const S1 := ["scene1", "scene2", "scene3", "scene4", "scene5", "scene6", "chapter0", "chapter1",
	"chapter2", "chapter3", "chapter4", "chapter5", "final"]
const S2 := ["s2_scene1", "s2_scene2", "s2_scene3", "s2_scene4", "s2_scene5", "s2_scene6",
	"s2_chapter0", "s2_chapter1", "s2_chapter2", "s2_chapter3", "s2_chapter4", "s2_chapter5", "s2_final"]
const S3 := ["s3_scene1", "s3_scene2", "s3_scene3", "s3_scene4", "s3_scene5", "s3_scene6",
	"s3_chapter0", "s3_chapter1", "s3_chapter2", "s3_chapter3", "s3_chapter4", "s3_chapter5", "s3_final"]
const KEEPERS := ["pati", "bado", "citir", "lumi", "tipis_panda", "tosbi"]

var _keeper := "pati"
var _keeper_buttons := {}


## Which seasons can be chosen (finished in some save).
static func open_seasons() -> Array:
	if DevTools.demo.begins_with("chapters"):
		return [1, 2, 3]
	var out := []
	if SaveGame.any_has_flag("sezon1_bitti"):
		out.append(1)
	if SaveGame.any_has_flag("sezon2_bitti"):
		out.append(2)
	if SaveGame.any_has_flag("sezon3_bitti"):
		out.append(3)
	return out


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var latest := SaveGame.summary(maxi(SaveGame.latest_slot(), 1))
	var d := SaveGame.load_dict(SaveGame.path_for(maxi(SaveGame.latest_slot(), 1)))
	var cid := String(d.get("character_id", "pati"))
	_keeper = cid if cid in KEEPERS else "pati"
	var scrim := ColorRect.new()
	scrim.color = Tokens.color("scrim")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style())
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := Tokens.px("space-6")
	panel.offset_left = m
	panel.offset_right = -m
	panel.offset_top = m
	panel.offset_bottom = -m
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	panel.add_child(v)
	var title := UiKit.label("Bölüm seç", "text-title", "ink")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var note := UiKit.label("Deneme kaydında oynanır: asıl kayıtların değişmez.", "text-caption", "ink-muted")
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(note)
	# keeper choice
	var krow := HBoxContainer.new()
	krow.alignment = BoxContainer.ALIGNMENT_CENTER
	krow.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	v.add_child(krow)
	krow.add_child(UiKit.label("Bekçi:", "text-label", "ink"))
	for k: String in KEEPERS:
		var b := UiKit.button(String(Content.keeper(k).get("name", k)), false)
		b.custom_minimum_size = Vector2(110, 48)
		b.toggle_mode = true
		b.button_pressed = k == _keeper
		b.pressed.connect(func() -> void: _pick_keeper(k))
		krow.add_child(b)
		_keeper_buttons[k] = b
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", int(Tokens.px("space-2")))
	scroll.add_child(list)
	var seasons := open_seasons()
	for season: int in seasons:
		list.add_child(UiKit.label("Sezon %d" % season, "text-heading", "ink"))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", int(Tokens.px("space-2")))
		grid.add_theme_constant_override("v_separation", int(Tokens.px("space-2")))
		list.add_child(grid)
		for scene: String in ([S1, S2, S3][season - 1]):
			var card: Array = SceneFlow.CARDS.get(scene, ["", scene])
			var b := UiKit.button("%s\n%s" % [TranslationServer.translate(String(card[0])), TranslationServer.translate(String(card[1]))], false)
			b.name = "Pick_" + scene
			b.custom_minimum_size = Vector2(340, 64)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func() -> void: play(scene))
			grid.add_child(b)
	if seasons.is_empty():
		list.add_child(UiKit.label("Bir sezonu bitirince bölümleri buradan yeniden oynayabilirsin.", "text-body", "ink-muted"))
	var back := UiKit.button("Geri", false)
	back.custom_minimum_size = Vector2(200, 56)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	v.add_child(back)
	var first_pick := find_child("Pick_*", true, false) as Control
	UiKit.menu(self, first_pick, back)
	if DevTools.demo.begins_with("chapters_"):
		# headless check: play one chapter from the list
		await get_tree().create_timer(0.5).timeout
		_pick_keeper("tipis_panda")
		(find_child("Pick_" + DevTools.demo.substr(9), true, false) as Button).pressed.emit()
		DevTools.report_next_scene("chapter_select")


func _pick_keeper(k: String) -> void:
	_keeper = k
	for id: String in _keeper_buttons:
		(_keeper_buttons[id] as Button).button_pressed = id == k


## Start `scene` with the progress of everything before it.
func play(scene: String) -> void:
	SaveGame.slot = SaveGame.PRACTICE
	SaveGame.clear(SaveGame.PRACTICE)
	var d := PlayerData.new()
	# Tıpış joins only in Season 2; Season 1 picks fall back to Pati there
	DevTools.preset_keeper = _keeper
	DevTools.preset(d, scene)
	DevTools.preset_keeper = ""
	d.recompute_stats(Content.items)
	GameState.data = d
	SceneFlow.go_to(scene)

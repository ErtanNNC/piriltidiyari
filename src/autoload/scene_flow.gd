extends CanvasLayer
## Moves between the game's scenes with a fade and a title card, and saves a
## checkpoint at the start of each story scene.

signal scene_started(scene_id: String)

const SCENES := {
	"title": "res://scenes/title.tscn",
	"scene1": "res://scenes/prologue/scene1_yildiz_senligi.tscn",
	"scene2": "res://scenes/prologue/scene2_gri_ruzgar.tscn",
	"scene3": "res://scenes/prologue/scene3_kuleye_kosu.tscn",
	"scene4": "res://scenes/prologue/scene4_pus_baykusu.tscn",
	"scene5": "res://scenes/prologue/scene5_fistigin_secimi.tscn",
	"scene6": "res://scenes/prologue/scene6_fenerin_secimi.tscn",
	"chapter0": "res://scenes/chapter0/koy_ve_cayir.tscn",
	"chapter1": "res://scenes/chapter1/fisilti_ormani.tscn",
	"chapter2": "res://scenes/chapter2/sekerleme_magaralari.tscn",
	"chapter3": "res://scenes/chapter3/bulut_limani.tscn",
	"chapter4": "res://scenes/chapter4/uyku_dagi.tscn",
	"chapter5": "res://scenes/chapter5/pus_kalesi.tscn",
	"final": "res://scenes/chapter5/final.tscn",
}

## Which content pack (content/<id>/) a scene reads its story from.
const SCENE_CHAPTER := {"chapter0": "chapter0", "chapter1": "chapter1", "chapter2": "chapter2", "chapter3": "chapter3", "chapter4": "chapter4", "chapter5": "chapter5", "final": "chapter5"}

## [small line, big title] shown when a scene starts.
const CARDS := {
	"scene1": ["Prolog · Sahne 1", "Yıldız Şenliği"],
	"scene2": ["Prolog · Sahne 2", "Gri Rüzgâr"],
	"scene3": ["Prolog · Sahne 3", "Kule'ye Koşu"],
	"scene4": ["Prolog · Sahne 4", "Pus Baykuşu"],
	"scene5": ["Prolog · Sahne 5", "Fıstık'ın Seçimi"],
	"scene6": ["Prolog · Sahne 6", "Fener'in Seçimi"],
	"chapter0": ["Bölüm 0", "Gökkuşağı Köyü"],
	"chapter1": ["Bölüm 1", "Fısıltı Ormanı"],
	"chapter2": ["Bölüm 2", "Şekerleme Mağaraları"],
	"chapter3": ["Bölüm 3", "Bulut Limanı"],
	"chapter4": ["Bölüm 4", "Uyku Dağı"],
	"chapter5": ["Bölüm 5", "Pus Kalesi"],
	"final": ["Kapanış", "Altı Renkli Fener"],
}

var current := ""
var busy := false
var _fade: ColorRect
var _card: VBoxContainer
var _small: Label
var _big: Label


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color("#1b1a2e")
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)
	_card = VBoxContainer.new()
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.modulate.a = 0.0
	add_child(_card)
	_small = UiKit.outlined(UiKit.label("", "text-heading", "honey"), 8)
	_big = UiKit.outlined(UiKit.label("", "text-hero", "panel@light"), 14)
	for l in [_small, _big]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_card.add_child(l)
	var path := get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	for id: String in SCENES:
		if SCENES[id] == path:
			current = id


func go_to(scene_id: String, save := true) -> void:
	if busy or not SCENES.has(scene_id):
		return
	busy = true
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.45)
	await tw.finished
	Pus.set_amount(0.0)
	var chapter: String = SCENE_CHAPTER.get(scene_id, "prologue")
	if Content.chapter.get("id", "") != chapter:
		Content.load_chapter(chapter)
	# Gece (dark) theme for the caves and other night chapters
	# the ending is a sunny morning in the village, whatever chapter it belongs to
	Tokens.set_theme("light" if scene_id in ["title", "final"] else String(Content.chapter.get("theme", "light")))
	get_tree().change_scene_to_file(SCENES[scene_id])
	current = scene_id
	if save and scene_id != "title":
		GameState.data.scene_id = scene_id
		SaveGame.write(GameState.data)
	await get_tree().process_frame
	await get_tree().process_frame
	scene_started.emit(scene_id)
	if CARDS.has(scene_id):
		_small.text = CARDS[scene_id][0]
		_big.text = CARDS[scene_id][1]
		var c := create_tween()
		c.tween_property(_card, "modulate:a", 1.0, 0.3)
		c.tween_interval(1.6)
		c.tween_property(_fade, "modulate:a", 0.0, 0.6)
		c.parallel().tween_property(_card, "modulate:a", 0.0, 0.6)
		await c.finished
	else:
		var f := create_tween()
		f.tween_property(_fade, "modulate:a", 0.0, 0.45)
		await f.finished
	busy = false


## Restart the current scene from its checkpoint (used after "uykuya daldın").
func reload_checkpoint() -> void:
	SaveGame.read_into(GameState.data)
	go_to(current, false)

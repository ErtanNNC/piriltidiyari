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
	# Season 2 · Kor Vadisi
	"s2_scene1": "res://scenes/season2/s2_scene1_dogum_gunu.tscn",
	"s2_scene2": "res://scenes/season2/s2_scene2_kirmizi_ruzgar.tscn",
	"s2_scene3": "res://scenes/season2/s2_scene3_yankilar.tscn",
	"s2_scene4": "res://scenes/season2/s2_scene4_gurledek.tscn",
	"s2_scene5": "res://scenes/season2/s2_scene5_miril_secimi.tscn",
	"s2_scene6": "res://scenes/season2/s2_scene6_kulak_bekcileri.tscn",
	"s2_chapter0": "res://scenes/season2/s2_chapter0_kaplica_koyu.tscn",
	"s2_chapter1": "res://scenes/season2/s2_chapter1_kizil_yaprak.tscn",
	"s2_chapter2": "res://scenes/season2/s2_chapter2_fokurdayan_gol.tscn",
	"s2_chapter3": "res://scenes/season2/s2_chapter3_patpat_tarlalari.tscn",
	"s2_chapter4": "res://scenes/season2/s2_chapter4_gumbur_kanyonu.tscn",
	"s2_chapter5": "res://scenes/season2/s2_chapter5_kukreyen_dag.tscn",
	"s2_final": "res://scenes/season2/s2_final.tscn",
	# inside a village house (which one: SceneFlow.house_id)
	"house": "res://scenes/chapter0/ev.tscn",
	# dev only: all characters side by side (tools/screenshot.sh --scene=preview)
	"preview": "res://scenes/dev/model_preview.tscn",
}

## Which content pack (content/<id>/) a scene reads its story from.
const SCENE_CHAPTER := {"chapter0": "chapter0", "chapter1": "chapter1", "chapter2": "chapter2", "chapter3": "chapter3", "chapter4": "chapter4", "chapter5": "chapter5", "final": "chapter5", "house": "chapter0",
	"s2_scene1": "s2_prologue", "s2_scene2": "s2_prologue", "s2_scene3": "s2_prologue",
	"s2_scene4": "s2_prologue", "s2_scene5": "s2_prologue", "s2_scene6": "s2_prologue",
	"s2_chapter0": "s2_chapter0", "s2_chapter1": "s2_chapter1", "s2_chapter2": "s2_chapter2", "s2_chapter3": "s2_chapter3", "s2_chapter4": "s2_chapter4", "s2_chapter5": "s2_chapter5", "s2_final": "s2_chapter5"}

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
	"s2_scene1": ["Sezon 2 · Prolog · Sahne 1", "Mırıl'ın İlk Doğum Günü"],
	"s2_scene2": ["Sezon 2 · Prolog · Sahne 2", "Kırmızı Rüzgâr"],
	"s2_scene3": ["Sezon 2 · Prolog · Sahne 3", "Yankıların Peşinde"],
	"s2_scene4": ["Sezon 2 · Prolog · Sahne 4", "Gürledek"],
	"s2_scene5": ["Sezon 2 · Prolog · Sahne 5", "Mırıl'ın Seçimi"],
	"s2_scene6": ["Sezon 2 · Prolog · Sahne 6", "Kulak Bekçileri"],
	"s2_chapter0": ["Sezon 2 · Bölüm 0", "Buharlı Kaplıca Köyü"],
	"s2_chapter1": ["Sezon 2 · Bölüm 1", "Kızıl Yaprak Ormanı"],
	"s2_chapter2": ["Sezon 2 · Bölüm 2", "Fokurdayan Göl"],
	"s2_chapter3": ["Sezon 2 · Bölüm 3", "Patpat Tarlaları"],
	"s2_chapter4": ["Sezon 2 · Bölüm 4", "Gümbür Kanyonu"],
	"s2_chapter5": ["Sezon 2 · Bölüm 5", "Kükreyen Dağ"],
	"s2_final": ["Sezon 2 · Kapanış", "Gökkuşağı Şenliği"],
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


## Which village house "house" shows ("dukkan" or "bekci"), and where the
## keeper stands when they come back out (Vector3.INF = the scene's start).
var house_id := "dukkan"
var return_point := Vector3.INF
## The scene a village house was entered from (walking out goes back there).
var house_from := "chapter0"


## A region exit: ask first ("… yoluna çıkalım mı?") so nobody leaves by
## stepping on the edge by accident. "Burada kal" just closes the question.
var _asking := false


func ask_go(scene_id: String) -> void:
	if busy or _asking or GameState.in_dialogue or not SCENES.has(scene_id):
		return
	var hud := get_tree().get_first_node_in_group("hud") as Hud
	if hud == null:
		go_to(scene_id)
		return
	_asking = true
	var place: String = CARDS.get(scene_id, ["", scene_id])[1]
	var title := TranslationServer.translate("%s yoluna çıkalım mı?") % TranslationServer.translate(place)
	var pick: String = await hud.ask(title, [{"id": "go", "label": "Evet, gidelim"}, {"id": "stay", "label": "Burada kal"}])
	_asking = false
	if pick == "go":
		go_to(scene_id)


## Let go of every held action (a touch stick or key held while the scene
## changes would otherwise keep the keeper walking in the next scene).
func release_inputs() -> void:
	for a in InputMap.get_actions():
		if not String(a).begins_with("ui_"):
			Input.action_release(a)


func go_to(scene_id: String, save := true, card := true) -> void:
	if busy or not SCENES.has(scene_id):
		return
	busy = true
	release_inputs()
	Audio.scene_changed(scene_id)
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.45)
	await tw.finished
	Pus.set_amount(0.0)
	Pus.set_color(Pus.GREY)
	var chapter: String = SCENE_CHAPTER.get(scene_id, "prologue")
	if Content.chapter.get("id", "") != chapter:
		Content.load_chapter(chapter)
	# Gece (dark) theme for the caves and other night chapters
	# the ending is a sunny morning in the village, whatever chapter it belongs to
	Tokens.set_theme("light" if scene_id in ["title", "final", "s2_final", "preview"] else String(Content.chapter.get("theme", "light")))
	get_tree().change_scene_to_file(SCENES[scene_id])
	current = scene_id
	if save and scene_id != "title":
		GameState.data.scene_id = scene_id
		SaveGame.write(GameState.data)
	await get_tree().process_frame
	await get_tree().process_frame
	release_inputs()
	scene_started.emit(scene_id)
	if card and CARDS.has(scene_id):
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

extends Node3D
## Gökkuşağı Şenliği (end of Season 2). Back in the village: the five Kor fly
## up to the Fener, which now burns in seven colors (the seventh is red: anger
## is part of the land too, as warmth). Hırıl wants to drum but holds back;
## nobody says "Sus!", Fıstık hands him the drum, and the whole village
## dances. The keeper's own closing beat, then far over the sea a pale blue,
## trembling mist and Hırıl's drum beating fast by itself (next season's
## seed). Then the season summary (`Season2End`).
## Beats: content/s2_chapter5/cutscenes/senlik.json.

const TOP := Vector3(0, 13.6, -17)
const KOR := [Color("#ff8a3a"), Color("#ff7f8f"), Color("#f2b33d"), Color("#c87a4a"), Color("#e8463a")]
const RAINBOW := ["hp", "spark-yellow", "honey", "spark-green", "sky", "spark-blue", "spark-purple"]
## The other keepers and friends round the square: [kind, position, turn].
const CROWD := [["turtle", Vector3(4.4, 0, -8.4), -30], ["mole", Vector3(-6.4, 0, -6.6), 40],
	["spider", Vector3(-5.4, 0, -4.4), 50], ["gull_captain", Vector3(6.4, 0, -5.4), -50],
	["gumbur", Vector3(5.2, 0, -3.6), -60], ["bunny", Vector3(-4.2, 0, -2.6), 50],
	["duckling", Vector3(3.6, 0, -2.4), -50], ["owl_teacher", Vector3(7.0, 0, -8.0), -40]]

@onready var _hud: Hud = $Hud
@onready var _cam: Camera3D = $Camera
var _keeper: Node3D
var _miril: Node3D
var _hiril: Node3D
var _fistik: Node3D
var _drum: Node3D
var _dancers: Array[Node3D] = []


func _ready() -> void:
	Pus.set_amount(0.0)
	_cam.make_current()
	var d := GameState.data
	_keeper = KeeperModels.build(d.character_id, d.character_look)
	add_child(_keeper)
	_keeper.position = Vector3(2.0, 0, -6.0)
	_keeper.rotation.y = -0.3
	_dancers.append(_keeper)
	_fistik = FistikModel.build()
	add_child(_fistik)
	_fistik.position = Vector3(-2.6, 0, -7.2)
	_fistik.rotation.y = 0.4
	_miril = MirilModel.star_child()
	add_child(_miril)
	_miril.position = Vector3(-1.1, 0, -5.8)
	_miril.rotation.y = 0.2
	_hiril = HirilModel.build(true)
	add_child(_hiril)
	_hiril.position = Vector3(0.4, 0, -7.6)
	_hiril.scale = Vector3.ONE * 0.9
	_dancers.append(_miril)
	# the keepers who didn't play this time, and Tıpış
	var others := ["pati", "bado", "citir", "lumi", "tipis_panda"]
	others.erase(d.character_id)
	for i in others.size():
		var k := KeeperModels.build(others[i])
		add_child(k)
		k.position = Vector3(-5.2 + i * 2.6, 0, -10.2 + (i % 2) * 0.6)
		k.rotation.y = 0.0
		_dancers.append(k)
	# Minnoş by Bado's side
	var minnos := KeeperModels.build("bado")
	minnos.scale = Vector3.ONE * 0.55
	add_child(minnos)
	minnos.position = Vector3(-3.6, 0, -8.6)
	minnos.rotation.y = 0.3
	_dancers.append(minnos)
	for f: Array in CROWD:
		var m := NpcModels.build(f[0])
		add_child(m)
		m.position = f[1]
		m.rotation_degrees.y = f[2]
		_dancers.append(m)
	var crystal := get_node_or_null("Village/FenerKulesi/BuyukKivilcim")
	if crystal:
		crystal.visible = false
	await get_tree().create_timer(1.9, false).timeout
	if DevTools.demo != "" and DisplayServer.get_name() == "headless":
		DevTools.auto_dialogue = true
	var cs := CutscenePlayer.new()
	cs.scene = self
	cs.camera = _cam
	cs.hud = _hud
	add_child(cs)
	cs.play("senlik")


## The five Kor fly from the keeper up to the Fener.
func kors_to_tower() -> void:
	for i in KOR.size():
		var orb := Toon.part(self, "sphere", Vector3(0.7, 0.9, 0.7), KOR[i], _keeper.global_position + Vector3(0, 1.2, 0), Vector3.ZERO, 1.6, 0.03)
		var tw := orb.create_tween()
		tw.tween_interval(i * 0.25)
		tw.tween_property(orb, "global_position", TOP, 1.6).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(orb.queue_free)
	Audio.play("memory")


## Seven colors now: the red one is the seventh.
func tower_rainbow() -> void:
	var gem := Toon.part(self, "sphere", Vector3(1.6, 2.2, 1.6), "spark-white", TOP, Vector3.ZERO, 2.0, 0.05)
	gem.name = "Gem"
	var l := OmniLight3D.new()
	l.omni_range = 22.0
	l.light_energy = 2.0
	gem.add_child(l)
	var tw := gem.create_tween().set_loops()
	for c: String in RAINBOW:
		tw.tween_callback(func() -> void:
			gem.material_override = Toon.material(c, 0.05, 2.0, 0.0)
			l.light_color = Tokens.color(c))
		tw.tween_interval(0.45)
	for i in RAINBOW.size():
		Effects.ring(self, TOP, 6.0 + i, Tokens.color(RAINBOW[i]), 0.6 + i * 0.1)
	# a rainbow arc over the village
	for i in RAINBOW.size():
		var arc := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 26.0 + i * 0.9
		tm.outer_radius = 26.8 + i * 0.9
		arc.mesh = tm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(Tokens.color(RAINBOW[RAINBOW.size() - 1 - i]), 0.55)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		arc.material_override = m
		arc.rotation_degrees = Vector3(90, 0, 0)
		arc.position = Vector3(0, -4, -40)
		arc.scale = Vector3.ZERO
		add_child(arc)
		var t2 := arc.create_tween()
		t2.tween_interval(i * 0.12)
		t2.tween_property(arc, "scale", Vector3.ONE, 0.8).set_trans(Tween.TRANS_SINE)
	Audio.play("fanfare")


## Fıstık hands Hırıl a drum (nobody says "Sus!").
func drum_offer() -> void:
	_drum = Node3D.new()
	_drum.name = "Drum"
	add_child(_drum)
	_drum.position = _fistik.global_position + Vector3(0.6, 0.9, 0.4)
	Toon.part(_drum, "cylinder", Vector3(0.9, 0.6, 0.9), Color("#c87a4a"), Vector3.ZERO, Vector3(90, 0, 0))
	Toon.part(_drum, "cylinder", Vector3(0.84, 0.62, 0.84), Color("#fff4dc"), Vector3(0, 0, 0.01), Vector3(90, 0, 0), 0.0, 0.0)
	var tw := _drum.create_tween()
	tw.tween_property(_drum, "global_position", _hiril.global_position + Vector3(0, 0.9, 0.9), 1.0).set_trans(Tween.TRANS_SINE)
	Effects.sparkle(self, _hiril.global_position + Vector3.UP, Color("#ffd9a8"), 12)


## Hırıl drums, Mırıl shines, everybody hops to the beat.
func dance() -> void:
	if _drum:
		var beat := _drum.create_tween().set_loops()
		beat.tween_property(_drum, "scale", Vector3(1.15, 1.15, 0.9), 0.08)
		beat.tween_property(_drum, "scale", Vector3.ONE, 0.32)
	for i in _dancers.size():
		var m := _dancers[i]
		if not is_instance_valid(m):
			continue
		var tw := m.create_tween().set_loops()
		tw.tween_interval((i % 4) * 0.1)
		tw.tween_property(m, "position:y", 0.35, 0.2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(m, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
		tw.tween_interval(0.4 - (i % 4) * 0.1)
	var shine := _miril.create_tween().set_loops()
	shine.tween_callback(func() -> void:
		Effects.sparkle(self, _miril.global_position + Vector3.UP * 1.4, Tokens.color("spark-white"), 6))
	shine.tween_interval(0.8)
	Audio.play("fanfare")


func keeper_line() -> void:
	var id := GameState.data.character_id
	if Content.barks.has("s2f_" + id):
		GameState.bark("s2f_" + id)


## Over the sea: a pale blue, trembling mist (next season's feeling).
func blue_tremble() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(Tokens.color("sky"), 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 12:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 3.0
		sm.height = 3.6
		mi.mesh = sm
		mi.material_override = mat
		add_child(mi)
		var at := Vector3(-40 + randf_range(-14, 14), randf_range(2, 9), -52 + randf_range(-6, 6))
		mi.position = at
		mi.scale = Vector3.ZERO
		var tw := mi.create_tween()
		tw.tween_interval(randf() * 1.2)
		tw.tween_property(mi, "scale", Vector3.ONE * randf_range(0.8, 1.4), 1.2)
		var shake := mi.create_tween().set_loops()
		shake.tween_property(mi, "position:x", at.x + 0.4, 0.07)
		shake.tween_property(mi, "position:x", at.x - 0.4, 0.07)
	# Hırıl's drum beats fast by itself
	if _drum:
		var fast := _drum.create_tween().set_loops()
		fast.tween_property(_drum, "rotation:z", 0.08, 0.05)
		fast.tween_property(_drum, "rotation:z", -0.08, 0.05)


func season_end() -> void:
	var d := GameState.data
	d.set_flag("sezon2_senlik")
	d.scene_id = "s2_chapter0"
	SaveGame.write(d)
	var panel := Season2End.new()
	_hud.add_child(panel)
	if DevTools.demo == "endclick":
		_click_test(panel)
	elif DevTools.demo != "" and DisplayServer.get_name() == "headless":
		print("S2FINAL senlik=%s scene_id=%s keeper=%s" % [d.has_flag("sezon2_senlik"), d.scene_id, d.character_id])
		get_tree().quit()
		return
	var to: String = await panel.chosen
	if to == "s3":
		SeasonFlow.start_season3()
		return
	SceneFlow.go_to(to, to != "title")


## Test: press "Ana menü" on the summary with a real click (and a touch).
func _click_test(panel: Control) -> void:
	# a level-up waiting at the end of the season (Hırıl's reward) used to
	# open its cards behind this summary and pause the game under it
	GameState.data.power_picks += 1
	await get_tree().create_timer(1.5, false).timeout
	print("S2END paused=%s level_panel=%s" % [get_tree().paused, _hud._level_panel != null])
	var target: Button = null
	for b in panel.find_children("*", "Button", true, false):
		if (b as Button).text == "Ana menü":
			target = b
	DevTools.report_next_scene("s2end_next")
	if OS.get_cmdline_user_args().has("--emit"):
		target.pressed.emit()
		return
	var at := target.get_global_rect().get_center()
	var hit := get_viewport().gui_get_hovered_control()
	print("S2END vp=%s panel=%s btn=%s" % [get_viewport().get_visible_rect().size, (panel.get_child(1) as Control).get_global_rect(), target.get_global_rect()])
	var tops := []
	for c in _hud.get_children():
		if c is Control and (c as Control).visible and (c as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE and (c as Control).get_global_rect().has_point(at):
			tops.append(c.name)
	print("S2END hud controls under point (later = on top): %s, last child=%s" % [tops, _hud.get_child(_hud.get_child_count() - 1).name])
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = at
	down.global_position = at
	down.pressed = true
	Input.parse_input_event(down)
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	await get_tree().process_frame
	Input.parse_input_event(up)
	await get_tree().create_timer(0.3, false).timeout
	print("S2END at=%s paused=%s hovered=%s scene=%s busy=%s" % [at, get_tree().paused, hit, SceneFlow.current, SceneFlow.busy])
	await get_tree().create_timer(2.5, false).timeout
	print("S2END_DONE scene=%s" % SceneFlow.current)
	get_tree().quit()

extends Node
## Command-line helpers for automated screenshots, used by tools/screenshot.sh:
##   -- --shot=out.png [--frames=60] [--scene=scene3] [--demo=talk|fight|...]
## --scene jumps to a story scene with the progress of the scenes before it.
## Never active in a normal run.

const ORDER := ["scene1", "scene2", "scene3", "scene4", "scene5", "scene6", "chapter0", "chapter1", "chapter2", "chapter3", "chapter4", "chapter5", "final", "s2_scene1", "s2_scene2", "s2_scene3", "s2_scene4", "s2_scene5", "s2_scene6", "s2_chapter0", "s2_chapter1", "s2_chapter2", "s2_chapter3", "s2_chapter4", "s2_chapter5", "s2_final"]

var _shot_path := ""
var _frames := 60
var demo := ""
var _shot_at := -1.0
## --auto: dialogue advances by itself (for cutscene screenshots and tests)
var auto_dialogue := false


func _ready() -> void:
	var scene := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.get_slice("=", 1)
		elif arg.begins_with("--frames="):
			_frames = int(arg.get_slice("=", 1))
		elif arg.begins_with("--demo="):
			demo = arg.get_slice("=", 1)
		elif arg.begins_with("--at="):
			_shot_at = float(arg.get_slice("=", 1))
		elif arg == "--auto":
			auto_dialogue = true
		elif arg.begins_with("--scene="):
			scene = arg.get_slice("=", 1)
		elif arg == "--probe":  # prints an ASCII height map (tools/probe_map.gd)
			add_child(load("res://tools/probe_map.gd").new())
	if scene != "":
		_jump.call_deferred(scene)
	if _shot_path != "":
		_take_shot.call_deferred()


func _jump(scene: String) -> void:
	# a village house: progress as after Bölüm 0, `--house=dukkan|bekci`
	preset(GameState.data, "chapter1" if scene == "house" else scene)
	if demo == "levelup":
		GameState.data.power_picks += 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--house="):
			SceneFlow.house_id = arg.get_slice("=", 1)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--flag="):
			GameState.data.set_flag(arg.get_slice("=", 1))
		elif arg.begins_with("--pus="):
			# screenshot helper: override the Pus once the scene has set its own
			var v := float(arg.get_slice("=", 1))
			get_tree().create_timer(1.0).timeout.connect(func() -> void: Pus.set_amount(v))
		elif arg.begins_with("--near="):
			# screenshot helper: put the keeper 3 m in front of a named node
			var target := arg.get_slice("=", 1)
			get_tree().create_timer(1.2).timeout.connect(func() -> void: _put_near(target))
	SceneFlow.go_to(scene, false)


func _put_near(node_name: String) -> void:
	var root := get_tree().current_scene
	var n := root.find_child(node_name, true, false) as Node3D if root else null
	var p := root.get_node_or_null("Player") as Node3D if root else null
	if n and p:
		p.global_position = n.global_position + Vector3(0, 0.5, 3.0)


## The level a keeper usually has on reaching each region.
const LEVEL_AT := {"chapter1": 5, "chapter2": 10, "chapter3": 15, "chapter4": 20, "chapter5": 25, "final": 28}


## Gives `data` the progress a player has when `scene` starts.
static func preset(data: PlayerData, scene: String) -> void:
	_preset_story(data, scene)
	# reach the region's level and take the power cards along the way
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	while data.level < int(LEVEL_AT.get(scene, 0)):
		data.add_xp(Progression.xp_to_next(data.level) - data.xp)
	while data.power_picks > 0:
		Powers.pick(data, Powers.choices(data.powers, rng)[0]["id"])


static func _preset_story(data: PlayerData, scene: String) -> void:
	var idx := ORDER.find(scene)
	if idx >= 1:
		_finish(data, "kayip_fenerler")
		data.set_flag("sahne1_bitti")
	if idx >= 2:
		_finish(data, "gri_ruzgar")
		data.add_item("bal_surubu", 2)
		data.set_flag("sahne2_bitti")
	if idx >= 3:
		if data.level < 2:
			data.add_xp(Progression.xp_to_next(1))
		data.unlock_skill("dikenli_donus")
		data.set_flag("sahne3_bitti")
	if idx >= 4:
		data.set_flag("sahne4_bitti")
	if idx >= 5:
		data.set_flag("sahne5_bitti")
	if idx >= 6:
		var content: Node = Engine.get_main_loop().root.get_node_or_null("Content")
		if content:
			var k := "pati"
			for arg in OS.get_cmdline_user_args():
				if arg.begins_with("--keeper="):
					k = arg.get_slice("=", 1)
			if not content.keepers.has(k):
				k = "pati"  # a Season 2 keeper (Tıpış) joins only in Season 2
			data.choose_keeper(k, content.keepers[k]["stats"], {}, content.keepers[k]["name"])
		data.set_flag("prolog_bitti")
	if idx >= 7:
		data.add_xp(Progression.xp_to_next(1) + Progression.xp_to_next(2))
		data.add_item("bal_surubu", 3)
		data.set_flag("bolum0_bitti")
	if idx >= 8:
		while data.level < 5:
			data.add_xp(Progression.xp_to_next(data.level))
		data.add_spark("green")
		data.add_piril(150)
		data.set_flag("bolum1_bitti")
	if idx >= 9:
		while data.level < 9:
			data.add_xp(Progression.xp_to_next(data.level))
		data.add_spark("blue")
		data.add_piril(200)
		data.set_flag("bolum2_bitti")
	if idx >= 10:
		while data.level < 14:
			data.add_xp(Progression.xp_to_next(data.level))
		data.add_spark("yellow")
		data.add_piril(200)
		data.set_flag("bolum3_bitti")
	if idx >= 11:
		while data.level < 20:
			data.add_xp(Progression.xp_to_next(data.level))
		data.add_spark("white")
		data.add_item("hikaye_tasi", 8)
		data.set_flag("bolum4_bitti")
	if idx >= 12:
		data.add_spark("purple")
		data.set_flag("bolum5_bitti")
	if idx >= 13:
		# Season 2: the first season is done, its keeper rests, Mırıl plays
		data.set_flag("sezon1_bitti")
		var content: Node = Engine.get_main_loop().root.get_node_or_null("Content")
		data.start_season2(content.items if content else {})
	if idx >= 14:
		data.set_flag("s2_sahne1_bitti")
	if idx >= 15:
		data.set_flag("s2_sahne2_bitti")
		data.add_xp(Progression.xp_to_next(1))
		data.add_item("nane_sekeri", 2)
	if idx >= 16:
		if data.level < 3:
			data.add_xp(Progression.xp_to_next(data.level) - data.xp)
		data.unlock_skill("yildiz_ninnisi")
		data.set_flag("s2_sahne3_bitti")
	if idx >= 17:
		data.set_flag("s2_sahne4_bitti")
	if idx >= 18:
		data.set_flag("s2_sahne5_bitti")
	if idx >= 19:
		# Season 2 keeper chosen (--keeper=..., Tıpış too), fresh at level 1
		var content: Node = Engine.get_main_loop().root.get_node_or_null("Content")
		if content:
			var k := "pati"
			for arg in OS.get_cmdline_user_args():
				if arg.begins_with("--keeper="):
					k = arg.get_slice("=", 1)
			data.powers = {}
			data.power_picks = 0
			data.choose_keeper(k, content.keeper(k)["stats"], {}, content.keeper(k)["name"])
		data.set_flag("s2_prolog_bitti")
	if idx >= 20:
		data.set_flag("s2_can0")
		data.set_flag("s2_bolum0_bitti")
		while data.level < 5:
			data.add_xp(Progression.xp_to_next(data.level) - data.xp)
		while data.power_picks > 0:
			Powers.pick(data, Powers.choices(data.powers, RandomNumberGenerator.new())[0]["id"])
		data.add_item("bal_surubu", 3)
		data.add_item("nane_sekeri", 2)
	if idx >= 22:
		data.set_flag("s2_can2")
		data.set_flag("kor_mercan")
		data.set_flag("s2_bolum2_bitti")
	if idx >= 25:
		for k: String in ["s2_can5", "kor_al", "s2_bolum5_bitti", "sezon2_bitti"]:
			data.set_flag(k)
	if idx >= 24:
		data.set_flag("s2_can4")
		data.set_flag("kor_bakir")
		data.set_flag("s2c4_ani")
		data.set_flag("s2_bolum4_bitti")
	if idx >= 23:
		data.set_flag("s2_can3")
		data.set_flag("kor_kehribar")
		data.set_flag("s2_bolum3_bitti")
		data.set_flag("s2_minnos_kacti")
	if idx >= 21:
		data.set_flag("s2_can1")
		data.set_flag("kor_turuncu")
		data.set_flag("s2_bolum1_bitti")
		while data.level < (25 if idx >= 24 else 20 if idx >= 23 else 15 if idx >= 22 else 10):
			data.add_xp(Progression.xp_to_next(data.level) - data.xp)
		while data.power_picks > 0:
			Powers.pick(data, Powers.choices(data.powers, RandomNumberGenerator.new())[0]["id"])


static func _finish(data: PlayerData, quest_id: String) -> void:
	var content: Node = Engine.get_main_loop().root.get_node_or_null("Content")
	var def: Dictionary = content.quests.get(quest_id, {}) if content else {}
	if def.is_empty() or data.quest_state(quest_id) == "done":
		return
	data.start_quest(def)
	for oid: String in data.quests[quest_id]["objectives"]:
		var p: Array = data.quests[quest_id]["objectives"][oid]
		p[0] = p[1]
	data.complete_quest(def)


func _take_shot() -> void:
	if _shot_at >= 0.0:
		await get_tree().create_timer(_shot_at).timeout
	else:
		for i in _frames:
			await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(_shot_path)
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	print("SHOT ", _shot_path, " scene=", get_tree().current_scene.name if get_tree().current_scene else "-", " flow=", SceneFlow.current,
		" player=", pl.global_position if pl else Vector3.ZERO, " mobs=", get_tree().get_nodes_in_group("mob").size())
	get_tree().quit()

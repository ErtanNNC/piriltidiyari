extends Node
## Command-line helpers for automated screenshots, used by tools/screenshot.sh:
##   -- --shot=out.png [--frames=60] [--scene=scene3] [--demo=talk|fight|...]
## --scene jumps to a story scene with the progress of the scenes before it.
## Never active in a normal run.

const ORDER := ["scene1", "scene2", "scene3", "scene4", "scene5", "scene6", "chapter0"]

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
	if scene != "":
		_jump.call_deferred(scene)
	if _shot_path != "":
		_take_shot.call_deferred()


func _jump(scene: String) -> void:
	preset(GameState.data, scene)
	SceneFlow.go_to(scene, false)


## Gives `data` the progress a player has when `scene` starts.
static func preset(data: PlayerData, scene: String) -> void:
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
		data.character_id = "pati"
		data.character_name = "Pati"
		data.set_flag("prolog_bitti")


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

class_name CutscenePlayer
extends Node
## Plays a cutscene from content/<chapter>/cutscenes/<id>.json. The player
## has no control; dialogue lines still wait for a tap. Steps run in order:
##   {"cam": {"pos": [x,y,z], "look": [x,y,z], "time": s}}   move the camera
##   {"say": "bark_id"}                                        lines, wait for close
##   {"wait": s}
##   {"do": "method", "args": [...]}   call a method on the scene (visual beats)
##   {"pus": amount, "time": s}         fade the grey Pus
##   {"flash": s}                       white flash
##   {"card": ["small", "big", "sub"], "time": s}
##   {"goto": "scene_id"}

signal finished

var scene: Node
var camera: Camera3D
var hud: Hud


func play(cutscene_id: String) -> void:
	var path := "res://content/%s/cutscenes/%s.json" % [Content.chapter.get("id", "prologue"), cutscene_id]
	var steps: Array = Content.read_json(path).get("steps", [])
	if hud:
		hud.cinematic(true)
	for step: Dictionary in steps:
		await _run(step)
	if hud:
		hud.cinematic(false)
	finished.emit()


func _run(step: Dictionary) -> void:
	if step.has("cam"):
		var c: Dictionary = step["cam"]
		var to := _v(c["pos"])
		var look := _v(c["look"])
		var t := float(c.get("time", 0.0))
		if t <= 0.0:
			camera.global_position = to
			camera.look_at(look)
		else:
			var from_pos := camera.global_position
			var from_look := camera.global_position - camera.global_transform.basis.z * 10.0
			var tw := create_tween()
			tw.tween_method(func(k: float) -> void:
				camera.global_position = from_pos.lerp(to, k)
				camera.look_at(from_look.lerp(look, k)), 0.0, 1.0, t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await tw.finished
	elif step.has("say"):
		GameState.bark(String(step["say"]).replace("{keeper}", GameState.data.character_id))
		await GameState.dialogue_closed
	elif step.has("wait"):
		await get_tree().create_timer(float(step["wait"])).timeout
	elif step.has("do"):
		scene.callv(step["do"], step.get("args", []))
	elif step.has("pus"):
		var tw := Pus.fade_to(self, float(step["pus"]), float(step.get("time", 1.0)))
		if step.get("block", false):
			await tw.finished
	elif step.has("flash"):
		await hud.flash(float(step["flash"]))
	elif step.has("card"):
		var c: Array = step["card"]
		hud.show_scene_card(c[0], c[1], c[2] if c.size() > 2 else "")
		await get_tree().create_timer(float(step.get("time", 3.4))).timeout
	elif step.has("goto"):
		SceneFlow.go_to(step["goto"])


static func _v(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])

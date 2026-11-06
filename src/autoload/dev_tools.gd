extends Node
## Command-line helpers for automated screenshots, used by tools/screenshot.sh:
##   -- --shot=out.png [--frames=60] [--demo=talk|quest|kids]
## Never active in a normal run.

var _shot_path := ""
var _frames := 60
var demo := ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.get_slice("=", 1)
		elif arg.begins_with("--frames="):
			_frames = int(arg.get_slice("=", 1))
		elif arg.begins_with("--demo="):
			demo = arg.get_slice("=", 1)
	if _shot_path != "":
		_take_shot.call_deferred()


func _take_shot() -> void:
	for i in _frames:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(_shot_path)
	print("SHOT ", _shot_path)
	get_tree().quit()

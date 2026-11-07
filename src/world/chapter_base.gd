class_name ChapterBase
extends Node3D
## Shared helpers for chapter scenes (Bölüm 4 on). Older chapters keep their
## own copies of these for now.

@onready var _hud: Hud = $Hud
@onready var _player: Player = $Player


func npc(parent: Node3D, id: String, kind: String, at: Vector3, face := 0.0) -> Npc:
	var n := Npc.new()
	n.npc_id = id
	n.kind = kind
	n.face_angle_deg = face
	n.position = at
	parent.add_child(n)
	return n


## Boss camera: look between the player and the arena so both stay in view.
func boss_camera(on: bool, anchor := Vector3.ZERO, weight := 0.45, dist := 19.0) -> void:
	var cam: FollowCamera = $Camera
	cam.anchor = anchor
	cam.anchor_weight = weight if on else 0.0
	cam.distance = dist if on else 14.0


## A glowing spark flies from `from` into the keeper's hands.
func fly_spark(from: Vector3, color_token: String) -> void:
	var orb := Toon.part(self, "sphere", Vector3(0.8, 1.1, 0.8), color_token, from, Vector3.ZERO, 1.2, 0.04)
	var tw := orb.create_tween()
	tw.tween_property(orb, "global_position", _player.global_position + Vector3.UP, 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(orb.queue_free)
	await tw.finished


## Young ones / kids that go home once their flag is set.
func send_home(prefix: String, flag_prefix: String, count: int) -> void:
	for i in range(1, count + 1):
		var n := get_node_or_null("Level/%s%d" % [prefix, i])
		if n and GameState.data.has_flag("%s%d" % [flag_prefix, i]) and not n.has_meta("leaving"):
			n.set_meta("leaving", true)
			Effects.sparkle(self, n.global_position + Vector3.UP, Tokens.color("panel@light"), 12)
			var tw := n.create_tween()
			tw.tween_interval(0.6)
			tw.tween_property(n, "scale", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.tween_callback(n.queue_free)


# --- test helpers -------------------------------------------------------------

func close_dialogs() -> void:
	await get_tree().create_timer(0.3).timeout
	while _hud._dialog.is_open():
		_hud._dialog.advance()
		await get_tree().create_timer(0.05).timeout


func walk_to(target: Vector3, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		var aim := target - _player.global_position
		aim.y = 0.0
		for a in ["move_left", "move_right", "move_forward", "move_back"]:
			Input.action_release(a)
		if aim.length() < 0.8:
			break
		var dir := aim.normalized()
		if dir.x > 0.2: Input.action_press("move_right", dir.x)
		if dir.x < -0.2: Input.action_press("move_left", -dir.x)
		if dir.z > 0.2: Input.action_press("move_back", dir.z)
		if dir.z < -0.2: Input.action_press("move_forward", -dir.z)
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	for a in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(a)

class_name ChapterBase
extends Node3D
## Shared helpers for chapter scenes (Bölüm 4 on). Older chapters keep their
## own copies of these for now.

@onready var _hud: Hud = $Hud
@onready var _player: Player = $Player


func _init() -> void:
	ready.connect(_place_side_spots, CONNECT_ONE_SHOT)


## Season 2 side collections (content/s2_side.json) for this scene.
func _place_side_spots() -> void:
	var scene := SceneFlow.current
	for pair: Array in SideQuests.spots(Content.side, scene):
		var s := SideSpot.new()
		s.scene_id = scene
		s.index = pair[0]
		s.spot = pair[1]
		s.name = "Side_%s_%d" % [pair[1]["set"], pair[0]]
		var at: Array = pair[1]["at"]
		s.position = Vector3(float(at[0]), 0.0, float(at[1]))
		add_child(s)
	if DevTools.demo == "side":
		_side_demo()


## Test helper: big meshes between the camera and a side spot (tree
## crowns, roofs) that would hide it.
func _side_occluders(s: Node3D, at := Vector3.INF) -> Array:
	var cam := get_viewport().get_camera_3d()
	var out := []
	if cam == null:
		return out
	var a := s.global_position + Vector3.UP * 1.2
	var b := cam.global_position
	if at != Vector3.INF:
		b += at - s.global_position
		a = at + Vector3.UP * 1.2
	for n in find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree() or s.is_ancestor_of(g) or _player.is_ancestor_of(g) or g is MultiMeshInstance3D or g is Label3D:
			continue
		var moving := false
		var up := g.get_parent()
		while up and up != self:
			if up is CharacterBody3D or up is Npc:
				moving = true
				break
			up = up.get_parent()
		if moving:
			continue
		var box := g.global_transform * g.get_aabb()
		if box.size.x > 20.0 or box.size.z > 20.0 or box.size.y < 1.2:
			continue
		if box.intersects_segment(a, b):
			out.append(String(g.get_parent().name) + "/" + String(g.name))
	return out


## Test: walk up to every side spot of this scene (ring its bell first) and
## use it the way a player would. Prints SIDE lines and quits.
func _side_demo() -> void:
	var d := GameState.data
	DevTools.auto_dialogue = true
	await get_tree().create_timer(3.0, false).timeout
	await close_dialogs()
	var ok := true
	for s: SideSpot in find_children("Side_*", "SideSpot", false, false):
		if s.spot.has("needs"):
			print("SIDE locked %s=%s" % [s.name, not SideQuests.available(d, s.spot)])
			d.set_flag(s.spot["needs"])
		var stand := s.global_position + Vector3(0, 0.4, 1.2)
		_player.global_position = stand
		_player.respawn_point = stand
		_player.velocity = Vector3.ZERO
		await get_tree().create_timer(0.7, false).timeout
		var on_floor := _player.is_on_floor() and _player.global_position.distance_to(stand) < 0.8
		var focus := _player._focus == s
		var hidden := _side_occluders(s)
		if not hidden.is_empty():
			print("SIDE hidden %s by %s" % [s.name, hidden])
			for r in [3.0, 5.0, 7.0]:
				var hit := false
				for k in 8:
					var c: Vector3 = s.global_position + Vector3(cos(k * TAU / 8), 0, sin(k * TAU / 8)) * r
					if _side_occluders(s, c).is_empty():
						print("SIDE try %s -> [%d, %d]" % [s.name, roundi(c.x), roundi(c.z)])
						hit = true
						break
				if hit:
					break
		_player.interact()
		await close_dialogs()
		var found := s.is_found()
		print("SIDE %s at=%s floor=%s focus=%s found=%s" % [s.name, s.global_position, on_floor, focus, found])
		ok = ok and on_floor and focus and found and hidden.is_empty()
	var sets := []
	for id: String in Content.side["sets"]:
		sets.append("%s=%d/%d" % [id, SideQuests.found(d, Content.side, id, SceneFlow.current), SideQuests.spots(Content.side, SceneFlow.current, id).size()])
	print("SIDE_DONE %s ok=%s %s" % [SceneFlow.current, ok, " ".join(sets)])
	get_tree().quit()


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


## Season 2, after a boss: the one who gave the quest comes over to the
## arena (pops up close by and walks up), so the last talk happens there
## instead of a long walk back. `walk` = false just places them (a reload).
func giver_comes(node_name: String, to: Vector3, walk := true) -> void:
	var g := get_node_or_null(node_name) as Node3D
	if g == null:
		return
	if not walk:
		g.global_position = to
		return
	var from := to + Vector3(2.5, 0, 2.5)
	g.global_position = from
	Effects.sparkle(self, from + Vector3.UP, Tokens.color("spark-white"), 14)
	Audio.play("blip")
	var rig := g.find_child("Rig", true, false) as CharacterRig
	if rig:
		rig.speed = 1.0
	var tw := g.create_tween()
	tw.tween_property(g, "global_position", to, 1.4)
	await tw.finished
	if rig:
		rig.speed = 0.0
	if not g.has_node("Beacon"):
		Beacon.attach(g, 2.8, Tokens.color("spark-white"))


## Once `flag` is set (the chapter is done), the way on is marked: a star
## over the exit to the next region and a hint.
func way_on(flag: String, at: Vector3, region: String) -> void:
	var d := GameState.data
	var mark := func() -> void:
		if not d.has_flag(flag) or has_node("WayOn"):
			return
		var n := Node3D.new()
		n.name = "WayOn"
		add_child(n)
		n.global_position = at
		Beacon.attach(n, 2.6, Tokens.color("spark-yellow"))
		var r := TranslationServer.translate(region)
		_hud.show_hint(TranslationServer.translate("Yol açık: %s. Yıldızlı yoldan geç!") % r, TranslationServer.translate("Yol açık: %s") % r)
	mark.call()
	d.flags_changed.connect(mark)


## Arriving by fast travel (or from a house): stand at SceneFlow.return_point.
func take_return_point() -> void:
	if SceneFlow.return_point != Vector3.INF:
		_player.global_position = SceneFlow.return_point
		_player.respawn_point = SceneFlow.return_point
		SceneFlow.return_point = Vector3.INF


# --- test helpers -------------------------------------------------------------

func close_dialogs() -> void:
	await get_tree().create_timer(0.3, false).timeout
	while _hud._dialog.is_open():
		_hud._dialog.advance()
		await get_tree().create_timer(0.05, false).timeout


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

extends Node3D
## Dev scene: every character model in a row on a meadow, close camera.
##   tools/screenshot.sh out.png --scene=preview [--demo=keepers|npcs|mobs] [--at=2]

const KEEPERS := ["pati", "bado", "citir", "lumi", "fistik"]
const NPCS := ["turtle", "bunny", "duckling", "owl_teacher", "spider", "mole", "gull_captain", "snowman", "frog", "star_child"]


func _ready() -> void:
	Pus.set_amount(0.0)
	var mood := "sabah"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mood="):
			mood = arg.get_slice("=", 1)
	WorldLook.add(self, mood)
	WorldLook.block(self, Vector3(0, -0.5, 0), Vector3(40, 1, 24), Tokens.color("spark-green").lerp(Tokens.color("bg"), 0.15), 0.0)
	Decor.auto(self, "koy")
	var which := DevTools.demo if DevTools.demo != "" else "keepers"
	if which == "sky":
		# look up at the sky over a strip of ground (--mood=sabah|aksam|...)
		var c := Camera3D.new()
		c.fov = 60.0
		c.position = Vector3(0, 1.6, 10)
		add_child(c)
		c.look_at(Vector3(0, 5.5, -20))
		return
	if which == "import":
		_import_check()
		return
	if which == "audio":
		_audio_check()
		return
	var list: Array = KEEPERS if which == "keepers" else NPCS
	var gap := 2.0 if which == "keepers" else 2.4
	for i in list.size():
		var id: String = list[i]
		var m: Node3D
		if which == "keepers":
			m = FistikModel.build() if id == "fistik" else KeeperModels.build(id, {"variant": 0, "accessory": "yok"})
		else:
			m = NpcModels.build(id)
		m.position = Vector3((i - (list.size() - 1) * 0.5) * gap, 0, 0)
		add_child(m)
	var cam := Camera3D.new()
	cam.fov = 40.0 if which == "keepers" else 50.0
	cam.position = Vector3(0, 2.6, 9.5 if which == "keepers" else 14.0)
	add_child(cam)
	cam.look_at(Vector3(0, 1.1, 0))


## Headless check of the .glb route: export a placeholder to glTF, read it back
## at runtime, pass it through ModelImport and print size + materials.
##   godot --headless --path . -- --scene=preview --demo=import
func _import_check() -> void:
	var src := KeeperModels.build("bado")
	add_child(src)
	src.scale = Vector3.ONE * 3.0  # wrong size on purpose: ModelImport must fit it
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	doc.append_from_scene(src, state)
	var path := "user://import_check.glb"
	doc.write_to_filesystem(state, path)
	src.queue_free()
	var doc2 := GLTFDocument.new()
	var state2 := GLTFState.new()
	var err := doc2.append_from_file(path, state2)
	var loaded := doc2.generate_scene(state2) as Node3D
	var model := ModelImport.from_scene(loaded, "bado")
	add_child(model)
	await get_tree().process_frame
	var box := ModelImport._bounds(model, Transform3D.IDENTITY)
	var toon := 0
	var other := 0
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i)
			if m is ShaderMaterial and (m as ShaderMaterial).shader == Toon.TOON_SHADER:
				toon += 1
			else:
				other += 1
	print("IMPORT err=%d height=%.2f bottom=%.2f toon=%d other=%d rig=%s" % [err, box.size.y, box.position.y, toon, other, CharacterRig.of(model) != null])
	get_tree().quit()


## Headless check that every sound and track loads and plays.
##   godot --headless --path . -- --scene=preview --demo=audio
func _audio_check() -> void:
	var sfx := 0
	var missing: Array = []
	for f in DirAccess.get_files_at(Audio.SFX_DIR):
		if f.ends_with(".wav"):
			sfx += 1
	var names := ["jump", "jump2", "land", "swish", "hit", "hurt", "roll", "skill", "sleep", "wake", "fall",
		"coin", "heal", "levelup", "quest", "fanfare", "lantern", "crystal", "stone", "memory", "calm",
		"boss_calm", "chest", "door", "bell", "boing", "wind", "whoosh", "warn", "click", "pop", "blip", "card", "shop"]
	for n in names:
		if Audio._stream(Audio.SFX_DIR + n + ".wav") == null:
			missing.append(n)
		Audio.play(n)
	var tracks := {}
	for t: String in Audio.SCENE_MUSIC.values():
		tracks[t] = true
	tracks["boss"] = true
	for t: String in tracks:
		if Audio._stream(Audio.MUSIC_DIR + t + ".ogg") == null:
			missing.append(t + ".ogg")
	Audio.scene_changed("chapter1")
	Audio.boss(true)
	await get_tree().create_timer(0.3).timeout
	var boss_track := Audio._track
	Audio.boss(false)
	print("AUDIO sfx_files=%d tracks=%d missing=%s boss=%s back=%s" % [sfx, tracks.size(), missing, boss_track, Audio._track])
	get_tree().quit()

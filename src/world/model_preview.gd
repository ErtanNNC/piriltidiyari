extends Node3D
## Dev scene: every character model in a row on a meadow, close camera.
##   tools/screenshot.sh out.png --scene=preview [--demo=keepers|npcs|mobs] [--at=2]
##   --demo=ref --model=pati: one character, front view on a plain background
##   (the reference image for image-to-3D tools)

const KEEPERS := ["pati", "bado", "citir", "lumi", "fistik"]
const MOBS := ["sumuklu", "mantar", "dev_mantar", "kirpi_topu", "karga", "kristal_bocek", "yarasa", "firtina_yumagi", "korsan_marti", "kar_tavsani", "buz_dikeni"]
const NPCS := ["turtle", "bunny", "duckling", "owl_teacher", "spider", "mole", "gull_captain", "snowman", "frog", "star_child"]


func _ready() -> void:
	Pus.set_amount(0.0)
	if DevTools.demo == "ref":
		_reference()
		return
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
	if which == "props":
		_row([["house", "berry"], ["house", "sky"], ["well", "spark-purple"], ["lantern_post", "honey"], ["big_tree", ""], ["bush", ""], ["rock", ""]], 4.6, Vector3(0, 4.0, 15.0), Vector3(0, 1.8, 0))
		return
	if which == "mobs":
		var kinds := ["sumuklu", "mantar", "kirpi_topu", "karga", "kristal_bocek", "yarasa", "firtina_yumagi", "korsan_marti", "kar_tavsani", "buz_dikeni"]
		for i in kinds.size():
			for row in 2:
				var m := MobModels.build(kinds[i], row == 0)
				m.position = Vector3((i - (kinds.size() - 1) * 0.5) * 2.3, 0, -row * 3.4)
				add_child(m)
		var c2 := Camera3D.new()
		c2.fov = 45.0
		c2.position = Vector3(0, 5.5, 14.5)
		add_child(c2)
		c2.look_at(Vector3(0, 0.4, -1.3))
		return
	if which == "looks":
		# one keeper (--model=pati) in four shop looks
		var kid := "pati"
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--model="):
				kid = arg.get_slice("=", 1)
		var looks := [{}, {"outfit": "kasif_sapkasi", "weapon": "isik_degnegi"}, {"outfit": "yildiz_pelerini", "accessory": "atki"}, {"outfit": "cicek_taci", "weapon": "kivilcim_kilici"}]
		for i in looks.size():
			var lk: Dictionary = looks[i]
			var km := KeeperModels.build(kid, lk)
			km.position = Vector3((i - 1.5) * 2.2, 0, 0)
			km.rotation_degrees.y = 0.0 if i != 2 else 160.0
			add_child(km)
		var c3 := Camera3D.new()
		c3.fov = 40.0
		c3.position = Vector3(0, 2.4, 8.5)
		add_child(c3)
		c3.look_at(Vector3(0, 1.0, 0))
		return
	if which == "heights":
		# prints each character's height (for assets/models/<id>.json) and quits
		for kid: String in KEEPERS + NPCS + ["gull_chick", "mole_kid", "bunny_sleepy"] + MOBS:
			var hm: Node3D
			if kid in MOBS:
				hm = MobModels.build(kid, false)
			else:
				hm = FistikModel.build() if kid == "fistik" else (KeeperModels.build(kid, {}) if kid in KEEPERS else NpcModels.build(kid))
			add_child(hm)
			var hb := ModelImport._bounds(hm, Transform3D.IDENTITY)
			print("HEIGHT %s %.2f top=%.2f width=%.2f" % [kid, hb.size.y, hb.end.y, hb.size.x])
			hm.queue_free()
		get_tree().quit()
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
	await get_tree().create_timer(0.3).timeout
	# Müzik: Kapalı must silence it, Açık must bring it back
	Audio.set_music_on(false)
	await get_tree().create_timer(0.8).timeout
	var silent: bool = not Audio._music[0].playing and not Audio._music[1].playing
	Audio.scene_changed("chapter2")
	await get_tree().create_timer(0.3).timeout
	var still_silent: bool = not Audio._music[0].playing and not Audio._music[1].playing
	Audio.set_music_on(true)
	await get_tree().create_timer(0.3).timeout
	var back_on: bool = Audio._music[0].playing or Audio._music[1].playing
	print("AUDIO sfx_files=%d tracks=%d missing=%s boss=%s back=%s off=%s off_after_scene=%s on=%s" % [sfx, tracks.size(), missing, boss_track, Audio._track, silent, still_silent, back_on])
	get_tree().quit()


func _row(items: Array, gap: float, cam_at: Vector3, look: Vector3) -> void:
	for i in items.size():
		var pr := Prop.new()
		pr.kind = items[i][0]
		if items[i][1] != "":
			pr.accent = items[i][1]
		pr.name = "P%d" % i
		pr.position = Vector3((i - (items.size() - 1) * 0.5) * gap, 0, 0)
		add_child(pr)
	var c := Camera3D.new()
	c.fov = 50.0
	c.position = cam_at
	add_child(c)
	c.look_at(look)


## A clean front view for image-to-3D: soft even light, plain background.
func _reference() -> void:
	var id := "pati"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--model="):
			id = arg.get_slice("=", 1)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(1, 1, 1)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 1, 1)
	env.environment.ambient_light_energy = 0.6
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 10, 0)
	add_child(sun)
	var m: Node3D
	if id in KEEPERS:
		m = FistikModel.build() if id == "fistik" else KeeperModels.build(id, {"variant": 0, "accessory": "yok"})
	elif id in NPCS or id in ["gull_chick", "mole_kid", "bunny_sleepy", "crab_friend"]:
		m = NpcModels.build(id)
	else:
		m = MobModels.build(id, false)
	add_child(m)
	_no_outline(m)
	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.position = Vector3(0, 1.05, 5.2)
	add_child(cam)
	cam.look_at(Vector3(0, 1.0, 0))


## The reference must hold only flat base colors: no outline (the game draws
## it) and no light (the game lights the model; light baked into the texture
## would be added twice and wash the colors out).
func _no_outline(n: Node) -> void:
	if n is GeometryInstance3D:
		var g := n as GeometryInstance3D
		if g.material_override:
			g.material_override = _flat(g.material_override)
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			for i in mi.get_surface_override_material_count():
				var mat := mi.get_active_material(i)
				if mat:
					mi.set_surface_override_material(i, _flat(mat))
	for c in n.get_children():
		_no_outline(c)


static func _flat(src: Material) -> Material:
	var col := Color.WHITE
	if src is ShaderMaterial:
		var v: Variant = (src as ShaderMaterial).get_shader_parameter("albedo")
		if v is Color:
			col = v
	elif src is BaseMaterial3D:
		col = (src as BaseMaterial3D).albedo_color
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	if col.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

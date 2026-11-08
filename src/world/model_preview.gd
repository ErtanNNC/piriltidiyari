extends Node3D
## Dev scene: every character model in a row on a meadow, close camera.
##   tools/screenshot.sh out.png --scene=preview [--demo=keepers|npcs|mobs] [--at=2]
##   --demo=ref --model=pati: one character, front view on a plain background
##   (the reference image for image-to-3D tools)

const KEEPERS := ["pati", "bado", "citir", "lumi", "fistik"]
const MOBS := ["sumuklu", "mantar", "dev_mantar", "kirpi_topu", "karga", "kristal_bocek", "yarasa", "firtina_yumagi", "korsan_marti", "kar_tavsani", "buz_dikeni"]
const BOSSES := ["pus_baykusu", "kutuk_kral", "kiskac", "ruzgar", "dondurma", "miril"]
const NPCS := ["turtle", "bunny", "duckling", "owl_teacher", "spider", "mole", "gull_captain", "snowman", "frog", "star_child"]


func _ready() -> void:
	Pus.set_amount(0.0)
	if DevTools.demo == "ref":
		_reference()
		return
	if DevTools.demo == "eyes":
		_eye_shots()
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
		var kinds := ["sumuklu", "mantar", "kirpi_topu", "karga", "kristal_bocek", "yarasa", "firtina_yumagi", "korsan_marti", "kar_tavsani", "buz_dikeni", "golge_kopya"]
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
	if which == "bosses":
		# the six bosses side by side (real models when the files exist)
		var xs := [-13.0, -7.5, -2.5, 2.5, 7.5, 13.5]
		for i in BOSSES.size():
			var bm := boss(BOSSES[i])
			bm.position = Vector3(xs[i], 0, -2.0 if BOSSES[i] == "dondurma" else 0.0)
			add_child(bm)
			if "--blink" in OS.get_cmdline_user_args() and CharacterRig.of(bm):
				CharacterRig.of(bm).hold_blink = 1.0
		var cb := Camera3D.new()
		cb.fov = 50.0
		cb.position = Vector3(0, 6.0, 24.0)
		add_child(cb)
		cb.look_at(Vector3(0, 3.0, 0))
		return
	if which == "rigtest":
		# --model=pati: every clip of a rigged model side by side (idle walk run jump attack)
		var rid := "pati"
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--model="):
				rid = arg.get_slice("=", 1)
		var clips := ["idle", "walk", "run", "jump", "attack"]
		for i in clips.size():
			var wrap := ModelImport.load_model(rid)
			wrap.position = Vector3((i - 2) * 2.2, 0, 0)
			add_child(wrap)
			var ap := wrap.find_children("*", "AnimationPlayer", true, false)
			if not ap.is_empty():
				var a: AnimationPlayer = ap[0]
				CharacterRig.of(wrap).set_process("--live" in OS.get_cmdline_user_args())
				if a.has_animation(clips[i]):
					a.get_animation(clips[i]).loop_mode = Animation.LOOP_LINEAR
					a.play(clips[i])
					a.seek(0.4, true)
		var cr := Camera3D.new()
		cr.fov = 45.0
		cr.position = Vector3(0, 2.0, 9.5)
		add_child(cr)
		cr.look_at(Vector3(0, 1.0, 0))
		return
	if which == "fur":
		# every keeper in its three fur colors
		for row in 3:
			for i in 4:
				var fm := KeeperModels.build(KEEPERS[i], {"variant": row})
				fm.position = Vector3((i - 1.5) * 2.6 + (row - 1) * 0.0, 0, -row * 2.6)
				add_child(fm)
		var cf := Camera3D.new()
		cf.fov = 45.0
		cf.position = Vector3(0, 5.0, 10.5)
		add_child(cf)
		cf.look_at(Vector3(0, 0.6, -2.6))
		return
	if which == "play":
		# the real player from the side: --act=walk|attack|roll (starts at 1 s)
		var act := "walk"
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--act="):
				act = arg.get_slice("=", 1)
		var kp := "pati"
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--keeper="):
				kp = arg.get_slice("=", 1)
		GameState.data.character_id = kp
		GameState.data.character_look = {}
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--weapon="):
				var wpn := arg.get_slice("=", 1)
				GameState.data.set_flag("owned_" + wpn)
				GameState.data.equipped["weapon"] = wpn
		var pl := Player.new()
		add_child(pl)
		pl.position = Vector3(-3 if act != "attack" else 0, 0.1, 0)
		pl.input_enabled = false
		var cp := Camera3D.new()
		cp.fov = 40.0
		cp.position = Vector3(5.5, 2.0, 5.5) if act == "attack" else Vector3(0, 2.2, 8.0)
		add_child(cp)
		cp.look_at(Vector3(0, 0.9, 0))
		await get_tree().create_timer(2.0).timeout
		pl._roll_dir = Vector3.RIGHT
		pl.model.rotation.y = PI * 0.5
		match act:
			"walk":
				while true:
					pl._move = Vector3(pl.speed * 0.8, 0, 0)
					await get_tree().physics_frame
			"attack":
				pl._attack_cd = 0.0
				pl.spin_attack()
			"roll":
				pl.start_roll()
		return
	if which == "anim":
		# shape rig check: --pose=walk|attack|happy|blink|idle (all keepers + a few)
		var pose_name := "walk"
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--pose="):
				pose_name = arg.get_slice("=", 1)
		var ids := ["pati", "bado", "citir", "lumi", "fistik", "frog", "gull_captain"]
		var rigs: Array = []
		for i in ids.size():
			var id: String = ids[i]
			var am: Node3D = FistikModel.build() if id == "fistik" else (KeeperModels.build(id, {}) if id in KEEPERS else NpcModels.build(id))
			am.position = Vector3((i - (ids.size() - 1) * 0.5) * 2.0, 0, 0)
			am.rotation_degrees.y = 30.0 if pose_name in ["walk", "attack"] else 0.0
			add_child(am)
			rigs.append(CharacterRig.of(am))
		var ca := Camera3D.new()
		ca.fov = 40.0
		ca.position = Vector3(0, 2.4, 11.0)
		add_child(ca)
		ca.look_at(Vector3(0, 1.0, 0))
		for r: CharacterRig in rigs:
			if r == null:
				continue
			match pose_name:
				"walk": r.speed = 1.0
				"blink": r.hold_blink = 1.0
				"happy": r.happy()
		if pose_name == "attack":
			await get_tree().create_timer(1.83).timeout
			for r: CharacterRig in rigs:
				if r:
					r.attack()
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
	var tex: Texture2D = null
	if src is ShaderMaterial:
		var v: Variant = (src as ShaderMaterial).get_shader_parameter("albedo")
		if v is Color:
			col = v
		tex = (src as ShaderMaterial).get_shader_parameter("albedo_tex") as Texture2D
	elif src is BaseMaterial3D:
		col = (src as BaseMaterial3D).albedo_color
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.albedo_texture = tex
	if col.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


static func boss(id: String) -> Node3D:
	match id:
		"pus_baykusu": return OwlModel.build()
		"kutuk_kral": return KutukKral._build_model()
		"kiskac": return KiskacModel.build()
		"ruzgar": return Ruzgar.build_model()
		"dondurma": return Dondurma.build_model()
	return MirilModel.shadow()


## --demo=eyes --out=DIR: every imported character front-on, flat and
## orthographic, one PNG each (DIR/<id>.png) plus a line "EYESHOT id height
## size" so tools/find_eyes.py can map pixels back to meters.
func _eye_shots() -> void:
	var out := "user://eyes"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.get_slice("=", 1)
	DirAccess.make_dir_recursive_absolute(out)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(1, 1, 1)
	add_child(env)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	add_child(cam)
	for i in 10:
		await get_tree().process_frame
	for id: String in ["pati"] + KEEPERS + NPCS + ["gull_chick"] + MOBS + BOSSES:
		if ModelImport.path_for(id) == "" or ModelImport._options(id).has("model"):
			continue
		var m: Node3D
		if id in BOSSES:
			m = boss(id)
		elif id in MOBS:
			m = MobModels.build(id, false)
		elif id in KEEPERS:
			m = FistikModel.build() if id == "fistik" else KeeperModels.build(id, {})
		else:
			m = NpcModels.build(id)
		var rig := CharacterRig.of(m)
		if rig:
			rig.free()
		add_child(m)
		_no_outline(m)
		var h := float(ModelImport._options(id).get("height", ModelImport.HEIGHTS.get(id, 2.0)))
		var size := h * 1.15
		cam.size = size
		cam.position = Vector3(0, h * 0.5, 10)
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(id + ".png"))
		print("EYESHOT %s %.4f %.4f" % [id, h, size])
		# depths of eyes already found (tools/find_eyes.py --write stores them)
		var ez: Array = ModelImport._eyes(m.get_node("Pose/Fit").get_child(0), m.get_node("Pose"), id + "#z", ModelImport._options(id), h)
		if ez.size() == 2:
			print("EYEZ %s %.4f %.4f" % [id, ez[0].z / h, ez[1].z / h])
		m.free()
	get_tree().quit()

extends ChapterBase
## Sezon 2 · Prolog · Sahne 2 – Kırmızı Rüzgâr. The candles are out, and a
## hot red wind blows over the mountains: the Kızıl Sis. The festival animals
## turn hot-tempered (Köpüklüler). Teaches attacking, Sakinleş (a breath
## calms a dazed creature), the Öfke barı (thick red mist heats Mırıl up
## too) and Nane Şekeri. Stages follow the quest "kirmizi_ruzgar".

const QUEST := "kirmizi_ruzgar"
## Thick Kızıl Sis by the frog pond: the Öfke barı fills inside it.
const HOT_SPOT := Vector3(8.0, 0, 5.0)
const HOT_RADIUS := 6.5
const HEAT := 0.14

var _stage := 0
var _dazed_bark := false
var _angry_bark := false
var _wave_t := 0.0


func _ready() -> void:
	var d := GameState.data
	Pus.set_color(Pus.RED)
	Pus.set_amount(0.1)
	Pus.fade_to(self, 0.5, 4.0)
	npc(self, "tospik_nine", "turtle", Vector3(-3.2, 0, -8.8), 20.0).name = "Tospik"
	npc(self, "fistik", "fistik", Vector3(1.6, 0, -8.6), 0.0).name = "Fistik"
	_cake()
	_red_wind()
	_hot_spot()
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	d.quest_changed.connect(func(_id: String) -> void: _advance())
	await get_tree().create_timer(1.5).timeout
	if d.quest_state(QUEST) == "done":
		_after_end()
		return
	GameState.bark("s2_ruzgar")
	_advance()
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _process(delta: float) -> void:
	if not _player.calm:
		return
	var flat := Vector2(_player.global_position.x - HOT_SPOT.x, _player.global_position.z - HOT_SPOT.z)
	_player.calm.heat = HEAT if _stage >= 3 and _stage < 5 and flat.length() < HOT_RADIUS else 0.0
	if not _dazed_bark and not get_tree().get_nodes_in_group("dazed").is_empty():
		_dazed_bark = true
		GameState.bark("s2_sersem")
		_hud.show_hint("Yanına git, C'ye basılı tut. Halka bitene kadar bırakma!", "Yanına git, Sakinleş'e basılı tut. Bırakma!")
	if not _angry_bark and _player.calm.anger > 0.35:
		_angry_bark = true
		GameState.bark("s2_kizgin")
		_hud.show_hint("Öfke barın doluyor! Sisten çık ya da Sakinleş'e bas.", "Öfke barın doluyor! Sakinleş'e bas.")
	# a creature that calmed down on its own didn't teach the breath: one more
	_wave_t -= delta
	if _stage == 1 and _wave_t <= 0.0 and GameState.data.objective_done(QUEST, "tavuk") \
			and not GameState.data.objective_done(QUEST, "nefes") and get_tree().get_nodes_in_group("mob").is_empty() \
			and get_tree().get_nodes_in_group("dazed").is_empty():
		_wave_t = 2.0
		Mob.spawn(self, "kopuklu_tavuk", _player.global_position + Vector3(3, 0, -3))


## Moves the scene along as quest objectives complete.
func _advance() -> void:
	var d := GameState.data
	if _stage == 0:
		_stage = 1
		for p: Vector3 in [Vector3(-4, 0, -2), Vector3(4, 0, -1), Vector3(0, 0, -5)]:
			Mob.spawn(self, "kopuklu_tavuk", p)
		_hud.show_hint("J: hafifçe vur. Oturunca yanına git!", "Vur'a bas. Oturunca yanına git!")
	if _stage == 1 and d.objective_done(QUEST, "tavuk") and d.objective_done(QUEST, "nefes"):
		_stage = 2
		_hud.clear_hint()
		GameState.toast.emit("Tospik Nine: Mırıl, buraya gel!", "quest")
		Beacon.attach(get_node("Tospik"), 2.6, Tokens.color("spark-white"))
	if _stage == 2 and d.objective_done(QUEST, "konus"):
		_stage = 3
		if get_node("Tospik").has_node("Beacon"):
			get_node("Tospik/Beacon").queue_free()
		for k in 3:
			var a := TAU * k / 3.0
			Mob.spawn(self, "gurultucu_kurbaga", HOT_SPOT + Vector3(cos(a) * 2.5, 0, sin(a) * 2.5))
		_hot_spot_shown(true)
		_hud.show_hint("Kurbağalar yoğun sisin içinde. Orada sen de kızarsın!", "Yoğun sis seni de kızdırır!")
	if _stage == 3 and d.quest_state(QUEST) == "ready":
		_stage = 4
		_hot_spot_shown(false)
		Pus.fade_to(self, 0.25, 2.5)
		_hud.show_hint("Tospik Nine'ye dön", "Tospik Nine'ye dön")
		Beacon.attach(get_node("Tospik"), 2.6, Tokens.color("spark-white"))
	if _stage == 4 and d.quest_state(QUEST) == "done":
		_stage = 5
		_hud.clear_hint()
		if get_node("Tospik").has_node("Beacon"):
			get_node("Tospik/Beacon").queue_free()
		_end()


## Mırıl hears the voice in the wind. The next scenes (the mountain path,
## Gürledek, Hırıl) come in the next update.
func _end() -> void:
	await get_tree().create_timer(0.8).timeout
	GameState.bark("s2_son")
	if DevTools.demo == "redwind" and DisplayServer.get_name() == "headless":
		await close_dialogs()
		var d := GameState.data
		print("S2_REDWIND quest=%s flag=%s nane=%d level=%d" % [d.quest_state(QUEST), d.has_flag("s2_sahne2_bitti"), d.item_count("nane_sekeri"), d.level])
		get_tree().quit()
		return
	await get_tree().create_timer(1.0).timeout
	_after_end()


func _after_end() -> void:
	_hud.show_hint("Prolog devam edecek: Sahne 3 çok yakında!", "Sahne 3 çok yakında!")


## The birthday table, candles out, crumbs of cake.
func _cake() -> void:
	var at := Vector3(0, 0, -10.2)
	WorldLook.block(self, at + Vector3(0, 0.45, 0), Vector3(2.6, 0.9, 1.4), Color("#c98d5e"))
	Toon.part(self, "cylinder", Vector3(1.0, 0.5, 1.0), Color("#ffd1dc"), at + Vector3(0, 1.15, 0))
	Toon.part(self, "cylinder", Vector3(0.8, 0.35, 0.8), Color("#fff4d6"), at + Vector3(0, 1.55, 0))


## Warm red puffs sweeping across the village from the mountains.
func _red_wind() -> void:
	var p := CPUParticles3D.new()
	p.amount = 40
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.position = Vector3(-24, 3, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(2, 2.5, 22)
	p.direction = Vector3(1, 0, 0.1)
	p.spread = 8.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 9.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	var c := Tokens.color("hp")
	g.colors = PackedColorArray([Color(c, 0.0), Color(c, 0.22), Color(c, 0.22), Color(c, 0.0)])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(2.6, 2.6)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = Weather.texture("soft")
	q.material = m
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)


## The thick red mist by the pond: billowing red puffs low over the grass
## with a "Yoğun Kızıl Sis" label, there only while the frogs are (stage 3–4).
func _hot_spot() -> void:
	var root := Node3D.new()
	root.name = "HotSpot"
	root.position = HOT_SPOT
	root.visible = false
	add_child(root)
	var p := CPUParticles3D.new()
	p.amount = 46
	p.lifetime = 5.0
	p.preprocess = 5.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = HOT_RADIUS * 0.8
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.5
	p.direction = Vector3.UP
	p.spread = 60.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.1
	p.initial_velocity_max = 0.35
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	var c := Tokens.color("hp")
	g.colors = PackedColorArray([Color(c, 0.0), Color(c, 0.32), Color(c, 0.32), Color(c, 0.0)])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(3.0, 3.0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = Weather.texture("soft")
	q.material = m
	p.mesh = q
	p.position.y = 0.8
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(p)
	var l := Label3D.new()
	l.text = "Yoğun Kızıl Sis"
	l.font = Tokens.font_for("text-heading")
	l.font_size = 72
	l.pixel_size = 0.008
	l.outline_size = 16
	l.outline_modulate = Tokens.color("outline")
	l.modulate = Tokens.color("panel@light")
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position.y = 3.6
	root.add_child(l)


## The thick mist shows with the frogs and blows away when they're calm.
func _hot_spot_shown(on: bool) -> void:
	var h := get_node_or_null("HotSpot") as Node3D
	if h and h.visible != on:
		h.visible = on


func _run_demo(which: String) -> void:
	match which:
		"redwind":
			# the whole scene: hit the hens, breathe one calm, Tospik, frogs
			# in the hot mist, back to Tospik (headless check)
			DevTools.auto_dialogue = true
			for i in 60:
				var mobs := get_tree().get_nodes_in_group("mob")
				var dazed := get_tree().get_nodes_in_group("dazed")
				if _stage >= 2 and GameState.data.objective_done(QUEST, "konus") == false:
					break
				if not dazed.is_empty():
					var m: Node3D = dazed[0]
					_player.global_position = m.global_position + Vector3(0, 0.3, 1.4)
					Input.action_press("calm")
					await get_tree().create_timer(BreathCalm.BREATH_IN + BreathCalm.BREATH_OUT + 0.3).timeout
					Input.action_release("calm")
				elif not mobs.is_empty():
					var m: Mob = mobs[0]
					_player.global_position = m.global_position + Vector3(0, 0.3, 1.2)
					await get_tree().physics_frame
					m.hit(999, _player.global_position, 1.0)
				await get_tree().create_timer(0.3).timeout
			_player.global_position = get_node("Tospik").global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("tospik_nine")
			await close_dialogs()
			# frogs: stand in the hot mist until angry, then a Nane Şekeri
			_player.global_position = HOT_SPOT + Vector3(0, 0.3, 4.5)
			await get_tree().create_timer(8.0).timeout
			print("S2_ANGER anger=%.2f angry=%s" % [_player.calm.anger, _player.calm.is_angry()])
			var slot := GameState.data.potions.find("nane_sekeri")
			if slot >= 0:
				_player.drink_potion(slot)
			print("S2_MINT anger=%.2f angry=%s" % [_player.calm.anger, _player.calm.is_angry()])
			for i in 40:
				var mobs := get_tree().get_nodes_in_group("mob")
				var dazed := get_tree().get_nodes_in_group("dazed")
				if mobs.is_empty() and dazed.is_empty():
					break
				if not mobs.is_empty():
					(mobs[0] as Mob).hit(999, _player.global_position, 1.0)
				await get_tree().create_timer(0.4).timeout
			# dazed frogs calm down by themselves after a while
			for i in 30:
				if get_tree().get_nodes_in_group("dazed").is_empty():
					break
				await get_tree().create_timer(0.5).timeout
			_player.global_position = get_node("Tospik").global_position + Vector3(0, 0.3, 1.8)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("tospik_nine")
			await close_dialogs()
		"guide":
			# screenshot: walk up to a hen, tap it dizzy, the guide shows over it
			var mobs := get_tree().get_nodes_in_group("mob")
			if not mobs.is_empty():
				var m: Mob = mobs[0]
				await walk_to(m.global_position + Vector3(0.3, 0, 1.7), 3.0)
				m.hit(999, _player.global_position, 0.1)
				await close_dialogs()
				if OS.get_cmdline_user_args().has("--hold"):
					Input.action_press("calm")
		"breath":
			# screenshot: a dazed hen and the breathing ring
			var mobs := get_tree().get_nodes_in_group("mob")
			if not mobs.is_empty():
				var m: Mob = mobs[0]
				_player.global_position = m.global_position + Vector3(0.4, 0.3, 1.6)
				await get_tree().physics_frame
				m.hit(999, _player.global_position, 0.1)
				await close_dialogs()
				Input.action_press("calm")
		"angry":
			_stage = 3
			_hot_spot_shown(true)
			_player.global_position = HOT_SPOT + Vector3(0, 0.3, 3.0)


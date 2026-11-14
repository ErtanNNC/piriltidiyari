extends S4Garden
## Sezon 4 · Prolog · Sahne 4 – Dev Kabak Bahçıvan (the first boss, played as
## Tırıl). The pumpkin patch at the forest's edge: once he was the village's
## biggest pumpkin, but last year a watermelon grew bigger. Three easy
## phases (seeds = circles, a roll = dash). At 0 HP he sulks; Tırıl claps:
## "Sen hâlâ çok büyük ve turuncu bir kabaksın!" He blushes, his thorns
## fall. Lesson: comparing hides what you have.

const QUEST := "dev_kabak"
const GRASS := Color("#8fcf7a")
const SOIL := Color("#b88a5a")
const ARENA := Vector3(0, 0, -3.0)
## Yeşil Diken round the patch (off the fighting floor; they fall at the end).
const THORNS := [[Vector3(-11.5, 0, -3), 90.0], [Vector3(11.5, 0, -3), 90.0], [Vector3(-7, 0, -13.5), 0.0],
	[Vector3(7, 0, -13.5), 0.0], [Vector3(-11.5, 0, 6), 90.0], [Vector3(11.5, 0, 6), 90.0]]

var _thorns: Array[ThornPatch] = []
var _ending := false


func _ready() -> void:
	begin_garden("s4_scene4")
	Pus.set_amount(0.25)
	_build()
	Decor.auto(self, "koy")
	var d := GameState.data
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	var over := d.quest_state(QUEST) in ["ready", "done"] or d.objective_done(QUEST, "alkis")
	make_boss("kabak", ARENA, over)
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.5, false).timeout
	if over:
		_drop_thorns()
		_finish()
		return
	if DevTools.demo != "":
		DevTools.auto_dialogue = true
		_run_demo(DevTools.demo)
	start_fight("s4b_basla", "Tohum halkalarından kaç, yuvarlanınca çekil. Yorulunca vur!", "Halkalardan kaç, yorulunca vur!")


func _build() -> void:
	land(Vector3(0, 0, -2), Vector2(30, 34), GRASS)
	fence(Vector3(0, 0, -2), Vector2(28, 32))
	# the tilled patch he grew in
	var bed := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 8.5
	disc.bottom_radius = 8.5
	disc.height = 0.04
	bed.mesh = disc
	bed.position = ARENA + Vector3(0, 0.03, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = SOIL
	bed.material_override = mat
	lv.add_child(bed)
	# the forest's edge behind (north), never south of the keeper
	for x: float in [-12.0, -6.5, 0.0, 6.5, 12.0]:
		if prop("orman_agaclar", Vector3(x, 0, -17.0 - absf(x) * 0.08), 7.5, x * 0.4) == null:
			prop("prop_tree", Vector3(x, 0, -17.0), 6.0)
	for i in 6:
		prop("bahce_citi", Vector3(-12.5 + i * 5.0, 0, -15.2), 1.2)
	prop("korkuluk_tarla", Vector3(-9.5, 0, -10.5), 2.6, 0.5)
	# small pumpkins of the patch and, on its own little hill, the watermelon
	for p: Vector3 in [Vector3(-9, 0, -7), Vector3(9.5, 0, -8.5), Vector3(-10, 0, 1.5), Vector3(10, 0, 2.5), Vector3(5.5, 0, -12)]:
		_pumpkin(p, 0.7 + fmod(absf(p.x), 0.5))
	_melon(Vector3(8.5, 0, -11.5))
	for i in THORNS.size():
		var e: Array = THORNS[i]
		var t := thorns(e[0], 5.0, false, false, "", deg_to_rad(e[1]))
		t.strength = 0.0   # scenery here: the fight is lesson enough
		t.open_flag = ""    # a linear scene: they grow back when it restarts
		_thorns.append(t)


func _pumpkin(at: Vector3, s: float) -> void:
	var n := Node3D.new()
	lv.add_child(n)
	n.position = at
	Toon.part(n, "ellipsoid", Vector3(1.2, 0.9, 1.2) * s, Color("#f0963c"), Vector3(0, 0.42 * s, 0))
	Toon.part(n, "cylinder", Vector3(0.14, 0.3, 0.14) * s, Color("#5a8a3c"), Vector3(0, 0.95 * s, 0))


## The watermelon that grew bigger last year, with its ribbon.
func _melon(at: Vector3) -> void:
	var n := Node3D.new()
	lv.add_child(n)
	n.position = at
	Toon.part(n, "cylinder", Vector3(2.6, 0.5, 2.6), SOIL.darkened(0.15), Vector3(0, 0.25, 0))
	Toon.part(n, "ellipsoid", Vector3(2.4, 1.7, 1.8), Color("#3f9a50"), Vector3(0, 1.3, 0))
	for k in 3:
		Toon.part(n, "ellipsoid", Vector3(0.22, 1.72, 1.82), Color("#2c6a38"), Vector3((k - 1) * 0.7, 1.3, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(n, "cylinder", Vector3(0.5, 0.06, 0.5), Color("#ffd86a"), Vector3(0, 1.55, 0.88), Vector3(90, 0, 0))


func fight_ready() -> bool:
	return false   # the scene starts the fight itself, after the first lines


func _on_phase(p: int) -> void:
	super._on_phase(p)
	if p == 1:
		GameState.bark("s4b_faz")


func _on_boss_sad() -> void:
	_hud.hide_boss()
	GameState.bark("s4b_kustu")
	await GameState.dialogue_closed
	if boss.is_sad:
		_hud.show_hint("Küstü, kendi güzelliğini göremiyor. Yanına git, Alkış'a bas!", "Yanına git, Alkış'a bas!")


## Applauded: he blushes, and his thorns fall all round the patch.
func _on_boss_calmed() -> void:
	_hud.clear_hint()
	boss_camera(false)
	Audio.play("fanfare")
	GameState.bark("s4b_alkis")
	_blush()
	await GameState.dialogue_closed
	_drop_thorns()
	await get_tree().create_timer(1.6, false).timeout
	_finish()


func _blush() -> void:
	var glow := OmniLight3D.new()
	glow.light_color = Color("#ff7a6a")
	glow.light_energy = 0.0
	glow.omni_range = 7.0
	glow.position = Vector3(0, 2.0, 1.6)
	boss.add_child(glow)
	for side: float in [-1.0, 1.0]:
		var cheek := Toon.part(boss, "sphere", Vector3(0.5, 0.36, 0.2), Color("#ff8f8f"), Vector3(side * 0.75, 1.5, 1.25), Vector3.ZERO, 0.6, 0.0, 0.0)
		cheek.scale = Vector3.ONE * 0.01
		create_tween().tween_property(cheek, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var tw := create_tween()
	tw.tween_property(glow, "light_energy", 2.4, 0.5)
	tw.parallel().tween_property(boss, "scale", Vector3(1.12, 0.92, 1.12), 0.18)
	tw.tween_property(boss, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(glow, "light_energy", 0.9, 1.2)
	Effects.sparkle(self, boss.global_position + Vector3.UP * 2.4, Tokens.color("hp"), 16)


func _drop_thorns() -> void:
	for t in _thorns:
		if not t.is_open:
			t.open()
	Pus.fade_to(self, 0.04, 2.5)


func _finish() -> void:
	if _ending:
		return
	_ending = true
	var d := GameState.data
	if d.quest_state(QUEST) == "ready":
		d.complete_quest(Content.quests[QUEST])
	d.set_flag("s4_sahne4_bitti")
	_hud.clear_hint()
	GameState.bark("s4b_son")
	if DevTools.demo == "pumpkin" and DisplayServer.get_name() == "headless":
		await close_dialogs()
		var open := _thorns.filter(func(t: ThornPatch) -> bool: return t.is_open).size()
		print("S4B4_PUMPKIN quest=%s flag=%s thorns_open=%d/%d level=%d hp=%d keeper=%s" % [d.quest_state(QUEST), d.has_flag("s4_sahne4_bitti"), open, _thorns.size(), d.level, d.hp, d.character_id])
		get_tree().quit()
		return
	await GameState.dialogue_closed
	SceneFlow.go_to("s4_scene5")


func _run_demo(which: String) -> void:
	match which:
		"pumpkin":
			await get_tree().create_timer(0.5, false).timeout
			print("S4B4_START keeper=%s level=%d clap=%s boss_hp=%d" % [GameState.data.character_id, GameState.data.level, _player.clap != null, boss.max_hp])
			await _beat_boss()
			print("S4B4_CALM sad=%s done=%s" % [boss.is_sad, GameState.data.objective_done(QUEST, "alkis")])

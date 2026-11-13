extends S3Island
## Sezon 3 · Prolog · Sahne 4 – Dev Gölge (the first boss). On top of the
## cliffs, in the moonlight, a huge clawed shadow. It can't be hit: after
## each round of its moves a torch comes free; every torch Hırıl lights
## makes the shadow smaller. After the third the owner shows: a tiny crab
## trembling in front of a lantern. Lesson: fears look bigger than they are.

const QUEST := "dev_golge"
const ROCK := Color("#8f8aa0")
const ROCK_DARK := Color("#6a6680")
const ARENA := Vector3(0, 0, -6.0)
const TORCHES := [Vector3(-7.0, 0, -2.0), Vector3(7.0, 0, -2.0), Vector3(0, 0, 4.5)]
const LANTERN := Vector3(0, 0, -15.0)

var _shadow: GiantShadow
var _torches: Array[BeachTorch] = []
var _crab: Titrek
var _started := false


func _ready() -> void:
	begin("s3_scene4")
	Pus.set_amount(0.3)
	cold_before = 0.0
	_build()
	Decor.auto(self, "kumsal")
	var d := GameState.data
	if d.quest_state(QUEST) == "none":
		d.start_quest(Content.quests[QUEST])
	d.quest_changed.connect(func(_id: String) -> void: _check())
	_player.respawn_point = _player.global_position
	await get_tree().create_timer(1.5, false).timeout
	if d.quest_state(QUEST) == "done":
		_end()
		return
	boss_camera(true, ARENA, 0.4, 19.0)
	if DevTools.demo != "":
		DevTools.auto_dialogue = true
	GameState.bark("s3d_basla")
	await GameState.dialogue_closed
	_hud.show_hint("Halkalardan kaç! Meşale açılınca git ve yak.", "Halkalardan kaç, açılan meşaleyi yak!")
	_started = true
	_shadow.start()
	if DevTools.demo != "":
		_run_demo(DevTools.demo)


func _build() -> void:
	land(Vector3(0, 0, -2), Vector2(26, 28), ROCK)
	fence(Vector3(0, 0, -2), Vector2(24, 26))
	ModelImport.cover_row(WorldLook.block(lv, Vector3(0, 4.0, -17.5), Vector3(28, 9, 2.4), ROCK_DARK), ["kiyi_kaya", "koy_kaya"], 6.0)
	# the lantern whose light throws the shadow, with its tiny owner
	var lamp := SmallLantern.new()
	lamp.lantern_id = "s3d_fener"
	lamp.accent = "honey"
	lamp.position = LANTERN + Vector3(1.2, 0, 0)
	lv.add_child(lamp)
	lamp.light_up(true)
	_shadow = GiantShadow.new()
	_shadow.position = Vector3(0, 0, -13.0)
	add_child(_shadow)
	_shadow.torch_free.connect(_on_torch_free)
	_shadow.revealed.connect(_on_revealed)
	for i in TORCHES.size():
		var t := BeachTorch.new()
		t.torch_id = "golge_mesale"
		t.position = TORCHES[i]
		lv.add_child(t)
		t.set_locked(true)
		t.lit_up.connect(_on_torch_lit)
		_torches.append(t)


func _on_torch_free(i: int) -> void:
	var t := _torches[clampi(i, 0, _torches.size() - 1)]
	if t.lit:
		return
	t.set_locked(false)
	Effects.sparkle(self, t.global_position + Vector3.UP * 2.0, Color(1.0, 0.8, 0.4), 10)
	Audio.play("blip")
	_hud.show_hint("Bir meşale açıldı! Yıldızın altına git ve yak.", "Meşale açıldı! Git ve yak.")


func _on_torch_lit() -> void:
	var n := _torches.filter(func(t: BeachTorch) -> bool: return t.lit).size()
	_shadow.shrink(n)
	if n < DevGolgePlan.PHASES:
		GameState.bark("s3d_mesale")
		_hud.show_hint("Gölge küçüldü! Halkalardan kaç, sıradaki meşaleyi bekle.", "Küçüldü! Sıradaki meşaleyi bekle.")
		# a potion drops between rounds
		var pk := Pickup.new()
		pk.item_id = "bal_surubu"
		add_child(pk)
		pk.global_position = ARENA + Vector3(randf_range(-4, 4), 0, randf_range(2, 5))


## The shadow is gone: its owner, a tiny crab, trembles by the lantern.
func _on_revealed() -> void:
	boss_camera(false)
	_hud.clear_hint()
	_crab = titrek("titrek_yengec", LANTERN + Vector3(0, 0, 1.6))
	_crab.home = _crab.position
	_crab.listen(9999.0)   # too scared to run: it only waits for a hand
	Beacon.attach(_crab, 2.0, Tokens.color("spark-yellow"))
	GameState.bark("s3d_minik")
	await GameState.dialogue_closed
	_hud.show_hint("Yanına git: ışığın onu ısıtır. Ya da Sakinleş ile el uzat.", "Yanına git, el uzat.")


func _check() -> void:
	var d := GameState.data
	if d.quest_state(QUEST) in ["ready", "done"] and not d.has_flag("s3_sahne4_bitti"):
		d.set_flag("s3_sahne4_bitti")
		if d.quest_state(QUEST) == "ready":
			d.complete_quest(Content.quests[QUEST])
		_end()


func _end() -> void:
	_hud.clear_hint()
	await get_tree().create_timer(1.0, false).timeout
	GameState.bark("s3d_son")
	if DevTools.demo == "shadow" and DisplayServer.get_name() == "headless":
		await close_dialogs()
		var d := GameState.data
		print("S3_SHADOW quest=%s flag=%s hp=%d" % [d.quest_state(QUEST), d.has_flag("s3_sahne4_bitti"), d.hp])
		get_tree().quit()
		return
	await GameState.dialogue_closed
	SceneFlow.go_to("s3_scene5")


func _run_demo(which: String) -> void:
	match which:
		"shadow":
			# stand still through the first round (how much does it hurt?),
			# then light each torch as it comes free, then the tiny crab
			DevTools.auto_dialogue = true
			for i in 3:
				var t := _torches[i]
				for k in 120:
					if not t.locked:
						break
					await get_tree().create_timer(0.25, false).timeout
				print("S3_TORCH free=%d hp=%d scale=%.2f" % [i, GameState.data.hp, _shadow.scale.x])
				_player.global_position = t.global_position + Vector3(0, 0.3, 1.2)
				await get_tree().create_timer(0.4, false).timeout
				_player.interact()
				await close_dialogs()
			for k in 40:
				if _crab:
					break
				await get_tree().create_timer(0.25, false).timeout
			await close_dialogs()
			print("S3_REVEAL crab=%s shadow=%s" % [_crab != null, _shadow.visible])
			_player.global_position = _crab.global_position + Vector3(0, 0.3, 1.2)

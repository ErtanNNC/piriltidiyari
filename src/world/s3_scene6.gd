extends Node3D
## Sezon 3 · Prolog · Sahne 6 – El Ele. Morning on the beach; the Fener's
## light can't get through the Mavi Titreme. Fıstık and Mırıl gather the
## keepers by the Kabuk Kayık: "This time... a hand is needed." Tosbi steps
## forward, trembling but sure. Then the six-keeper select (KeeperSelect
## with Season 3's order and lines) and the prologue is done.

const KEEPER_Z := 0.0
## The keepers stand in a line 11 m wide (six of them), a little wider for
## the eight of Yeni Oyun+.
const LINE_WIDTH := 11.0
const LINE_WIDTH_NG := 13.3
const BLUE := Color(0.7, 0.86, 1.25)

var _keepers: Dictionary = {}   # id -> model node
var _order: Array = []
var _ng := false                # Yeni Oyun+: Hırıl and Tırıl can be chosen too
var _prev: Dictionary = {}      # the keeper offered first {"id", "look"}
var _select: KeeperSelect
@onready var _hud: Hud = $Hud
@onready var _cam: Camera3D = $Camera
var _cam_home: Transform3D
var _cam_tween: Tween


func _ready() -> void:
	WorldLook.add(self, "sabah")
	Pus.set_color(BLUE)
	Pus.set_amount(0.25)
	S3Beach.build_beach(self)
	_cam.make_current()
	if DevTools.demo.begins_with("ngplus"):
		_demo_new_game_plus()
	var d := GameState.data
	_order = (Content.keepers_s3.get("order", KeeperSelect.ORDER) as Array).duplicate()
	_ng = d.has_flag("ng_plus")
	_prev = d.s2_keeper
	if _ng:
		for id: String in Content.keepers_s3.get("ng_plus", []):
			if not _order.has(id) and not Content.keeper(id).is_empty():
				_order.append(id)
		# the keeper who finished the last run is offered first, as they looked
		_prev = {"id": d.character_id, "look": d.character_look}
	for i in _order.size():
		var id: String = _order[i]
		var look: Dictionary = _prev.get("look", {}) if _prev.get("id", "") == id else {}
		var m := KeeperModels.build(id, look)
		add_child(m)
		m.position = _slot(i)
		if id == "tosbi":
			m.position = Vector3(8.0, 0, -3.0)   # hangs back until his beat
			m.rotation.y = -0.8
		_keepers[id] = m
	var f := FistikModel.build()
	add_child(f)
	f.position = Vector3(-7.4, 0, -1.6)
	f.rotation.y = 0.6
	var mi := MirilModel.star_child()
	MobModels._no_pus(mi)
	add_child(mi)
	mi.position = Vector3(-8.6, 0.4, -0.2)
	mi.rotation.y = 0.8
	var nine := NpcModels.build("turtle")
	add_child(nine)
	nine.position = Vector3(8.4, 0, -0.8)
	nine.rotation.y = -0.7
	# the drum Hırıl left, still beating slowly
	var drum := Node3D.new()
	Toon.part(drum, "cylinder", Vector3(0.9, 0.6, 0.9), Color("#c9452f"), Vector3(0, 0.3, 0))
	Toon.part(drum, "cylinder", Vector3(0.95, 0.08, 0.95), Color("#fff1dc"), Vector3(0, 0.62, 0))
	add_child(drum)
	drum.position = Vector3(0, 0, -5.5)
	_beat(drum)
	await get_tree().create_timer(1.9, false).timeout
	if DevTools.demo == "ngplus_select":
		open_select()  # straight to the eight cards (screenshot)
		return
	var cs := CutscenePlayer.new()
	cs.scene = self
	cs.camera = _cam
	cs.hud = _hud
	add_child(cs)
	cs.play("el_ele")


## Where keeper `i` of the line stands.
func _slot(i: int) -> Vector3:
	var n := maxi(_order.size(), 2)
	var width := LINE_WIDTH_NG if n > 6 else LINE_WIDTH
	return Vector3((float(i) / (n - 1) - 0.5) * width, 0, KEEPER_Z)


func _beat(drum: Node3D) -> void:
	while is_inside_tree():
		Effects.ring(self, drum.position + Vector3.UP * 0.4, 2.2, Tokens.color("hp"), 0.6)
		var tw := create_tween()
		tw.tween_property(drum, "scale", Vector3(1.1, 0.9, 1.1), 0.08)
		tw.tween_property(drum, "scale", Vector3.ONE, 0.2)
		await get_tree().create_timer(1.1, false).timeout


func _process(_delta: float) -> void:
	for id: String in _keepers:
		var m: Node3D = _keepers[id]
		if _select and _select.current == id:
			m.position.y = absf(sin(Time.get_ticks_msec() / 160.0)) * 0.15
		elif is_instance_valid(m):
			m.position.y = move_toward(m.position.y, 0.0, 0.02)


# --- beats -------------------------------------------------------------

## Tosbi steps into the line: trembling, but he steps.
func tosbi_steps() -> void:
	var i := _order.find("tosbi")
	var m: Node3D = _keepers["tosbi"]
	var to := _slot(i)
	var rig := CharacterRig.of(m)
	if rig:
		rig.speed = 1.0
	var tw := create_tween()
	tw.tween_property(m, "position", to, 1.8)
	tw.tween_callback(func() -> void:
		if rig:
			rig.speed = 0.0
		m.rotation.y = 0.0
		Effects.sparkle(self, to + Vector3.UP, Tokens.color("spark-green"), 10))


func open_select() -> void:
	await get_tree().process_frame  # after the cutscene hands the HUD back
	_hud.cinematic(true)
	_cam_home = _cam.global_transform
	_select = KeeperSelect.new()
	_select.order = _order
	_select.lines = Content.keepers_s3.get("lines", {})
	_hud.add_child(_select)
	_select.highlighted.connect(_on_highlight)
	_select.look_changed.connect(_on_look)
	_select.chosen.connect(_on_chosen)
	var back: String = _prev.get("id", "")
	if DevTools.demo == "ngplus_select":
		_select.select("tiril")
		return
	if DevTools.demo.begins_with("pick_") or DevTools.demo.begins_with("ngplus_"):
		var who := DevTools.demo.get_slice("_", 1) if DevTools.demo.begins_with("ngplus_") else DevTools.demo.substr(5)
		_select.select(who)
		await get_tree().create_timer(1.0, false).timeout
		_select.chosen.emit(who, {}, String(Content.keeper(who).get("name", who)))
		return
	if back in _order:
		_select.select(back)  # Season 2's keeper is the first one offered


func _on_highlight(id: String) -> void:
	var i := _order.find(id)
	_focus_camera(id)
	for k: String in _keepers:
		var m: Node3D = _keepers[k]
		var t2 := create_tween()
		t2.tween_property(m, "rotation:y", 0.0 if k == id else (0.5 if m.position.x < _slot(i).x else -0.5), 0.3)


func _on_look(id: String, look: Dictionary) -> void:
	var old: Node3D = _keepers[id]
	var m := KeeperModels.build(id, look)
	add_child(m)
	m.position = old.position
	old.queue_free()
	_keepers[id] = m


func _on_chosen(id: String, look: Dictionary, display_name: String) -> void:
	_select.queue_free()
	_select = null
	var d := GameState.data
	if look.is_empty() and _prev.get("id", "") == id:
		look = _prev.get("look", {})
	if _ng:
		# Yeni Oyun+: level, XP and powers go on with whoever is chosen
		var lv := d.level
		var x := d.xp
		d.choose_keeper(id, Content.keeper(id)["stats"], look, display_name)
		d.level = lv
		d.xp = x
		d.recompute_stats(Content.items)
		d.learn_season_skill()
		d.mp = d.max_mp
	else:
		# the prologue's level-ups were Hırıl's: the keeper sets out fresh
		d.powers = {}
		d.power_picks = 0
		d.choose_keeper(id, Content.keeper(id)["stats"], look, display_name)
		d.recompute_stats(Content.items)
	d.hp = d.max_hp
	d.set_flag("s3_prolog_bitti")
	d.scene_id = "s3_chapter0"  # Devam et goes on from the cove, not this choice again
	SaveGame.write(d)
	var m: Node3D = _keepers[id]
	Effects.ring(self, m.global_position + Vector3.UP * 0.2, 3.0, Tokens.color("sky"), 0.5)
	Effects.sparkle(self, m.global_position + Vector3.UP, Tokens.color("honey"), 14)
	_hud.cinematic(false)
	GameState.bark("s6c_son")
	await GameState.dialogue_closed
	if DevTools.demo.begins_with("ngplus_") and DisplayServer.get_name() == "headless":
		var built := KeeperModels.build(d.character_id, d.character_look)
		print("NGPLUS_PICK id=%s name=%s level=%d skill=%s skills=%s model=%s rig=%s hp=%d/%d scene_next=%s" % [d.character_id, d.character_name, d.level, d.active_skill(), ",".join(d.skills), ModelImport.path_for(d.character_id).get_file(), CharacterRig.of(built) != null, d.hp, d.max_hp, d.scene_id])
		built.free()
		get_tree().quit()
		return
	if DevTools.demo.begins_with("pick_") and DisplayServer.get_name() == "headless":
		print("S6C_PICK id=%s name=%s level=%d skill=%s flag=%s season=%d" % [d.character_id, d.character_name, d.level, d.active_skill(), d.has_flag("s3_prolog_bitti"), d.season])
		get_tree().quit()
		return
	var panel := PrologueDone.new()
	_hud.add_child(panel)
	var to: String = await panel.chosen
	SceneFlow.go_to(to, to != "title")


func _focus_camera(id: String) -> void:
	var m: Node3D = _keepers.get(id)
	if m == null:
		return
	var at := m.global_position
	var home := _cam_home
	var from := home.origin + Vector3((at.x - home.origin.x) * 0.35, 0.5, -1.2)
	var look := Transform3D(Basis(), from).looking_at(at + Vector3(0, -0.6, 0), Vector3.UP)
	var target := Transform3D(home.basis.slerp(look.basis, 0.45), from)
	if _cam_tween:
		_cam_tween.kill()
	_cam_tween = create_tween()
	_cam_tween.tween_property(_cam, "global_transform", target, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# --- demo ---------------------------------------------------------------

## --demo=ngplus_<id> / ngplus_select: a save that finished Season 3 (level,
## Pırıl, an owned outfit, pearls, torches, quests), then Yeni Oyun+.
func _demo_new_game_plus() -> void:
	var d := GameState.data
	d.powers = {}
	d.power_picks = 0
	d.choose_keeper("pati", Content.keeper("pati")["stats"], {"variant": 1, "accessory": "atki"}, "Pati")
	while d.level < 12:
		d.add_xp(Progression.xp_to_next(d.level) - d.xp)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	while d.power_picks > 0:
		Powers.pick(d, Powers.choices(d.powers, rng)[0]["id"])
	d.add_piril(345)
	d.add_item("sicak_kakao", 2)
	d.set_flag("owned_kasif_sapkasi")
	d.equipped["outfit"] = "kasif_sapkasi"
	for f: String in ["s3_prolog_bitti", "s3_fisek0", "s3_fisek1", "s3_bolum0_bitti", "s3_bolum1_bitti", "s3_bolum5_bitti",
			"inci_lacivert", "inci_turkuaz", "inci_kum", "inci_gumus", "inci_beyaz", "s3_chapter1_m1", "s3_chapter1_m2",
			"s3c1_perde", "s3c1_geldi", "s3k2_ruzgar", "s3_kaleler", "yan_sise_bitti", "s2_can0", "kor_al",
			"sezon3_bitti", "sezon3_senlik"]:
		d.set_flag(f)
	var ids := SeasonFlow.s3_story_quests()
	for i in mini(ids.size(), 4):
		d.quests[ids[i]] = {"state": "done", "objectives": {}, "ordered": false}
	d.quests["eski_gorev"] = {"state": "done", "objectives": {}, "ordered": false}   # not Season 3's: stays
	d.hp = 10
	var can := d.can_start_new_game_plus()
	d.start_new_game_plus(Content.items, ids)
	d.start_new_game_plus(Content.items, ids)   # twice is the same as once
	var left := 0
	var pearls := 0
	for f: String in d.flags:
		if f.begins_with("inci_"):
			pearls += 1
		if f.begins_with("s3") or f.begins_with("inci_"):
			left += 1
	var quests_left := 0
	for q: String in ids:
		if d.quests.has(q):
			quests_left += 1
	print("NGPLUS_RESET can=%s level=%d piril=%d kakao=%d owned=%s outfit=%s powers=%d pearls=%d s3_flags_left=%d quests_left=%d/%d other_quest=%s yan=%s s2=%s sezon3=%s senlik=%s ng=%s runs=%d again=%s hp=%d/%d season=%d scene=%s keeper=%s" % [
		can, d.level, d.piril, d.item_count("sicak_kakao"), d.has_flag("owned_kasif_sapkasi"), d.equipped.get("outfit", ""),
		d.powers.size(), pearls, left, quests_left, ids.size(), d.quests.has("eski_gorev"), d.has_flag("yan_sise_bitti"),
		d.has_flag("s2_can0") and d.has_flag("kor_al"), d.has_flag("sezon3_bitti"), d.has_flag("sezon3_senlik"),
		d.has_flag("ng_plus"), d.ng_plus_runs, d.can_start_new_game_plus(), d.hp, d.max_hp, d.season, d.scene_id, d.character_id])

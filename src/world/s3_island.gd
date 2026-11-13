class_name S3Island
extends ChapterBase
## Season 3: what every island of Titrek Kıyılar shares. An island is a
## floor in the night sea with a pier (`dock`), torches that stay lit,
## Titrekler, an İşaret Fişeği that pushes the Mavi Titreme back, a
## Titreme Perdesi in front of the keeper's place and the keeper itself (a
## `ShoreBoss`): fight → it trembles → a hand (Sakinleş) → its pearl.
##
## A chapter script builds its map with these helpers and overrides
## `fight_ready()`, `_on_flare()`, `_on_boss_calmed()` and `_on_pearl()`.

const BLUE := Color(0.7, 0.86, 1.25)
const SEA_Y := -0.35

var lv: Node3D
var scene_id := ""
var boss: ShoreBoss
var arena := Vector3.ZERO
var flare_flag := ""
## The Titreme barı's fill speed before / after the island's flare burns.
var cold_before := 1.0
var cold_after := 0.0
var fighting := false
var _torch_n := 0


## The level node, the mood, the blue mist and the night sea all round.
func begin(id: String, mood := "ada") -> Node3D:
	scene_id = id
	WorldLook.add(self, mood)
	Pus.set_color(BLUE)
	lv = Node3D.new()
	lv.name = "Level"
	add_child(lv)
	var sea := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(260, 260)
	plane.subdivide_width = 48
	plane.subdivide_depth = 48
	sea.mesh = plane
	sea.position.y = SEA_Y
	WorldLook.water(sea, "sea_night")
	lv.add_child(sea)
	# the way on shows as soon as the island is done (the flag is set after
	# the quest closes, so a quest signal alone would miss it)
	GameState.data.flags_changed.connect(_way_on)
	get_tree().create_timer(3.0, false).timeout.connect(_way_on)
	return lv


## The island is finished and the next one isn't started: a star on the
## pier and a hint to board the Kabuk Kayık.
func _way_on() -> void:
	var d := GameState.data
	var n := int(scene_id.right(1))
	var next := "s3_chapter%d" % (n + 1)
	if not scene_id.begins_with("s3_chapter") or not ShoreTravel.ISLANDS.has(next) or not is_inside_tree():
		return
	if not d.has_flag("s3_bolum%d_bitti" % n) or d.has_flag("s3_fisek%d" % (n + 1)):
		return
	var dk := lv.get_node_or_null("Dock") as Node3D
	if dk == null or dk.has_node("Beacon"):
		return
	Beacon.attach(dk, 3.0, Tokens.color("spark-white"))
	var region := TranslationServer.translate(ShoreTravel.region(next))
	_hud.show_hint(TranslationServer.translate("İskeledeki Kabuk Kayık'a bin: %s yolu açıldı!") % region,
		TranslationServer.translate("İskeleye git, kayığa bin: %s") % region)
	GameState.toast.emit(TranslationServer.translate("Yeni yer açıldı: %s") % region, "star")


## A piece of island: a walkable block whose top is at `top` (0 = shore).
func land(center: Vector3, size: Vector2, col: Color, top := 0.0, thick := 3.0) -> StaticBody3D:
	return WorldLook.block(lv, Vector3(center.x, top - thick * 0.5, center.z), Vector3(size.x, thick, size.y), col, 0.0)


## Invisible walls round the walkable rectangle (nobody walks into the sea).
func fence(center: Vector3, size: Vector2) -> void:
	for k in 4:
		var wall := StaticBody3D.new()
		wall.set_meta("camera_ignore", true)   # the camera looks over the sea
		var c := CollisionShape3D.new()
		var b := BoxShape3D.new()
		var along_x := k < 2
		b.size = Vector3(size.x + 2.0, 12.0, 1.0) if along_x else Vector3(1.0, 12.0, size.y + 2.0)
		c.shape = b
		wall.add_child(c)
		var s := -1.0 if k % 2 == 0 else 1.0
		wall.position = center + (Vector3(0, 6, s * (size.y * 0.5 + 0.5)) if along_x else Vector3(s * (size.x * 0.5 + 0.5), 6, 0))
		lv.add_child(wall)


func dock(at: Vector3, yaw := 0.0) -> BoatDock:
	var d := BoatDock.new()
	d.name = "Dock"
	d.here = scene_id
	d.position = at
	d.rotation.y = yaw
	lv.add_child(d)
	return d


## A torch that stays lit once lit (flag "<scene>_m<n>").
func torch(at: Vector3, target := "mesale") -> BeachTorch:
	var t := BeachTorch.new()
	t.torch_id = target
	t.save_flag = "%s_m%d" % [scene_id, _torch_n]
	_torch_n += 1
	t.position = at
	lv.add_child(t)
	return t


func titrek(kind: String, at: Vector3) -> Titrek:
	var t := Titrek.new()
	t.kind = kind
	t.position = at
	add_child(t)
	return t


func titreks(list: Array) -> void:
	for e: Array in list:
		titrek(e[0], e[1])


func flare(at: Vector3, id: String, needs := "", locked_bark := "") -> SignalFlare:
	flare_flag = id
	var f := SignalFlare.new()
	f.name = "Flare"
	f.flare_id = id
	f.needs = needs
	f.locked_bark = locked_bark
	f.position = at
	lv.add_child(f)
	f.fired.connect(func(_f: SignalFlare) -> void:
		Pus.fade_to(self, 0.06, 3.0)
		_on_flare())
	return f


func veil(at: Vector3, width: float, flag: String, hand_only := false, yaw := 0.0) -> ShiverVeil:
	var v := ShiverVeil.new()
	v.open_flag = flag
	v.width = width
	v.hand_only = hand_only
	if not hand_only:
		v.hint = "Sis çok koyu. Önce adanın İşaret Fişeği'ni yak."
	v.position = at
	v.rotation.y = yaw
	lv.add_child(v)
	return v


func friend(id: String, model_id: String, at: Vector3, goal := Vector3.INF) -> HandFriend:
	var f := HandFriend.new()
	f.friend_id = id
	f.model_id = model_id
	f.goal = goal
	f.position = at
	add_child(f)
	return f


## The island keeper at `at` (its arena). `calm` = the fight is over.
func make_boss(id: String, at: Vector3, calm := false) -> ShoreBoss:
	arena = at
	boss = ShoreBoss.new()
	boss.name = "Boss"
	boss.setup(id)
	add_child(boss)
	boss.position = at
	boss.home = at
	boss.hp_changed.connect(func(h: int, m: int) -> void: _hud.set_boss_hp(h, m))
	boss.phase_changed.connect(_on_phase)
	boss.sad.connect(_on_boss_sad)
	boss.calmed.connect(_on_boss_calmed)
	if calm:
		boss.set_calm()
	return boss


func start_fight(bark_id: String, hint: String, hint_touch: String) -> void:
	fighting = true
	boss_camera(true, arena, 0.4, 19.0)
	if bark_id != "":
		GameState.bark(bark_id)
		await GameState.dialogue_closed
	_hud.show_boss(String(ShorePlan.BOSSES[boss.boss_id]["name"]), boss.hp, boss.max_hp)
	_hud.show_hint(hint, hint_touch)
	boss.start()


func _on_phase(_p: int) -> void:
	for id: String in ["bal_surubu", "sicak_kakao"]:
		var pk := Pickup.new()
		pk.item_id = id
		add_child(pk)
		pk.global_position = arena + Vector3(randf_range(-5, 5), 0, randf_range(3, 6))


func _on_boss_sad() -> void:
	_hud.hide_boss()
	_hud.show_hint("Korkuyor. Yanına git, Sakinleş'e basılı tut: el uzat.", "Yanına git, Sakinleş'e basılı tut!")


func _on_boss_calmed() -> void:
	pass


func _on_flare() -> void:
	pass


func _on_pearl(_id: String) -> void:
	pass


## The island's pearl hovering at `at`: walking into it takes it (flag
## "inci_<id>", event "collect"/"inci").
func drop_pearl(id: String, at: Vector3, title: String, sub: String) -> void:
	if GameState.data.has_flag("inci_" + id):
		return
	var col: Color = PearlTracker.COLORS[id]
	var pearl := Node3D.new()
	pearl.name = "Pearl"
	add_child(pearl)
	pearl.position = at + Vector3.UP * 1.2
	Toon.part(pearl, "sphere", Vector3(0.7, 0.7, 0.7), col, Vector3.ZERO, Vector3.ZERO, 2.0, 0.03)
	var l := OmniLight3D.new()
	l.light_color = col.lightened(0.3)
	l.omni_range = 5.0
	l.light_energy = 2.0
	pearl.add_child(l)
	Beacon.attach(pearl, 1.4, col.lightened(0.3))
	var tw := pearl.create_tween().set_loops()
	tw.tween_property(pearl, "position:y", at.y + 1.5, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(pearl, "position:y", at.y + 1.2, 0.8).set_trans(Tween.TRANS_SINE)
	var t := TriggerArea.new()
	t.area_id = "inci_" + id
	t.radius = 1.4
	add_child(t)
	t.position = at
	t.reached.connect(func() -> void:
		GameState.data.set_flag("inci_" + id)
		GameState.notify("collect", "inci")
		Effects.ring(self, pearl.global_position, 3.0, col, 0.5)
		Effects.sparkle(self, pearl.global_position, col.lightened(0.3), 20)
		Audio.play("fanfare")
		pearl.queue_free()
		_hud.show_scene_card("İnci", title, sub)
		_on_pearl(id))


## Override: true when the fight should begin as the keeper walks in.
func fight_ready() -> bool:
	return false


func _process(_delta: float) -> void:
	if _player.ring:
		_player.ring.cold = cold_after if flare_flag != "" and GameState.data.has_flag(flare_flag) else cold_before
	if boss and not fighting and not GameState.in_dialogue and fight_ready() \
			and _player.global_position.distance_to(arena) < 10.0:
		_begin_fight()


## Override to start the fight with the chapter's own lines.
func _begin_fight() -> void:
	start_fight("", "Halkalardan kaç. Soluklanınca vur!", "Halkalardan kaç, soluklanınca vur!")


## The mist at arrival: thin once the flare burns.
func mist(before := 0.5) -> void:
	Pus.set_amount(0.06 if flare_flag != "" and GameState.data.has_flag(flare_flag) else before)


## A scenery model standing on the ground (no collision), `h` tall.
func prop(id: String, at: Vector3, h: float, yaw := 0.0) -> Node3D:
	var m := ModelImport.prop_copy(id)
	if m == null:
		return null
	var b := ModelImport.static_bounds(id)
	var s := h / maxf(b.size.y, 0.01)
	var holder := Node3D.new()
	lv.add_child(holder)
	holder.position = at
	holder.rotation.y = yaw
	holder.add_child(m)
	m.scale = Vector3.ONE * s
	m.position = -Vector3(b.position.x + b.size.x * 0.5, b.position.y, b.position.z + b.size.z * 0.5) * s
	return holder


# --- demo helpers ---------------------------------------------------------

func _talk(npc_id: String, node_name: String) -> void:
	var n := get_node(node_name) as Node3D
	_player.global_position = n.global_position + Vector3(0, 0.3, 1.8)
	await get_tree().create_timer(0.3, false).timeout
	GameState.talk_to(npc_id)
	await close_dialogs()


## Demo: drum every Titrek still, then stand next to it.
func _calm_all() -> void:
	for i in 40:
		var left := get_tree().get_nodes_in_group("titrek").filter(func(t: Titrek) -> bool: return t.state != "calm")
		if left.is_empty():
			break
		var t: Titrek = left[0]
		_player.global_position = t.global_position + Vector3(0, 0.3, 5.5)
		for k in 4:
			_player.spin_attack()
			await get_tree().create_timer(0.6, false).timeout
		_player.global_position = t.global_position + Vector3(0, 0.3, 1.2)
		await get_tree().create_timer(0.6, false).timeout


## Demo: wait for the fight, hit the keeper whenever it is tired, then hold
## out a hand (Sakinleş) once it trembles.
func _beat_boss() -> void:
	for i in 80:
		if fighting:
			break
		await get_tree().create_timer(0.25, false).timeout
	await close_dialogs()
	for i in 2400:
		if boss.is_sad or not boss.active and boss.hp <= 0:
			break
		if boss.tired:
			boss.hit(60, _player.global_position, 0.0)
		await get_tree().create_timer(0.1, false).timeout
		if GameState.data.hp < 30:
			GameState.data.heal(100)
	await close_dialogs()
	_player.global_position = boss.global_position + Vector3(0, 0.3, 1.6)
	await get_tree().create_timer(0.3, false).timeout
	Input.action_press("calm")
	for i in 60:
		if not boss.is_sad:
			break
		await get_tree().create_timer(0.2, false).timeout
	Input.action_release("calm")
	await close_dialogs()
	await get_tree().create_timer(0.5, false).timeout
	await close_dialogs()

class_name S4Garden
extends S3Island
## Season 4: what every garden of Dikenli Bahçeler shares (built on the
## island base: `land`, `fence`, `prop`, `make_boss`, `start_fight`, the demo
## helpers). A garden is a walled daylight place with a Bahar Kapısı
## (`gate`), Yeşil Diken clumps (`thorns`), soil to plant in (`plot`),
## Dikenciler (`dikenci`: Mobs that sit dazed at 0 HP until someone claps),
## an ark sluice (`ark`) that lets the water run again, and the garden's
## jealous keeper (a `ShoreBoss` from `ShorePlan`): fight → it sulks → Alkış
## → it sees what it has → its Bahar Tohumu (`drop_seed`).
##
## A chapter script builds its map with these helpers and overrides
## `fight_ready()`, `_on_ark()`, `_on_boss_calmed()` and `_on_seed()`.
## `night` is read by SeedPlots (Gece Çiçeği opens only at night).

const GREEN := Color(0.62, 1.1, 0.6)

var night := false
var ark_flag := ""
var _thorn_n := 0
var _plot_n := 0


## The level node, the daylight mood and the green haze of the Yeşil Diken.
func begin_garden(id: String, mood := "sabah") -> Node3D:
	scene_id = id
	cold_before = 0.0
	cold_after = 0.0
	WorldLook.add(self, mood)
	Pus.set_color(GREEN)
	lv = Node3D.new()
	lv.name = "Level"
	add_child(lv)
	GameState.data.flags_changed.connect(_gate_star)
	get_tree().create_timer(3.0, false).timeout.connect(_gate_star)
	return lv


## The garden is finished and the next one isn't visited yet: a star on the
## Bahar Kapısı and a hint.
func _gate_star() -> void:
	var d := GameState.data
	if not is_inside_tree() or not scene_id.begins_with("s4_chapter"):
		return
	var n := int(scene_id.right(1))
	var next := "s4_chapter%d" % (n + 1)
	if not GardenTravel.GARDENS.has(next) or not d.has_flag("s4_bolum%d_bitti" % n) or d.has_flag("s4_geldi%d" % (n + 1)):
		return
	var g := lv.get_node_or_null("Gate") as Node3D
	if g == null or g.has_node("Beacon"):
		return
	Beacon.attach(g, 4.6, Tokens.color("spark-white"))
	var region := TranslationServer.translate(GardenTravel.region(next))
	_hud.show_hint(TranslationServer.translate("Bahar Kapısı çiçek açtı: %s yolu açıldı!") % region,
		TranslationServer.translate("Bahar Kapısı'na git: %s") % region)
	GameState.toast.emit(TranslationServer.translate("Yeni yer açıldı: %s") % region, "star")


## The Bahar Kapısı (travel between gardens). Marks this garden as visited.
func gate(at: Vector3, yaw := 0.0) -> SpringGate:
	GameState.data.set_flag("s4_geldi%s" % scene_id.right(1))
	var g := SpringGate.new()
	g.name = "Gate"
	g.here = scene_id
	g.position = at
	g.rotation.y = yaw
	lv.add_child(g)
	return g


## The garden's ark sluice. Opening it thins the green haze and calls
## `_on_ark()`.
func ark(at: Vector3, id: String, needs := "", locked_bark := "", yaw := 0.0) -> ArkGate:
	ark_flag = id
	var a := ArkGate.new()
	a.name = "Ark"
	a.ark_id = id
	a.needs = needs
	a.locked_bark = locked_bark
	a.position = at
	a.rotation.y = yaw
	lv.add_child(a)
	a.opened.connect(func(_a: ArkGate) -> void:
		Pus.fade_to(self, 0.04, 3.0)
		_on_ark())
	return a


## A clump of Yeşil Diken `width` wide. `blocks`: a wall across the path.
## `clap`: it draws back when someone claps beside it (event "clap"/clap_id).
## It stays open through its flag ("<scene>_d<n>").
func thorns(at: Vector3, width := 4.0, blocks := true, clap := false, clap_id := "", yaw := 0.0) -> ThornPatch:
	var t := ThornPatch.new()
	t.name = "Thorns%d" % _thorn_n
	t.size = Vector3(width, 2.2, 1.6)
	t.blocks = blocks
	t.clap_opens = clap
	t.clap_id = clap_id
	t.open_flag = "%s_d%d" % [scene_id, _thorn_n]
	_thorn_n += 1
	t.position = at
	t.rotation.y = yaw
	lv.add_child(t)
	return t


## Soil to plant in: `kind` from `Growth.KINDS`; `span` = where a bridge or
## ladder leads (relative). Stays grown through its flag ("<scene>_t<n>").
func plot(at: Vector3, kind: String, span := Vector3(0, 0, -5.0), yonca_only := false) -> SeedPlot:
	var p := SeedPlot.new()
	p.name = "Plot%d" % _plot_n
	p.kind = kind
	p.span = span
	p.yonca_only = yonca_only
	p.plot_flag = "%s_t%d" % [scene_id, _plot_n]
	_plot_n += 1
	p.position = at
	lv.add_child(p)
	return p


## A Dikenci (a Mob that sits dazed at 0 HP until someone claps for it).
func dikenci(kind: String, at: Vector3) -> Mob:
	return Mob.spawn(self, kind, at)


func dikenciler(list: Array) -> void:
	for e: Array in list:
		dikenci(e[0], e[1])


## The mist at arrival: thin once the ark runs.
func haze(before := 0.3) -> void:
	Pus.set_amount(0.04 if ark_flag != "" and GameState.data.has_flag(ark_flag) else before)


func _on_ark() -> void:
	pass


func _on_seed(_id: String) -> void:
	pass


func _on_boss_sad() -> void:
	_hud.hide_boss()
	_hud.show_hint("Küstü, kendi güzelliğini göremiyor. Yanına git, Alkış'a bas!", "Yanına git, Alkış'a bas!")


## The garden's Bahar Tohumu hovering at `at`: walking into it takes it (flag
## "tohum_<id>", event "collect"/"tohum").
func drop_seed(id: String, at: Vector3, title: String, sub: String) -> void:
	if GameState.data.has_flag("tohum_" + id):
		return
	var col: Color = SeedTracker.COLORS[id]
	var seed := Node3D.new()
	seed.name = "Seed"
	add_child(seed)
	seed.position = at + Vector3.UP * 1.2
	Toon.part(seed, "ellipsoid", Vector3(0.5, 0.75, 0.5), Color("#a8794f"), Vector3.ZERO, Vector3.ZERO, 0.6, 0.03)
	Toon.part(seed, "sphere", Vector3(0.28, 0.28, 0.28), col, Vector3(0, 0.45, 0), Vector3.ZERO, 2.0, 0.02)
	var l := OmniLight3D.new()
	l.light_color = col.lightened(0.3)
	l.omni_range = 5.0
	l.light_energy = 1.6
	seed.add_child(l)
	Beacon.attach(seed, 1.4, col.lightened(0.3))
	var tw := seed.create_tween().set_loops()
	tw.tween_property(seed, "position:y", at.y + 1.5, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(seed, "position:y", at.y + 1.2, 0.8).set_trans(Tween.TRANS_SINE)
	var t := TriggerArea.new()
	t.area_id = "tohum_" + id
	t.radius = 1.4
	add_child(t)
	t.position = at
	t.reached.connect(func() -> void:
		if GameState.data.has_flag("tohum_" + id):
			return
		GameState.data.set_flag("tohum_" + id)
		GameState.notify("collect", "tohum")
		Effects.ring(self, seed.global_position, 3.0, col, 0.5)
		Effects.sparkle(self, seed.global_position, col.lightened(0.3), 20)
		Audio.play("fanfare")
		seed.queue_free()
		_hud.show_scene_card("Bahar Tohumu", title, sub)
		_on_seed(id))


## Demo: beat every Dikenci, then clap for the dazed ones.
func _calm_dikenciler() -> void:
	for i in 60:
		var left := get_tree().get_nodes_in_group("mob").filter(func(m: Node) -> bool: return (m as Mob) != null and (m as Mob).state != "calm")
		left.append_array(get_tree().get_nodes_in_group("dazed").filter(func(m: Node) -> bool: return m is Mob and (m as Mob).state != "calm" and not left.has(m)))
		if left.is_empty():
			break
		var m: Mob = left[0]
		_player.global_position = m.global_position + Vector3(0, 0.3, 1.4)
		await get_tree().create_timer(0.15, false).timeout
		if m.state != "dazed":
			m.hit(9999, _player.global_position, 0.0)
			await get_tree().create_timer(0.3, false).timeout
		if _player.clap:
			_player.clap._cd = 0.0
			_player.clap.clap()
		await get_tree().create_timer(0.3, false).timeout
		if GameState.data.hp < 30:
			GameState.data.heal(100)

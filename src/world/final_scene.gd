extends Node3D
## Kapanış (end of Season 1). In the village: the five sparks rejoin the
## Büyük Kıvılcım, the Fener burns in six colors, Fıstık wakes up, a new
## Yıldız Şenliği with Mırıl's first birthday cake, the keeper's own closing
## line, and far away a red mist... Then the season summary.

const COLORS := ["spark-green", "spark-blue", "spark-yellow", "spark-white", "spark-purple", "berry"]

@onready var _hud: Hud = $Hud
@onready var _cam: Camera3D = $Camera
var _keeper: Node3D
var _statue: Node3D
var _miril: Node3D
var _crystal: MeshInstance3D
var _candles: Array[MeshInstance3D] = []


func _ready() -> void:
	Pus.set_amount(0.25)
	_cam.make_current()
	var d := GameState.data
	_keeper = KeeperModels.build(d.character_id, d.character_look) if d.character_id != "fistik" else FistikModel.build()
	add_child(_keeper)
	_keeper.position = Vector3(1.5, 0, -2.5)
	_keeper.rotation.y = PI
	_statue = Node3D.new()
	add_child(_statue)
	_statue.position = Vector3(-4.6, 0, -12.6)
	Toon.part(_statue, "cylinder", Vector3(1.6, 1.0, 1.8), Color("#b9b0a4"), Vector3(0, 0.5, 0))
	var stone := FistikModel.build(true)
	stone.position.y = 1.0
	stone.name = "Stone"
	_statue.add_child(stone)
	_miril = MirilModel.star_child()
	add_child(_miril)
	_miril.position = Vector3(-1.2, 0, -3.0)
	_miril.rotation.y = PI * 0.8
	# friends gathered for the festival
	var friends := [["turtle", Vector3(3.5, 0, -6.5), -30], ["bunny", Vector3(-3.0, 0, -0.5), 20], ["duckling", Vector3(4.5, 0, -1.5), -40],
		["frog", Vector3(-4.5, 0, -2.5), 30], ["owl_teacher", Vector3(6.5, 0, -4.5), -50], ["mole", Vector3(-6.5, 0, -5.5), 40],
		["gull_captain", Vector3(6.0, 0, 0.5), -60], ["snowman", Vector3(-7.0, 0, 0.0), 50]]
	for f: Array in friends:
		var m := NpcModels.build(f[0])
		add_child(m)
		m.position = f[1]
		m.rotation_degrees.y = f[2] + 180.0
	# the birthday cake
	WorldLook.block(self, Vector3(0, 0.45, -4.6), Vector3(2.6, 0.9, 1.4), Color("#c98d5e"))
	Toon.part(self, "cylinder", Vector3(1.0, 0.5, 1.0), Color("#ffd1dc"), Vector3(0, 1.15, -4.6))
	Toon.part(self, "cylinder", Vector3(0.8, 0.35, 0.8), Color("#fff4d6"), Vector3(0, 1.55, -4.6))
	for i in 5:
		var a := TAU * i / 5.0
		Toon.part(self, "cylinder", Vector3(0.06, 0.3, 0.06), ["berry", "sky", "spark-yellow", "leaf", "spark-purple"][i], Vector3(cos(a) * 0.25, 1.85, -4.6 + sin(a) * 0.25), Vector3.ZERO, 0.0, 0.0)
		_candles.append(Toon.part(self, "sphere", Vector3(0.1, 0.16, 0.1), "honey", Vector3(cos(a) * 0.25, 2.06, -4.6 + sin(a) * 0.25), Vector3.ZERO, 2.0, 0.0))
	_crystal = $Village/FenerKulesi.get_node_or_null("BuyukKivilcim")
	if _crystal:
		_crystal.visible = false
	await get_tree().create_timer(1.9).timeout
	var cs := CutscenePlayer.new()
	cs.scene = self
	cs.camera = _cam
	cs.hud = _hud
	add_child(cs)
	cs.play("final")


func sparks_to_tower() -> void:
	var top := Vector3(0, 13.6, -17)
	for i in 5:
		var orb := Toon.part(self, "sphere", Vector3(0.7, 0.9, 0.7), COLORS[i], _keeper.global_position + Vector3(0, 1.2, 0), Vector3.ZERO, 1.4, 0.03)
		var tw := orb.create_tween()
		tw.tween_interval(i * 0.25)
		tw.tween_property(orb, "global_position", top, 1.6).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(orb.queue_free)
	Effects.sparkle(self, _miril.global_position + Vector3.UP, Tokens.color("spark-white"), 16)


## The Fener burns in six colors (the sixth is Mırıl's).
func tower_rainbow() -> void:
	var gem := Toon.part(self, "sphere", Vector3(1.6, 2.2, 1.6), "spark-white", Vector3(0, 13.6, -17), Vector3.ZERO, 2.0, 0.05)
	var l := OmniLight3D.new()
	l.omni_range = 22.0
	l.light_energy = 2.0
	gem.add_child(l)
	var tw := gem.create_tween().set_loops()
	for c in COLORS:
		tw.tween_callback(func() -> void:
			gem.material_override = Toon.material(c, 0.05, 2.0, 0.0)
			l.light_color = Tokens.color(c))
		tw.tween_interval(0.5)
	for i in 6:
		Effects.ring(self, Vector3(0, 13.6, -17), 6.0 + i, Tokens.color(COLORS[i]), 0.6 + i * 0.1)


func fistik_wakes() -> void:
	var stone := _statue.get_node("Stone")
	Effects.sparkle(self, stone.global_position + Vector3.UP, Tokens.color("honey"), 20)
	stone.queue_free()
	var f := FistikModel.build()
	f.position.y = 1.0
	_statue.add_child(f)
	var tw := f.create_tween()
	tw.tween_property(f, "position:y", 1.4, 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_property(f, "position:y", 1.0, 0.2)


func badge() -> void:
	var b := Toon.part(_keeper, "cone", Vector3(0.25, 0.35, 0.12), "honey", Vector3(0.2, 0.95, 0.42), Vector3.ZERO, 1.2, 0.02)
	Effects.sparkle(self, b.global_position, Tokens.color("honey"), 14)


func candles_out() -> void:
	for c in _candles:
		var tw := c.create_tween()
		tw.tween_property(c, "scale", Vector3.ZERO, 0.3)
	# the stars that had gone out light up again, one by one
	for i in 30:
		var s := Toon.part(self, "sphere", Vector3(0.35, 0.35, 0.35), "spark-yellow", Vector3(randf_range(-30, 30), randf_range(18, 30), randf_range(-60, -25)), Vector3.ZERO, 2.0, 0.0)
		s.scale = Vector3.ZERO
		var t2 := s.create_tween()
		t2.tween_interval(randf() * 1.5)
		t2.tween_property(s, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK)


func keeper_line() -> void:
	var id := GameState.data.character_id
	if Content.barks.has("final_" + id):
		GameState.bark("final_" + id)


## Far beyond a mountain: a mist that is red, not grey (next season's seed).
func red_mist() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Tokens.color("hp")
	mat.albedo_color.a = 0.55
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	Toon.part(self, "cone", Vector3(30, 18, 30), Color("#8f86b0"), Vector3(32, 0, -64))
	for i in 10:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 3.0
		sm.height = 4.0
		mi.mesh = sm
		mi.material_override = mat
		add_child(mi)
		mi.position = Vector3(32 + randf_range(-14, 14), randf_range(12, 20), -72 + randf_range(-6, 4))
		mi.scale = Vector3.ZERO
		var tw := mi.create_tween()
		tw.tween_interval(randf() * 1.2)
		tw.tween_property(mi, "scale", Vector3(1.6, 1.0, 1.4), 1.0).set_trans(Tween.TRANS_SINE)


func season_end() -> void:
	var d := GameState.data
	d.set_flag("sezon1_bitti")
	d.scene_id = "chapter0"
	SaveGame.write(d)
	var panel := SeasonEnd.new()
	_hud.add_child(panel)
	var to: String = await panel.chosen
	SceneFlow.go_to(to, to != "title")

extends Node3D
## Fener Gecesi (end of Season 3). Back in Mercan Koyu: the five pearls fly
## up into the Yaşlı Deniz Feneri and it burns for the first time in years.
## Its beam reaches over the sea and a group of jellyfish comes swimming:
## Tırıl's family, who never stopped looking. Everybody sets a lantern on
## the water; Hırıl drums, Mırıl lights the sky, Tırıl the sea: the three
## misty friends side by side for the first time. Fıstık grumbles about a
## holiday, the keeper's own closing beat, then next season's seed: a thin
## green thorny vine in the village gardens. Then `Season3End`.
## Beats: content/s3_chapter5/cutscenes/fener_gecesi.json.

const LIGHTHOUSE := Vector3(13, 0, -6)
const LAMP := LIGHTHOUSE + Vector3(0, 11.2, 0)
const SEA_Z := -11.0
const CROWD := [["turtle", Vector3(-5.5, 0, 4.4), 150], ["mors_dede", Vector3(8.5, 0, -1.0), -120],
	["olta", Vector3(-9.0, 0, 0.5), 110], ["kerpeten", Vector3(-7.5, 0, 6.5), 130],
	["dantel", Vector3(6.5, 0, 7.0), -140], ["paytak", Vector3(9.5, 0, 4.0), -110],
	["balikcil", Vector3(-3.0, 0, 7.5), 170], ["balikcil", Vector3(-1.8, 0, 8.0), 180]]

@onready var _hud: Hud = $Hud
@onready var _cam: Camera3D = $Camera
var _keeper: Node3D
var _hiril: Node3D
var _miril: Node3D
var _tiril: Node3D
var _fistik: Node3D
var _family: Array[Node3D] = []
var _dancers: Array[Node3D] = []
var _dancing := false
var _vine: Node3D


func _ready() -> void:
	WorldLook.add(self, "kumsal")
	Pus.set_color(Color(0.7, 0.86, 1.25))
	Pus.set_amount(0.0)
	_cam.make_current()
	var lv := S3Beach.build_beach(self)
	var d := GameState.data
	# the lighthouse, dark until the pearls arrive
	var tower := ModelImport.fit_static("deniz_feneri", lv, LIGHTHOUSE + Vector3(0, 6.0, 0), Vector3(5.0, 12.0, 5.0))
	if tower == null:
		Toon.part(lv, "cylinder", Vector3(3.0, 10.0, 3.0), Color("#f4efe6"), LIGHTHOUSE + Vector3(0, 5.0, 0))
		Toon.part(lv, "cone", Vector3(3.6, 2.0, 3.6), Color("#e8463a"), LIGHTHOUSE + Vector3(0, 11.0, 0))
	_keeper = KeeperModels.build(d.character_id, d.character_look)
	add_child(_keeper)
	_keeper.position = Vector3(2.0, 0, -3.0)
	_keeper.rotation.y = PI - 0.3
	_dancers.append(_keeper)
	_hiril = HirilModel.build(true)
	MobModels._no_pus(_hiril)
	add_child(_hiril)
	_hiril.position = Vector3(-1.2, 0, -4.2)
	_hiril.rotation.y = PI
	_miril = MirilModel.star_child()
	MobModels._no_pus(_miril)
	add_child(_miril)
	_miril.position = Vector3(-3.4, 0.3, -5.0)
	_miril.rotation.y = PI
	_fistik = FistikModel.build()
	add_child(_fistik)
	_fistik.position = Vector3(4.6, 0, -1.6)
	_fistik.rotation.y = PI + 0.5
	_tiril = ModelImport.load_model("tiril")
	if _tiril == null:
		_tiril = Node3D.new()
		Toon.part(_tiril, "sphere", Vector3(0.9, 0.9, 0.9), Color("#9fd8ff"), Vector3(0, 0.6, 0), Vector3.ZERO, 1.5, 0.0)
	MobModels._no_pus(_tiril)
	add_child(_tiril)
	_tiril.position = Vector3(0.6, 0.8, -6.5)
	var others := ["pati", "bado", "citir", "lumi", "tipis_panda", "tosbi"]
	others.erase(d.character_id)
	for i in others.size():
		var k := KeeperModels.build(others[i])
		add_child(k)
		k.position = Vector3(-6.0 + i * 2.6, 0, 0.6 + (i % 2) * 0.8)
		k.rotation.y = PI
		_dancers.append(k)
	for f: Array in CROWD:
		var m := NpcModels.build(f[0])
		add_child(m)
		m.position = f[1]
		m.rotation_degrees.y = f[2]
		_dancers.append(m)
	await get_tree().create_timer(1.9, false).timeout
	if DevTools.demo != "" and DisplayServer.get_name() == "headless":
		DevTools.auto_dialogue = true
	var cs := CutscenePlayer.new()
	cs.scene = self
	cs.camera = _cam
	cs.hud = _hud
	add_child(cs)
	cs.play("fener_gecesi")


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	if _tiril:
		_tiril.position.y = 0.8 + sin(t * 1.3) * 0.2
	for i in _family.size():
		_family[i].position.y = 0.9 + sin(t * 1.1 + i) * 0.3
	if _dancing:
		for i in _dancers.size():
			var m := _dancers[i]
			if is_instance_valid(m):
				m.position.y = absf(sin(t * 4.0 + i * 0.7)) * 0.25


# --- beats -------------------------------------------------------------

## The five pearls fly from the keeper up into the lamp room.
func pearls_to_lamp() -> void:
	var i := 0
	for id: String in ShoreTravel.PEARLS:
		var orb := Toon.part(self, "sphere", Vector3(0.55, 0.55, 0.55), PearlTracker.COLORS[id], _keeper.global_position + Vector3(0, 1.2, 0), Vector3.ZERO, 1.8, 0.03)
		var tw := orb.create_tween()
		tw.tween_interval(i * 0.25)
		tw.tween_property(orb, "global_position", LAMP, 1.6).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(orb.queue_free)
		i += 1
	Audio.play("memory")


## The lighthouse burns again: a warm lamp and a beam sweeping the sea.
func lighthouse_on() -> void:
	var gem := Toon.part(self, "sphere", Vector3(1.4, 1.4, 1.4), Color("#fff1c0"), LAMP, Vector3.ZERO, 2.4, 0.0)
	var l := OmniLight3D.new()
	l.light_color = Color("#fff1c0")
	l.omni_range = 26.0
	l.light_energy = 2.4
	gem.add_child(l)
	var beam := Node3D.new()
	beam.position = LAMP
	add_child(beam)
	var ray := Toon.part(beam, "cone", Vector3(7.0, 46.0, 2.0), Color(1.0, 0.95, 0.7), Vector3(0, 0, -23.0), Vector3(-90, 0, 0), 1.4, 0.0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(1.0, 0.95, 0.7, 0.16)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ray.material_override = mat
	var sweep := beam.create_tween().set_loops()
	sweep.tween_property(beam, "rotation:y", 0.9, 3.0).set_trans(Tween.TRANS_SINE)
	sweep.tween_property(beam, "rotation:y", -0.5, 3.0).set_trans(Tween.TRANS_SINE)
	for k in 3:
		Effects.ring(self, LAMP, 6.0 + k * 4.0, Color("#fff1c0"), 0.7 + k * 0.2)
	Audio.play("fanfare")


## Tırıl's family comes over the waves.
func family_arrives() -> void:
	for i in 5:
		var m := ModelImport.load_model("tiril")
		if m == null:
			m = Node3D.new()
			Toon.part(m, "sphere", Vector3(0.9, 0.9, 0.9), Color("#9fd8ff"), Vector3(0, 0.6, 0), Vector3.ZERO, 1.5, 0.0)
		MobModels._no_pus(m)
		m.scale *= [1.6, 1.4, 0.8, 0.7, 1.1][i]
		add_child(m)
		m.position = Vector3(-8.0 + i * 4.0, 0.9, -46.0)
		var l := OmniLight3D.new()
		l.light_color = Color("#9fd8ff")
		l.light_energy = 1.4
		l.omni_range = 6.0
		m.add_child(l)
		_family.append(m)
		var tw := m.create_tween()
		tw.tween_interval(i * 0.3)
		tw.tween_property(m, "position", Vector3(-4.0 + i * 2.0, 0.9, SEA_Z - 3.0 - (i % 2) * 1.6), 3.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	Audio.play("memory")


## Tırıl swims out to them; for the first time the light doesn't tremble.
func tiril_to_family() -> void:
	var tw := _tiril.create_tween()
	tw.tween_property(_tiril, "position", Vector3(0.0, 0.8, SEA_Z - 3.2), 1.8).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		for k in 3:
			Effects.ring(self, _tiril.position, 2.0 + k * 1.5, Color("#9fd8ff"), 0.6 + k * 0.2)
		Effects.sparkle(self, _tiril.position + Vector3.UP, Color("#9fd8ff"), 20))


## Everybody sets a lantern on the water; they drift out.
func lanterns_float() -> void:
	var cols := ["spark-yellow", "berry", "sky", "spark-green", "honey", "spark-purple"]
	for i in 14:
		var lamp := Node3D.new()
		add_child(lamp)
		lamp.position = Vector3(-13.0 + i * 2.0, 0.25, SEA_Z - 0.6)
		Toon.part(lamp, "box", Vector3(0.5, 0.08, 0.5), Color("#a8794f"), Vector3.ZERO)
		Toon.part(lamp, "sphere", Vector3(0.36, 0.42, 0.36), Tokens.color(cols[i % cols.size()]), Vector3(0, 0.26, 0), Vector3.ZERO, 2.0, 0.0)
		var tw := lamp.create_tween()
		tw.tween_interval(i * 0.12)
		tw.tween_property(lamp, "position:z", SEA_Z - 6.0 - (i % 4) * 3.0, 6.0 + (i % 3)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	Audio.play("lantern")


## Hırıl drums, Mırıl lights the sky, Tırıl the sea; everybody dances.
func three_friends() -> void:
	_dancing = true
	_beat()
	_sky()


func _beat() -> void:
	while _dancing and is_inside_tree():
		Audio.play("drum")
		Effects.ring(self, _hiril.position + Vector3.UP * 0.4, 2.6, Tokens.color("hp"), 0.5)
		await get_tree().create_timer(0.6, false).timeout


func _sky() -> void:
	var cols := ["spark-purple", "sky", "spark-yellow", "berry", "spark-green"]
	while _dancing and is_inside_tree():
		Effects.sparkle(self, Vector3(randf_range(-14, 14), randf_range(7, 11), randf_range(-26, -14)), Tokens.color(cols[randi() % cols.size()]), 14)
		Effects.ring(self, Vector3(randf_range(-10, 10), 0.3, SEA_Z - randf_range(3, 12)), 1.6, Color("#9fd8ff"), 0.8)
		await get_tree().create_timer(0.7, false).timeout


## Next season's seed: a thin green thorny vine creeps up by Fıstık.
func vine_grows() -> void:
	_dancing = false
	_vine = Node3D.new()
	add_child(_vine)
	_vine.position = _fistik.position + Vector3(1.2, 0, 0.4)
	for i in 7:
		var seg := Toon.part(_vine, "capsule", Vector3(0.12, 0.7, 0.12), Color("#3f9f4a"), Vector3(sin(i * 0.9) * 0.25, 0.3 + i * 0.42, cos(i * 1.3) * 0.2), Vector3(sin(i) * 25.0, 0, cos(i) * 25.0))
		Toon.part(_vine, "cone", Vector3(0.1, 0.22, 0.1), Color("#2f7a3a"), seg.position + Vector3(0.12, 0.05, 0), Vector3(0, 0, -70))
		seg.scale = Vector3.ONE * 0.01
		var tw := seg.create_tween()
		tw.tween_interval(i * 0.3)
		tw.tween_property(seg, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.play("stone")


func season_end() -> void:
	_dancing = false
	var d := GameState.data
	d.set_flag("sezon3_bitti")
	d.set_flag("sezon3_senlik")
	d.scene_id = "s3_chapter0"
	SaveGame.write(d)
	var panel := Season3End.new()
	_hud.add_child(panel)
	if DevTools.demo != "" and DisplayServer.get_name() == "headless":
		print("S3FINAL senlik=%s bitti=%s scene_id=%s keeper=%s" % [d.has_flag("sezon3_senlik"), d.has_flag("sezon3_bitti"), d.scene_id, d.character_id])
		get_tree().quit()
		return
	var to: String = await panel.chosen
	SceneFlow.go_to(to, to != "title")

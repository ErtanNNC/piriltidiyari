extends Node3D
## Sezon 3 · Prolog · Sahne 5 – Hırıl'ın Seçimi. Cutscene, no player
## control: at the end of the cliffs a small trembling light shows over the
## waves – Tırıl. Hırıl calls, Tırıl takes fright and is gone, the mist
## swells. Hırıl knows that feeling ("İşte geldim!"), jumps into a little
## boat and rows into the mist. The drum stays on the sand and keeps a slow
## beat by itself: wherever Hırıl is, the rhythm shows the way.
## Beats: content/s3_prologue/cutscenes/hiril_secimi.json.

const BLUE := Color(0.7, 0.86, 1.25)

var _hiril: Node3D
var _tiril: Node3D
var _boat: Node3D
var _drum: Node3D
var _drumming := false
@onready var _hud: Hud = $Hud
@onready var _cam: Camera3D = $Camera


func _ready() -> void:
	WorldLook.add(self, "kumsal")
	Pus.set_color(BLUE)
	Pus.set_amount(0.3)
	var lv := Node3D.new()
	lv.name = "Level"
	add_child(lv)
	WorldLook.block(lv, Vector3(0, -0.5, 8), Vector3(50, 1, 30), Color("#b8a27a"), 0.0)
	var sea := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(160, 90)
	plane.subdivide_width = 40
	plane.subdivide_depth = 24
	sea.mesh = plane
	sea.position = Vector3(0, 0.08, -52.6)
	WorldLook.water(sea, "sea_night")
	lv.add_child(sea)
	for x: float in [-9.0, 10.0]:
		var rock := ModelImport.prop_copy("kiyi_kaya")
		if rock:
			rock.scale *= 2.4
			rock.position = Vector3(x, 0.8, 1.0)
			lv.add_child(rock)
	_hiril = HirilModel.build(true)
	MobModels._no_pus(_hiril)
	add_child(_hiril)
	_hiril.position = Vector3(-1.0, 0, 2.0)
	_hiril.rotation.y = PI
	_boat = ModelImport.load_model("kabuk_kayik")
	if _boat == null:
		_boat = Node3D.new()
		Toon.part(_boat, "ellipsoid", Vector3(1.6, 0.7, 2.8), Color("#f4dcc0"), Vector3(0, 0.3, 0))
	_boat.scale *= 2.0
	add_child(_boat)
	_boat.position = Vector3(3.5, -0.2, -8.2)
	_boat.rotation.y = 0.3
	# the drum Hırıl carries, set down later
	_drum = Node3D.new()
	Toon.part(_drum, "cylinder", Vector3(0.9, 0.6, 0.9), Color("#c9452f"), Vector3(0, 0.3, 0))
	Toon.part(_drum, "cylinder", Vector3(0.95, 0.08, 0.95), Color("#fff1dc"), Vector3(0, 0.62, 0))
	add_child(_drum)
	_drum.position = Vector3(-2.2, 0, 2.6)
	_drum.visible = false
	_cam.make_current()
	await get_tree().create_timer(1.6, false).timeout
	var cs := CutscenePlayer.new()
	cs.scene = self
	cs.camera = _cam
	cs.hud = _hud
	add_child(cs)
	cs.play("hiril_secimi")


func _process(_delta: float) -> void:
	if _tiril and is_instance_valid(_tiril):
		var t := Time.get_ticks_msec() / 1000.0
		_tiril.position.x = 0.5 + sin(t * 38.0) * 0.04   # always trembling
		_tiril.position.y = 1.6 + sin(t * 1.4) * 0.25


# --- beats -------------------------------------------------------------

## A small trembling light over the waves.
func tiril_appears() -> void:
	_tiril = ModelImport.load_model("tiril")
	if _tiril == null:
		_tiril = Node3D.new()
		Toon.part(_tiril, "sphere", Vector3(0.9, 0.9, 0.9), Color("#9fd8ff"), Vector3(0, 0.6, 0), Vector3.ZERO, 1.5, 0.0)
	MobModels._no_pus(_tiril)
	add_child(_tiril)
	_tiril.position = Vector3(0.5, 1.6, -15.0)
	_tiril.scale = Vector3.ONE * 0.05
	var l := OmniLight3D.new()
	l.name = "Glow"
	l.light_color = Color("#9fd8ff")
	l.light_energy = 2.2
	l.omni_range = 7.0
	l.position.y = 0.7
	_tiril.add_child(l)
	var tw := create_tween()
	tw.tween_property(_tiril, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Effects.sparkle(self, _tiril.position + Vector3.UP, Color("#9fd8ff"), 14)


## Hırıl calls out; Tırıl takes fright, its light goes out, the mist swells.
func tiril_hides() -> void:
	if _tiril == null:
		return
	Audio.play("whoosh")
	var l := _tiril.get_node_or_null("Glow") as OmniLight3D
	var tw := create_tween()
	if l:
		tw.tween_property(l, "light_energy", 0.0, 0.5)
	tw.tween_property(_tiril, "position:z", -40.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_tiril, "scale", Vector3.ONE * 0.05, 1.2)
	tw.tween_callback(_tiril.queue_free)
	Pus.fade_to(self, 0.6, 2.0)


## Hırıl puts the drum down on the sand.
func drum_down() -> void:
	_drum.visible = true
	Effects.sparkle(self, _drum.position + Vector3.UP * 0.6, Tokens.color("hp"), 8)
	Audio.play("drum")


## Hırıl runs to the little boat and rows into the mist.
func hiril_rows() -> void:
	var rig := CharacterRig.of(_hiril)
	if rig:
		rig.speed = 1.0
	var tw := create_tween()
	tw.tween_property(_hiril, "position", Vector3(3.3, 0.2, -7.4), 1.6)
	tw.tween_callback(func() -> void:
		if rig:
			rig.speed = 0.0
		_hiril.reparent(_boat)
		_hiril.position = Vector3(0, 0.25, 0)
		_hiril.scale = Vector3.ONE * 0.5
		Audio.play("splash"))
	tw.tween_property(_boat, "position", Vector3(1.0, -0.2, -42.0), 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_boat, "rotation:y", PI, 1.2)


## The drum keeps a slow beat by itself.
func drum_beats() -> void:
	_drumming = true
	while _drumming and is_inside_tree():
		Audio.play("drum")
		Effects.ring(self, _drum.position + Vector3.UP * 0.4, 2.4, Tokens.color("hp"), 0.6)
		var tw := create_tween()
		tw.tween_property(_drum, "scale", Vector3(1.1, 0.9, 1.1), 0.08)
		tw.tween_property(_drum, "scale", Vector3.ONE, 0.2)
		await get_tree().create_timer(1.0, false).timeout


func finish() -> void:
	_drumming = false
	GameState.data.set_flag("s3_sahne5_bitti")
	if DevTools.demo == "flow" and DisplayServer.get_name() == "headless":
		print("S3_CHOICE flag=%s" % GameState.data.has_flag("s3_sahne5_bitti"))
		get_tree().quit()

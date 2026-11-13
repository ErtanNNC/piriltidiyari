class_name BreathCalm
extends Node3D
## Season 2's two new rules, carried by the player:
##
## Sakinleş (C / "Sakinleş" button, hold): next to a dazed Köpüklü a breathing
## ring grows ("Nefes al...") and shrinks ("Nefes ver..."); when one full
## breath is done the creature calms down (Mob.breathe_calm). Let go and the
## breath slowly fades back.
##
## Öfke barı: inside thick Kızıl Sis (`heat` > 0, set by the scene) the bar
## fills. Full = "kızgın" for a while: stronger hits, a wobbly walk and no
## Sakinleş for others. Holding Sakinleş with nobody dazed nearby cools the
## keeper down; Nane Şekeri empties it at once.

signal anger_changed(value: float)

const BREATH_IN := 2.0
const BREATH_OUT := 2.0
const REACH := 2.8
const ANGRY_TIME := 6.0

## 0..1 progress through one breath (in, then out).
var breath := 0.0
var target: Node3D = null
## 0..1 how full the Öfke barı is.
var anger := 0.0
## Seconds of "kızgın" left (0 = calm).
var angry := 0.0
## Kızıl Sis strength around the keeper (bar fill per second), set by scenes.
var heat := 0.0
## Papatya Çayı: breaths go faster until this time (seconds).
var fast_until := 0.0
## Sis Kalkanı: the Öfke barı doesn't fill until then (engine seconds).
var shield_until := 0.0

var _ring: MeshInstance3D
var _label: Label3D
## Over the nearest dazed creature: "Yanına git" / "Sakinleş'e basılı tut!"
var _guide: Label3D
var _player: Player


func _ready() -> void:
	_player = get_parent() as Player
	_ring = MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.9
	t.outer_radius = 1.0
	_ring.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Tokens.color("leaf")
	m.albedo_color.a = 0.85
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring.material_override = m
	_ring.top_level = true
	_ring.visible = false
	add_child(_ring)
	_label = Label3D.new()
	_label.font = Tokens.font_for("text-heading")
	_label.font_size = 64
	_label.pixel_size = 0.006
	_label.outline_size = 14
	_label.outline_modulate = Tokens.color("outline")
	_label.modulate = Tokens.color("panel@light")
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.top_level = true
	_label.visible = false
	add_child(_label)
	_guide = _label.duplicate() as Label3D
	_guide.modulate = Tokens.color("honey")
	_guide.font_size = 72
	add_child(_guide)


func is_angry() -> bool:
	return angry > 0.0


func _physics_process(delta: float) -> void:
	var held := Input.is_action_pressed("calm") and _player.input_enabled and not _player.asleep
	_update_anger(delta, held)
	target = _nearest_dazed() if not is_angry() else null
	if held and target:
		var fast := 1.6 if GameState.clock < fast_until else 1.0
		breath += delta * fast / (BREATH_IN + BREATH_OUT)
		if breath >= 1.0:
			var m := target
			breath = 0.0
			target = null
			Audio.play("calm")
			Effects.ring(_player.get_parent(), m.global_position + Vector3.UP * 0.3, 2.2, Tokens.color("leaf"), 0.5)
			m.call("breathe_calm")
	else:
		breath = maxf(breath - delta * 0.35, 0.0)
	_show(held)
	_show_guide(held)


## Tells the player what to do next with the nearest dazed creature: walk up
## to it, then hold Sakinleş (and keep holding until the ring is done).
func _show_guide(held: bool) -> void:
	var m: Node3D = null
	var best := 12.0
	for n in get_tree().get_nodes_in_group("dazed"):
		var d := (n as Node3D).global_position.distance_to(_player.global_position)
		if d < best:
			best = d
			m = n
	_guide.visible = m != null and not is_angry() and not (held and target != null)
	if not _guide.visible:
		return
	if target == null:
		_guide.text = TranslationServer.translate("Yanına git!")
	elif breath > 0.05:
		_guide.text = TranslationServer.translate("Bırakma! Tekrar basılı tut.")
	elif TouchControls.is_touch():
		_guide.text = TranslationServer.translate("Sakinleş'e basılı tut!")
	else:
		_guide.text = TranslationServer.translate("C tuşuna basılı tut!")
	var k := 1.0 + 0.08 * sin(Time.get_ticks_msec() / 140.0)
	_guide.scale = Vector3(k, k, k)
	_guide.global_position = m.global_position + Vector3.UP * 2.9


## In (0 → 0.5): the ring grows; out (0.5 → 1): it shrinks.
func _show(held: bool) -> void:
	var on := breath > 0.0 and (target != null or held)
	_ring.visible = on and target != null
	_label.visible = on and target != null
	if not _ring.visible:
		if held and is_angry():
			_label.visible = true
			_label.text = TranslationServer.translate("Önce sen sakinleş...")
			_label.global_position = _player.global_position + Vector3.UP * 2.4
		return
	var k := breath / 0.5 if breath < 0.5 else (1.0 - breath) / 0.5
	var r := lerpf(0.6, 2.0, ease(k, -1.8))
	_ring.global_position = target.global_position + Vector3.UP * 0.25
	_ring.scale = Vector3(r, 1.0, r)
	_label.text = TranslationServer.translate("Nefes al...") if breath < 0.5 else TranslationServer.translate("Nefes ver...")
	_label.text += "  %d%%" % roundi(breath * 100.0)
	_label.global_position = target.global_position + Vector3.UP * 2.6


func _nearest_dazed() -> Node3D:
	var best: Node3D = null
	var best_d := REACH
	for m in get_tree().get_nodes_in_group("dazed"):
		var d := (m as Node3D).global_position.distance_to(_player.global_position)
		# big ones (a boss) can be reached from a little further away
		d -= float(m.get_meta("calm_reach", REACH)) - REACH
		if d < best_d:
			best_d = d
			best = m
	return best


func _update_anger(delta: float, held: bool) -> void:
	var before := anger
	if angry > 0.0:
		angry -= delta
		if held:
			angry -= delta * 2.0   # breathing on your own helps
		if angry <= 0.0:
			angry = 0.0
			anger = 0.0
			GameState.toast.emit("Oh... Sakinleştin.", "heart")
	elif heat > 0.0 and GameState.clock >= shield_until:
		anger = minf(anger + heat * delta, 1.0)
		if anger >= 1.0:
			angry = ANGRY_TIME
			Audio.play("warn")
			GameState.toast.emit("Kızgınsın! Güçlü vurursun ama zor yürürsün. Sakinleş'e bas.", "spark")
	if held and angry <= 0.0 and _nearest_dazed() == null:
		anger = maxf(anger - delta * 0.5, 0.0)
	elif heat <= 0.0 and angry <= 0.0:
		anger = maxf(anger - delta * 0.04, 0.0)
	if not is_equal_approx(before, anger) or angry > 0.0:
		anger_changed.emit(anger)


## Nane Şekeri: the bar is cool again.
func cool_down() -> void:
	anger = 0.0
	angry = 0.0
	anger_changed.emit(anger)

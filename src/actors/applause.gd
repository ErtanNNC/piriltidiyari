class_name Applause
extends Node3D
## Season 4's two rules, carried by the player (like BreathCalm and LightRing):
##
## Alkış (C / "Alkış" button, one press): the keeper claps. Everything in
## group "applaudable" within REACH gets `applauded(by)`: a neighbour's garden
## pulls its thorns back (ThornPatch), a dazed Dikenci or a keeper at 0 HP
## calms at once (`breathe_calm`). Clapping FOR someone also takes a good
## piece off the Diken barı: being glad for another is the cure.
##
## Diken barı: where the Yeşil Diken is thick (`heat` > 0, set by ThornPatch
## areas and scenes) the bar fills (`ThornRules`). Full = "kıskandın" for a
## moment: no skill, no powers. Papatya Çelengi keeps it from filling,
## Nane Limonata and a Teşekkür Yaprağı empty it.

signal thorn_changed(value: float)
signal clapped(hits: int)

const REACH := 4.5
const COOLDOWN := 0.7

## 0..1 how full the Diken barı is.
var thorn := 0.0
## Seconds of "kıskandın" left.
var envy := 0.0
## Thorn strength round the keeper, set every frame by ThornPatch areas and
## scenes; used once, then cleared.
var heat := 0.0
## Papatya Çelengi: the bar does not fill until then.
var wreath_until: float:
	get: return GameState.buff_until("celenk")
	set(v): GameState.set_buff_until("celenk", v)
var _cd := 0.0
var _player: Player


func _ready() -> void:
	_player = get_parent() as Player


func is_envious() -> bool:
	return envy > 0.0


## Nane Limonata / Teşekkür Yaprağı.
func cool_down() -> void:
	thorn = 0.0
	envy = 0.0
	thorn_changed.emit(thorn)


func _process(delta: float) -> void:
	_cd = maxf(_cd - delta, 0.0)
	if envy > 0.0:
		envy = maxf(envy - delta, 0.0)
		if envy <= 0.0:
			thorn = 0.4
			thorn_changed.emit(thorn)
	elif not GameState.in_dialogue:
		var h := 0.0 if GameState.clock < wreath_until else heat
		var before := thorn
		thorn = ThornRules.fill(thorn, h, delta)
		if thorn >= 1.0:
			envy = ThornRules.ENVY_TIME
			GameState.toast.emit("Kıskandın! Birini alkışla, geçer.", "spark")
			Audio.play("warn")
		if not is_equal_approx(before, thorn):
			thorn_changed.emit(thorn)
	heat = 0.0
	if _player and _player.input_enabled and not _player.asleep and Input.is_action_just_pressed("calm"):
		clap()


## One clap. Returns how many things it reached.
func clap() -> int:
	if _cd > 0.0 or _player == null:
		return 0
	_cd = COOLDOWN
	var at := _player.global_position
	Audio.play("click")
	Effects.ring(_player.get_parent(), at + Vector3.UP * 0.2, REACH, Tokens.color("spark-yellow"), 0.45)
	Effects.sparkle(_player.get_parent(), at + Vector3.UP * 1.5, Tokens.color("spark-yellow"), 10)
	var hits := 0
	for n in get_tree().get_nodes_in_group("applaudable"):
		var a := n as Node3D
		if a == null or not a.has_method("applauded"):
			continue
		var reach := float(a.get_meta("clap_reach", REACH))
		if a.global_position.distance_to(at) <= reach:
			if a.call("applauded", _player) != false:
				hits += 1
	# a dazed Dikenci (or a keeper at 0 HP) calms with one clap
	for n in get_tree().get_nodes_in_group("dazed"):
		var m := n as Node3D
		if m and m.has_method("breathe_calm") and m.global_position.distance_to(at) <= float(m.get_meta("calm_reach", 2.8)) + 0.6:
			m.call("breathe_calm")
			hits += 1
	if hits > 0:
		thorn = ThornRules.after_clap(thorn)
		if envy > 0.0:
			envy = 0.0
		thorn_changed.emit(thorn)
		GameState.notify("clap", "any")
	clapped.emit(hits)
	return hits

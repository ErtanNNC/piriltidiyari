class_name SeedPlot
extends Interactable
## Season 4: a little mound of soil. "Ek" plants a seed that grows in a few
## seconds (`Growth`): a leaf bridge over a gap, a vine ladder up a ledge, a
## Şifa Papatyası that heals, a Kalkan Yaprağı that guards, or a Gece Çiçeği
## that opens only at night. Night kinds wait (closed bud) until the scene
## says it is night (`night` on the current scene). What grew stays grown
## (`plot_flag`). `yonca_only` plots answer only Yonca's Filizlendirme
## (keeper-only corners with Pırıl). Event: "grow"/<kind> and "grow"/"any".

signal grown(plot: SeedPlot)

@export var kind := "kopru"
@export var plot_flag := ""
## Bridge/ladder: where it leads, relative to the plot (local space).
@export var span := Vector3(0, 0, -5.0)
@export var yonca_only := false
var is_grown := false
var _planted := false
var _t := 0.0
var _sprout: Node3D
var _result: Node3D


func _build() -> void:
	action_label = "Ek"
	reach = 1.5
	Toon.part(self, "ellipsoid", Vector3(1.2, 0.3, 1.2), Color("#7a5236"), Vector3(0, 0.08, 0))
	Toon.part(self, "ring", Vector3(1.3, 0.06, 1.3), "honey" if not yonca_only else "spark-green", Vector3(0, 0.12, 0), Vector3.ZERO, 0.3, 0.0)
	if plot_flag != "" and GameState.data.has_flag(plot_flag):
		_planted = true
		_finish(true)
	else:
		Beacon.attach(self, 1.6, Tokens.color("spark-green"))


func _ready() -> void:
	super._ready()
	if is_grown:
		done()


func _night() -> bool:
	var s := get_tree().current_scene
	return s != null and "night" in s and bool(s.get("night"))


func use(_by: Node) -> void:
	if _planted:
		return
	if yonca_only and GameState.data.character_id != "yonca":
		GameState.toast.emit("Bu toprak çok nazlı. Yonca filizlendirebilir.", "spark")
		return
	plant()


func plant() -> void:
	if _planted:
		return
	_planted = true
	Audio.play("pop")
	_sprout = Node3D.new()
	add_child(_sprout)
	Toon.part(_sprout, "cylinder", Vector3(0.08, 0.5, 0.08), Color("#4a9a5a"), Vector3(0, 0.3, 0))
	Toon.part(_sprout, "ellipsoid", Vector3(0.3, 0.1, 0.16), Color("#6cc070"), Vector3(0.14, 0.5, 0), Vector3(0, 0, 25))
	Toon.part(_sprout, "ellipsoid", Vector3(0.3, 0.1, 0.16), Color("#6cc070"), Vector3(-0.14, 0.5, 0), Vector3(0, 0, -25))
	_sprout.scale = Vector3.ONE * 0.2
	if not Growth.can_grow(kind, _night()):
		GameState.toast.emit("Bu bir Gece Çiçeği. Gece olunca açar." if kind == "gece" else "Bu çiçek gündüz açar.", "lantern")


func _process(delta: float) -> void:
	if not _planted or is_grown:
		return
	var fert := GameState.clock < GameState.buff_until("gubre")
	if not Growth.can_grow(kind, _night()):
		return
	_t += delta
	var p := Growth.progress(kind, _t, _night(), fert)
	if _sprout:
		_sprout.scale = Vector3.ONE * lerpf(0.2, 1.6, p)
	if p >= 1.0:
		_finish(false)


func _finish(quiet: bool) -> void:
	is_grown = true
	if _sprout:
		_sprout.queue_free()
		_sprout = null
	if has_node("Beacon"):
		get_node("Beacon").queue_free()
	_result = Node3D.new()
	_result.name = "Grown"
	add_child(_result)
	match kind:
		"kopru":
			_bridge()
		"merdiven":
			_ladder()
		"sifa":
			_flower("papatya", Color("#fff7ea"), true)
		"kalkan":
			_flower("lale", Color("#e8604a"), false)
		_:
			_flower("ay_cicegi", Color("#dfe8ff"), true)
	if quiet:
		return
	if plot_flag != "":
		GameState.data.set_flag(plot_flag)
	_result.scale = Vector3.ONE * 0.1
	var tw := _result.create_tween()
	tw.tween_property(_result, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.play("crystal")
	Effects.sparkle(get_parent(), global_position + Vector3.UP, Tokens.color("spark-green"), 18)
	GameState.notify("grow", kind)
	GameState.notify("grow", "any")
	grown.emit(self)
	done()


## A broad leaf from the plot to `span` (walkable).
func _bridge() -> void:
	var len := Vector2(span.x, span.z).length()
	var mid := span * 0.5
	var holder := Node3D.new()
	_result.add_child(holder)
	holder.position = Vector3(mid.x, span.y * 0.5, mid.z)
	holder.rotation.y = atan2(span.x, span.z)
	Toon.part(holder, "box", Vector3(2.4, 0.25, len + 1.0), Color("#5fb868"), Vector3(0, -0.1, 0))
	Toon.part(holder, "box", Vector3(0.2, 0.3, len + 1.0), Color("#3f8a4a"), Vector3(0, 0.02, 0), Vector3.ZERO, 0.0, 0.0)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.4, 0.3, len + 1.0)
	c.shape = b
	c.position.y = -0.15
	body.add_child(c)
	holder.add_child(body)


## Leaf steps climbing to `span` (each ≤ 0.45 m high).
func _ladder() -> void:
	var steps := maxi(2, ceili(absf(span.y) / 0.42))
	for i in steps:
		var f := float(i + 1) / steps
		var at := Vector3(span.x * f, span.y * f, span.z * f)
		var st := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(2.0, 0.3, 1.4)
		c.shape = b
		st.add_child(c)
		st.position = at + Vector3(0, -0.15, 0)
		_result.add_child(st)
		Toon.part(st, "ellipsoid", Vector3(2.1, 0.3, 1.5), Color("#5fb868"), Vector3.ZERO)
	Toon.part(_result, "cylinder", Vector3(0.3, absf(span.y) + 0.4, 0.3), Color("#3f8a4a"), Vector3(span.x * 0.5, span.y * 0.5, span.z * 0.5 - 0.9))


## A big flower; a healing one tops up HP when the keeper stands by it.
func _flower(model_id: String, col: Color, heals: bool) -> void:
	if ModelImport.fit_static(model_id, _result, Vector3(0, 0.9, 0), Vector3(1.3, 1.8, 1.3)) == null:
		Toon.part(_result, "cylinder", Vector3(0.12, 1.2, 0.12), Color("#4a9a5a"), Vector3(0, 0.6, 0))
		Toon.part(_result, "sphere", Vector3(0.9, 0.5, 0.9), col, Vector3(0, 1.3, 0), Vector3.ZERO, 0.6, 0.03)
	var l := OmniLight3D.new()
	l.light_color = col
	l.omni_range = 4.0
	l.light_energy = 0.9
	l.position.y = 1.4
	_result.add_child(l)
	if not heals:
		return
	var t := Timer.new()
	t.wait_time = 2.0
	t.autostart = true
	_result.add_child(t)
	t.timeout.connect(func() -> void:
		var p := get_tree().get_first_node_in_group("player") as Player
		var d := GameState.data
		if p and p.global_position.distance_to(global_position) < 3.0 and d.hp < d.max_hp and not p.asleep:
			d.heal(maxi(3, d.max_hp / 25))
			Effects.sparkle(get_parent(), p.global_position + Vector3.UP * 1.4, col, 4))

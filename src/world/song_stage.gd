class_name SongStage
extends Node3D
## Season 4, Şarkı Çayırı: a little stage whose singer has been drowned out
## (a grey hush cloud over the head). Keep a calm, steady beat beside it
## (four even strikes, `Rhythm`: every strike is a beat) and the singer
## sings again (flag `sung_flag`, event "ritim"/<stage_id>). A clap for the
## singing one then pulls back the thorns of its stage (`patch.open()`,
## event "clap"/<stage_id>). A clap before the song only gets a friendly tip.
## The chapter sets `listening` while its quest wants the stages.

signal sang(stage: SongStage)
signal cheered(stage: SongStage)

const REACH := 5.0
const STREAK := 4

@export var stage_id := "sarkici"
@export var sung_flag := ""
@export var color := Color("#ffd86a")
## The singer standing on the stage (bobs while singing).
var singer: Node3D
## The thorns a clap for the singer opens.
var patch: ThornPatch
var listening := false:
	set(v):
		listening = v
		_mark()
var is_sung := false
var _hush: Node3D
var _pips: Array[MeshInstance3D] = []
var _bob: Tween


func _ready() -> void:
	add_to_group("rhythm_listener")
	add_to_group("applaudable")
	set_meta("clap_reach", REACH)
	Toon.part(self, "cylinder", Vector3(3.2, 0.25, 3.2), Color("#c9a070"), Vector3(0, 0.12, 0))
	Toon.part(self, "ring", Vector3(3.5, 0.08, 3.5), color, Vector3(0, 0.05, 0), Vector3.ZERO, 0.4, 0.0)
	# four beat lamps on the front edge: one lights with every steady beat
	for i in STREAK:
		var at := Vector3((i - 1.5) * 0.55, 0.2, 1.9)
		Toon.part(self, "sphere", Vector3(0.3, 0.3, 0.3), Color("#8a8f98"), at, Vector3.ZERO, 0.0, 0.02)
		var lit := Toon.part(self, "sphere", Vector3(0.38, 0.38, 0.38), color, at, Vector3.ZERO, 2.0, 0.02)
		lit.visible = false
		_pips.append(lit)
	# the hush: a grey cloud that sits over the singer
	_hush = Node3D.new()
	_hush.position = Vector3(0, 2.7, 0)
	add_child(_hush)
	for p: Vector3 in [Vector3(-0.4, 0, 0), Vector3(0.4, 0.05, 0), Vector3(0, 0.25, 0)]:
		Toon.part(_hush, "ellipsoid", Vector3(0.9, 0.55, 0.6), Color("#9aa0a8"), p, Vector3.ZERO, 0.0, 0.02)
	var notes := Timer.new()
	notes.wait_time = 1.1
	notes.autostart = true
	add_child(notes)
	notes.timeout.connect(func() -> void:
		if is_sung:
			note(self, Vector3(randf_range(-0.6, 0.6), 2.2, 0.3), color))
	if sung_flag != "" and GameState.data.has_flag(sung_flag):
		_set_sung()
	_mark()


## A star over a stage that still waits for its beat or its clap.
func _mark() -> void:
	if not is_inside_tree():
		return
	var want := listening and not is_done()
	if want and not has_node("Beacon"):
		Beacon.attach(self, 3.6, color)
	elif not want and has_node("Beacon"):
		get_node("Beacon").queue_free()


func is_done() -> bool:
	return is_sung and (patch == null or patch.is_open)


func hear_rhythm(from: Vector3, streak: int) -> void:
	if not listening or is_sung or from.distance_to(global_position) > REACH:
		return
	for i in STREAK:
		_pips[i].visible = i < streak
	Effects.sparkle(get_parent(), global_position + Vector3(0, 0.4, 1.9), color, 3)
	if streak >= STREAK:
		sing()


## The hush lifts: the singer sings again.
func sing() -> void:
	if is_sung:
		return
	if sung_flag != "":
		GameState.data.set_flag(sung_flag)
	Audio.play("crystal")
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.2, 3.0, color, 0.5)
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 2.4, color, 18)
	var tw := _hush.create_tween()
	tw.tween_property(_hush, "scale", Vector3.ONE * 1.4, 0.15)
	tw.tween_property(_hush, "scale", Vector3.ONE * 0.01, 0.25)
	tw.tween_callback(_set_sung)
	is_sung = true
	GameState.notify("ritim", stage_id)
	sang.emit(self)


func _set_sung() -> void:
	is_sung = true
	_hush.visible = false
	for p in _pips:
		p.visible = true
	if singer and (_bob == null or not _bob.is_valid()):
		_bob = singer.create_tween().set_loops()
		_bob.tween_property(singer, "scale", Vector3(1.06, 0.93, 1.06), 0.28).set_trans(Tween.TRANS_SINE)
		_bob.tween_property(singer, "scale", Vector3(0.96, 1.07, 0.96), 0.28).set_trans(Tween.TRANS_SINE)
	_mark()


## A clap for the singer: its thorns draw back.
func applauded(_by: Node) -> bool:
	if not listening or is_done():
		return false
	if not is_sung:
		GameState.toast.emit("Sesi çıkmıyor. Önce yanında düzenli ritim tut: dört vuruş!", "spark")
		return false
	Audio.play("laugh")
	for k in 4:
		note(self, Vector3(randf_range(-1.0, 1.0), 1.8, randf_range(-0.3, 0.6)), color)
	if patch:
		patch.open()
	GameState.notify("clap", stage_id)
	cheered.emit(self)
	_mark()
	return true


## A little music note that floats up and fades (primitives: no font needed).
static func note(parent: Node3D, at: Vector3, col: Color) -> void:
	var n := Node3D.new()
	parent.add_child(n)
	n.position = at
	Toon.part(n, "ellipsoid", Vector3(0.3, 0.22, 0.2), col, Vector3.ZERO, Vector3(0, 0, 20), 1.2, 0.02)
	Toon.part(n, "box", Vector3(0.05, 0.5, 0.05), col, Vector3(0.12, 0.27, 0), Vector3.ZERO, 1.2, 0.0)
	Toon.part(n, "box", Vector3(0.22, 0.08, 0.05), col, Vector3(0.22, 0.5, 0), Vector3(0, 0, -20), 1.2, 0.0)
	var tw := n.create_tween()
	tw.tween_property(n, "position", at + Vector3(randf_range(-0.5, 0.5), 1.8, 0), 1.3).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(n, "rotation:z", randf_range(-0.5, 0.5), 1.3)
	tw.tween_property(n, "scale", Vector3.ONE * 0.01, 0.25)
	tw.tween_callback(n.queue_free)

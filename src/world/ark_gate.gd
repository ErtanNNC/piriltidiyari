class_name ArkGate
extends Interactable
## Season 4: the sluice at the head of a garden's ark (water channel), the
## garden's "flare". "Aç" once the garden's quest allows it (`needs`): water
## runs to the Bahar Çeşmesi again, the Yeşil Diken dries round here. Event
## "light"/"ark", flag `ark_id`. Opened early it still counts (see `_sync`).

signal opened(gate: ArkGate)

@export var ark_id := "s4_ark0"
## "quest/objective", a whole "quest" (ready or done), or "" = always.
@export var needs := ""
@export var locked_bark := ""
var is_open := false
var _wheel: Node3D
var _water: MeshInstance3D


func _build() -> void:
	action_label = "Aç"
	reach = 1.7
	Toon.part(self, "box", Vector3(2.2, 1.2, 0.6), Color("#9a9aa8"), Vector3(0, 0.6, 0))
	Toon.part(self, "box", Vector3(0.3, 2.2, 0.3), Color("#7a5236"), Vector3(-1.0, 1.1, 0))
	Toon.part(self, "box", Vector3(0.3, 2.2, 0.3), Color("#7a5236"), Vector3(1.0, 1.1, 0))
	_wheel = Node3D.new()
	_wheel.position = Vector3(0, 1.9, 0.35)
	add_child(_wheel)
	Toon.part(_wheel, "ring", Vector3(1.0, 0.1, 1.0), Color("#c98d5e"), Vector3.ZERO, Vector3(90, 0, 0))
	for k in 4:
		Toon.part(_wheel, "box", Vector3(0.9, 0.08, 0.08), Color("#c98d5e"), Vector3.ZERO, Vector3(0, 0, k * 45))
	_water = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1.6, 9.0)
	_water.mesh = pm
	_water.position = Vector3(0, 0.07, 5.0)
	_water.visible = false
	WorldLook.water(_water, "lake")
	add_child(_water)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.2, 2.2, 0.6)
	c.shape = b
	c.position.y = 1.1
	body.add_child(c)
	add_child(body)
	if GameState.data.has_flag(ark_id):
		is_open = true
		_water.visible = true
	else:
		Beacon.attach(self, 3.0, Tokens.color("sky"))


func _ready() -> void:
	super._ready()
	if is_open:
		done()
	GameState.data.quest_changed.connect(_sync)
	_sync.call_deferred()


func _sync(_quest_id := "") -> void:
	if GameState.data.has_flag(ark_id):
		GameState.notify("light", "ark")


func _allowed(d: PlayerData) -> bool:
	if needs == "":
		return true
	if needs.contains("/"):
		return d.objective_done(needs.get_slice("/", 0), needs.get_slice("/", 1))
	return d.quest_state(needs) in ["ready", "done"]


func use(_by: Node) -> void:
	var d := GameState.data
	if is_open:
		return
	if not _allowed(d):
		if locked_bark != "":
			GameState.bark(locked_bark)
		return
	is_open = true
	d.set_flag(ark_id)
	Audio.play("splash")
	Audio.play("fanfare")
	var tw := _wheel.create_tween()
	tw.tween_property(_wheel, "rotation:z", TAU * 2.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_water.visible = true
	_water.scale = Vector3(1, 1, 0.05)
	var tw2 := _water.create_tween()
	tw2.tween_property(_water, "scale:z", 1.0, 1.4)
	for i in 3:
		Effects.ring(get_parent(), global_position + Vector3.UP * 0.3, 5.0 + i * 4.0, Tokens.color("sky"), 0.7 + i * 0.2)
	GameState.notify("light", "ark")
	done()
	opened.emit(self)

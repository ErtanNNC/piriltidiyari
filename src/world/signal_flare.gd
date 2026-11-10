class_name SignalFlare
extends Interactable
## Season 3: an island's İşaret Fişeği. Lit ("Yak") once the island's quest
## allows it (`needs`): the Mavi Titreme draws back from the island and the
## flare keeps burning as a big warm light (group "light_ring"). Event
## "light"/`fire_target`; the flag is `flare_id`.

signal fired(flare: SignalFlare)

const RADIUS := 7.0

@export var flare_id := "s3_fisek0"
## "quest/objective", a whole "quest" (ready or done), or "" = always.
@export var needs := ""
@export var locked_bark := ""
@export var fire_target := "fisek"
var radius := RADIUS
var lit := false
var _light: OmniLight3D
var _top: Node3D


func _build() -> void:
	action_label = "Yak"
	reach = 1.6
	if ModelImport.fit_static("isaret_fisegi", self, Vector3(0, 1.2, 0), Vector3(1.4, 2.4, 1.4)) == null:
		Toon.part(self, "box", Vector3(1.0, 0.5, 1.0), Color("#8a5a3a"), Vector3(0, 0.25, 0))
		Toon.part(self, "cylinder", Vector3(0.45, 1.4, 0.45), Color("#e8c24a"), Vector3(0, 1.2, 0))
		Toon.part(self, "cone", Vector3(0.5, 0.6, 0.5), Color("#e8463a"), Vector3(0, 2.2, 0))
	_top = Node3D.new()
	_top.position.y = 2.7
	add_child(_top)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.8, 0.5)
	_light.light_energy = 0.0
	_light.omni_range = RADIUS * 1.6
	_light.position.y = 3.0
	add_child(_light)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := CylinderShape3D.new()
	b.radius = 0.6
	b.height = 2.2
	c.shape = b
	c.position.y = 1.1
	body.add_child(c)
	add_child(body)
	if GameState.data.has_flag(flare_id):
		_burn()


func _ready() -> void:
	super._ready()
	if lit:
		done()
	# a flare lit before its quest asked for it still counts (see EchoBell)
	GameState.data.quest_changed.connect(_sync)
	_sync.call_deferred()


func _sync(_quest_id := "") -> void:
	if GameState.data.has_flag(flare_id):
		GameState.notify("light", fire_target)


func _allowed(d: PlayerData) -> bool:
	if needs == "":
		return true
	if needs.contains("/"):
		return d.objective_done(needs.get_slice("/", 0), needs.get_slice("/", 1))
	return d.quest_state(needs) in ["ready", "done"]


func _burn() -> void:
	lit = true
	add_to_group("light_ring")
	_light.light_energy = 2.0
	Toon.part(_top, "sphere", Vector3(0.6, 0.8, 0.6), Color("#ffd27a"), Vector3.ZERO, Vector3.ZERO, 2.4, 0.0)


func use(_by: Node) -> void:
	var d := GameState.data
	if lit:
		return
	if not _allowed(d):
		if locked_bark != "":
			GameState.bark(locked_bark)
		return
	d.set_flag(flare_id)
	Audio.play("whoosh")
	Audio.play("fanfare")
	_burn()
	# the rocket: a star shoots up and bursts over the island
	var star := Toon.part(get_parent(), "sphere", Vector3(0.5, 0.5, 0.5), Color("#fff1b0"), global_position + Vector3.UP * 2.6, Vector3.ZERO, 3.0, 0.0)
	var tw := star.create_tween()
	tw.tween_property(star, "position:y", global_position.y + 14.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		for i in 6:
			Effects.sparkle(get_parent(), star.global_position + Vector3(randf_range(-3, 3), randf_range(-1, 2), randf_range(-3, 3)), Tokens.color(["spark-yellow", "sky", "berry", "spark-green"][i % 4]), 16)
		star.queue_free())
	for i in 3:
		Effects.ring(get_parent(), global_position + Vector3.UP * 0.3, 6.0 + i * 5.0, Tokens.color("spark-yellow"), 0.7 + i * 0.2)
	GameState.notify("light", fire_target)
	done()
	fired.emit(self)

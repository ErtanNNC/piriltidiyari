class_name EchoBell
extends Interactable
## A Ses Çanı (Season 2): each region of Kor Vadisi has one. It rings only
## once the region's quest allows it (`ready_flag`, or no flag needed); then
## the Kızıl Sis lifts there and the bell stays lit (a travel point later).

signal rung(bell: EchoBell)

@export var bell_id := "s2_can0"
## The bell rings only when this is done: "quest/objective", or a whole
## "quest" (ready or done); "" = always.
@export var needs := ""
## What the keeper says when it can't ring yet.
@export var locked_bark := "s2c0_kilit"
## The quest event it sends (the region's own bell objective).
@export var ring_target := "ses_cani"
var _bell: Node3D


func _build() -> void:
	action_label = "Çal"
	var wood := Color("#8a5a3c")
	# the real frame model when there is one (the bell itself swings apart)
	if ModelImport.fit_static("ses_cani_cerceve", self, Vector3(0, 2.15, 0), Vector3(3.2, 4.4, 1.5)) == null:
		Toon.part(self, "cylinder", Vector3(0.3, 3.4, 0.3), wood, Vector3(-1.1, 1.7, 0))
		Toon.part(self, "cylinder", Vector3(0.3, 3.4, 0.3), wood, Vector3(1.1, 1.7, 0))
		Toon.part(self, "box", Vector3(2.9, 0.34, 0.34), wood, Vector3(0, 3.4, 0))
		Toon.part(self, "cone", Vector3(3.3, 0.8, 1.4), Color("#c9452f"), Vector3(0, 3.95, 0))
	_bell = Node3D.new()
	_bell.position.y = 3.2
	add_child(_bell)
	if ModelImport.fit_static("ses_cani_zil", _bell, Vector3(0, -0.7, 0), Vector3(1.2, 1.4, 1.2)) == null:
		Toon.part(_bell, "cone", Vector3(1.3, 1.3, 1.3), Color("#c98a3a"), Vector3(0, -0.55, 0))
		Toon.part(_bell, "sphere", Vector3(0.3, 0.3, 0.3), "outline", Vector3(0, -1.2, 0), Vector3.ZERO, 0.0, 0.0)
	var body := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(2.9, 3.6, 0.5)
	c.shape = b
	c.position.y = 1.8
	body.add_child(c)
	add_child(body)
	if GameState.data.has_flag(bell_id):
		_lit()
		action_label = "Seyahat"  # a rung bell is a travel point


func _ready() -> void:
	super._ready()
	# A bell rung before the quest that asks for it had started (say, before
	# going back to the quest giver) still counts: whenever a quest changes,
	# a rung bell sends its event again (does nothing once the objective is
	# done). Old saves stuck this way come loose on load too.
	var d := GameState.data
	d.quest_changed.connect(_sync)
	_sync.call_deferred()


func _sync(_quest_id := "") -> void:
	if GameState.data.has_flag(bell_id):
		GameState.notify("ring", ring_target)


func _allowed(d: PlayerData) -> bool:
	if needs.contains("/"):
		return d.objective_done(needs.get_slice("/", 0), needs.get_slice("/", 1))
	return d.quest_state(needs) in ["ready", "done"]


func _lit() -> void:
	_bell.get_child(0).material_override = Toon.material("spark-yellow", 0.035, 0.8, 0.0)


func use(_by: Node) -> void:
	var d := GameState.data
	if d.has_flag(bell_id):
		_travel()
		return
	if needs != "" and not _allowed(d):
		GameState.bark(locked_bark)
		return
	d.set_flag(bell_id)
	Audio.play("bell")
	var tw := create_tween()
	for i in 3:
		tw.tween_property(_bell, "rotation:z", 0.5, 0.12)
		tw.tween_property(_bell, "rotation:z", -0.5, 0.12)
	tw.tween_property(_bell, "rotation:z", 0.0, 0.1)
	_lit()
	for i in 3:
		Effects.ring(get_parent(), global_position + Vector3.UP * 2.5, 6.0 + i * 4.0, Tokens.color("spark-yellow"), 0.7 + i * 0.2)
	Effects.sparkle(get_parent(), global_position + Vector3.UP * 2.8, Tokens.color("spark-yellow"), 16)
	GameState.notify("ring", ring_target)
	if get_node_or_null("Beacon"):
		get_node("Beacon").queue_free()
	action_label = "Seyahat"
	set_meta("action_label", action_label)
	rung.emit(self)


## Fast travel to another rung bell (`BellTravel`).
func _travel() -> void:
	var d := GameState.data
	var to := BellTravel.destinations(d, bell_id)
	if to.is_empty():
		GameState.toast.emit(TranslationServer.translate("Başka bir çan çalınca buradan oraya gidebilirsin."), "spark")
		return
	var opts := []
	for id: String in to:
		opts.append({"id": id, "label": BellTravel.region(id)})
	var hud := get_tree().get_first_node_in_group("hud") as Hud
	if hud == null:
		return
	var pick: String = await hud.ask("Hangi çana gidelim?", opts)
	if pick == "":
		return
	Audio.play("bell")
	SceneFlow.return_point = BellTravel.arrival(pick)
	SceneFlow.go_to(BellTravel.scene_of(pick))

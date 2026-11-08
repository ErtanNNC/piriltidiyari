extends ChapterBase
## Sezon 2 · Prolog · Sahne 1 – Mırıl'ın İlk Doğum Günü. A year after the
## Fener was lit again, the village throws Mırıl a birthday party. Played as
## Mırıl: walk, talk, and float (hold jump while falling). Hand out four
## invitations (Çıtır waits on a hilltop you can only reach by floating),
## then blow out the candles with Fıstık. Then the red wind comes (Sahne 2).

const QUEST := "davetiyeler"
## The glide course: steps up to a ledge, a gap only a float crosses, and
## Çıtır's hilltop on the other side.
const LEDGE := Vector3(-12, 2.0, 18.5)
const HILL := Vector3(-0.3, 1.5, 17.0)

var _npcs := {}
var _candles: Array[MeshInstance3D] = []
var _hinted := false
var _ending := false


func _ready() -> void:
	Pus.set_amount(0.0)
	_build_party()
	_build_glide_course()
	for k: Array in [["fistik", "fistik", Vector3(1.6, 0, -8.6), 0.0], ["tospik_nine", "turtle", Vector3(-3.2, 0, -8.8), 20.0],
			["pati", "pati", Vector3(-9.0, 0, -1.0), 60.0], ["bado", "bado", Vector3(9.0, 0, 1.5), -60.0],
			["lumi", "lumi", Vector3(5.5, 0, 9.5), -20.0], ["citir", "citir", HILL + Vector3(0.6, 1.5, 0), 30.0]]:
		_npcs[k[0]] = _npc(k[0], k[1], k[2], k[3])
	var d := GameState.data
	d.quest_changed.connect(func(_id: String) -> void: _refresh())
	_refresh()
	await get_tree().create_timer(1.6).timeout
	GameState.bark("s2_basla")
	if DevTools.demo != "":
		await close_dialogs()
		_run_demo(DevTools.demo)


func _npc(id: String, kind: String, at: Vector3, face: float) -> Npc:
	var n := npc(self, id, kind, at, face)
	n.name = id.capitalize().replace(" ", "")
	return n


func _process(_delta: float) -> void:
	if not _hinted and _player.global_position.distance_to(Vector3(LEDGE.x, 0, LEDGE.z - 3.0)) < 5.0:
		_hinted = true
		_hud.show_hint("Boşluk: zıpla, havada basılı tut: süzül!", "Zıpla'ya basılı tut: süzül!")
		get_tree().create_timer(7.0).timeout.connect(_hud.clear_hint)
	if _player.global_position.y > 2.7 and _player.global_position.distance_to(HILL) < 3.0 and not GameState.data.has_flag("s2_suzuldu"):
		GameState.data.set_flag("s2_suzuldu")
		GameState.bark("s2_suzul")


## Stars on the friends still waiting for an invitation; the cake when done.
func _refresh() -> void:
	var d := GameState.data
	var state := d.quest_state(QUEST)
	for id: String in ["pati", "bado", "citir", "lumi"]:
		var waiting := state == "active" and not d.objective_done(QUEST, id)
		_beacon(_npcs[id], waiting)
	_beacon(_npcs["fistik"], state == "none" or state == "ready")
	if state == "done" and not _ending:
		_ending = true
		_blow_candles()


func _beacon(n: Node3D, on: bool) -> void:
	var has := n.has_node("Beacon")
	if on and not has:
		Beacon.attach(n, 2.6, Tokens.color("spark-white"))
	elif not on and has:
		n.get_node("Beacon").queue_free()


## The party in front of the tower: a cake with five candles, bunting, lights.
func _build_party() -> void:
	var at := Vector3(0, 0, -10.2)
	WorldLook.block(self, at + Vector3(0, 0.45, 0), Vector3(2.6, 0.9, 1.4), Color("#c98d5e"))
	Toon.part(self, "cylinder", Vector3(1.0, 0.5, 1.0), Color("#ffd1dc"), at + Vector3(0, 1.15, 0))
	Toon.part(self, "cylinder", Vector3(0.8, 0.35, 0.8), Color("#fff4d6"), at + Vector3(0, 1.55, 0))
	var cols := ["berry", "sky", "spark-yellow", "leaf", "spark-purple"]
	for i in 5:
		var a := TAU * i / 5.0
		var p := at + Vector3(cos(a) * 0.25, 0, sin(a) * 0.25)
		Toon.part(self, "cylinder", Vector3(0.06, 0.3, 0.06), cols[i], p + Vector3(0, 1.85, 0), Vector3.ZERO, 0.0, 0.0)
		_candles.append(Toon.part(self, "sphere", Vector3(0.1, 0.16, 0.1), "honey", p + Vector3(0, 2.06, 0), Vector3.ZERO, 2.0, 0.0))
	var light := OmniLight3D.new()
	light.light_color = Tokens.color("honey")
	light.omni_range = 6.0
	light.light_energy = 1.4
	light.position = at + Vector3(0, 2.4, 0)
	light.name = "CakeLight"
	add_child(light)
	# little party lights strung between the lantern posts
	for i in 12:
		var a := TAU * i / 12.0
		Toon.part(self, "sphere", Vector3(0.22, 0.22, 0.22), cols[i % 5], Vector3(cos(a) * 6.5, 3.1, sin(a) * 6.5), Vector3.ZERO, 1.6, 0.0)


## Steps up to a ledge, a gap, and Çıtır's hilltop: reachable only by
## floating (a plain jump falls short by about 3 m). Falling in just lands
## on the grass, a few steps from the stairs.
func _build_glide_course() -> void:
	var stone := Color("#c9b9a6")
	var grass := Color("#8fcf6a")
	for i in 3:
		var h := float(i + 1)
		WorldLook.block(self, Vector3(LEDGE.x, h * 0.5, LEDGE.z - 5.3 + i * 1.6), Vector3(2.6, h, 1.6), stone)
	var ledge := WorldLook.block(self, LEDGE, Vector3(3.0, 4.0, 2.6), stone)
	ledge.name = "Ledge"
	Toon.part(ledge, "box", Vector3(3.05, 0.12, 2.65), grass, Vector3(0, 2.02, 0), Vector3.ZERO, 0.0, 0.0)
	var hill := WorldLook.block(self, HILL, Vector3(3.4, 3.0, 3.4), stone)
	hill.name = "Hill"
	Toon.part(hill, "box", Vector3(3.45, 0.12, 3.45), grass, Vector3(0, 1.52, 0), Vector3.ZERO, 0.0, 0.0)
	# the sign stands on a post in front of the stairs (not sunk in the grass)
	var sign_at := Vector3(LEDGE.x - 2.4, 0, LEDGE.z - 6.8)
	Toon.part(self, "box", Vector3(0.16, 1.2, 0.16), Color("#a86b45"), sign_at + Vector3(0, 0.6, -0.05))
	TravelSign.board(self, "Çıtır'ın tepesi →", sign_at + Vector3(0, 1.35, 0), 2.6)


## All invitations out and the cake blown: the candles go out, wishes rise.
func _blow_candles() -> void:
	await get_tree().create_timer(0.6).timeout
	for c in _candles:
		Effects.sparkle(self, c.global_position, Tokens.color("spark-white"), 6)
		var tw := c.create_tween()
		tw.tween_property(c, "scale", Vector3.ZERO, 0.3)
	Audio.play("calm")
	var l := get_node_or_null("CakeLight") as OmniLight3D
	if l:
		l.create_tween().tween_property(l, "light_energy", 0.0, 0.6)
	await get_tree().create_timer(2.2).timeout
	if DevTools.demo == "party" and DisplayServer.get_name() == "headless":
		print("S2_PARTY done=%s flag=%s" % [GameState.data.quest_state(QUEST), GameState.data.has_flag("s2_sahne1_bitti")])
		get_tree().quit()
		return
	SceneFlow.go_to("s2_scene2")


func _run_demo(which: String) -> void:
	match which:
		"glide", "jump":
			# from the ledge's edge toward the hilltop: floating gets there,
			# a plain jump doesn't (headless check)
			_player.global_position = LEDGE + Vector3(0.8, 2.1, 0)
			await get_tree().create_timer(0.5).timeout
			var hold := which == "glide"
			Input.action_press("move_right")
			Input.action_press("jump")
			await get_tree().physics_frame
			await get_tree().physics_frame
			if not hold:
				Input.action_release("jump")
			await get_tree().create_timer(2.2).timeout
			Input.action_release("move_right")
			Input.action_release("jump")
			await get_tree().create_timer(0.5).timeout
			var p := _player.global_position
			var on_hill := p.y > 2.8 and absf(p.x - HILL.x) < 1.8 and absf(p.z - HILL.z) < 1.8
			print("S2_GLIDE hold=%s pos=%s on_hill=%s" % [hold, p, on_hill])
			if DisplayServer.get_name() == "headless":
				get_tree().quit()
		"party":
			# the whole scene by talking: start, four invitations, the cake
			DevTools.auto_dialogue = true
			for id: String in ["fistik", "pati", "bado", "citir", "lumi", "fistik"]:
				_player.global_position = _npcs[id].global_position + Vector3(0, 0.3, 1.6)
				await get_tree().create_timer(0.3).timeout
				GameState.talk_to(id)
				await close_dialogs()
		"invite":
			_player.global_position = _npcs["fistik"].global_position + Vector3(0, 0, 2.0)
			await get_tree().create_timer(0.3).timeout
			GameState.talk_to("fistik")
		"stairs":
			_player.global_position = Vector3(LEDGE.x - 1.0, 0.3, LEDGE.z - 9.0)
		"hill":
			_player.global_position = HILL + Vector3(-0.6, 1.7, 0.6)


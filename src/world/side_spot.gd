class_name SideSpot
extends Interactable
## One spot of a Season 2 side collection (SideQuests, content/s2_side.json):
##   minnos: paw prints and a chalk drawing on a little slate ("Bak")
##   davul:  a drum wrapped in a grey "SUS" cloth ("Çöz"); freed drums keep
##           a soft beat you hear when close, the three of a region in turn
##   mektup: a mailbox; after the region's bell its flag is up ("Oku")
## A small floating star marks what is still to find (not through walls,
## so they stay a little hidden).

## Season 3 (content/s3_side.json):
##   sise: a Mesaj Şişesi washed up on the sand, a note from Tırıl ("Oku")
##   isik: a Işık Parçası for Minnoş's night lamp ("Al")
##   kart: Fıstık's postcard in a mailbox, after the island's flare ("Oku")
##   pati: Pati by the water (Bado when you are Pati): stand with them
const COLORS := {"minnos": "spark-green", "davul": "honey", "mektup": "sky",
	"sise": "sky", "isik": "spark-yellow", "kart": "honey", "pati": "berry"}
## drum beat patterns (one char = BEAT seconds), one per drum of a region
const PATTERNS := ["x...x...x.x.....", "..x...x...x...x.", "x.x.....x.x.x..."]
const BEAT := 0.3
const HEAR := 9.0

var scene_id := ""
var index := 0
var spot: Dictionary = {}
var _set := ""
var _star: Node3D
var _cloth: Node3D
var _drum: Node3D
var _flag_arm: Node3D
var _beat_player: AudioStreamPlayer3D
var _beat_t := 0.0
var _beat_i := 0
var _player: Node3D


func _build() -> void:
	_set = spot.get("set", "")
	action_label = String(Content.side.get("sets", {}).get(_set, {}).get("action", "Bak"))
	reach = 1.4
	match _set:
		"minnos":
			_build_drawing()
		"davul":
			_build_drum()
		"mektup", "kart":
			_build_mailbox()
		"sise":
			_build_bottle()
		"isik":
			_build_shard()
		"pati":
			_build_friend()
	_refresh()


func _ready() -> void:
	super._ready()
	set_meta("action_label", action_label)
	if _set == "isik" and is_found():
		done()
	_player = get_tree().get_first_node_in_group("player") as Node3D
	GameState.data.flags_changed.connect(_refresh)


func is_found() -> bool:
	return GameState.data.has_flag(SideQuests.flag(scene_id, index, _set))


func _refresh() -> void:
	var waiting := not is_found() and SideQuests.available(GameState.data, spot)
	if waiting and _star == null:
		_star = Node3D.new()
		_star.name = "SideStar"
		_star.position = Vector3(0, 2.1, 0)
		add_child(_star)
		Toon.part(_star, "sphere", Vector3(0.32, 0.32, 0.32), COLORS.get(_set, "honey"), Vector3.ZERO, Vector3.ZERO, 1.4, 0.03)
		Toon.part(_star, "ring", Vector3(0.62, 0.05, 0.62), "spark-white", Vector3.ZERO, Vector3(90, 0, 0), 1.0, 0.0)
		var tw := _star.create_tween().set_loops()
		tw.tween_property(_star, "position:y", 2.4, 0.9).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_star, "position:y", 2.1, 0.9).set_trans(Tween.TRANS_SINE)
	elif not waiting and _star:
		_star.queue_free()
		_star = null
	# Paytak's Şişe Pusulası: bottles not found yet shine through everything
	if _set == "sise":
		var show := waiting and GameState.data.has_flag("owned_sise_pusulasi")
		if show and not has_node("Beacon"):
			Beacon.attach(self, 2.6, Tokens.color("sky"))
		elif not show and has_node("Beacon"):
			get_node("Beacon").queue_free()
	if _flag_arm:
		_flag_arm.rotation_degrees.z = 0.0 if SideQuests.available(GameState.data, spot) and not is_found() else -90.0
	if _set == "davul" and is_found():
		if _cloth:
			_cloth.visible = false
		_start_beat()


func use(_by: Node) -> void:
	var d := GameState.data
	var def: Dictionary = Content.side["sets"][_set]
	if not SideQuests.available(d, spot):
		GameState.toast.emit(String(def.get("locked", "Posta kutusu boş. Çan çalınca mektup gelir.")), "lantern")
		return
	if is_found():
		# drawings and letters can be read again
		if not _lines(spot, "lines").is_empty():
			GameState.lines_requested.emit(GameState.resolve_speakers(_lines(spot, "lines")), {})
		return
	var events := SideQuests.take(d, Content.side, scene_id, index)
	if events.is_empty():
		return
	var lines := []
	if "first" in events:
		lines.append_array(_lines(def, "first"))
	lines.append_array(_lines(spot, "lines"))
	if "region" in events:
		lines.append_array(_lines(def, "region"))
	if "done" in events:
		lines.append_array(_lines(def, "done"))
	var n := SideQuests.found(d, Content.side, _set)
	var title := TranslationServer.translate(String(def["title"]))
	GameState.toast.emit("%s: %d/%d" % [title, n, SideQuests.total(Content.side, _set)], "star")
	Effects.sparkle(get_parent(), global_position + Vector3.UP, Tokens.color(COLORS.get(_set, "honey")), 16)
	Effects.ring(get_parent(), global_position + Vector3.UP * 0.1, 1.8, Tokens.color(COLORS.get(_set, "honey")), 0.4)
	match _set:
		"davul":
			_free_drum("region" in events)
		"mektup", "kart", "sise":
			Audio.play("page")
		"isik":
			Audio.play("crystal")
		_:
			Audio.play("memory")
	if "done" in events:
		Audio.play("fanfare")
	if not lines.is_empty():
		GameState.lines_requested.emit(GameState.resolve_speakers(lines), {})
	_refresh()
	if _set == "davul":
		done()
	elif _set == "isik":
		# the shard goes into the pocket
		if _shard:
			_shard.queue_free()
		done()


## Lines for whoever is played: "<key>_<keeper id>" wins over "<key>"
## (Pati's secret is told BY Pati when you are Pati).
func _lines(from: Dictionary, key: String) -> Array:
	return from.get("%s_%s" % [key, GameState.data.character_id], from.get(key, []))


# --- looks -----------------------------------------------------------------

func _build_drawing() -> void:
	# paw prints leading up to the slate
	for k in 4:
		var at := Vector3(-0.35 if k % 2 == 0 else 0.0, 0.02, 2.6 - k * 0.6)
		Toon.part(self, "ellipsoid", Vector3(0.22, 0.04, 0.26), Color("#6b4a3a"), at, Vector3.ZERO, 0.0, 0.0)
		for t in 3:
			Toon.part(self, "sphere", Vector3(0.08, 0.04, 0.08), Color("#6b4a3a"), at + Vector3(-0.08 + t * 0.08, 0, -0.17), Vector3.ZERO, 0.0, 0.0)
	var slate := Node3D.new()
	slate.name = "Slate"
	add_child(slate)
	if ModelImport.fit_static("cizim_tahtasi", slate, Vector3(0, 0.8, 0), Vector3(1.2, 1.6, 0.9)):
		return
	slate.rotation_degrees = Vector3(-18, 0, 0)
	Toon.part(slate, "box", Vector3(0.1, 0.9, 0.1), Color("#8a5a3a"), Vector3(0, 0.45, -0.05))
	Toon.part(slate, "box", Vector3(1.1, 0.8, 0.08), Color("#3c4a44"), Vector3(0, 1.05, 0))
	Toon.part(slate, "box", Vector3(1.2, 0.9, 0.06), Color("#b07a4a"), Vector3(0, 1.05, -0.02), Vector3.ZERO, 0.0, 0.0)
	# chalk: a big ear, a little paw, a star
	Toon.part(slate, "ring", Vector3(0.42, 0.04, 0.5), Color("#ffd2e4"), Vector3(-0.18, 1.08, 0.05), Vector3(90, 0, 0), 0.3, 0.0)
	Toon.part(slate, "sphere", Vector3(0.16, 0.16, 0.03), Color("#fff4dc"), Vector3(0.26, 0.95, 0.05), Vector3.ZERO, 0.3, 0.0)
	Toon.part(slate, "sphere", Vector3(0.1, 0.1, 0.03), Color("#ffe066"), Vector3(0.3, 1.25, 0.05), Vector3.ZERO, 0.4, 0.0)


func _build_drum() -> void:
	_drum = Node3D.new()
	_drum.name = "Drum"
	add_child(_drum)
	if ModelImport.fit_static("kucuk_davul", _drum, Vector3(0, 0.42, 0), Vector3(0.95, 0.84, 0.95)):
		_drum_cloth()
		return
	Toon.part(_drum, "cylinder", Vector3(0.9, 0.75, 0.9), Color("#c87a4a"), Vector3(0, 0.38, 0))
	Toon.part(_drum, "cylinder", Vector3(0.84, 0.04, 0.84), Color("#fff4dc"), Vector3(0, 0.77, 0), Vector3.ZERO, 0.0, 0.0)
	for k in 2:
		Toon.part(_drum, "ring", Vector3(0.94, 0.06, 0.94), "honey", Vector3(0, 0.12 + k * 0.52, 0), Vector3.ZERO, 0.0, 0.0)
	_drum_cloth()


## The grey "SUS" cloth tied over a silenced drum.
func _drum_cloth() -> void:
	_cloth = Node3D.new()
	_cloth.name = "Cloth"
	add_child(_cloth)
	Toon.part(_cloth, "ellipsoid", Vector3(1.08, 0.5, 1.08), Color("#8f8f99"), Vector3(0, 0.78, 0))
	Toon.part(_cloth, "cylinder", Vector3(1.0, 0.45, 1.0), Color("#8f8f99"), Vector3(0, 0.5, 0), Vector3.ZERO, 0.0, 0.0)
	Toon.part(_cloth, "ring", Vector3(1.04, 0.07, 1.04), Color("#6a6a74"), Vector3(0, 0.62, 0), Vector3.ZERO, 0.0, 0.0)
	var tag := Label3D.new()
	tag.text = "SUS"
	tag.font = Tokens.font_for("text-heading")
	tag.font_size = 40
	tag.pixel_size = 0.006
	tag.modulate = Tokens.color("panel@light")
	tag.outline_modulate = Color("#2a2433")
	tag.outline_size = 10
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 1.25, 0)
	_cloth.add_child(tag)


func _build_mailbox() -> void:
	if ModelImport.fit_static("posta_kutusu", self, Vector3(0, 0.78, 0), Vector3(0.7, 1.56, 0.95)):
		_mail_flag()
		return
	Toon.part(self, "box", Vector3(0.14, 1.0, 0.14), Color("#8a5a3a"), Vector3(0, 0.5, 0))
	Toon.part(self, "box", Vector3(0.5, 0.42, 0.8), Color("#e8604a"), Vector3(0, 1.18, 0))
	Toon.part(self, "cylinder", Vector3(0.5, 0.8, 0.5), Color("#e8604a"), Vector3(0, 1.39, 0), Vector3(90, 0, 0))
	Toon.part(self, "box", Vector3(0.3, 0.05, 0.02), Color("#2a2433"), Vector3(0, 1.3, 0.41), Vector3.ZERO, 0.0, 0.0)
	_mail_flag()


## A corked bottle half in the sand, a rolled note inside.
func _build_bottle() -> void:
	var b := Node3D.new()
	b.name = "Bottle"
	add_child(b)
	b.rotation_degrees = Vector3(0, 30, 0)
	if ModelImport.fit_static("mesaj_sisesi", b, Vector3(0, 0.38, 0), Vector3(0.75, 0.76, 0.75)):
		return
	b.rotation_degrees = Vector3(0, 30, 62)
	Toon.part(b, "cylinder", Vector3(0.34, 0.6, 0.34), Color("#9fd8d0"), Vector3(0, 0.36, 0), Vector3.ZERO, 0.3, 0.02)
	Toon.part(b, "cylinder", Vector3(0.16, 0.24, 0.16), Color("#9fd8d0"), Vector3(0, 0.76, 0), Vector3.ZERO, 0.3, 0.02)
	Toon.part(b, "cylinder", Vector3(0.18, 0.1, 0.18), Color("#a8794f"), Vector3(0, 0.92, 0))
	Toon.part(b, "cylinder", Vector3(0.14, 0.4, 0.14), Color("#fff4dc"), Vector3(0, 0.34, 0), Vector3.ZERO, 0.2, 0.0)


var _shard: Node3D


## A small warm crystal turning over the sand (gone once taken).
func _build_shard() -> void:
	if is_found():
		return
	_shard = Node3D.new()
	_shard.name = "Shard"
	_shard.position.y = 0.9
	add_child(_shard)
	Toon.part(_shard, "sphere", Vector3(0.34, 0.5, 0.34), "spark-yellow", Vector3.ZERO, Vector3.ZERO, 1.6, 0.02)
	Toon.part(_shard, "ring", Vector3(0.7, 0.05, 0.7), "spark-white", Vector3.ZERO, Vector3(70, 0, 0), 1.0, 0.0)
	var l := OmniLight3D.new()
	l.light_color = Tokens.color("spark-yellow")
	l.omni_range = 3.0
	l.light_energy = 0.8
	_shard.add_child(l)
	var tw := _shard.create_tween().set_loops()
	tw.tween_property(_shard, "rotation:y", TAU, 4.0).from(0.0)


## Pati looking at the water (Bado listens when you play Pati).
func _build_friend() -> void:
	var id := "bado" if GameState.data.character_id == "pati" else "pati"
	var m := KeeperModels.build(id)
	m.name = "Friend"
	m.rotation.y = float(spot.get("face", 180.0)) * PI / 180.0
	add_child(m)
	reach = 1.9


## The flag that stands up while a letter waits.
func _mail_flag() -> void:
	_flag_arm = Node3D.new()
	_flag_arm.name = "Flag"
	_flag_arm.position = Vector3(0.27, 1.15, 0.1)
	add_child(_flag_arm)
	Toon.part(_flag_arm, "box", Vector3(0.04, 0.5, 0.04), Color("#fff4dc"), Vector3(0, 0.25, 0))
	Toon.part(_flag_arm, "box", Vector3(0.04, 0.18, 0.24), Color("#ffd23a"), Vector3(0, 0.42, 0.1))



func _free_drum(region_done: bool) -> void:
	Audio.play("drum")
	if _cloth:
		var c := _cloth
		_cloth = null
		var tw := c.create_tween().set_parallel()
		tw.tween_property(c, "position", Vector3(0.6, 2.4, 0.3), 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(c, "rotation", Vector3(0.8, 2.0, 0.4), 0.6)
		tw.tween_property(c, "scale", Vector3.ONE * 0.01, 0.6).set_delay(0.2)
		tw.chain().tween_callback(c.queue_free)
	var b := _drum.create_tween()
	b.tween_property(_drum, "scale", Vector3(1.15, 0.85, 1.15), 0.08)
	b.tween_property(_drum, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	if region_done:
		# the region's drums play one roll together
		for n in get_tree().get_nodes_in_group("side_drum"):
			(n as SideSpot)._roll()
	_start_beat()


func _roll() -> void:
	var tw := create_tween()
	for k in 6:
		tw.tween_callback(func() -> void:
			_hit_drum(-4.0))
		tw.tween_interval(0.15 if k < 4 else 0.3)


func _start_beat() -> void:
	if _beat_player:
		return
	add_to_group("side_drum")
	_beat_player = AudioStreamPlayer3D.new()
	_beat_player.stream = load("res://assets/audio/sfx/drum.wav")
	_beat_player.bus = "Sfx"
	# the listener is the camera (about 14 m behind the keeper), not the keeper
	_beat_player.unit_size = 9.0
	_beat_player.max_distance = HEAR + 22.0
	_beat_player.position = Vector3(0, 0.8, 0)
	add_child(_beat_player)
	_beat_i = 0


func _process(delta: float) -> void:
	if _beat_player == null or _player == null or not Audio.sfx_on:
		return
	if global_position.distance_to(_player.global_position) > HEAR or GameState.in_dialogue:
		return
	_beat_t += delta
	if _beat_t < BEAT:
		return
	_beat_t -= BEAT
	var pat: String = PATTERNS[index % PATTERNS.size()]
	if pat[_beat_i % pat.length()] == "x":
		_hit_drum(-12.0)
	_beat_i += 1


func _hit_drum(db: float) -> void:
	if _beat_player == null:
		return
	_beat_player.volume_db = db
	_beat_player.pitch_scale = 0.9 + float(index % 3) * 0.12
	_beat_player.play()
	if _drum:
		var b := _drum.create_tween()
		b.tween_property(_drum, "scale", Vector3(1.06, 0.94, 1.06), 0.05)
		b.tween_property(_drum, "scale", Vector3.ONE, 0.15)

class_name Mob
extends CharacterBody3D
## A Pus-touched animal. Grey and grumpy, still cute. It wanders, chases
## when you come near, warns 0.8 s before every attack (a honey ground mark
## and a wind-up), and when beaten turns back into its own colors, shrinks
## and runs off — nobody dies. Drops Pırıl and a little XP.

signal calmed(mob: Mob)

const TELEGRAPH := 0.8
## Köpüklüler sit dazed this long waiting for a breath (Sakinleş), then
## calm down by themselves (with a smaller reward).
const DAZE_TIME := 9.0

static var attackers := 0

@export_enum("kopuklu_tavuk", "gurultucu_kurbaga", "kapici_rakun", "somurtkan_sincap", "sumuklu", "mantar", "dev_mantar", "kirpi_topu", "karga", "kristal_bocek", "yarasa", "firtina_yumagi", "korsan_marti", "kar_tavsani", "buz_dikeni", "golge_kopya") var kind := "sumuklu"
@export var gravity := 22.0
## 0 = the kind's own level (MobStats.LEVELS, a little variety by place)
@export var level := 0
var _tag: Label3D

var hp := 30
var stats: Dictionary
var state := "idle"   # idle, chase, windup, attack, recover, hurt, dazed, calm
var _t := 0.0
var _home := Vector3.ZERO
var _wander := Vector3.ZERO
var _attack_dir := Vector3.ZERO
var _knock := Vector3.ZERO
var _hit_this_attack := false
var _grey: Node3D
var _bright: Node3D
var _player: Player
var _has_token := false
var _flies := false
var _fly_height := 2.6
var _swoop_from := Vector3.ZERO
var _swoop_to := Vector3.ZERO
var _stolen := 0
var _strafe := 1.0


func _ready() -> void:
	if level <= 0:
		level = MobStats.level_of(kind, int(absf(global_position.x * 3.0 + global_position.z * 7.0)) % 2)
	stats = MobStats.scaled(kind, level)
	hp = stats["hp"]
	add_to_group("hittable")
	add_to_group("mob")
	set_meta("hit_radius", 1.0 if kind == "dev_mantar" else 0.5)
	collision_layer = 2
	collision_mask = 1 | 16
	var col := CollisionShape3D.new()
	var s := CapsuleShape3D.new()
	var big := kind == "dev_mantar"
	s.radius = 1.0 if big else 0.45
	s.height = 2.4 if big else 1.0
	col.shape = s
	col.position.y = s.height * 0.5
	add_child(col)
	_flies = stats.get("flies", false)
	if _flies:
		collision_mask = 16  # flies over hedges; only blocked by beams
	_grey = MobModels.build(kind, true)
	add_child(_grey)
	_level_tag()
	_home = global_position
	_wander = _home
	_t = randf() * 2.0


## Spawns a mob with a little grey puff. Used by scene directors.
static func spawn(parent: Node, mob_kind: String, at: Vector3) -> Mob:
	var m := Mob.new()
	m.kind = mob_kind
	parent.add_child(m)
	m.global_position = at
	# _ready ran before the move: home is where it was placed (so a mob
	# knocked off a ledge or roof hops back here, never somewhere unreachable)
	m._home = at
	m._wander = at
	Effects.sparkle(parent, at + Vector3.UP, Tokens.color("pus"), 8)
	return m


func _physics_process(delta: float) -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
	_t -= delta
	var move := Vector3.ZERO
	var to_player := Vector3.ZERO
	var dist := INF
	if _player and not _player.asleep:
		to_player = _player.global_position - global_position
		to_player.y = 0.0
		dist = to_player.length()
	match state:
		"idle":
			if dist < stats["aggro"] * GameState.notice_factor():
				state = "chase"
			else:
				if _t <= 0.0:
					_t = randf_range(1.5, 3.0)
					_wander = _home + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
				var w := _wander - global_position
				w.y = 0.0
				if w.length() > 0.3:
					move = w.normalized() * stats["speed"] * 0.5
		"chase":
			if dist > stats["aggro"] * 1.6 * GameState.notice_factor():
				state = "idle"
			elif dist <= stats["range"] and not GameState.in_dialogue and (attackers < MobStats.MAX_ATTACKERS or kind == "dev_mantar"):
				_windup(to_player)
			elif stats["attack"] == "throw" and dist < 3.5:
				# a thrower keeps its distance: hop back
				move = -to_player.normalized() * stats["speed"]
			elif dist <= stats["range"] + 1.8 and stats["attack"] != "throw":
				# wait for a turn: circle around at a polite distance
				var side := to_player.normalized().cross(Vector3.UP) * _strafe
				var keep := -to_player.normalized() * (1.0 if dist < stats["range"] + 0.8 else -0.3)
				move = (side + keep).normalized() * stats["speed"] * 0.6
			else:
				move = to_player.normalized() * stats["speed"]
			move += _separation()
		"windup":
			# 0.8 s tell: wobble and swell. Damage only comes after it.
			var k := 1.0 - _t / TELEGRAPH
			if stats["attack"] != "burrow":
				_grey.scale = Vector3.ONE * (1.0 + 0.18 * k) * Vector3(1.0 + sin(k * 40.0) * 0.04, 1.0, 1.0)
			if _t <= 0.0:
				_grey.scale = Vector3.ONE
				_attack()
		"attack":
			if stats["attack"] == "charge":
				move = _attack_dir * 11.0
				_grey.rotate_object_local(Vector3.RIGHT, delta * 18.0)
				if not _hit_this_attack and dist < 1.2 and _player.hurt(stats["damage"], global_position):
					_hit_this_attack = true
			elif stats["attack"] == "swoop":
				var k := 1.0 - _t / 0.45
				global_position = _swoop_from.lerp(_swoop_to, clampf(k, 0.0, 1.0))
				if not _hit_this_attack and k >= 0.9 and _player.global_position.distance_to(_swoop_to) < 1.4:
					_hit_this_attack = _player.hurt(stats["damage"], _swoop_to)
					if _hit_this_attack and stats.has("steals"):
						var n := mini(int(stats["steals"]), GameState.data.piril)
						if n > 0 and GameState.data.spend_piril(n):
							_stolen += n
							GameState.toast.emit(TranslationServer.translate("Korsan Martı %d Pırıl kaptı!") % n, "piril")
			elif stats["attack"] == "lunge":
				move = _attack_dir * 10.0
				if not _hit_this_attack and dist < 1.2 and _player.hurt(stats["damage"], global_position):
					_hit_this_attack = true
			if _t <= 0.0:
				state = "recover"
				# charge and swoop leave it dizzy / grounded: the moment to hit it
				_t = 1.8 if stats["attack"] in ["charge", "swoop", "burrow"] else 1.4
				_grey.rotation = Vector3.ZERO
				_release_token()
		"recover", "hurt":
			if _t <= 0.0:
				state = "chase"
		"dazed":
			if _t <= 0.0:
				_calm()
		"calm":
			var away := -to_player.normalized() if dist < INF else Vector3.BACK
			move = away * 6.0
	velocity.x = move.x + _knock.x
	velocity.z = move.z + _knock.z
	_knock = _knock.move_toward(Vector3.ZERO, 25.0 * delta)
	if _flies and state != "attack":
		var want_y := 0.0 if state in ["recover", "hurt", "calm"] else _fly_height
		velocity.y = (want_y - global_position.y) * 4.0
	elif not _flies:
		velocity.y -= gravity * delta
		if is_on_floor() and velocity.y < 0.0:
			velocity.y = 0.0
	if state == "attack" and stats["attack"] == "swoop":
		pass  # position driven directly
	else:
		move_and_slide()
	if not _flies and global_position.y < _home.y - 2.5 and state != "calm":
		# knocked off a ledge: hop back to where it started (never unreachable)
		global_position = _home + Vector3.UP * 0.5
		velocity = Vector3.ZERO
		_knock = Vector3.ZERO
		Effects.sparkle(get_parent(), global_position + Vector3.UP, Tokens.color("pus"), 6)
	var rig := _grey.find_child("Rig", true, false) as CharacterRig if is_instance_valid(_grey) else null
	if rig:
		rig.speed = Vector2(move.x, move.z).length() / maxf(float(stats["speed"]), 0.1)
		rig.airborne = state == "attack" and stats["attack"] in ["swoop", "lunge"]
	var face := move if move.length() > 0.1 else (to_player if state == "windup" else Vector3.ZERO)
	if face.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(face.x, face.z), 1.0 - exp(-10.0 * delta))


func _windup(to_player: Vector3) -> void:
	if not _has_token:
		_has_token = true
		attackers += 1
	_strafe = -1.0 if randf() < 0.5 else 1.0
	state = "windup"
	_t = TELEGRAPH
	_attack_dir = to_player.normalized()
	if stats["attack"] == "burst" or stats["attack"] == "blast":
		Effects.warning(get_parent(), global_position, stats["range"], TELEGRAPH)
	elif stats["attack"] == "charge":
		for k in 4:
			Effects.warning(get_parent(), global_position + _attack_dir * (1.5 + k * 2.0), 0.7, TELEGRAPH)
	elif stats["attack"] == "throw":
		_swoop_to = _player.global_position if _player else global_position
		Effects.warning(get_parent(), _swoop_to, 1.2, TELEGRAPH)
	elif stats["attack"] == "swoop" or stats["attack"] == "burrow":
		_swoop_to = _player.global_position if _player else global_position
		_swoop_to.y = global_position.y if stats["attack"] == "burrow" else 0.0
		Effects.warning(get_parent(), Vector3(_swoop_to.x, 0.0, _swoop_to.z) + Vector3.UP * global_position.y, 1.3, TELEGRAPH)
		if stats["attack"] == "burrow":
			# dig down: can't be hit while underground
			remove_from_group("hittable")
			var dig := create_tween()
			dig.tween_property(_grey, "position:y", -1.4, 0.35).set_ease(Tween.EASE_IN)
			Effects.sparkle(get_parent(), global_position + Vector3.UP * 0.3, Tokens.color("pus"), 8)
	else:
		var mark := Effects.warning(get_parent(), global_position + _attack_dir * 1.8, 1.1, TELEGRAPH)
		mark.scale.z *= 1.6


func _attack() -> void:
	var rig := _grey.find_child("Rig", true, false) as CharacterRig if is_instance_valid(_grey) else null
	if rig:
		rig.attack()
	state = "attack"
	_hit_this_attack = false
	if stats["attack"] == "charge":
		_t = 1.0
		return
	if stats["attack"] == "swoop":
		_t = 0.45
		_swoop_from = global_position
		return
	if stats["attack"] == "burrow":
		# pop up where the circle warned, then sit dizzy (hit it now!)
		global_position = _swoop_to
		_t = 0.3
		var up := create_tween()
		up.tween_property(_grey, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_BACK)
		Effects.ring(get_parent(), global_position + Vector3.UP * 0.2, 1.6, Tokens.color("pus"), 0.3)
		if _player and Vector2(_player.global_position.x - global_position.x, _player.global_position.z - global_position.z).length() < 1.3:
			_player.hurt(stats["damage"], global_position)
		add_to_group("hittable")
		return
	if stats["attack"] == "throw":
		_t = 0.5
		_throw_snowball(_swoop_to)
		return
	if stats["attack"] == "blast":
		# a puff of storm: shoves you away, small damage
		_t = 0.25
		Effects.ring(get_parent(), global_position + Vector3.UP * 0.5, stats["range"] + 0.5, Color(1, 1, 1, 0.9), 0.35)
		if _player and _player.global_position.distance_to(global_position) <= stats["range"] + 0.4:
			var away := _player.global_position - global_position
			away.y = 0.0
			_player.push(away.normalized() * 13.0)
			_player.hurt(stats["damage"], global_position)
		return
	if stats["attack"] == "burst":
		_t = 0.25
		Effects.ring(get_parent(), global_position + Vector3.UP * 0.3, stats["range"], Tokens.color("pus"), 0.35)
		if _player and _player.global_position.distance_to(global_position) <= stats["range"] + 0.4:
			_player.hurt(stats["damage"], global_position)
	else:
		_t = 0.3


## Called by the player's attacks.
func hit(damage: int, from: Vector3, push: float) -> void:
	Effects.hit(self)
	if state == "calm" or state == "dazed":
		return
	hp -= damage
	var away := global_position - from
	away.y = 0.0
	_knock = away.normalized() * push * (0.35 if kind == "dev_mantar" else 1.0)
	FloatText.spawn(get_parent(), global_position + Vector3.UP * (3.0 if kind == "dev_mantar" else 1.6), str(damage), Tokens.color("panel@light"))
	var tw := create_tween()
	tw.tween_property(_grey, "scale", Vector3(1.25, 0.75, 1.25), 0.06)
	tw.tween_property(_grey, "scale", Vector3.ONE, 0.12)
	if hp <= 0:
		if MobStats.breathes(kind):
			_daze()
		else:
			_calm()
	elif state != "windup" or kind != "dev_mantar":
		if state == "windup" or state == "attack":
			_release_token()
			_grey.position.y = 0.0
		state = "hurt"
		_t = 0.35


## Rolling into a mob knocks it back without damage.
func bump(from: Vector3) -> void:
	if state == "calm":
		return
	var away := global_position - from
	away.y = 0.0
	_knock = away.normalized() * (4.0 if kind == "dev_mantar" else 8.0)


## A Köpüklü at 0 HP: it plops down, stars spin over its head and the steam
## keeps puffing. A breath (Sakinleş, `breathe_calm`) calms it for a bigger
## reward; left alone it calms down by itself after DAZE_TIME.
func _daze() -> void:
	state = "dazed"
	_t = DAZE_TIME
	_release_token()
	_knock = Vector3.ZERO
	add_to_group("dazed")
	remove_from_group("mob")
	var tw := create_tween()
	tw.tween_property(_grey, "scale", Vector3(1.15, 0.8, 1.15), 0.18).set_trans(Tween.TRANS_BACK)
	var stars := Node3D.new()
	stars.name = "DazeStars"
	stars.position.y = 1.7
	add_child(stars)
	for i in 3:
		var a := TAU * i / 3.0
		Toon.part(stars, "sphere", Vector3(0.16, 0.16, 0.16), "spark-yellow", Vector3(cos(a) * 0.4, 0, sin(a) * 0.4), Vector3.ZERO, 1.6, 0.0)
	var spin := stars.create_tween().set_loops()
	spin.tween_property(stars, "rotation:y", TAU, 1.2).from(0.0)
	GameState.notify("daze", kind)


## Yıldız Ninnisi: a Köpüklü sits down dazed right away; anything else
## takes a soft hit.
func lull() -> void:
	if state == "calm" or state == "dazed":
		return
	if MobStats.breathes(kind):
		hp = 0
		_knock = Vector3.ZERO
		if state == "windup" or state == "attack":
			_grey.scale = Vector3.ONE
			_grey.position.y = 0.0
		GameState.notify("lull", kind)
		GameState.notify("lull", "any")
		_daze()
	else:
		hit(maxi(1, stats["hp"] / 3), global_position + Vector3.BACK, 2.0)


## Sakinleş finished on this mob: a deep breath, steam gone, double Pırıl.
func breathe_calm() -> void:
	if state != "dazed":
		return
	_breathed = true
	GameState.notify("breathe", kind)
	GameState.notify("breathe", "any")
	_calm()


var _breathed := false


## Beaten: back to its own colors, small, and off it runs. Never "dies".
func _calm() -> void:
	remove_from_group("dazed")
	if has_node("DazeStars"):
		get_node("DazeStars").queue_free()
	state = "calm"
	Audio.play("calm")
	_release_token()
	remove_from_group("hittable")
	remove_from_group("mob")
	collision_layer = 0
	collision_mask = 1
	Effects.sparkle(get_parent(), global_position + Vector3.UP, Tokens.color("honey"), 14)
	_grey.queue_free()
	_bright = MobModels.build(kind, false)
	add_child(_bright)
	var tw := create_tween()
	tw.tween_property(_bright, "scale", Vector3.ONE * 0.5, 0.35).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(1.2)
	tw.tween_property(_bright, "scale", Vector3.ZERO, 0.3)
	tw.tween_callback(queue_free)
	if has_meta("carry"):
		# a grabbed thing (a cub's toy) is let go
		var toy := Pickup.new()
		toy.item_id = String(get_meta("carry"))
		get_parent().add_child(toy)
		toy.global_position = global_position + Vector3(0, 0, 0.8)
		GameState.notify("drop", String(get_meta("carry")))
	var drops: int = int(stats["piril"]) * (2 if _breathed else 1) + _stolen
	if _breathed:
		FloatText.spawn(get_parent(), global_position + Vector3.UP * 2.7, TranslationServer.translate("Derin nefes!"), Tokens.color("leaf"))
	for i in drops:
		var p := Pickup.new()
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
	FloatText.spawn(get_parent(), global_position + Vector3.UP * 2.2, TranslationServer.translate("+%d XP") % int(stats["xp"]), Tokens.color("xp"))
	if _tag:
		_tag.queue_free()
	GameState.data.add_xp(stats["xp"])
	GameState.notify("defeat", kind)
	GameState.notify("defeat", "pus")
	calmed.emit(self)


## A snowball in a little arc onto the warned spot.
func _throw_snowball(spot: Vector3) -> void:
	# a snowball, or an acorn from the sulky squirrel
	var acorn := kind == "somurtkan_sincap"
	var ball := Toon.part(get_parent(), "sphere", Vector3(0.36, 0.42, 0.36) if acorn else Vector3(0.5, 0.5, 0.5),
		Color("#8a5a3c") if acorn else MountainKit.SNOW, global_position + Vector3.UP * 1.0)
	var from := ball.global_position
	var tw := ball.create_tween()
	tw.tween_method(func(k: float) -> void:
		ball.global_position = from.lerp(spot, k) + Vector3.UP * (sin(k * PI) * 2.5 + (1.0 - k) * 0.2), 0.0, 1.0, 0.4)
	await tw.finished
	Effects.ring(get_parent(), spot + Vector3.UP * 0.2, 1.4, Tokens.color("panel@light"), 0.25)
	if _player and Vector2(_player.global_position.x - spot.x, _player.global_position.z - spot.z).length() < 1.3:
		_player.hurt(stats["damage"], spot)
	ball.queue_free()


func _release_token() -> void:
	if _has_token:
		_has_token = false
		attackers = maxi(attackers - 1, 0)


func _exit_tree() -> void:
	_release_token()


## Keep a little space between mobs so they don't stack into one blob.
func _separation() -> Vector3:
	var push := Vector3.ZERO
	for other in get_tree().get_nodes_in_group("mob"):
		if other == self:
			continue
		var d: Vector3 = global_position - (other as Node3D).global_position
		d.y = 0.0
		var l := d.length()
		if l > 0.01 and l < 1.6:
			push += d / l * (1.6 - l) * 2.0
	return push


## "Sv 7" over its head: honey = your level, leaf = easier, berry = tougher.
func _level_tag() -> void:
	_tag = Label3D.new()
	_tag.text = TranslationServer.translate("Sv %d") % level
	_tag.font = Tokens.font_for("text-heading")
	_tag.font_size = 56
	_tag.pixel_size = 0.006
	_tag.outline_size = 14
	_tag.outline_modulate = Tokens.color("outline")
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.no_depth_test = true
	var diff := level - GameState.data.level
	_tag.modulate = Tokens.color("leaf" if diff <= -3 else ("hp" if diff >= 3 else "honey"))
	_tag.position.y = 3.6 if kind == "dev_mantar" else (2.1 if stats.get("flies", false) else 1.7)
	add_child(_tag)

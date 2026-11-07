class_name CharacterRig
extends Node
## Small procedural animation for primitive-built characters. It looks for
## named nodes under `pose` (Body, Head, HandL/R, FootL/R, Tail, EarL/R) and
## eyes in the "rig_eye" group; whatever is missing is skipped. It only moves
## `pose` and its children, never the model root (the player owns that).
##   idle: breathing, blinking, ear twitch, tail wag
##   walk: steps, arm swing, waddle      (set `speed` 0..1 each frame)
##   one-shots: jump(), land(), attack(), happy()

var pose: Node3D
var speed := 0.0
var airborne := false

var _parts: Dictionary = {}
var _rest: Dictionary = {}
var _eyes: Array = []
var _t := 0.0
var _walk := 0.0
var _step := 0.0
var _blink_in := 2.0
var _blink := 0.0
var _squash := 0.0
var _squash_v := 0.0
var _arms_up := 0.0
var _hop := 0.0
var _phase := 0.0
## Imported models: their own AnimationPlayer clips (idle/walk/run/jump/attack).
var _anim: AnimationPlayer
var _clips: Dictionary = {}
var _oneshot := 0.0


## Wraps the root's children in a "Pose" node and adds the rig to `root`.
static func attach(root: Node3D) -> CharacterRig:
	var p := root.get_node_or_null("Pose") as Node3D
	if p == null:
		p = Node3D.new()
		p.name = "Pose"
		var kids := root.get_children()
		root.add_child(p)
		for k in kids:
			k.reparent(p, false)
	var rig := CharacterRig.new()
	rig.name = "Rig"
	rig.pose = p
	root.add_child(rig)
	return rig


static func of(root: Node) -> CharacterRig:
	return root.get_node_or_null("Rig") as CharacterRig if root else null


func _ready() -> void:
	_phase = randf() * TAU
	_blink_in = randf_range(0.5, 3.0)
	for n in ["Body", "Head", "HandL", "HandR", "FootL", "FootR", "Tail", "EarL", "EarR", "WingL", "WingR"]:
		var node := pose.find_child(n, true, false) as Node3D
		if node:
			_parts[n] = node
			_rest[n] = node.transform
	for e in pose.find_children("*", "Node3D", true, false):
		if e.is_in_group("rig_eye"):
			_eyes.append(e)
	var found := pose.find_children("*", "AnimationPlayer", true, false)
	_anim = found[0] if not found.is_empty() else null
	if _anim:
		for clip in _anim.get_animation_list():
			var low := String(clip).to_lower()
			for key in ["idle", "walk", "run", "jump", "attack", "punch", "slash", "happy", "wave"]:
				if low.contains(key) and not _clips.has(key):
					_clips[key] = clip
		for key in ["idle", "walk", "run"]:
			if _clips.has(key):
				_anim.get_animation(_clips[key]).loop_mode = Animation.LOOP_LINEAR
		_play("idle")


func _play(key: String, oneshot := false) -> bool:
	var clip: Variant = _clips.get(key)
	if clip == null and key == "attack":
		clip = _clips.get("punch", _clips.get("slash"))
	if clip == null and key == "happy":
		clip = _clips.get("wave")
	if clip == null and key == "run":
		clip = _clips.get("walk")
	if clip == null:
		return false
	if _anim.current_animation != clip:
		_anim.play(clip, 0.15)
	if oneshot:
		_oneshot = _anim.get_animation(clip).length
	return true


func jump() -> void:
	if _anim:
		_play("jump", true)
	_squash_v = 5.0
	_squash = -0.12


func land() -> void:
	_squash = 0.22
	_squash_v = 0.0


func attack() -> void:
	if _anim:
		_play("attack", true)
	_arms_up = 1.0


func happy() -> void:
	_hop = 1.0
	_arms_up = 1.0


func _process(delta: float) -> void:
	if pose == null or not is_instance_valid(pose):
		return
	_t += delta
	_walk = move_toward(_walk, clampf(speed, 0.0, 1.0), delta * 6.0)
	if _walk > 0.05:
		_step += delta * 11.0 * (0.6 + 0.4 * _walk)
	_arms_up = move_toward(_arms_up, 0.0, delta * 3.0)
	# squash & stretch spring (positive = squashed)
	_squash_v += (-_squash * 120.0 - _squash_v * 12.0) * delta
	_squash += _squash_v * delta
	var breath := sin(_t * 2.4 + _phase) * 0.018 * (1.0 - _walk)
	var sq := _squash + (0.08 if airborne else 0.0) * -1.0
	var sy := 1.0 + breath - sq
	var sxz := 1.0 - breath * 0.5 + sq * 0.5
	pose.scale = Vector3(sxz, sy, sxz)
	# waddle and hop
	pose.rotation.z = sin(_step) * 0.07 * _walk
	_hop = move_toward(_hop, 0.0, delta * 1.6)
	pose.position.y = absf(sin(_hop * PI * 3.0)) * 0.35 * _hop
	if _anim:
		_oneshot -= delta
		if _oneshot <= 0.0:
			_play("idle" if speed < 0.1 else ("run" if speed > 0.7 else "walk"))
		return
	_animate_parts()
	_animate_eyes(delta)


func _animate_parts() -> void:
	var swing := sin(_step) * _walk
	for side in [["L", 1.0], ["R", -1.0]]:
		var s: float = side[1]
		var foot: Node3D = _parts.get("Foot" + side[0])
		if foot:
			var t: Transform3D = _rest["Foot" + side[0]]
			foot.transform = t
			foot.position = t.origin + Vector3(0, maxf(0.0, swing * s) * 0.14, swing * s * 0.16)
		var hand: Node3D = _parts.get("Hand" + side[0])
		if hand:
			var t2: Transform3D = _rest["Hand" + side[0]]
			hand.transform = t2
			var up := _arms_up * 0.35
			hand.position = t2.origin + Vector3(0, up + sin(_t * 2.4 + _phase) * 0.012, -swing * s * 0.14 + _arms_up * 0.12)
		var ear: Node3D = _parts.get("Ear" + side[0])
		if ear:
			var t3: Transform3D = _rest["Ear" + side[0]]
			var twitch := 0.0
			var cyc := fmod(_t + _phase + (0.0 if s > 0 else 0.15), 4.3)
			if cyc < 0.25:
				twitch = sin(cyc / 0.25 * PI) * 0.25
			ear.transform = t3.rotated_local(Vector3.FORWARD, twitch * s + swing * 0.08)
		var wing: Node3D = _parts.get("Wing" + side[0])
		if wing:
			var t4: Transform3D = _rest["Wing" + side[0]]
			var flap := sin(_t * (9.0 if _walk > 0.1 or airborne else 3.0) + _phase) * (0.35 if _walk > 0.1 or airborne else 0.12)
			wing.transform = t4.rotated_local(Vector3.FORWARD, flap * s)
	var head: Node3D = _parts.get("Head")
	if head:
		var th: Transform3D = _rest["Head"]
		var tilt := sin(_t * 0.9 + _phase) * 0.04 * (1.0 - _walk)
		head.transform = th.rotated_local(Vector3.FORWARD, tilt - pose.rotation.z * 0.6)
		head.position = th.origin + Vector3(0, absf(sin(_step)) * 0.03 * _walk, 0)
	var tail: Node3D = _parts.get("Tail")
	if tail:
		var tt: Transform3D = _rest["Tail"]
		tail.transform = tt.rotated(Vector3.UP, sin(_t * (3.0 + _walk * 6.0) + _phase) * (0.18 + 0.12 * _walk))
		tail.position = tt.origin


func _animate_eyes(delta: float) -> void:
	if _eyes.is_empty():
		return
	_blink_in -= delta
	if _blink_in <= 0.0:
		_blink = 0.16
		_blink_in = randf_range(2.0, 4.5)
		if randf() < 0.2:
			_blink_in = 0.25  # double blink now and then
	var open := 1.0
	if _blink > 0.0:
		_blink -= delta
		open = 0.12 if _blink > 0.04 and _blink < 0.13 else 0.5
	for e: Node3D in _eyes:
		if is_instance_valid(e):
			e.scale.y = open

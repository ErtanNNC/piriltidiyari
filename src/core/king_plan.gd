class_name KingPlan
extends RefCounted
## Kütük Kral's fight plan (Bölüm 1). He can't sleep, so he's grumpy.
## Roots burst where honey circles warn; his stomp sends a ring along the
## ground (jump over it); after a stomp he yawns, dazed — that's the moment.

const MAX_HP := 420
const DAZE_TIME := 3.2
const ROOT_DAMAGE := 10
const RING_DAMAGE := 12
const RING_SPEED := 9.0       ## m/s the stomp ring spreads
const RING_MAX := 14.0
const JUMP_CLEAR := 0.35      ## feet this high above the ground clear the ring


static func phase(hp: int, max_hp := MAX_HP) -> int:
	var r := float(hp) / float(max_hp)
	if r > 0.66:
		return 1
	if r > 0.33:
		return 2
	return 3


static func cycle(p: int) -> Array[String]:
	match p:
		1:
			return ["roots", "stomp"]
		2:
			return ["roots", "summon", "stomp"]
		_:
			return ["roots", "roots", "stomp"]


static func root_count(p: int) -> int:
	return [3, 4, 5][clampi(p - 1, 0, 2)]


static func rest(p: int) -> float:
	return [1.8, 1.5, 1.2][clampi(p - 1, 0, 2)]


## True when the stomp ring at radius `ring_r` hits someone `dist` away
## whose feet are `height` above the ground.
static func ring_hits(dist: float, ring_r: float, height: float) -> bool:
	return absf(dist - ring_r) < 0.7 and height < JUMP_CLEAR

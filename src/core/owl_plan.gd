class_name OwlPlan
extends RefCounted
## Pus Baykuşu's fight plan (Prolog · Sahne 4): three easy phases.
## Every cycle ends in a dive; after a dive the owl is dazed on the ground
## and only then can the quills hit it ("sersemleyince dikenle vurulur").

const MAX_HP := 360
const STUN_TIME := 3.0
const FEATHER_DAMAGE := 8
const DIVE_DAMAGE := 12


static func phase(hp: int, max_hp := MAX_HP) -> int:
	var r := float(hp) / float(max_hp)
	if r > 0.66:
		return 1
	if r > 0.33:
		return 2
	return 3


## The attacks of one cycle, in order.
static func cycle(p: int) -> Array[String]:
	match p:
		1:
			return ["volley", "volley", "dive"]
		2:
			return ["volley", "dive", "dive"]
		_:
			return ["volley", "volley", "dive", "dive"]


## Feathers per volley and their fan angle (degrees).
static func volley(p: int) -> Vector2:
	match p:
		1:
			return Vector2(3, 40)
		2:
			return Vector2(5, 60)
		_:
			return Vector2(7, 80)


## Seconds between attacks; the 0.8 s tell comes on top of this.
static func rest(p: int) -> float:
	return [1.6, 1.3, 1.0][clampi(p - 1, 0, 2)]

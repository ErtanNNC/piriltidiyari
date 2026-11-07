class_name GolemPlan
extends RefCounted
## Buz Golem Dondurma's fight plan (Bölüm 4): a big golem made of ice-cream
## scoops who froze the Beyaz Kıvılcım. The Pus told him everyone finds him
## too cold to hug. Opening: after a slam his fists are stuck in the ice.

const MAX_HP := 760
const STUCK_TIME := 3.0
const SLAM_DAMAGE := 14
const RING_DAMAGE := 10
const ICICLE_DAMAGE := 10
const BREATH_DAMAGE := 6
const BREATH_SLOW := 0.35
const BREATH_SLOW_TIME := 2.0
const BREATH_RANGE := 7.0
const BREATH_HALF_ANGLE := 30.0


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
			return ["icicles", "slam"]
		2:
			return ["breath", "icicles", "slam"]
		_:
			return ["breath", "icicles", "slam", "slam"]


static func icicles(p: int) -> int:
	return [4, 5, 6][clampi(p - 1, 0, 2)]


static func rest(p: int) -> float:
	return [1.8, 1.5, 1.3][clampi(p - 1, 0, 2)]


## Is `to` (player - golem, flat) inside the breath cone facing `forward`?
static func in_breath(forward: Vector3, to: Vector3) -> bool:
	var flat := Vector3(to.x, 0, to.z)
	if flat.length() > BREATH_RANGE or flat.length() < 0.01:
		return false
	var f := Vector3(forward.x, 0, forward.z).normalized()
	return rad_to_deg(f.angle_to(flat.normalized())) <= BREATH_HALF_ANGLE

class_name CrabPlan
extends RefCounted
## Kristal Yengeç Kıskaç's fight plan (Bölüm 2). A misunderstanding: he is
## guarding the Mavi Kıvılcım from the Pus and thinks you're the Pus.
## He can be hit when a claw is stuck in the ground or when he's dizzy
## after spinning in his shell.

const MAX_HP := 520
const STUCK_TIME := 2.8
const DIZZY_TIME := 2.6
const CLAW_DAMAGE := 14
const BUBBLE_DAMAGE := 8
const SPIN_DAMAGE := 12
const BUBBLE_SPEED := 5.0
const SPIN_DASHES := 3


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
			return ["bubbles", "claw"]
		2:
			return ["bubbles", "claw", "spin"]
		_:
			return ["spin", "bubbles", "claw"]


static func bubbles(p: int) -> int:
	return [5, 7, 9][clampi(p - 1, 0, 2)]


static func rest(p: int) -> float:
	return [1.8, 1.5, 1.2][clampi(p - 1, 0, 2)]


## Every cycle has at least one moment he can be hit.
static func has_opening(p: int) -> bool:
	return cycle(p).has("claw") or cycle(p).has("spin")

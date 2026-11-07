class_name GullPlan
extends RefCounted
## Fırtına Martısı Rüzgâr's fight plan (Bölüm 3). Pırpır's old rival; the
## Pus whispered that Pırpır was better than him, so he became a storm.
## Openings: after every dive he's dazed on the ground.

const MAX_HP := 620
const DAZE_TIME := 3.0
const BOLT_DAMAGE := 12
const DIVE_DAMAGE := 12
const GALE_STRENGTH := 3.5
const GALE_TIME := 1.6


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
			return ["lightning", "dive"]
		2:
			return ["gale", "lightning", "dive"]
		_:
			return ["gale", "lightning", "lightning", "dive"]


static func bolts(p: int) -> int:
	return [4, 5, 6][clampi(p - 1, 0, 2)]


static func rest(p: int) -> float:
	return [1.7, 1.4, 1.2][clampi(p - 1, 0, 2)]

class_name GurledekPlan
extends RefCounted
## Gürledek's fight plan (Sezon 2 · Prolog · Sahne 4): a red thundercloud
## born from a "Sus!" that was never answered. Three easy phases; every
## cycle ends with the cloud sinking low, tired: only then can it be hit.
## At 0 HP it doesn't fall: it starts to cry, and Sakinleş (a breath next to
## it) is what ends the fight.

const MAX_HP := 380
const LOW_TIME := 3.2
const BOLT_DAMAGE := 9
const RAIN_DAMAGE := 4
const BOLT_RADIUS := 1.3
const RAIN_RADIUS := 2.4


static func phase(hp: int, max_hp := MAX_HP) -> int:
	var r := float(hp) / float(max_hp)
	if r > 0.66:
		return 1
	if r > 0.33:
		return 2
	return 3


## The attacks of one cycle, in order ("low" = it sinks down, hittable).
static func cycle(p: int) -> Array[String]:
	match p:
		1:
			return ["bolt", "bolt", "low"]
		2:
			return ["rain", "bolt", "low"]
		_:
			return ["bolt", "rain", "bolt", "low"]


## Lightning spots per strike.
static func bolts(p: int) -> int:
	return [2, 3, 4][clampi(p - 1, 0, 2)]


## Seconds between attacks; the 0.8 s tell comes on top of this.
static func rest(p: int) -> float:
	return [1.5, 1.2, 1.0][clampi(p - 1, 0, 2)]

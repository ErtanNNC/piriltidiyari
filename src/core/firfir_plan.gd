class_name FirfirPlan
extends RefCounted
## Tilki Fırfır's fight plan (Sezon 2 · Bölüm 1 boss): the fox who locked the
## forest when his pinwheel was taken without asking. Three easy phases;
## every cycle ends with him sitting down, out of breath (hittable). At 0 HP
## he is sad, and listening (Sakinleş) ends the fight.

const MAX_HP := 520
const TIRED_TIME := 3.2
const LEAF_DAMAGE := 7
const DASH_DAMAGE := 9
const LEAF_RADIUS := 1.6


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
			return ["leaves", "dash", "tired"]
		2:
			return ["dash", "leaves", "dash", "tired"]
		_:
			return ["leaves", "dash", "leaves", "dash", "tired"]


## Leaf whirls per attack.
static func whirls(p: int) -> int:
	return [3, 4, 5][clampi(p - 1, 0, 2)]


static func rest(p: int) -> float:
	return [1.4, 1.2, 1.0][clampi(p - 1, 0, 2)]

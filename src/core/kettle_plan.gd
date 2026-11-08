class_name KettlePlan
extends RefCounted
## Homurdanan Çaydanlık (Sezon 2 · Bölüm 0 mini boss): the village's big
## copper kettle, boiled over by the Kızıl Sis. It stays in place. Two easy
## phases; every cycle ends with the lid popping up (the only time it can be
## hit). At 0 HP it simmers down and a breath (Sakinleş) cools it.

const MAX_HP := 260
const LID_TIME := 3.0
const JET_DAMAGE := 7
const SPLASH_DAMAGE := 6
const JET_LENGTH := 7.0
const SPLASH_RADIUS := 1.6


static func phase(hp: int, max_hp := MAX_HP) -> int:
	return 1 if float(hp) / float(max_hp) > 0.5 else 2


static func cycle(p: int) -> Array[String]:
	if p == 1:
		return ["jets", "splash", "lid"]
	return ["jets", "splash", "jets", "lid"]


## Steam jets per burst (4 = the four sides; 8 adds the corners).
static func jets(p: int) -> int:
	return 4 if p == 1 else 8


static func rest(p: int) -> float:
	return 1.4 if p == 1 else 1.1

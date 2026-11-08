class_name FokurPlan
extends RefCounted
## Kaynar Kurbağa Fokur's fight plan (Sezon 2 · Bölüm 2 boss): the frog whose
## song was always cut short. Three easy phases; every cycle ends with a big
## hop onto the keeper's spot (warned), after which he sits puffing (the
## moment to hit). At 0 HP he is sad; Sakinleş = listening to his song.

const MAX_HP := 640
const TIRED_TIME := 3.2
const BUBBLE_DAMAGE := 8
const CROAK_DAMAGE := 8
const HOP_DAMAGE := 10
const BUBBLE_RADIUS := 1.5
const CROAK_RADIUS := 4.2
const HOP_RADIUS := 2.0


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
			return ["bubbles", "croak", "hop"]
		2:
			return ["croak", "bubbles", "hop"]
		_:
			return ["bubbles", "croak", "bubbles", "hop"]


static func bubbles(p: int) -> int:
	return [3, 4, 5][clampi(p - 1, 0, 2)]


static func rest(p: int) -> float:
	return [1.4, 1.2, 1.0][clampi(p - 1, 0, 2)]

class_name HirilPlan
extends RefCounted
## Hırıl's final (Sezon 2 · Bölüm 5): the little volcano kid who was always
## told "Sus!". Faz 1 is a fight: lava balls drop on warned circles and he
## calls up the angry ghosts of the keepers you calmed before (Köpüklüler
## from the earlier regions); then he runs out of steam (hittable). At 0 HP
## Faz 2 starts: no fighting, only listening. The keeper brings back the
## words he never got to say (`ECHOES`), one by one, and answers each.

const MAX_HP := 640
const TIRED_TIME := 3.4
const LAVA_DAMAGE := 8
const LAVA_RADIUS := 1.6
## How many echoes Faz 2 plays back (the ones found on the mountain).
const ECHOES := 5
## Never more summoned helpers awake at once.
const MAX_SUMMONED := 2
## Who he calls up: the earlier regions' Köpüklüler.
const SUMMONS := ["kopuklu_tavuk", "kapici_rakun", "laf_kesen_ordek", "kiskanc_civciv", "tepinen_keci"]


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
			return ["lava", "lava", "tired"]
		2:
			return ["lava", "summon", "lava", "tired"]
		_:
			return ["lava", "summon", "lava", "lava", "tired"]


## Lava balls per attack.
static func balls(p: int) -> int:
	return [3, 4, 5][clampi(p - 1, 0, 2)]


static func rest(p: int) -> float:
	return [1.4, 1.2, 1.0][clampi(p - 1, 0, 2)]


## Which earlier Köpüklü the n-th call brings back.
static func summon_kind(n: int) -> String:
	return SUMMONS[n % SUMMONS.size()]


## Faz 2: how much steam is left after `heard` echoes (1 = boiling, 0 = calm).
static func steam_left(heard: int) -> float:
	return clampf(1.0 - float(heard) / float(ECHOES), 0.0, 1.0)

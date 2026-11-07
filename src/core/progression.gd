class_name Progression
extends RefCounted
## Level curve from the design doc (oyun-tasarimi.md → Seviye ve statlar).

const MAX_LEVEL := 30


## XP needed to go from `level` to `level + 1`: round(50 × level^1.6).
static func xp_to_next(level: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	return roundi(50.0 * pow(level, 1.6))


## A new skill unlocks at 5, 10, 15, 20, 25 and 30.
static func unlocks_skill(level: int) -> bool:
	return level % 5 == 0


## What each new level adds: grows with the level so a keeper keeps up with
## the tougher Pus creatures of later regions.
static func hp_gain(level: int) -> int:
	return 10 + level


static func power_gain(level: int) -> int:
	return 2 + level / 5


## A typical keeper's power / max HP at `level` (base 12 power, 100 HP).
## Mob and boss toughness are measured against these.
static func expected_power(level: int) -> int:
	var p := 12
	for l in range(2, level + 1):
		p += power_gain(l)
	return p


static func expected_hp(level: int) -> int:
	var h := 100
	for l in range(2, level + 1):
		h += hp_gain(l)
	return h


## A boss keeps the same number of hits whatever your level: hits land as
## if from the power the fights were tuned for (18) once you're stronger.
static func boss_damage(damage: int, player_power: int) -> int:
	return maxi(1, roundi(damage * 18.0 / maxf(18.0, player_power)))


## Saves from before mob levels: the level a keeper should have for how far
## they got (found sparks). Loading raises them to it; never lowers.
static func catch_up_level(sparks: int, chapter0_done: bool) -> int:
	var by_sparks := [1, 10, 15, 20, 25, 28]
	var lv: int = by_sparks[clampi(sparks, 0, 5)]
	if sparks == 0 and chapter0_done:
		lv = 5
	return lv

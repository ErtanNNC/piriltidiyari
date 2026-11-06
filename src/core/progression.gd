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

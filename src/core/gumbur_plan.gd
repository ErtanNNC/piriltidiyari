class_name GumburPlan
extends RefCounted
## Davulcu Keçi Gümbür's fight plan (Sezon 2 · Bölüm 4 boss): the goat whose
## drumming was laughed at, so he made the whole canyon echo back louder.
## The fight is played to his drum: every bar is four beats, one beat is
## exactly the warning time, so each "bum" lands where it was shown one beat
## before. "x" = a drum hit where the keeper stands, "o" = a ring around
## Gümbür (step away), "-" = a quiet beat. After the bars he stops to catch
## his breath (hittable). At 0 HP he is sad; Sakinleş ends the fight.

const MAX_HP := 560
const BEAT := 0.8
const TIRED_TIME := 3.4
const HIT_RADIUS := 1.5
const RING_RADIUS := 4.0
const DAMAGE := 8


static func phase(hp: int, max_hp := MAX_HP) -> int:
	var r := float(hp) / float(max_hp)
	if r > 0.66:
		return 1
	if r > 0.33:
		return 2
	return 3


## The bars he drums before resting. Every bar starts with a quiet beat so
## the first warning always has a whole beat before it lands.
static func bars(p: int) -> Array[String]:
	match p:
		1:
			return ["-x-x", "-x-o"]
		2:
			return ["-xx-", "-x-o", "-xxo"]
		_:
			return ["-xxx", "-o-x", "-xxo", "-x-o"]


## How long one full cycle (bars + rest) lasts.
static func cycle_time(p: int) -> float:
	return bars(p).size() * 4 * BEAT + TIRED_TIME


## A bar is valid when it has 4 beats, starts quiet and uses known marks.
static func valid_bar(bar: String) -> bool:
	if bar.length() != 4 or bar[0] != "-":
		return false
	for ch in bar:
		if not ch in ["x", "o", "-"]:
			return false
	return true

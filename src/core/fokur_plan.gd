class_name FokurPlan
extends RefCounted
## Kaynar Kurbağa Fokur's fight plan (Sezon 2 · Bölüm 2 boss): the frog whose
## song was always cut short. He hops about the island between attacks
## (bubbles, a croak ring, a tongue along a warned line, a big hop). Every
## cycle ends with his song: let him finish (sıra beklemek) and he sits
## puffing for a long while (the moment to hit); cut in by hitting him and he
## croaks back angrily and skips the rest. At 0 HP he is sad; Sakinleş =
## listening to his song to the end.

const MAX_HP := 640
const TIRED_TIME := 3.2
const BUBBLE_DAMAGE := 8
const CROAK_DAMAGE := 8
const HOP_DAMAGE := 10
const BUBBLE_RADIUS := 1.5
const CROAK_RADIUS := 4.2
const HOP_RADIUS := 2.0
const TONGUE_DAMAGE := 8
const TONGUE_LENGTH := 8.0
const TONGUE_WIDTH := 1.0
## How long his song lasts, and the longer rest you earn by waiting for it.
const SONG_TIME := 2.6
const SONG_REST := 4.6


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
			return ["bubbles", "tongue", "song"]
		2:
			return ["tongue", "croak", "bubbles", "song"]
		_:
			return ["bubbles", "tongue", "croak", "hop", "song"]


## The rest after his song: long if the keeper waited, none if cut short.
static func song_rest(interrupted: bool) -> float:
	return 0.0 if interrupted else SONG_REST


## Is `p` within the tongue's reach (a strip from `from` along `dir`)?
static func tongue_hits(from: Vector2, dir: Vector2, p: Vector2) -> bool:
	var d := dir.normalized()
	var along := (p - from).dot(d)
	if along < 0.0 or along > TONGUE_LENGTH:
		return false
	return absf((p - from).cross(d)) <= TONGUE_WIDTH


static func bubbles(p: int) -> int:
	return [3, 4, 5][clampi(p - 1, 0, 2)]


static func rest(p: int) -> float:
	return [1.4, 1.2, 1.0][clampi(p - 1, 0, 2)]

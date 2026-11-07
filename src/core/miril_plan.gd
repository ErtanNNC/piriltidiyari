class_name MirilPlan
extends RefCounted
## Gölge Prens Mırıl, the final (Bölüm 5). Two phases:
##   Faz 1 – a classic fight: shadow copies and faded echoes of earlier
##           bosses (owl dive, king's ring, golem's icicles). After each cycle
##           he sits down, tired and sad — the moment to reach him.
##   Faz 2 – no fighting: offer the four Kıvılcım one by one; each lights a
##           memory. After the last, the shadow falls away: a star child.

const MAX_HP := 700
const TIRED_TIME := 3.2
const ECHO_DAMAGE := 10
const MAX_COPIES := 2
## The order the sparks are offered in Faz 2 and the memory each one lights.
const OFFER_ORDER := ["green", "blue", "yellow", "white"]


static func cycle(p: int) -> Array[String]:
	match p:
		1:
			return ["copies", "echo_owl", "tired"]
		2:
			return ["echo_ring", "echo_icicles", "tired"]
		_:
			return ["copies", "echo_ring", "echo_owl", "tired"]


static func phase(hp: int, max_hp := MAX_HP) -> int:
	var r := float(hp) / float(max_hp)
	if r > 0.66:
		return 1
	if r > 0.33:
		return 2
	return 3


static func rest(p: int) -> float:
	return [1.7, 1.4, 1.2][clampi(p - 1, 0, 2)]


## Faz 2 can start only with all four sparks gathered in Bölüm 1–4.
static func can_offer(sparks: Array) -> bool:
	for s in OFFER_ORDER:
		if not sparks.has(s):
			return false
	return true

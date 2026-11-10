class_name Rhythm
extends RefCounted
## Season 3: Hırıl's drum. A calm, steady rhythm (beats about the same time
## apart, not too fast, not too slow) is what a sand castle dances to and
## what makes a frightened Titrek stop and listen. `beat(t)` returns how
## many steady beats in a row have been played so far (1 = a fresh start).

const MIN_GAP := 0.32   ## faster than this is a hurried rattle
const MAX_GAP := 1.15   ## slower than this, the rhythm starts again
const WOBBLE := 0.24    ## how much one gap may differ from the one before

var streak := 0
var _last := -100.0
var _gap := 0.0


func beat(t: float) -> int:
	var gap := t - _last
	_last = t
	if gap < MIN_GAP or gap > MAX_GAP:
		streak = 1
		_gap = 0.0
		return streak
	if _gap > 0.0 and absf(gap - _gap) > WOBBLE:
		streak = 2   # this gap starts a new steady pair
	else:
		streak += 1
	_gap = gap
	return streak


func reset() -> void:
	streak = 0
	_last = -100.0
	_gap = 0.0

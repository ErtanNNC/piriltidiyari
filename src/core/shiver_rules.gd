class_name ShiverRules
extends RefCounted
## Season 3: the Titreme barı. Out in the dark Mavi Titreme the bar fills;
## inside a light (your own ring is small, a lit torch is big) it empties.
## Full = donakaldın: a short stand-still that a deep breath (Sakinleş) or a
## friend's hand ends. Holding hands keeps the bar from filling at all.

const FILL := 0.07      ## per second at cold 1.0
const WARM := 0.35      ## per second inside a torch's light
const FROZEN_TIME := 2.5
const BREATH_SPEED := 3.0   ## Sakinleş thaws this many times faster


## The bar after `delta` seconds: `cold` 0..1 (0 = in a torch's light).
static func fill(value: float, cold: float, delta: float, holding_hands := false) -> float:
	if holding_hands:
		return maxf(value - WARM * delta, 0.0)
	if cold <= 0.0:
		return maxf(value - WARM * delta, 0.0)
	return minf(value + FILL * cold * delta, 1.0)

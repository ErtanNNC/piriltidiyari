class_name ThornRules
extends RefCounted
## Season 4: the Diken barı. Where the Yeşil Diken is thick the bar fills;
## away from it, it slowly empties. Full = kıskandın: for a moment the keeper
## only looks at others (no skills, no powers) until it passes. Clapping for
## someone (Alkış) or a Teşekkür Yaprağı empties the bar at once: being glad
## for another and thankful for your own is what stops envy.

const FILL := 0.08       ## per second at thorn 1.0
const DRAIN := 0.05      ## per second away from the vines
const ENVY_TIME := 4.0   ## how long "kıskandın" lasts
const CLAP_RELIEF := 0.5 ## one Alkış for someone takes this much off


## The bar after `delta` seconds in vines of strength `thorn` (0..1).
static func fill(value: float, thorn: float, delta: float) -> float:
	if thorn <= 0.0:
		return maxf(value - DRAIN * delta, 0.0)
	return minf(value + FILL * thorn * delta, 1.0)


static func after_clap(value: float) -> float:
	return maxf(value - CLAP_RELIEF, 0.0)

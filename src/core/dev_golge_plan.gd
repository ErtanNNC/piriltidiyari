class_name DevGolgePlan
extends RefCounted
## Season 3 prologue boss: the Dev Gölge, a huge clawed shadow on the
## cliffs. It can't be hit. Every round of moves ends with a torch coming
## free ("torch"): light it and the shadow shrinks. Three torches = three
## phases; then the shadow's owner shows: a tiny crab in front of a lantern.

const PHASES := 3
const CLAW_DAMAGE := 6
const ROCK_DAMAGE := 5
const SLAM_DAMAGE := 8
const SLAM_RADIUS := 3.6
const ROCK_RADIUS := 1.5
## The shadow's size by torches lit.
const SCALE := [1.0, 0.7, 0.45, 0.12]


static func cycle(phase: int) -> Array[String]:
	match phase:
		1:
			return ["claw", "claw", "torch"]
		2:
			return ["claw", "rocks", "claw", "torch"]
		_:
			return ["slam", "rocks", "claw", "torch"]


static func rocks(phase: int) -> int:
	return [3, 4, 5][clampi(phase - 1, 0, 2)]


static func rest(phase: int) -> float:
	return [1.5, 1.3, 1.1][clampi(phase - 1, 0, 2)]

class_name GardenTravel
extends RefCounted
## Season 4: the Bahar Kapıları between Sera Kasabası and the five gardens.
## A garden's gate opens when the garden before it is finished; a finished
## garden's gate is a travel point. Same list shape as ShoreTravel so the
## gate's menu reads the same way as the boat's.

## scene -> [garden name, flag that opens it ("" = always)]
const GARDENS := {
	"s4_chapter0": ["Sera Kasabası", ""],
	"s4_chapter1": ["Parlak Pazar", "s4_bolum0_bitti"],
	"s4_chapter2": ["Şarkı Çayırı", "s4_bolum1_bitti"],
	"s4_chapter3": ["Yuva Ağacı", "s4_bolum2_bitti"],
	"s4_chapter4": ["Ayna Gölü", "s4_bolum3_bitti"],
	"s4_chapter5": ["Gölge Köşesi", "s4_bolum4_bitti"],
}
const SEEDS := ["lale", "papatya", "gul", "nilufer", "ay_cicegi"]


static func is_open(d: PlayerData, scene: String) -> bool:
	var flag: String = GARDENS[scene][1]
	return flag == "" or d.has_flag(flag)


static func is_done(d: PlayerData, scene: String) -> bool:
	return d.has_flag("s4_bolum%s_bitti" % scene.right(1))


static func next_stop(d: PlayerData) -> String:
	for s: String in GARDENS:
		if is_open(d, s) and not is_done(d, s):
			return s
	return ""


## Every garden in story order: [{scene, n, state}], state "here" | "done" |
## "next" | "open" | "locked".
static func menu(d: PlayerData, here: String) -> Array:
	var out := []
	var nxt := next_stop(d)
	var n := 0
	for s: String in GARDENS:
		n += 1
		var state := "locked"
		if s == here:
			state = "here"
		elif not is_open(d, s):
			state = "locked"
		elif s == nxt:
			state = "next"
		elif is_done(d, s):
			state = "done"
		else:
			state = "open"
		out.append({"scene": s, "n": n, "state": state})
	return out


static func region(scene: String) -> String:
	return GARDENS[scene][0]


static func seeds(d: PlayerData) -> int:
	var n := 0
	for s: String in SEEDS:
		if d.has_flag("tohum_" + s):
			n += 1
	return n

class_name ShoreTravel
extends RefCounted
## Season 3: the Kabuk Kayık sails between the cove and the five islands.
## An island opens when the one before it is finished (its İşaret Fişeği
## burns and its keeper gave the pearl); Mürekkep Adası opens once the
## cove's own flare is lit.

## scene -> [region name, flag that opens it ("" = always)]
const ISLANDS := {
	"s3_chapter0": ["Mercan Koyu", ""],
	"s3_chapter1": ["Mürekkep Adası", "s3_fisek0"],
	"s3_chapter2": ["Rüzgârlı Kayalıklar", "s3_bolum1_bitti"],
	"s3_chapter3": ["Değişen Kumlar", "s3_bolum2_bitti"],
	"s3_chapter4": ["Fırtına Kayası", "s3_bolum3_bitti"],
	"s3_chapter5": ["Kayıp Ada", "s3_bolum4_bitti"],
}
const PEARLS := ["lacivert", "turkuaz", "kum", "gumus", "beyaz"]


static func is_open(d: PlayerData, scene: String) -> bool:
	var flag: String = ISLANDS[scene][1]
	return flag == "" or d.has_flag(flag)


## Where the boat can go from `here`, nearest first.
static func destinations(d: PlayerData, here: String) -> Array[String]:
	var out: Array[String] = []
	for s: String in ISLANDS:
		if s != here and is_open(d, s):
			out.append(s)
	return out


## Finished = the island's last talk is done (flag s3_bolum<N>_bitti).
static func is_done(d: PlayerData, scene: String) -> bool:
	return d.has_flag("s3_bolum%s_bitti" % scene.right(1))


## The island the story sends you to next: the first open one not finished.
static func next_stop(d: PlayerData) -> String:
	for s: String in ISLANDS:
		if is_open(d, s) and not is_done(d, s):
			return s
	return ""


## The boat's list, always in story order with every island on it:
## [{scene, n (1..6), state}] where state is "here", "done", "next" (go here
## now), "open" or "locked".
static func menu(d: PlayerData, here: String) -> Array:
	var out := []
	var nxt := next_stop(d)
	var n := 0
	for s: String in ISLANDS:
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
	return ISLANDS[scene][0]


static func pearls(d: PlayerData) -> int:
	var n := 0
	for p: String in PEARLS:
		if d.has_flag("inci_" + p):
			n += 1
	return n

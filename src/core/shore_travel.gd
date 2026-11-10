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


static func region(scene: String) -> String:
	return ISLANDS[scene][0]


static func pearls(d: PlayerData) -> int:
	var n := 0
	for p: String in PEARLS:
		if d.has_flag("inci_" + p):
			n += 1
	return n

class_name Growth
extends RefCounted
## Season 4: what a planted seed becomes and when. A seed grows in a short
## real time (no "come back tomorrow"); Gübre Topu makes it instant. Some
## kinds open only by day, some only by night (the lesson the final rests
## on: Dırıl is an Ay Çiçeği and blooms at night).

## kind -> {seconds, when ("any" | "day" | "night"), what it becomes}
const KINDS := {
	"kopru": {"seconds": 6.0, "when": "any", "name": "Yaprak Köprü"},
	"merdiven": {"seconds": 6.0, "when": "any", "name": "Sarmaşık Merdiven"},
	"sifa": {"seconds": 8.0, "when": "day", "name": "Şifa Papatyası"},
	"kalkan": {"seconds": 5.0, "when": "any", "name": "Kalkan Yaprağı"},
	"gece": {"seconds": 6.0, "when": "night", "name": "Gece Çiçeği"},
}


static func seconds(kind: String, fertilized := false) -> float:
	return 0.4 if fertilized else float(KINDS.get(kind, {}).get("seconds", 6.0))


## Can this kind grow now? ("night" kinds wait for the night, "day" for day.)
static func can_grow(kind: String, night: bool) -> bool:
	var w := String(KINDS.get(kind, {}).get("when", "any"))
	return w == "any" or (w == "night") == night


## 0..1 after `elapsed` seconds (stays 0 while the time of day is wrong).
static func progress(kind: String, elapsed: float, night: bool, fertilized := false) -> float:
	if not can_grow(kind, night):
		return 0.0
	return clampf(elapsed / seconds(kind, fertilized), 0.0, 1.0)

class_name BellTravel
extends RefCounted
## Season 2 fast travel: every Ses Çanı that has rung is a travel point.
## Using a rung bell lists the other rung bells; you arrive next to them.

## bell flag -> [scene id, region name, arrival point next to the bell]
const BELLS := {
	"s2_can0": ["s2_chapter0", "Buharlı Kaplıca Köyü", Vector3(15.0, 1.8, -15.2)],
	"s2_can1": ["s2_chapter1", "Kızıl Yaprak Ormanı", Vector3(-9.0, 0.3, -10.2)],
	"s2_can2": ["s2_chapter2", "Fokurdayan Göl", Vector3(15.0, 0.3, 17.8)],
	"s2_can3": ["s2_chapter3", "Patpat Tarlaları", Vector3(-15.0, 0.3, -4.2)],
	"s2_can4": ["s2_chapter4", "Gümbür Kanyonu", Vector3(-7.0, 0.3, -9.2)],
	"s2_can5": ["s2_chapter5", "Kükreyen Dağ", Vector3(6.0, 0.3, -10.2)],
}


## The rung bells you can travel to from `here` (a bell flag), in order.
static func destinations(d: PlayerData, here: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in BELLS:
		if id != here and d.has_flag(id):
			out.append(id)
	return out


static func scene_of(bell_id: String) -> String:
	return BELLS[bell_id][0]


static func arrival(bell_id: String) -> Vector3:
	return BELLS[bell_id][2]


static func region(bell_id: String) -> String:
	return BELLS[bell_id][1]

class_name TitrekKinds
extends RefCounted
## Season 3 mobs (Titrekler): creatures shivering in the Mavi Titreme. None
## of them attacks. "model" = the assets/models id (some share one), "fly" =
## nervous hops/flaps while running, "still" = sits like a stone until you
## come close, "level" = the region level (XP only).

const KINDS := {
	"titrek_yengec": {"name": "Titrek Yengeç", "speed": 4.4, "level": 1},
	"urkek_marti": {"name": "Ürkek Martı", "speed": 5.0, "fly": true, "level": 2},
	"saklambac_ahtapotu": {"name": "Saklambaç Ahtapotu", "speed": 4.2, "level": 6},
	"golge_baligi": {"name": "Gölge Balığı", "speed": 5.2, "fly": true, "level": 8},
	"basi_donen_marti": {"name": "Başı Dönen Martı", "speed": 5.2, "fly": true, "model": "urkek_marti", "level": 11},
	"kayan_tas_kaplumbagasi": {"name": "Kayan Taş Kaplumbağası", "speed": 3.0, "still": true, "level": 13},
	"kumdan_hortlak": {"name": "Kumdan Hortlak", "speed": 4.6, "level": 16},
	"kayip_denizyildizi": {"name": "Kayıp Denizyıldızı", "speed": 3.4, "level": 18},
	"gok_bulutu": {"name": "Minik Gök Gürültüsü Bulutu", "speed": 4.8, "fly": true, "level": 21},
	"irkilen_fok_yavrusu": {"name": "İrkilen Fok Yavrusu", "speed": 4.2, "model": "tombik", "scale": 0.5, "level": 23},
	"sis_kuklasi": {"name": "Sis Kuklası", "speed": 4.6, "fly": true, "level": 26},
	"korku_golgesi": {"name": "Korku Gölgesi", "speed": 5.0, "level": 28},
}


static func get_kind(kind: String) -> Dictionary:
	return KINDS.get(kind, KINDS["titrek_yengec"])


static func model(kind: String) -> String:
	return String(get_kind(kind).get("model", kind))


static func speed(kind: String) -> float:
	return float(get_kind(kind)["speed"])

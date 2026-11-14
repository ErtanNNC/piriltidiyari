class_name ShorePlan
extends RefCounted
## Season 3's island keepers (bosses). None of them is angry: they are
## scared, and what they do out of fear is the fight. Three easy phases;
## every cycle ends with the keeper out of breath ("tired" = hittable). At
## 0 HP it trembles, and reaching out a hand (Sakinleş) ends the fight.
##
## Moves: "circles" warned circles round the keeper · "dash" a rush along a
## warned line · "ring" a wide warned ring round the boss · "gust" wind that
## pushes you (no damage) · "ink" dark puddles that fill the Titreme barı ·
## "thunder" four strikes on the beat · "burrow" pops up under a warned
## circle · "tired".

const BEAT := 0.8   ## = Mob.TELEGRAPH: a strike lands one beat after its warning
const TIRED_TIME := 3.4
const CIRCLE_DAMAGE := 7
const RING_DAMAGE := 8
const RING_RADIUS := 4.6
const BURROW_RADIUS := 2.4
const INK_TIME := 7.0
const GUST_TIME := 2.4
const GUST_PUSH := 7.5

const BOSSES := {
	"carsaf": {"name": "Hortlak Çarşaf", "hp": 300, "model": "hortlak_carsaf", "color": "#eef2ff",
		"cycles": [["circles", "tired"], ["dash", "circles", "tired"], ["circles", "dash", "circles", "tired"]]},
	"murekkep": {"name": "Ahtapot Mürekkep", "hp": 560, "model": "murekkep", "color": "#5a4fb0",
		"cycles": [["ink", "circles", "tired"], ["ink", "dash", "circles", "tired"], ["ink", "circles", "dash", "ink", "tired"]]},
	"pamuk": {"name": "Albatros Yavrusu Pamuk", "hp": 620, "model": "pamuk", "color": "#bfe8f2",
		"cycles": [["gust", "circles", "tired"], ["gust", "ring", "circles", "tired"], ["ring", "gust", "circles", "ring", "tired"]]},
	"bikbik": {"name": "Keşiş Yengeç Bikbik", "hp": 680, "model": "bikbik", "color": "#e8a05c",
		"cycles": [["dash", "circles", "tired"], ["burrow", "dash", "tired"], ["burrow", "circles", "dash", "burrow", "tired"]]},
	"tombik": {"name": "Fok Tombik", "hp": 740, "model": "tombik", "color": "#c9d4e8",
		"cycles": [["thunder", "ring", "tired"], ["thunder", "thunder", "ring", "tired"], ["thunder", "ring", "thunder", "ring", "tired"]]},
	# Season 4: the gardens' jealous keepers (they sulk at 0 HP; Alkış ends it)
	"kabak": {"name": "Dev Kabak Bahçıvan", "hp": 260, "model": "dev_kabak", "color": "#f0963c",
		"cycles": [["circles", "tired"], ["dash", "circles", "tired"], ["circles", "dash", "circles", "tired"]]},
	"korkuluk": {"name": "Huysuz Korkuluk", "hp": 320, "model": "korkuluk", "color": "#c9a05c",
		"cycles": [["gust", "circles", "tired"], ["circles", "ring", "tired"], ["gust", "circles", "ring", "tired"]]},
	"sikir": {"name": "Saksağan Şıkır", "hp": 560, "model": "sikir", "color": "#7fb2ee",
		"cycles": [["circles", "dash", "tired"], ["circles", "circles", "dash", "tired"], ["dash", "circles", "dash", "circles", "tired"]]},
	"circir": {"name": "Cırcır Böceği Cırcır", "hp": 620, "model": "circir", "color": "#8fd06a",
		"cycles": [["thunder", "ring", "tired"], ["thunder", "thunder", "ring", "tired"], ["thunder", "ring", "thunder", "ring", "tired"]]},
	"pitpit": {"name": "Serçe Pıtpıt", "hp": 680, "model": "pitpit", "color": "#c9a07a",
		"cycles": [["gust", "dash", "tired"], ["gust", "circles", "dash", "tired"], ["dash", "gust", "circles", "dash", "tired"]]},
	"pacali": {"name": "Ördek Yavrusu Paçalı", "hp": 740, "model": "pacali", "color": "#ffd86a",
		"cycles": [["ring", "circles", "tired"], ["burrow", "ring", "tired"], ["burrow", "circles", "ring", "burrow", "tired"]]},
	"diril": {"name": "Dırıl", "hp": 800, "model": "diril", "color": "#6cc070",
		"cycles": [["circles", "dash", "tired"], ["ring", "thunder", "tired"], ["circles", "ring", "dash", "thunder", "tired"]]},
	"tiril": {"name": "Tırıl", "hp": 800, "model": "tiril", "color": "#9fd8ff",
		"cycles": [["ink", "circles", "tired"], ["gust", "thunder", "tired"], ["ink", "gust", "thunder", "circles", "tired"]]},
}


static func max_hp(id: String) -> int:
	return int(BOSSES[id]["hp"])


static func phase(hp: int, total: int) -> int:
	var r := float(hp) / float(maxi(total, 1))
	if r > 0.66:
		return 1
	if r > 0.33:
		return 2
	return 3


static func cycle(id: String, p: int) -> Array:
	return BOSSES[id]["cycles"][clampi(p - 1, 0, 2)]


static func rest(p: int) -> float:
	return [1.4, 1.2, 1.0][clampi(p - 1, 0, 2)]


## Ink puddles / circles per move.
static func count(p: int) -> int:
	return [3, 4, 5][clampi(p - 1, 0, 2)]

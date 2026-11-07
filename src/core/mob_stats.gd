class_name MobStats
extends RefCounted
## Stats per mob kind. "attack": "lunge" dashes at you, "burst" puffs spores
## around itself. Every attack is announced 0.8 s ahead (Mob.TELEGRAPH).

const KINDS := {
	"sumuklu": {"name": "Puslu Sümüklü", "hp": 30, "speed": 2.4, "damage": 8, "attack": "lunge", "range": 2.6, "aggro": 9.0, "xp": 3, "piril": 2},
	"mantar": {"name": "Somurtkan Mantar", "hp": 40, "speed": 1.6, "damage": 10, "attack": "burst", "range": 2.2, "aggro": 7.0, "xp": 3, "piril": 3},
	"kirpi_topu": {"name": "Huysuz Kirpi Topu", "hp": 45, "speed": 2.6, "damage": 10, "attack": "charge", "range": 7.0, "aggro": 10.0, "xp": 6, "piril": 3},
	"karga": {"name": "Gıcık Karga", "hp": 35, "speed": 3.2, "damage": 9, "attack": "swoop", "range": 6.0, "aggro": 11.0, "xp": 6, "piril": 3, "flies": true},
	"kristal_bocek": {"name": "Gri Kristal Böceği", "hp": 60, "speed": 2.0, "damage": 11, "attack": "burrow", "range": 6.0, "aggro": 9.0, "xp": 9, "piril": 4},
	"yarasa": {"name": "Yarasa Fısıltısı", "hp": 30, "speed": 3.8, "damage": 9, "attack": "swoop", "range": 6.5, "aggro": 12.0, "xp": 8, "piril": 3, "flies": true},
	"firtina_yumagi": {"name": "Fırtına Yumağı", "hp": 55, "speed": 2.2, "damage": 6, "attack": "blast", "range": 3.0, "aggro": 9.0, "xp": 12, "piril": 4},
	"korsan_marti": {"name": "Korsan Martı", "hp": 45, "speed": 4.0, "damage": 8, "attack": "swoop", "range": 6.5, "aggro": 12.0, "xp": 12, "piril": 4, "flies": true, "steals": 3},
	"kar_tavsani": {"name": "Kar Topu Tavşanı", "hp": 60, "speed": 2.8, "damage": 9, "attack": "throw", "range": 8.0, "aggro": 12.0, "xp": 16, "piril": 5},
	"buz_dikeni": {"name": "Buz Dikeni", "hp": 80, "speed": 0.0, "damage": 11, "attack": "burst", "range": 2.6, "aggro": 4.0, "xp": 16, "piril": 5},
	"golge_kopya": {"name": "Gölge Kopya", "hp": 80, "speed": 3.0, "damage": 12, "attack": "lunge", "range": 2.8, "aggro": 11.0, "xp": 30, "piril": 6},
	"dev_mantar": {"name": "Dev Somurtkan Mantar", "hp": 160, "speed": 1.4, "damage": 15, "attack": "burst", "range": 3.4, "aggro": 10.0, "xp": 20, "piril": 15},
}

## How many mobs may wind up an attack at the same time. Kids get one at a time.
const MAX_ATTACKERS := 1


## Each kind's level: it belongs to its region's level range
## (Köy 1–5, Orman 5–10, Mağara 10–15, Liman 15–20, Dağ 20–25, Kale 25–30).
const LEVELS := {"sumuklu": 1, "mantar": 2, "dev_mantar": 4, "kirpi_topu": 6, "karga": 7,
	"kristal_bocek": 11, "yarasa": 12, "firtina_yumagi": 16, "korsan_marti": 17,
	"kar_tavsani": 21, "buz_dikeni": 22, "golge_kopya": 26}


static func level_of(kind: String, variety := 0) -> int:
	return int(LEVELS.get(kind, 1)) + clampi(variety, 0, 1)


## Stats of `kind` at `level`: HP follows a keeper's power at that level,
## damage follows a keeper's HP (gently), XP is about a fifth of a level.
static func scaled(kind: String, level: int) -> Dictionary:
	var s: Dictionary = KINDS[kind].duplicate()
	var pr := float(Progression.expected_power(level)) / Progression.expected_power(1)
	var hr := float(Progression.expected_hp(level)) / Progression.expected_hp(1)
	s["level"] = level
	s["hp"] = roundi(float(s["hp"]) * (1.0 + (pr - 1.0) * 0.65))
	s["damage"] = roundi(float(s["damage"]) * (1.0 + (hr - 1.0) * 0.6))
	s["xp"] = xp_for(level) * (2 if kind == "dev_mantar" or kind == "golge_kopya" else 1)
	s["piril"] = int(s["piril"]) + level / 4
	return s


## Tougher (higher level) creatures give more XP.
static func xp_for(level: int) -> int:
	return maxi(5, roundi(Progression.xp_to_next(level) * 0.22))

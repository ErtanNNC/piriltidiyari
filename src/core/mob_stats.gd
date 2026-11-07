class_name MobStats
extends RefCounted
## Stats per mob kind. "attack": "lunge" dashes at you, "burst" puffs spores
## around itself. Every attack is announced 0.8 s ahead (Mob.TELEGRAPH).

const KINDS := {
	"sumuklu": {"name": "Puslu Sümüklü", "hp": 30, "speed": 2.4, "damage": 8, "attack": "lunge", "range": 2.6, "aggro": 9.0, "xp": 3, "piril": 2},
	"mantar": {"name": "Somurtkan Mantar", "hp": 40, "speed": 1.6, "damage": 10, "attack": "burst", "range": 2.2, "aggro": 7.0, "xp": 3, "piril": 3},
	"kirpi_topu": {"name": "Huysuz Kirpi Topu", "hp": 45, "speed": 2.6, "damage": 10, "attack": "charge", "range": 7.0, "aggro": 10.0, "xp": 6, "piril": 3},
	"karga": {"name": "Gıcık Karga", "hp": 35, "speed": 3.2, "damage": 9, "attack": "swoop", "range": 6.0, "aggro": 11.0, "xp": 6, "piril": 3, "flies": true},
	"dev_mantar": {"name": "Dev Somurtkan Mantar", "hp": 160, "speed": 1.4, "damage": 15, "attack": "burst", "range": 3.4, "aggro": 10.0, "xp": 20, "piril": 15},
}

## How many mobs may wind up an attack at the same time. Kids get one at a time.
const MAX_ATTACKERS := 1

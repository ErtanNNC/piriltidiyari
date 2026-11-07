class_name Powers
extends RefCounted
## Level-up powers. Every new level lets the keeper pick one of three cards:
## a new power, or one more rank (max 5) of a power they have. Active powers
## sit on the on-screen power buttons (O / P keys); passive ones are always on.
## Pure rules, so tests can run them.

const MAX_RANK := 5
const ACTIVE_SLOTS := 2

const DEFS := {
	# active: a button, costs energy (mp), cooldown in seconds
	"yildiz_yagmuru": {"name": "Yıldız Yağmuru", "short": "Yıldız", "kind": "active", "mp": 16, "cd": 3.0, "color": "spark-yellow",
		"desc": "Yakındaki Pus'lu yaratıkların üstüne yıldızlar yağar", "up": "Bir yıldız daha, daha parlak"},
	"gokkusagi_dalgasi": {"name": "Gökkuşağı Dalgası", "short": "Gökkuşağı", "kind": "active", "mp": 14, "cd": 2.5, "color": "sky",
		"desc": "Önüne yelpaze gibi açılan bir gökkuşağı yollar", "up": "Dalga daha uzağa, daha güçlü gider"},
	"baloncuk_patlamasi": {"name": "Baloncuk Patlaması", "short": "Baloncuk", "kind": "active", "mp": 12, "cd": 2.5, "color": "spark-blue",
		"desc": "Her yöne ışıklı baloncuklar fırlatır", "up": "İki baloncuk daha"},
	"isik_donencesi": {"name": "Işık Dönencesi", "short": "Dönence", "kind": "active", "mp": 18, "cd": 7.0, "color": "spark-purple",
		"desc": "Etrafında 6 saniye dönen ışık topları dokunduğunu parlatır", "up": "Bir ışık topu daha"},
	# passive: always on
	"guclu_vurus": {"name": "Güçlü Vuruş", "kind": "passive", "color": "berry",
		"desc": "Bütün vuruşların %10 güçlenir", "up": "%10 daha güçlü"},
	"kocaman_yurek": {"name": "Kocaman Yürek", "kind": "passive", "color": "hp",
		"desc": "Canın 15 artar", "up": "Canın 15 daha artar"},
	"cevik_pati": {"name": "Çevik Patiler", "kind": "passive", "color": "leaf",
		"desc": "Daha hızlı koşarsın", "up": "Biraz daha hızlı"},
}

## When every power is at rank 5, a level-up still gives something nice.
const FALLBACK := "pirildak"
const FALLBACK_PIRIL := 60


static func rank(powers: Dictionary, id: String) -> int:
	return int(powers.get(id, 0))


static func actives(powers: Dictionary) -> Array:
	var out := []
	for id: String in DEFS:
		if DEFS[id]["kind"] == "active" and rank(powers, id) > 0:
			out.append(id)
	return out


## Up to `n` distinct cards to choose from after a level-up.
## Each is {"id", "new": bool, "rank": the rank you'd reach}.
static func choices(powers: Dictionary, rng: RandomNumberGenerator, n := 3) -> Array:
	var pool := []
	var full := actives(powers).size() >= ACTIVE_SLOTS
	for id: String in DEFS:
		var r := rank(powers, id)
		if r >= MAX_RANK:
			continue
		if r == 0 and DEFS[id]["kind"] == "active" and full:
			continue
		pool.append(id)
	# shuffle with the given rng (deterministic in tests)
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = pool[i]
		pool[i] = pool[j]
		pool[j] = t
	# make sure an early pick offers at least one new active power
	if actives(powers).is_empty():
		for i in pool.size():
			if DEFS[pool[i]]["kind"] == "active":
				var t2: Variant = pool[0]
				pool[0] = pool[i]
				pool[i] = t2
				break
	var out := []
	for id: String in pool.slice(0, n):
		out.append({"id": id, "new": rank(powers, id) == 0, "rank": rank(powers, id) + 1})
	if out.is_empty():
		out.append({"id": FALLBACK, "new": false, "rank": 0})
	return out


## Take a card: rank up (or learn) the power and use up one waiting pick.
static func pick(data: PlayerData, id: String) -> void:
	if data.power_picks > 0:
		data.power_picks -= 1
	if id == FALLBACK:
		data.add_piril(FALLBACK_PIRIL)
		return
	if not DEFS.has(id) or rank(data.powers, id) >= MAX_RANK:
		return
	data.powers[id] = rank(data.powers, id) + 1
	if id == "kocaman_yurek":
		data.max_hp += 15
		data.heal(15)
	data.stats_changed.emit()
	data.skills_changed.emit()


## Passive effects.
static func attack_mult(powers: Dictionary) -> float:
	return 1.0 + 0.1 * rank(powers, "guclu_vurus")


static func bonus_hp(powers: Dictionary) -> int:
	return 15 * rank(powers, "kocaman_yurek")


static func bonus_speed(powers: Dictionary) -> float:
	return 0.35 * rank(powers, "cevik_pati")


## Active power numbers at a rank (damage is a multiple of attack power).
static func numbers(id: String, r: int) -> Dictionary:
	match id:
		"yildiz_yagmuru":
			return {"count": 2 + r, "mult": 0.7 + 0.15 * r, "radius": 5.0}
		"gokkusagi_dalgasi":
			return {"reach": 6.0 + 0.6 * r, "mult": 0.9 + 0.2 * r}
		"baloncuk_patlamasi":
			return {"count": 4 + 2 * r, "mult": 0.5 + 0.12 * r}
		"isik_donencesi":
			return {"count": 1 + r, "mult": 0.45 + 0.1 * r, "seconds": 6.0}
	return {}

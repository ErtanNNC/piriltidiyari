class_name Skills
extends RefCounted
## Special skills (L key / skill button). Fıstık learns Dikenli Dönüş in
## Sahne 3; each keeper starts with their own (karakterler.md).

const DEFS := {
	"dikenli_donus": {"name": "Dikenli Dönüş", "short": "Dönüş", "mp": 20, "owner": "fistik"},
	"pence_kombosu": {"name": "Pençe Kombosu", "short": "Kombo", "mp": 15, "owner": "pati"},
	"kucaklama_kalkani": {"name": "Kucaklama Kalkanı", "short": "Kalkan", "mp": 20, "owner": "bado"},
	"findik_firlatma": {"name": "Fındık Fırlatma", "short": "Fındık", "mp": 15, "owner": "citir"},
	"isik_patlamasi": {"name": "Işık Patlaması", "short": "Işık", "mp": 25, "owner": "lumi"},
	# Season 2: Mırıl's lullaby, learned in Sahne 3 (Yankıların Peşinde)
	"yildiz_ninnisi": {"name": "Yıldız Ninnisi", "short": "Ninni", "mp": 20, "owner": "miril"},
	# Season 2's new keeper Tıpış: a well-timed breath turns a hit away
	"derin_nefes": {"name": "Derin Nefes", "short": "Nefes", "mp": 10, "owner": "tipis_panda"},
	# Season 2: each Season 1 keeper learns a calming skill at level 5
	"mirlama": {"name": "Mırlama", "short": "Mırla", "mp": 20, "owner": "pati", "season": 2},
	"kocaman_sarilma": {"name": "Kocaman Sarılma", "short": "Sarıl", "mp": 25, "owner": "bado", "season": 2},
	"komik_yuz": {"name": "Komik Yüz", "short": "Komik", "mp": 20, "owner": "citir", "season": 2},
	"ninni_isigi": {"name": "Ninni Işığı", "short": "Ninni", "mp": 25, "owner": "lumi", "season": 2},
}

## The level a keeper learns their Season 2 calming skill.
const S2_LEVEL := 5
## Mırlama / Komik Yüz reach, Kocaman Sarılma's reach, Ninni Işığı's area.
const PURR_RADIUS := 4.5
const HUG_REACH := 3.0
const LAUGH_RADIUS := 5.0
const NINNI_RADIUS := 5.0
const NINNI_SLOW := 4.0
const NINNI_HEAL := 15


static func for_character(character_id: String) -> String:
	for id: String in DEFS:
		if DEFS[id]["owner"] == character_id and int(DEFS[id].get("season", 1)) == 1:
			return id
	return ""


## The calming skill a keeper learns in Season 2 ("" if none).
static func season2_for(character_id: String) -> String:
	for id: String in DEFS:
		if DEFS[id]["owner"] == character_id and int(DEFS[id].get("season", 1)) == 2:
			return id
	return ""


## Kucaklama Kalkanı: damage taken while the shield is up.
static func shielded_damage(amount: int) -> int:
	return 0


## Işık Patlaması heals the caster this much.
const LIGHT_HEAL := 20
## Fındık Fırlatma bounces to at most this many targets.
const NUT_BOUNCES := 3

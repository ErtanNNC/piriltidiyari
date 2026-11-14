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
	# Season 3: Hırıl's drum wave (prologue, Sahne 3) and the new keeper Tosbi
	"gumbur_dalgasi": {"name": "Gümbür Dalgası", "short": "Dalga", "mp": 15, "owner": "hiril"},
	"kabuk_kalkani": {"name": "Kabuk Kalkanı", "short": "Kabuk", "mp": 10, "owner": "tosbi"},
	# Season 3: each keeper learns a courage skill at level 5 (light and hands)
	"onden_giden": {"name": "Önden Giden", "short": "Önden", "mp": 20, "owner": "pati", "season": 3},
	"ayi_kucagi": {"name": "Ayı Kucağı", "short": "Kucak", "mp": 25, "owner": "bado", "season": 3},
	"fener_findigi": {"name": "Fener Fındığı", "short": "Fener", "mp": 20, "owner": "citir", "season": 3},
	"gece_lambasi": {"name": "Gece Lambası", "short": "Lamba", "mp": 25, "owner": "lumi", "season": 3},
	"ritim_kalkani": {"name": "Ritim Kalkanı", "short": "Ritim", "mp": 20, "owner": "tipis_panda", "season": 3},
	"kabuk_yuvasi": {"name": "Kabuk Yuvası", "short": "Yuva", "mp": 20, "owner": "tosbi", "season": 3},
	# Yeni Oyun+: Tırıl is a keeper too (a light pulse; at level 5 the family's light)
	"isik_dalgasi": {"name": "Işık Dalgası", "short": "Işık", "mp": 15, "owner": "tiril"},
	"aile_isigi": {"name": "Aile Işığı", "short": "Aile", "mp": 25, "owner": "tiril", "season": 3},
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
	return season_for(character_id, 2)


## The skill a keeper learns at level 5 of `season` (2: calming, 3: courage).
static func season_for(character_id: String, season: int) -> String:
	if season < 2:
		return ""
	for id: String in DEFS:
		if DEFS[id]["owner"] == character_id and int(DEFS[id].get("season", 1)) == season:
			return id
	return ""


## Season 3 courage skills: light radii/times, hug reach, rhythm reach.
const LEAD_LIGHTS := 3
const LEAD_STEP := 2.2
const TEMP_LIGHT := {"onden_giden": [3.0, 8.0], "fener_findigi": [3.6, 10.0], "gece_lambasi": [5.5, 12.0],
	"isik_dalgasi": [4.5, 5.0], "aile_isigi": [6.0, 12.0]}
const NUT_THROW := 6.0
const LAMP_HEAL := 15
const BEAR_HUG := 3.6
const RHYTHM_SHIELD := 6.5
const SHELL_GUARD := 3.0
const DRUM_WAVE := 8.0
const FAMILY_HEAL := 15


## Kucaklama Kalkanı: damage taken while the shield is up.
static func shielded_damage(amount: int) -> int:
	return 0


## Işık Patlaması heals the caster this much.
const LIGHT_HEAL := 20
## Fındık Fırlatma bounces to at most this many targets.
const NUT_BOUNCES := 3

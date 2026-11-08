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
}


static func for_character(character_id: String) -> String:
	for id: String in DEFS:
		if DEFS[id]["owner"] == character_id:
			return id
	return ""


## Kucaklama Kalkanı: damage taken while the shield is up.
static func shielded_damage(amount: int) -> int:
	return 0


## Işık Patlaması heals the caster this much.
const LIGHT_HEAL := 20
## Fındık Fırlatma bounces to at most this many targets.
const NUT_BOUNCES := 3

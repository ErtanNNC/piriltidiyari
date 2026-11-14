"""Season 4 prologue, scenes 1-3 (İlk Bahar, Yeşil Diken, Köklerin Peşinde).

The pack content/s4_prologue/ is shared with prologue_b.py (scenes 4-6), so
this script never calls pack(): it MERGES. It adds/replaces only its own
quests (QUESTS), its own dialogue variants (marked "by": "a"; other variants
of the same npc file are kept after them) and its own barks (ids "s4a_...").
Run it again whenever the pack was rewritten by someone else."""
import sys, os, json
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from s4_pack import *

PACK = "s4_prologue"
O = "oyuncu"
N = "tospik_nine"
speakers({"havuc_teyze": ("Havuç Teyze", "honey"), "kok_amca": ("Kök Amca", "sky"),
          "nilufer_abla": ("Nilüfer Abla", "spark-green")})

Q1 = {"id": "ilk_bahar", "title": "İlk Bahar", "giver": N, "objectives": [
    {"id": "havuc", "text": "Havuç Teyze ile konuş", "type": "talk", "target": "havuc_teyze"},
    {"id": "kok", "text": "Kök Amca ile konuş", "type": "talk", "target": "kok_amca"},
    {"id": "nilufer", "text": "Nilüfer Abla ile konuş", "type": "talk", "target": "nilufer_abla"},
    {"id": "ek", "text": "Kendi toprağına ilk tohumunu ek", "type": "collect", "target": "ekim"},
    {"id": "su", "text": "Filizini su balonunla sula", "type": "collect", "target": "su"}],
    "turn_in": "Meydandaki Tospik Nine'ye git", "rewards": {"piril": 10, "xp": 0}}
Q2 = {"id": "yesil_diken", "title": "Yeşil Diken", "giver": N, "objectives": [
    {"id": "nine", "text": "Meydandaki Tospik Nine ile konuş", "type": "talk", "target": N},
    {"id": "dikenci", "text": "Dikencileri sersemlet, sonra alkışla", "type": "breathe", "target": "any", "count": 3},
    {"id": "bahce", "text": "Üç komşunun bahçesini alkışla", "type": "clap", "target": "bahce", "count": 3}],
    "turn_in": "Tospik Nine'ye dön", "rewards": {"piril": 15, "xp": 0}}
Q3 = {"id": "koklerin_pesinde", "title": "Köklerin Peşinde", "giver": N, "objectives": [
    {"id": "merdiven", "text": "Merdiven tohumu ek, çitin üstünden geç", "type": "grow", "target": "merdiven"},
    {"id": "kopru", "text": "Derenin başına köprü tohumu ek", "type": "grow", "target": "kopru"},
    {"id": "kok", "text": "Sarmaşıkların dev köküne ulaş", "type": "reach", "target": "dev_kok"}],
    "turn_in": "Dev köke ulaş", "rewards": {"piril": 10, "xp": 0}}  # _learn_wave lifts to level 2
Q4 = {"id": "ince_ses", "title": "İnce Ses", "giver": N, "objectives": [
    {"id": "isik", "text": "Gölge çitini Işık Dalgası ile aç", "type": "collect", "target": "isik_cit"},
    {"id": "dikenci", "text": "Dikencileri sersemlet, sonra alkışla", "type": "breathe", "target": "any", "count": 2},
    {"id": "orman", "text": "Kütüklerden tırman, orman kenarına çık", "type": "reach", "target": "orman_kenari"}],
    "turn_in": "Orman kenarına çık", "rewards": {"piril": 15, "xp": 10}}
QUESTS = [Q1, Q2, Q3, Q4]

D = {}
D[N] = [
    {"when": {"quest": "yesil_diken", "state": "ready"}, "lines": [
        L(N, "mutlu", "Bahçeler yine çiçek dolu! Alkışın herkese iyi geldi yavrum."),
        L(N, "dertli", "Ama bu sarmaşıklar köyde bitmedi. Kökleri ormana uzanıyor."),
        L(O, "kararlı", "Köklerin peşinden giderim. Balonum hazır, ışığım da!"),
        L(N, "sakin", "Dikenler sıkarsa bir yudum limonata iç. Yolun açık olsun.")],
     "then": {"complete_quest": "yesil_diken", "set_flag": "s4_sahne2_bitti"}},
    {"when": {"quest": "yesil_diken", "state": "active", "objective_not_done": "yesil_diken/nine"}, "lines": [
        L(N, "dertli", "Herkes komşusunun bahçesine yan yan bakıyor: Onunki daha güzel!"),
        L(N, "dertli", "Böyle bakınca yerden Yeşil Diken çıkıyor. İçimiz de sıkışıyor."),
        L(N, "mutlu", "Al, Nane Limonata. İçin dikenle dolarsa bir yudum iç, ferahlarsın."),
        L(N, "kararlı", "Asıl çare alkış! Komşunun bahçesi için sevin, dikenler çekilir.")],
     "then": {"advance": "yesil_diken/nine", "give_items": {"nane_limonata": 2}}},
    {"when": {"quest": "yesil_diken", "state": "active"}, "lines": [
        L(N, "sakin", "Dikenciyi önce sersemlet, sonra yanında alkışla."),
        L(N, "sakin", "Bahçelerin önünde de alkışla. Dikenler utanıp çekilir.")]},
    {"when": {"quest": "ilk_bahar", "state": "ready"}, "lines": [
        L(N, "mutlu", "İlk tohumun çiçek açmış! Hem de ilk baharında, aferin Tırıl."),
        L(N, "kararlı", "Duyun! Yarın Çiçek Yarışması var. Jüri başkanı benim."),
        L(N, "kararlı", "Kazanan en büyük çiçek değil, en çok sevilen bahçe olacak!"),
        L(O, "şaşkın", "Nine... Kimse dinlemiyor. Herkes çiçeğini ölçüyor.")],
     "then": {"complete_quest": "ilk_bahar", "set_flag": "s4_sahne1_bitti"}},
    {"when": {"quest": "ilk_bahar", "state": "active"}, "lines": [
        L(N, "mutlu", "Hoş geldin Tırıl! Karadaki ilk baharın bu, tadını çıkar."),
        L(N, "sakin", "Komşularla tanış, kendi toprağına da bir tohum ek.")]},
]
VILLAGERS = [
    ("havuc_teyze", "havuc", 0,
     ["Merhaba Tırıl! Su balonun ne güzel parlıyor.", "Havuçlarımı yarışmaya hazırlıyorum. En turuncusu benim olacak!"],
     ["Kök Amca'nın laleleri benimkinden uzun. Hiç adil değil!", "Dikenler de nereden çıktı? Havuçlarımı göremiyorum."],
     ["Alkışladın, dikenler çekildi! Havuçlarım yerinde duruyormuş.", "Kök Amca'ya bir demet götüreyim. Laleleri de güzelmiş."]),
    ("kok_amca", "kok", 1,
     ["Hoş geldin denizanası evlat! Karada yüzmek nasıl?", "Lalelerimi cetvelle ölçüyorum. Bir parmak daha uzasınlar!"],
     ["Nilüfer'in gülleri mis kokuyor. Benim lalelerim kokmuyor!", "Dikenler tarhımı sardı. Ben bunları ekmedim ki!"],
     ["Aa, lalelerim ne renkliymiş! Ölçmekten bakmayı unutmuşum.", "Alkışın için sağ ol evlat. İçim ferahladı."]),
    ("nilufer_abla", "nilufer", 2,
     ["Vırak! Balonunda su mu var? Güllerim bayılır.", "Yarışmayı ben kazanacağım. Ya da... kazanmalıyım, değil mi?"],
     ["Havuç Teyze'nin bahçesi dolu dolu. Benimki yarım kalmış gibi.", "Bu dikenler güllerimin dikeni değil. Bunlar başka!"],
     ["Vırak! Güllerim açmış da haberim yokmuş.", "Havuç Teyze'ye gül suyu götüreceğim. Birlikte sevinelim."]),
]
for nid, oid, n, hello, envy, glad in VILLAGERS:
    D[nid] = [
        {"when": {"quest": "yesil_diken", "state": ["active", "ready", "done"], "flag": "s4_scene2_d%d" % n},
         "lines": [L(nid, "mutlu", glad[0]), L(nid, "mutlu", glad[1])]},
        {"when": {"quest": "yesil_diken", "state": "active"},
         "lines": [L(nid, "dertli", envy[0]), L(nid, "şaşkın", envy[1]),
                   L(O, "sakin", "Bahçenin önünde bir alkış patlatayım, belki iyi gelir.")]},
        {"when": {"quest": "ilk_bahar", "state": "active", "objective_not_done": "ilk_bahar/%s" % oid},
         "lines": [L(nid, "mutlu", hello[0]), L(nid, "mutlu", hello[1]),
                   L(O, "mutlu", "Çok güzel olmuş! Ben de ilk tohumumu ekeceğim.")],
         "then": {"advance": "ilk_bahar/%s" % oid}},
        {"lines": [L(nid, "mutlu", "Toprağı kabart, tohumu ek, suyunu ver. Gerisi sabır!")]},
    ]

F = "fisilti"
B = {
    # Sahne 1
    "s4a_basla": [L(O, "mutlu", "Karadaki ilk baharım! Su balonum sayesinde her yere süzülürüm."),
                  L(O, "şaşkın", "Herkes bahçesini süslüyor. Çiçek Yarışması varmış!")],
    "s4a_ekim": [L(O, "mutlu", "Tohumu ektim! Minicik bir filiz çıktı."),
                 L(O, "sakin", "Biraz su ister. Balonumdan birkaç damla vereyim.")],
    "s4a_cicek": [L(O, "mutlu", "Açtı! İlk çiçeğim bir Şifa Papatyası oldu."),
                  L(O, "kararlı", "Tospik Nine'ye göstereyim. Meydanda bekliyor.")],
    "s4a_son": [L("havuc_teyze", "kararlı", "En büyük havuç benimki olacak!"),
                L("kok_amca", "kararlı", "Hayır, en uzun lale benimki!"),
                L(O, "dertli", "Nine'yi duymadılar. İçimde tuhaf bir his var...")],
    # Sahne 2
    "s4a_diken_basla": [L(O, "şaşkın", "Yarışma günü! Ama herkes komşusunun bahçesine bakıyor."),
                        L(O, "şaşkın", "Bahçelerin dibinden ince yeşil sarmaşıklar çıkmış!"),
                        L(O, "kararlı", "Tospik Nine meydanda. Ona sorayım.")],
    "s4a_dikenci": [L(O, "şaşkın", "Sırtı dikenli bir tavşan, komşunun havucunu kapmış!"),
                    L(O, "kararlı", "Işığımla sersemleteyim. Canı yanmaz, sadece durur.")],
    "s4a_sersem": [L(O, "şaşkın", "Sersemledi, başında yıldızlar dönüyor."),
                   L(O, "mutlu", "Onu alkışlayayım: kendi havucu da güzel, görsün!")],
    "s4a_ilk_alkis": [L(O, "mutlu", "Alkışlayınca dikenleri döküldü! Evine koşuyor.")],
    "s4a_bahce": [L(O, "mutlu", "Dikenler çekildi, yerinde çiçekler kaldı!"),
                  L(O, "sakin", "Birinin bahçesi için sevinmek, dikenin ilacıymış.")],
    "s4a_bar": [L(O, "dertli", "Dikenlerin yanında içim sıkışıyor. Diken barım doluyor!"),
                L(O, "kararlı", "Birini alkışlarsam ya da limonata içersem boşalır.")],
    # Sahne 3
    "s4a_kok_basla": [L(O, "şaşkın", "Sarmaşıkların kökleri ormana doğru uzanıyor."),
                      L(O, "kararlı", "Dikenli çit yolu kapatmış. Bir tohum toprağı görüyorum!")],
    "s4a_merdiven": [L(O, "mutlu", "Tohum sarmaşık merdiven oldu! Çitin üstünden geçerim.")],
    "s4a_kopru": [L(O, "mutlu", "Yaprak köprü! Dereyi ıslanmadan geçerim. Gerçi ben hep ıslağım.")],
    "s4a_ses1": [L(F, "dertli", "Onunki daha güzel..."),
                 L(O, "şaşkın", "Kim konuştu? Sarmaşıkların arasından ince bir ses geldi.")],
    "s4a_kok": [L(O, "şaşkın", "Dev bir kök! Bütün sarmaşıklar buradan çıkıyor."),
                L(O, "mutlu", "Işığım büyüdü! İçimde yeni bir dalga kıpırdıyor.")],
    "s4a_isik": [L(O, "mutlu", "Işık görünce gölge çiti çekildi! Karanlığı sevmiyor demek.")],
    "s4a_ses2": [L(F, "dertli", "...neden ben değilim?"),
                 L(O, "dertli", "Bu ses çok üzgün. Kızgın değil, sadece yalnız.")],
    "s4a_son3": [L(F, "dertli", "Onunki daha güzel... neden ben değilim?"),
                 L(O, "kararlı", "Ses ormanın kenarındaki bostandan geliyor. Bakmalıyım."),
                 L(O, "şaşkın", "Bir dakika... Şu kabak az önce kıpırdadı mı?")],
}


def read(rel, fallback):
    path = os.path.join(ROOT, PACK, rel)
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return fallback


def main():
    ch = read("chapter.json", {"id": PACK, "title": "Onunki Daha Güzel", "region": "Gökkuşağı Köyü",
                               "theme": "light", "levels": [1, 5], "spark": None,
                               "quests": [], "dialogue": [], "barks": "barks"})
    mine = [q["id"] for q in QUESTS]
    # scenes 1-3 come first: the HUD tracks the first open quest in this order
    ch["quests"] = mine + [q for q in ch.get("quests", []) if q not in mine]
    ch["dialogue"] = list(ch.get("dialogue", [])) + [n for n in D if n not in ch.get("dialogue", [])]
    ch.setdefault("barks", "barks")
    write(PACK, "chapter.json", ch)
    for q in QUESTS:
        write(PACK, "quests/%s.json" % q["id"], q)
    for npc, variants in D.items():
        old = read("dialogue/%s.json" % npc, {"variants": []})
        others = [v for v in old.get("variants", []) if v.get("by") != "a"]
        for v in variants:
            v["by"] = "a"
        write(PACK, "dialogue/%s.json" % npc, {"npc": npc, "variants": variants + others})
    barks = read("barks.json", {"barks": {}}).get("barks", {})
    barks = {k: v for k, v in barks.items() if not k.startswith("s4a_")}
    barks.update(B)
    write(PACK, "barks.json", {"barks": barks})


main()

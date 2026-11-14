"""Season 4 prologue, scenes 4-6 (Dev Kabak Bahçıvan, Tırıl'ın Seçimi, Alkış).
Scenes 1-3 come from prologue_a.py into the same pack, so nothing here
rewrites the shared files whole: chapter.json and barks.json are merged
(only this script's quest, cutscene and `s4b_` bark ids are touched)."""
import json, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from s4_pack import L, write, speakers, ROOT

PACK = "s4_prologue"
T = "tiril"

Q = {"id": "dev_kabak", "title": "Dev Kabak Bahçıvan", "giver": "tiril", "objectives": [
    {"id": "alkis", "text": "Dev Kabak yorulunca vur, küsünce alkışla", "type": "breathe", "target": "kabak"}],
    "turn_in": "Kabağın yanında dur", "rewards": {"piril": 25, "xp": 25}}

B = {
    # --- Sahne 4: Dev Kabak Bahçıvan ---
    "s4b_basla": [L(T, "şaşkın", "Bostanda dev bir kabak! Yaprakları diken diken olmuş."),
                  L("kabak", "huysuz", "Karpuz benden büyük çıktı! Artık bana kimse bakmıyor!"),
                  L(T, "kararlı", "Tohum atıyor, yuvarlanıyor... Yorulunca yanına gideyim.")],
    "s4b_faz": [L("kabak", "huysuz", "Bir zamanlar köyün en büyük kabağıydım ben!")],
    "s4b_kustu": [L("kabak", "dertli", "Karpuz varken bana kim bakar ki... Püf."),
                  L(T, "sakin", "Küstü. Onu alkışlayayım: kendi güzelliğini görsün.")],
    "s4b_alkis": [L(T, "mutlu", "Sen hâlâ çok büyük ve turuncu bir kabaksın!"),
                  L("kabak", "şaşkın", "Ben mi? Hâlâ... büyük ve turuncu muyum?"),
                  L("kabak", "mutlu", "Yanaklarım kızardı! Dikenlerim de döküldü, bak!")],
    "s4b_son": [L(T, "sakin", "Hep karpuza bakmış. Kendi turuncusunu görememiş."),
                L(T, "sakin", "Kıyaslayınca elindeki güzellik saklanıyor demek."),
                L(T, "şaşkın", "Aa! Ormanın arkasında dikenli bir kapı açılıyor...")],
    # --- Sahne 5: Tırıl'ın Seçimi ---
    "s4b_c1": [L(T, "şaşkın", "Dikenli kapı kendi kendine açıldı. İçeride biri var.")],
    "s4b_c2": [L("diril", "dertli", "Herkes çiçek açtı. Ben hiç açamadım."),
               L("diril", "huysuz", "Sen bile ışık saçıyorsun!")],
    "s4b_c3": [L(T, "şaşkın", "Sarmaşıklar kabarıyor! Ama ben bu duyguyu tanıyorum."),
               L(T, "sakin", "Ben de önce parlayamıyordum. Işığım tir tir titrerdi.")],
    "s4b_c4": [L(T, "kararlı", "Yanına geliyorum. Köşeni birlikte aydınlatalım."),
               L("diril", "şaşkın", "Benim yanıma mı? Buraya kimse gelmezdi ki...")],
    # --- Sahne 6: Alkış ---
    "s4b_m1": [L("fistik", "dertli", "Sabah oldu. Tırıl dikenli kapının ardında kaldı."),
               L("miril", "sakin", "Kapının altından soluk mavi bir ışık sızıyor."),
               L("hiril", "kararlı", "O benim elimi tutmuştu. Şimdi sıra bizde!")],
    "s4b_m2": [L("fistik", "kararlı", "İlk seferde ışık, sonra kulak, sonra el lazımdı."),
               L("fistik", "sakin", "Bu sefer... başkası için sevinebilen bir kalp.")],
    "s4b_m3": [L("pati", "şaşkın", "Şey... Çiçek Yarışması'nı kim kazanacak acaba?"),
               L("citir", "şaşkın", "Hııı! Ben de tam onu düşünüyordum.")],
    "s4b_m4": [L("yonca", "sakin", "Ben bahçelerden anlarım. Gelebilir miyim?"),
               L("yonca", "mutlu", "Yarışmada sona kaldım ama herkesin bahçesini suladım!"),
               L("fistik", "mutlu", "Gel Yonca! Aradığımız kalp tam da böyle bir kalp.")],
    "s4b_sec_pati": [L("pati", "kararlı", "Bu sefer de öndeyim. ...Ama önde olmak şart mı?")],
    "s4b_sec_bado": [L("bado", "sakin", "Minnoş, sen burada kal. ...Hayır, gel. Gel tamam mı?")],
    "s4b_sec_citir": [L("citir", "mutlu", "Yeni harita! Paytak'ınkinden de güzel olacak. ...Şaka şaka.")],
    "s4b_sec_lumi": [L("lumi", "kararlı", "Tırıl'ın ışığını bulalım.")],
    "s4b_sec_tipis_panda": [L("tipis_panda", "kararlı", "Bu sefer ritmi ben tutarım.")],
    "s4b_sec_tosbi": [L("tosbi", "mutlu", "Ben artık küçük değilim!")],
    "s4b_sec_yonca": [L("yonca", "mutlu", "Her tohum kendi zamanında açar. Dedem öyle derdi.")],
    "s4b_sec_son": [L("fistik", "mutlu", "Dikenlere kızmayın. Alkışlayın: kendileri çekilir!"),
                    L("hiril", "mutlu", "Tırıl'a söyleyin: davulum onun için çalıyor!")],
}


def cam(pos, look, t=0.0):
    return {"cam": {"pos": pos, "look": look, "time": t}}


CUTSCENES = {
    "tiril_secimi": [
        cam([0, 6, 14], [0, 1.4, -4]), {"wait": 1.0},
        {"do": "gate_opens"}, {"wait": 1.6}, {"say": "s4b_c1"},
        cam([2.6, 2.4, -4.5], [0, 0.5, -10], 2.2), {"say": "s4b_c2"},
        {"do": "vines_swell"}, {"pus": 0.45, "time": 1.5}, {"wait": 1.4},
        cam([3.5, 3.0, 8.5], [0, 1.4, 3.0], 1.8), {"say": "s4b_c3"},
        {"do": "tiril_floats"}, cam([-2.8, 2.6, -4.0], [0.6, 0.9, -9.6], 2.6), {"wait": 0.8},
        {"say": "s4b_c4"},
        cam([0, 4.6, 9], [0, 1.2, -4], 2.2), {"do": "gate_closes"}, {"wait": 2.4},
        {"do": "light_seeps"}, cam([1.6, 1.0, 1.5], [0, 0.1, -3.4], 2.4), {"wait": 2.2},
        {"card": ["", "Tırıl kendi isteğiyle kaldı", "Dırıl'ın köşesini aydınlatmak için."], "time": 3.8},
        {"do": "finish"}, {"goto": "s4_scene6"}],
    "alkis": [
        cam([0, 6, 14], [0, 1.2, -1]), {"wait": 1.0}, {"say": "s4b_m1"},
        cam([-5.5, 3.0, 6.5], [-8.0, 1.0, -0.5], 1.6), {"say": "s4b_m2"},
        cam([0, 4.2, 10.5], [0, 1.0, 0], 1.6), {"do": "silence"}, {"wait": 2.0}, {"say": "s4b_m3"},
        {"do": "yonca_steps"}, cam([4.5, 3.0, 7.0], [6.0, 0.9, 0.3], 1.6), {"wait": 0.6},
        {"say": "s4b_m4"},
        cam([0, 5.4, 12.5], [0, 1.2, 0], 1.2), {"do": "open_select"}],
}


def merge():
    # chapter.json: keep what scenes 1-3 put there, add this script's quest
    p = os.path.join(ROOT, PACK, "chapter.json")
    ch = json.load(open(p)) if os.path.exists(p) else {
        "id": PACK, "title": "Onunki Daha Güzel", "region": "Gökkuşağı Köyü", "theme": "light",
        "levels": [1, 5], "spark": None, "quests": [], "dialogue": [], "barks": "barks"}
    if Q["id"] not in ch["quests"]:
        ch["quests"].append(Q["id"])
    ch["barks"] = "barks"
    write(PACK, "chapter.json", ch)
    write(PACK, "quests/%s.json" % Q["id"], Q)
    # barks.json: replace only the s4b_ ids
    p = os.path.join(ROOT, PACK, "barks.json")
    barks = json.load(open(p)).get("barks", {}) if os.path.exists(p) else {}
    barks = {k: v for k, v in barks.items() if not k.startswith("s4b_")}
    barks.update(B)
    write(PACK, "barks.json", {"barks": barks})
    for cid, steps in CUTSCENES.items():
        write(PACK, "cutscenes/%s.json" % cid, {"steps": steps})


if __name__ == "__main__":
    for bid in B:
        assert bid.startswith("s4b_"), bid
    merge()

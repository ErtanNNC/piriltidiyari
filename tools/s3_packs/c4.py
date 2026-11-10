import sys, os; sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from s3_pack import *
# Sezon 3 · Bölüm 4 – Fırtına Kayası. The helper at the landing is Tıpış
# (speaker "tipis_panda"), or Tosbi when the player is Tıpış: the same
# dialogue is written for both ids, and barks the helper speaks in get a
# second copy with the suffix "_t" (helper = Tosbi).
O = "oyuncu"
TO = "tombik"
Y = "fok_yavrusu"
TI = "tiril"
speakers({"fok_yavrusu": ("Fok Yavrusu Pıtır", "sky")})
Q1 = {"id": "gok_davulu", "title": "Gök Davulu", "giver": "tipis_panda", "objectives": [
    {"id": "mesale", "text": "Kaya altlarındaki beş meşaleyi yak", "type": "light", "target": "mesale", "count": 5},
    {"id": "titrek", "text": "Titrekleri ritimle durdur, sakinleştir", "type": "titrek", "target": "any", "count": 4},
    {"id": "ust_kaya", "text": "Basamaklardan zıplayarak Üst Kaya'ya çık", "type": "reach", "target": "ust_kaya"},
    {"id": "el", "text": "Fok yavrusunu el ele iskeleye getir", "type": "el", "target": "yavru"}],
    "turn_in": "İskelede bekleyen arkadaşına dön", "rewards": {"piril": 70, "xp": 160}}
Q2 = {"id": "bagiran_bekci", "title": "Bağıran Bekçi", "giver": "tipis_panda", "objectives": [
    {"id": "fisek", "text": "Fırtına Kayası'nın İşaret Fişeği'ni yak", "type": "light", "target": "fisek"},
    {"id": "tombik", "text": "Vuruşları say, yorulan Tombik'e el uzat", "type": "breathe", "target": "tombik"},
    {"id": "inci", "text": "Gümüş İnci'yi al", "type": "collect", "target": "inci"}],
    "turn_in": "Arkadaşınla konuş", "rewards": {"piril": 90, "xp": 220}}


def helper(H):
    return [
        {"when": {"quest": "bagiran_bekci", "state": "ready"}, "lines": [
            L(H, "mutlu", "Gümüş İnci! Fırtına bile ritim tutuyor artık."),
            L(TO, "mutlu", "Güm gelince sayıyorum. Bir, iki, üç... Davul gibi!"),
            L(H, "kararlı", "Geriye tek inci kaldı. Kayıp Ada sisin içinde."),
            L(O, "kararlı", "Tırıl da orada bir yerde. Hadi, Kabuk Kayık'a!")],
         "then": {"complete_quest": "bagiran_bekci", "set_flag": "s3_bolum4_bitti"}},
        {"when": {"quest": "bagiran_bekci", "state": "active", "objective_done": "bagiran_bekci/tombik"}, "lines": [
            L(H, "mutlu", "Gümüş İnci orada parlıyor. Al onu!")]},
        {"when": {"quest": "bagiran_bekci", "state": "active", "flag": "s3_fisek4"}, "lines": [
            L(H, "sakin", "Sis perdesi açıldı. Tombik köprünün ötesinde bağırıyor."),
            L(H, "kararlı", "Şimşek dört vuruşla gelir. Say, arada koş, yorulunca vur.")]},
        {"when": {"quest": "bagiran_bekci", "state": "active"}, "lines": [
            L(H, "sakin", "Fişek kuzeyde, taş köprünün önünde duruyor."),
            L(H, "kararlı", "Onu yak ki sis çekilsin, şimşekler denize gitsin.")]},
        {"when": {"quest": "gok_davulu", "state": "ready"}, "lines": [
            L(H, "mutlu", "Yavru iskelede, meşaleler yanıyor. Harikasın!"),
            L(Y, "utangaç", "Güm deyince saklanıyordum. Sayınca içim rahatladı."),
            L(H, "kararlı", "Şimdi İşaret Fişeği. Kuzeyde, taş köprünün önünde."),
            L(H, "dertli", "Sonra Tombik'e gidelim. O hâlâ kulaklarını kapatıyor.")],
         "then": {"complete_quest": "gok_davulu", "start_quest": "bagiran_bekci"}},
        {"when": {"quest": "gok_davulu", "state": "active"}, "lines": [
            L(H, "sakin", "Yerdeki halka dolunca şimşek düşer. Sonra sessizlik gelir."),
            L(H, "sakin", "Kaya altına şimşek düşmez. Meşaleler de orada."),
            L(H, "sakin", "Üst Kaya'da bir fok yavrusu saklanıyor. Elini uzat.")]},
        {"when": {"quest": "gok_davulu", "state": "none"}, "lines": [
            L(H, "şaşkın", "Güm! Duydun mu? Bu ada hiç susmuyor."),
            L(H, "dertli", "Bekçi Fok Tombik her gürültüde bağırıyor. Fırtına büyüyor."),
            L(H, "kararlı", "Ama şimşek hep sırayla düşüyor. Say: güm, sus, sus, sus."),
            L(H, "kararlı", "Sessizlikte yürü, kaya altında bekle. Meşaleleri yakalım!")],
         "then": {"start_quest": "gok_davulu"}},
        {"lines": [L(H, "mutlu", "Güm, sus, sus, sus... Artık ben de ritim tutuyorum!")]}]


D = {"tipis_panda": helper("tipis_panda"), "tosbi": helper("tosbi")}


def shared(H):
    return {
        "s3k4_basla": [L(O, "şaşkın", "Fırtına Kayası... Şimşek hiç durmuyor!"),
                       L(H, "şaşkın", "Güm! Ama dinle... Hep aynı sırayla geliyor.")],
        "s3k4_fisek": [L(O, "mutlu", "İşaret Fişeği yandı! Şimşekler denize çekildi."),
                       L(H, "dertli", "Kuzeyde hâlâ gürlüyor. Tombik bağırdıkça büyüyor.")],
        "s3k4_ritim": [L(H, "sakin", "Tombik, gök gürültüsü bir davul gibi. Hep sırayla vurur."),
                       L(TO, "şaşkın", "Davul mu? Ama çok yüksek sesli..."),
                       L(O, "kararlı", "Birlikte ritim tutalım. Dört vuruş, sen de say!")],
        "s3k4_ritim_son": [L(TO, "mutlu", "Bir, iki, üç, dört... Güm! Biliyordum, şimdi gelecekti!"),
                           L(H, "mutlu", "Ne zaman geleceğini bilince o kadar ürkütmüyor, değil mi?"),
                           L(TO, "mutlu", "Gök davul çalıyor, ben de sayıyorum. Bu inci senin olsun.")],
    }


B = {
    "s3k4_kilit": [L(O, "dertli", "Fişek ıslak. Önce meşaleler ve yavru, sonra bu.")],
    "s3k4_ust": [L(Y, "üzgün", "Güm... Yine güm... Buradan çıkamıyorum."),
                 L(O, "sakin", "Elimi tut. Sessizlikte yürür, kaya altında bekleriz.")],
    "s3k4_yavru": [L(Y, "mutlu", "Geldik! Bir kere bile çarpmadı. Saymak işe yarıyor!")],
    "s3k4_tombik": [L(TO, "şaşkın", "GÜM! Aaah, kulaklarım! Susun, susun, SUSUN!"),
                    L(O, "kararlı", "Bağırdıkça fırtına büyüyor. Vuruşları say, arada koş!")],
    "s3k4_tombik_yorgun": [L(TO, "üzgün", "Ne zaman gürleyecek, bilmiyorum... Çok yoruldum.")],
    "s3k4_inci": [L(O, "mutlu", "Gümüş İnci! Deniz Feneri'nin dördüncü incisi."),
                  L(TO, "sakin", "Fırtınalı bir gece buradan minik bir ışık geçti. Titriyordu.")],
    "s3k4_ani": [L(TI, "üzgün", "Çok gürültü vardı. Batık bir oyuncak tekneye saklandım."),
                 L(TI, "üzgün", "Ailem beni aramış. Ama gök gürlerken hiç duymadım."),
                 L(O, "sakin", "Seni bulacağız Tırıl. Bu sefer sesimizi duyacaksın.")],
}
B.update(shared("tipis_panda"))
B.update({k + "_t": v for k, v in shared("tosbi").items()})
pack("s3_chapter4", "Fırtına Kayası", "Fırtına Kayası", [20, 25], [Q1, Q2], D, B)

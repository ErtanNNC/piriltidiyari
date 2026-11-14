import sys, os; sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from s3_pack import *
O = "oyuncu"
P = "paytak"
A = "pamuk3"
C = "civciv"
speakers({"paytak": ("Kaşif Paytak", "spark-yellow"), "pamuk3": ("Pamuk", "sky"), "civciv": ("Martı Civciv", "honey")})
Q1 = {"id": "ruzgar_yolu", "title": "Rüzgârın Yolu", "giver": "paytak", "objectives": [
    {"id": "mesale", "text": "Tırmanış yolundaki altı meşaleyi yak", "type": "light", "target": "mesale", "count": 6},
    {"id": "titrek", "text": "Titrekleri ritimle durdur, sakinleştir", "type": "titrek", "target": "any", "count": 4},
    {"id": "civciv", "text": "Başı dönen civcivi el ele köprüden geçir", "type": "el", "target": "civciv"},
    {"id": "ust", "text": "Rüzgâr tünelinden geç, üst kata çık", "type": "reach", "target": "s3k2_ust"}],
    "turn_in": "Üst katta Kaşif Paytak ile konuş", "rewards": {"piril": 60, "xp": 110}}
Q2 = {"id": "ilk_kanat", "title": "İlk Kanat", "giver": "paytak", "objectives": [
    {"id": "fisek", "text": "Kayalıkların İşaret Fişeği'ni yak", "type": "light", "target": "fisek"},
    {"id": "pamuk", "text": "Yuvadaki Pamuk'a el uzat", "type": "breathe", "target": "pamuk"},
    {"id": "inci", "text": "Turkuaz İnci'yi al", "type": "collect", "target": "inci"}],
    "turn_in": "Kaşif Paytak ile konuş", "rewards": {"piril": 90, "xp": 170}}
D = {}
D[P] = [
    {"when": {"quest": "ilk_kanat", "state": "ready"}, "lines": [
        L(P, "mutlu", "Vak vak! Pamuk süzüldü! Bunu haritama çizdim bile."),
        L(P, "mutlu", "Fırtına dindi. Kayalıklar ilk kez bu kadar sakin."),
        L(P, "kararlı", "Üçüncü inci Değişen Kumlar'da. Kabuk Kayık iskelede."),
        L(O, "kararlı", "İki inci tamam. Sıradaki adaya yelken açalım!")],
     "then": {"complete_quest": "ilk_kanat", "set_flag": "s3_bolum2_bitti", "give_items": {"cesaret_kurabiyesi": 2}}},
    {"when": {"quest": "ilk_kanat", "state": "active", "objective_done": "ilk_kanat/pamuk"}, "lines": [
        L(P, "mutlu", "Vak! Turkuaz İnci orada parlıyor. Al bakalım!")]},
    {"when": {"quest": "ilk_kanat", "state": "active", "flag": "s3_fisek2"}, "lines": [
        L(P, "sakin", "Perde açıldı. Yuva, ikinci köprünün öbür ucunda."),
        L(P, "sakin", "Pamuk kızgın değil. Sadece aşağı bakmaya korkuyor."),
        L(P, "mutlu", "Yolluk lazımsa çantam açık.")],
     "then": {"open_shop": "paytak"}},
    {"when": {"quest": "ilk_kanat", "state": "active"}, "lines": [
        L(P, "kararlı", "Fişek hemen şurada. Yak ki sis perdesi açılsın."),
        L(P, "mutlu", "Yolluk lazımsa çantam açık.")],
     "then": {"open_shop": "paytak"}},
    {"when": {"quest": "ruzgar_yolu", "state": "ready"}, "lines": [
        L(P, "mutlu", "Vak! Meşaleler yandı, civciv yuvasında. Harikasın!"),
        L(P, "dertli", "Ama fırtına dinmiyor. Tepedeki yuvadan esiyor."),
        L(P, "dertli", "Orada Pamuk var. Koca bir albatros yavrusu."),
        L(P, "sakin", "Yüksekten korkuyor. Kanat çırptıkça fırtına kopuyor."),
        L(P, "kararlı", "Fişeği yak, köprüyü geç. Ona bir el lazım.")],
     "then": {"complete_quest": "ruzgar_yolu", "start_quest": "ilk_kanat"}},
    {"when": {"quest": "ruzgar_yolu", "state": "active"}, "lines": [
        L(P, "sakin", "Meşaleleri yaka yaka tırman. Işık olan yer güvenli."),
        L(P, "sakin", "Rüzgâr esince kayanın ardında bekle. Sonra yürü."),
        L(P, "mutlu", "Düşersen korkma. Aşağısı yumuşak, merdiven de orada.")],
     "then": {"open_shop": "paytak"}},
    {"when": {"quest": "ruzgar_yolu", "state": "none"}, "lines": [
        L(P, "mutlu", "Vak! Ben Kaşif Paytak. Bu kayalıkların haritasını çiziyorum."),
        L(P, "dertli", "Ama rüzgâr kalemimi bile uçurdu! Tepeden fırtına esiyor."),
        L(P, "dertli", "Köprüler sallanıyor, meşaleler söndü, kuşlar titriyor."),
        L(P, "kararlı", "Yukarı çıkan yolu aydınlatır mısın? Ben de peşinden gelirim."),
        L(O, "kararlı", "Tamam Paytak. Adım adım, meşale meşale çıkarız.")],
     "then": {"start_quest": "ruzgar_yolu"}},
    {"lines": [L(P, "mutlu", "Vak! Kaşif çantamda yolluk var. Bir bak istersen.")], "then": {"open_shop": "paytak"}}]
B = {
    "s3k2_basla": [L(O, "şaşkın", "Rüzgârlı Kayalıklar... Kayalar göğe kadar uzanıyor!"),
                   L(P, "mutlu", "Vak vak! Bir yolcu! Buraya gel, sana bir şey soracağım.")],
    "s3k2_kilit": [L(O, "dertli", "Fişek rüzgârda sönüyor. Önce Paytak'ın işini bitireyim.")],
    "s3k2_ruzgar": [L(O, "şaşkın", "Hop! Rüzgâr beni itiyor. Köprü de sallanıyor!"),
                    L(O, "kararlı", "Esince kayanın ardına geçerim. Ya da karşı yürürüm.")],
    "s3k2_dustu": [L(O, "şaşkın", "Hop! Yumuşak düştüm. Bir şeyim yok."),
                   L(O, "kararlı", "Merdivenden yine çıkarım. Bu sefer rüzgârı beklerim.")],
    "s3k2_civciv_el": [L(C, "dertli", "Cik... Başım dönüyor. Yuvam köprünün öbür ucunda."),
                       L(O, "sakin", "Elimi tut. Aşağı bakma, bana bak. Birlikte geçeriz.")],
    "s3k2_civciv_yuva": [L(C, "mutlu", "Cik cik! Geçtim! El ele köprü kısacıkmış!"),
                         L(O, "mutlu", "İlk sefer hep zor. Bir el tutunca kolaylaşıyor.")],
    "s3k2_ust": [L(O, "mutlu", "Üst kattayım! Buradan bütün deniz görünüyor."),
                 L(O, "sakin", "Paytak da geliyor. Fişek tam burada duruyor.")],
    "s3k2_fisek": [L(O, "mutlu", "İşaret Fişeği yandı! Sis perdesi açılıyor."),
                   L(P, "mutlu", "Vak vak! Yuvanın köprüsü göründü!")],
    "s3k2_pamuk": [L(A, "şaşkın", "Gelmeyin! Yuvadan çıkmam! Aşağısı çok yüksek!"),
                   L(O, "kararlı", "Kanat çırptıkça fırtına kopuyor. Yorulunca yaklaşırım.")],
    "s3k2_pamuk_yorgun": [L(A, "üzgün", "Puf... Kanatlarım yoruldu. Ama içim hâlâ pır pır...")],
    "s3k2_pamuk_son": [L(A, "utangaç", "Yuvaya sığmıyorum artık. Ama uçmayı hiç denemedim."),
                       L(O, "sakin", "İlk sefer tek başına zor olur. Kanadını ver."),
                       L(A, "şaşkın", "Tutacak mısın? Ama bırakmak yok!"),
                       L(O, "kararlı", "Bırakmak yok. Üç deyince: bir, iki, üüüç!")],
    "s3k2_sustu": [L(A, "mutlu", "Süzüldüm! Gördün mü? Rüzgâr beni taşıdı!"),
                   L(O, "mutlu", "Hem de ilk seferde! El ele her şey daha kolay."),
                   L(A, "mutlu", "Fırtınam dindi. Al, bu inci yuvamda duruyordu.")],
    "s3k2_inci": [L(O, "mutlu", "Turkuaz İnci! Deniz Feneri'nin ikinci incisi."),
                  L(P, "mutlu", "Vak! Haritama yazıyorum: Pamuk bugün uçtu!")],
}
S = {"paytak": {"title": "Paytak'ın Kaşif Çantası", "items": [
    {"id": "bal_surubu", "price": 15}, {"id": "sicak_kakao", "price": 15},
    {"id": "cesaret_kurabiyesi", "price": 35}, {"id": "atesbocegi_kavanozu", "price": 30},
    {"id": "sise_pusulasi", "price": 60, "once": True}]}}
pack("s3_chapter2", "Rüzgârlı Kayalıklar", "Rüzgârlı Kayalıklar", [10, 15], [Q1, Q2], D, B, S)

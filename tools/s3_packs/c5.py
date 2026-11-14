import sys, os; sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from s3_pack import *
O = "oyuncu"
H = "hiril"
T = "tiril"
Q1 = {"id": "davulun_izi", "title": "Davulun İzi", "giver": "hiril", "objectives": [
    {"id": "mesale", "text": "Yol ayrımlarındaki dört meşaleyi yak", "type": "light", "target": "mesale", "count": 4},
    {"id": "titrek", "text": "Sisin içindeki Titrekleri sakinleştir", "type": "titrek", "target": "any", "count": 4},
    {"id": "tekne", "text": "Davulu izle: batık oyuncak tekneye ulaş", "type": "reach", "target": "tekne"}],
    "turn_in": "Teknenin yanında Hırıl ile konuş", "rewards": {"piril": 60, "xp": 120}}
Q2 = {"id": "tiril", "title": "Seni Buldum", "giver": "hiril", "objectives": [
    {"id": "fisek", "text": "Kayıp Ada'nın İşaret Fişeği'ni yak", "type": "light", "target": "fisek"},
    {"id": "saklambac", "text": "Saklanan Tırıl'ı dört kez bul", "type": "collect", "target": "saklambac", "count": 4},
    {"id": "tiril", "text": "El ele halkanın ortasında Tırıl'a el uzat", "type": "breathe", "target": "tiril"},
    {"id": "inci", "text": "İnci Beyazı'nı al", "type": "collect", "target": "inci"}],
    "turn_in": "Hırıl ile konuş", "rewards": {"piril": 100, "xp": 200}}
D = {}
D["hiril"] = [
    {"when": {"quest": "tiril", "state": "ready"}, "lines": [
        L(H, "mutlu", "Başardın! Tırıl'ın ışığı artık titremiyor."),
        L(T, "utangaç", "Beni buldunuz... Dört kere. Hep buldunuz."),
        L(H, "mutlu", "Davulumu alıyorum. Hadi eve, Fener Gecesi'ne!"),
        L(O, "mutlu", "Beş inci tamam. Deniz Feneri yeniden yanacak!")],
     "then": {"complete_quest": "tiril", "set_flag": "s3_bolum5_bitti", "goto_scene": "s3_final"}},
    {"when": {"quest": "tiril", "state": "active", "objective_done": "tiril/tiril"}, "lines": [
        L(H, "mutlu", "İnci Beyazı orada parlıyor. Al onu!")]},
    {"when": {"quest": "tiril", "state": "active"}, "lines": [
        L(H, "sakin", "Fişeği yak. Işık gelince Tırıl dışarı bakar."),
        L(H, "sakin", "Ürkünce gölgeler çağırır. Kızma, sadece korkuyor.")]},
    {"when": {"quest": "davulun_izi", "state": "ready"}, "lines": [
        L(H, "mutlu", "Geldin! Davulumu duydun, değil mi?"),
        L(H, "sakin", "Tırıl bu teknenin içinde. Günlerdir çalıyorum, çıkmadı."),
        L(O, "kararlı", "Yalnız değilsin artık. Birlikte bekleyelim."),
        L(H, "kararlı", "Önce adanın fişeğini yak. Sis incelsin.")],
     "then": {"complete_quest": "davulun_izi", "start_quest": "tiril"}},
    {"lines": [L(H, "sakin", "Bum... bum... Yavaş çalıyorum ki korkmasın.")]}]
B = {
    "s3k5_basla": [L(O, "şaşkın", "Kayıp Ada... Her yol birbirine benziyor."),
                   L(O, "kararlı", "Dinle! Uzaktan bir davul: bum... bum... Hırıl!")],
    "s3k5_kilit": [L(O, "dertli", "Fişek sisten sırılsıklam. Önce Hırıl'ı bulmalıyım.")],
    "s3k5_fisek": [L(O, "mutlu", "Fişek yandı! Sis perdesi açılıyor."),
                   L(T, "üzgün", "Işık! Çok ışık! Gölgelerim, beni saklayın!")],
    "s3k5_tiril": [L(T, "üzgün", "Gelmeyin! Karanlık, uçurum, fırtına... Hepsi burada!"),
                   L(H, "sakin", "Bunlar senin değil, bizim korkularımız. Geçer.")],
    "s3k5_faz2": [L(T, "üzgün", "Yoruldum... Saklanacağım. Kimse beni bulmasın!"),
                  L(H, "kararlı", "Saklambaç mı? İyi oynarız. Seni hep bulacağız!")],
    "s3k5_buldum1": [L(O, "mutlu", "Seni buldum!"), L(T, "şaşkın", "Bu... buldun mu? Bir daha saklanırım!")],
    "s3k5_buldum2": [L(O, "mutlu", "Seni buldum!"), L(T, "şaşkın", "Yine mi? Ama çok iyi saklanmıştım...")],
    "s3k5_buldum3": [L(O, "mutlu", "Seni yine buldum!"), L(T, "utangaç", "Her seferinde arıyorsunuz. Hiç vazgeçmiyorsunuz.")],
    "s3k5_buldum4": [L(O, "mutlu", "Buldum! Kaç kere saklanırsan saklan."), L(T, "utangaç", "Demek... biri beni hep arıyormuş.")],
    "s3k5_halka": [L(H, "mutlu", "Herkes el ele! Halka kuruldu."),
                   L(T, "üzgün", "Işığım titriyor. Ya yine sönerse?"),
                   L(O, "sakin", "Sönerse biz buradayız. Elimi tut.")],
    "s3k5_son": [L(T, "mutlu", "Işığım... durdu. Titremiyor!"),
                 L(H, "mutlu", "Korkun bitmedi belki. Ama artık yalnız değilsin."),
                 L(T, "mutlu", "Kimse karanlıkta yalnız kalmaz. Öyle mi?")],
    "s3k5_inci": [L(O, "mutlu", "İnci Beyazı! Beşinci ve son inci.")],
}
# the closing scene (s3_final, Fener Gecesi) reads this pack too
B.update({
    "s3f_1": [L("mors_dede", "mutlu", "Ho ho! Beş inci de geldi. Bıyıklarım sevinçten titriyor!"),
              L(O, "mutlu", "Hadi incileri yerine koyalım, Mors Dede.")],
    "s3f_2": [L("mors_dede", "mutlu", "Yandı! Yıllar sonra ilk kez yandı!"),
              L("tosbi", "mutlu", "Işığı ta denizin öbür ucuna gidiyor!")],
    "s3f_3": [L("tiril", "şaşkın", "O ışıklar... Onlar... annem! Babam!"),
              L(O, "mutlu", "Seni hiç bırakmamışlar. Yıllardır arıyorlarmış.")],
    "s3f_4": [L("tiril", "mutlu", "Buradayım! Beni buldular. Siz de buldunuz!"),
              L("hiril", "mutlu", "Fener Gecesi başlasın! Bum, bum, bum!")],
    "s3f_5": [L("miril", "mutlu", "Ben gökyüzünü aydınlatırım, Tırıl denizi!"),
              L("fistik", "huysuz", "Bir dahaki sefere tatil yapacağım, haberiniz olsun.")],
    "s3f_pati": [L("pati", "mutlu", "Herkes baksın: atlıyorum! Şap! ...Yüzüyorum!")],
    "s3f_bado": [L("bado", "mutlu", "Minnoş uyudu. Gece lambası yok, elim yanında.")],
    "s3f_citir": [L("citir", "mutlu", "Haritaya yazdım: Kaybolursan buraya gel.")],
    "s3f_lumi": [L("lumi", "mutlu", "Ailem geldi! Işık dansı: ateşböcekleri ve denizanaları!")],
    "s3f_tipis_panda": [L("tipis_panda", "mutlu", "Hırıl, hazır mısın? İlk konserimiz: bir, iki, üç!")],
    "s3f_tosbi": [L("tospik_nine", "mutlu", "Dedenin kabuk kalkanı artık senin, Tosbi."),
                  L("tosbi", "mutlu", "Saklanmak da cesaret. Yeter ki tekrar çıkayım!")],
    # Yeni Oyun+ keepers
    "s3f_hiril": [L("hiril", "mutlu", "Bu ritim hepimizin! Tırıl, sen de vur: bum, bum!")],
    "s3f_tiril": [L("tiril", "mutlu", "Ürkünce ışığıma bakın. Ben hep buradayım!")],
    "s3f_6": [L("fistik", "şaşkın", "Bu sarmaşık da ne? Dikenleri benimkilere benzemiyor.")],
})
pack("s3_chapter5", "Kayıp Ada", "Kayıp Ada", [25, 30], [Q1, Q2], D, B)

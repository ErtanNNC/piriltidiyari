#!/usr/bin/env python3
"""Writes content/s3_side.json: Season 3's side collections (see SideQuests,
SideSpot). Spots are [x, z] on an island's floor; check them with
`tools/run_demo.sh s3_chapterN side`."""
import json, os

def L(who, mood, text):
    assert len(text) <= 70, (len(text), text)
    return {"speaker": who, "mood": mood, "text": text}

O = "oyuncu"
SETS = {
 "sise": {"season": 3, "title": "Mesaj Şişeleri", "action": "Oku",
  "desc": "Kıyıya vuran şişeler: içlerinde Tırıl'ın notları var",
  "reward": {"piril": 300, "xp": 600},
  "first": [L(O, "şaşkın", "Kumda bir şişe! İçinde rulo yapılmış bir kâğıt var."),
            L(O, "sakin", "Titrek bir yazı... Bunu Tırıl yazmış olmalı.")],
  "done": [L(O, "mutlu", "Yirmi beş şişe, yirmi beş not. Hepsini okudum!"),
           L(O, "şaşkın", "Son notun arkasında bir harita var: Mercan Bahçesi."),
           L(O, "kararlı", "Kabuk Kayık artık oraya da gider. İskeleye!")]},
 "isik": {"season": 3, "title": "Minnoş'un Gece Lambası", "action": "Al",
  "desc": "Her adada bir Işık Parçası: Minnoş'un lambası için",
  "reward": {"piril": 200, "xp": 400},
  "first": [L(O, "şaşkın", "Sıcacık bir ışık parçası! Kum bile ısınmış."),
            L(O, "mutlu", "Minnoş'un gece lambasına tam uyar. Toplayalım!")],
  "done": [L(O, "mutlu", "Beş parça da tamam! Lamba ay gibi parlıyor."),
           L(O, "sakin", "Minnoş'a söyleyeceğim: karanlıkta da yalnız değilsin.")],
  "done_bado": [L(O, "mutlu", "Beş parça da tamam! Lamba ay gibi parlıyor."),
           L(O, "mutlu", "Kardeşim Minnoş bu gece ışıl ışıl uyuyacak!")]},
 "kart": {"season": 3, "title": "Fıstık'ın Kartpostalları", "action": "Oku",
  "desc": "Fişek yanınca posta kutusuna Fıstık'tan bir kart gelir",
  "locked": "Posta kutusu boş. Fişek yanınca kart gelir.",
  "reward": {"piril": 150, "xp": 300},
  "first": [],
  "done": [L(O, "mutlu", "Fıstık'ın bütün kartlarını okudum."),
           L(O, "mutlu", "Ona en güzel deniz kabuğunu götüreceğim!")]},
 "pati": {"season": 3, "title": "Pati'nin Sırrı", "action": "Yanında dur",
  "desc": "Pati üç adada kıyıda duruyor. Yanında dur, acele etme",
  "reward": {"piril": 200, "xp": 400},
  "first": [],
  "done": [L("pati", "dertli", "Sırrım şu: sudan çok ürküyorum. Kediyim işte."),
           L(O, "sakin", "Bunu söylemek cesaret ister. Teşekkür ederim."),
           L("pati", "kararlı", "Elimi tutar mısın? Bir patimi suya sokacağım."),
           L("pati", "şaşkın", "Islak! Soğuk! Ama... hâlâ buradayım!"),
           L(O, "mutlu", "Yarın iki pati. Yüzmeyi birlikte öğreniriz.")],
  "done_pati": [L(O, "dertli", "Bado, sırrım şu: sudan çok ürküyorum."),
           L("bado", "sakin", "Bunu söylemek cesaret ister. İyi ki söyledin."),
           L(O, "kararlı", "Elimi tutar mısın? Bir patimi suya sokacağım."),
           L(O, "şaşkın", "Islak! Soğuk! Ama... hâlâ buradayım!"),
           L("bado", "mutlu", "Yarın iki pati. Yüzmeyi birlikte öğreniriz.")]},
}

T = "tiril"
NOTES = [  # 25 notes, in the order the islands are visited
 ("dertli", "Biri bu şişeyi bulursa: ben Tırıl. Sanırım kayboldum."),
 ("dertli", "Ailem dalgaların öbür yanında. Hangi yanında, bilmiyorum."),
 ("sakin", "Bugün bir yıldız kaydı. Ürkmedim. Yani... çok az ürktüm."),
 ("dertli", "Işığım titriyor. Titreyince etrafım mavi sis oluyor."),
 ("sakin", "Biri beni arıyor mu? Arıyorsa: buradayım, sisin içinde."),
 ("şaşkın", "Bir ahtapot gördüm. O da saklanıyordu. İkimiz de sustuk."),
 ("sakin", "Karanlıkta mantarlar parlıyor. Onlar hiç titremiyor."),
 ("dertli", "Annem 'Uzaklaşma' demişti. Bir dalga beni aldı götürdü."),
 ("sakin", "Şişe atmayı sürdürüyorum. Deniz iyi bir postacıdır belki."),
 ("şaşkın", "Rüzgâr şarkı söylüyor. Önce canavar sandım, rüzgârmış."),
 ("sakin", "Bir martı yavrusu uçmayı deniyor. O da ürküyor. Yine deniyor."),
 ("dertli", "Kendi kendime konuşuyorum. Cevap veren yok, komik değil."),
 ("mutlu", "Uzakta bir ışık yandı! Sonra bir tane daha. Kim yakıyor?"),
 ("şaşkın", "Burada kumlar yürüyor. Yolumu üç kere kaybettim."),
 ("sakin", "Bir yengeç evini sırtında taşıyor. Benim evim nerede?"),
 ("mutlu", "Bir davul sesi duydum. Gümbür gümbür ama... tatlı."),
 ("sakin", "Davul çalınca sisim biraz dağıldı. Tuhaf, hoşuma gitti."),
 ("dertli", "Gök gürledi. Gölgem kocaman oldu. Kendi gölgemden kaçtım."),
 ("sakin", "Büyük bir fok da gök gürültüsünden ürküyor. Rahatladım."),
 ("mutlu", "Işıklar yaklaşıyor. Biri adaları tek tek aydınlatıyor!"),
 ("şaşkın", "Belki beni arıyorlardır. Belki de sadece geçiyorlardır."),
 ("dertli", "Oyuncak teknem battı. İçinde ailemin resmi vardı."),
 ("sakin", "Saklandığım yeri kimse bulamaz. Bulsalar... keşke bulsalar."),
 ("mutlu", "Biri 'Buldum seni!' derse kaçmayacağım. Söz."),
 ("mutlu", "Evim Mercan Bahçesi. Bir gün birini oraya götüreceğim."),
]
CARDS = [
 [L("fistik", "huysuz", "Kart 1: Deniz mi? Dikenlerime tuz doldu. Çok sağ olun."),
  L("fistik", "sakin", "Yine de fişek güzel yandı. Aferin. Söylemedim say.")],
 [L("fistik", "huysuz", "Kart 2: Mürekkep lekesi çıkmıyor. Denedim. Üç kere."),
  L("fistik", "sakin", "Karanlıkta mantar parlarmış. Bana da bir tane getir.")],
 [L("fistik", "huysuz", "Kart 3: Rüzgâr şapkamı aldı. Şapkam yoktu ama olsun."),
  L("fistik", "mutlu", "Yavru kuş uçmuş diyorlar. İyi. Çok iyi. Hapşu!")],
 [L("fistik", "huysuz", "Kart 4: Kum her yerde. Yatağımda bile. Kim getirdi?"),
  L("fistik", "sakin", "Dar gelen kabuğu değiştirmek akıllıca. Not aldım.")],
 [L("fistik", "huysuz", "Kart 5: Gök gürleyince dikenlerim kabardı. Soğuktan!"),
  L("fistik", "sakin", "Tamam, biraz ürktüm. Kimseye söyleme. Sana söyledim.")],
 [L("fistik", "sakin", "Kart 6: Kaybolan bulunur. Ben de bir kere kaybolmuştum."),
  L("fistik", "mutlu", "Beni bulan sizdiniz. Şimdi sıra sizde. Yolunuz açık olsun.")],
]
PATI = [
 {"lines": [L("pati", "sakin", "Sadece dalgalara bakıyorum. Yaklaşmıyorum, bakıyorum."),
            L(O, "sakin", "Ben de bakarım. Acelemiz yok.")],
  "lines_pati": [L(O, "sakin", "Sadece dalgalara bakıyorum Bado. Yaklaşmıyorum."),
            L("bado", "sakin", "Ben de bakarım. Acelemiz yok.")]},
 {"lines": [L("pati", "şaşkın", "Rüzgâr su sıçratıyor. Tüylerim diken diken oldu."),
            L(O, "sakin", "Yanındayım. İstersen bir adım geri gidelim."),
            L("pati", "kararlı", "Yok. Burada, seninle durabilirim.")],
  "lines_pati": [L(O, "şaşkın", "Rüzgâr su sıçratıyor. Tüylerim diken diken oldu."),
            L("bado", "sakin", "Yanındayım. İstersen bir adım geri gidelim."),
            L(O, "kararlı", "Yok. Burada, seninle durabilirim.")]},
 {"lines": [L("pati", "dertli", "Burada kumlar bile yürüyor. Ben niye yürüyemiyorum?"),
            L(O, "şaşkın", "Nereye yürüyemiyorsun Pati?"),
            L("pati", "sakin", "Söyleyeceğim. Az kaldı. Yanımda durman iyi geldi.")],
  "lines_pati": [L(O, "dertli", "Burada kumlar bile yürüyor. Ben niye yürüyemiyorum?"),
            L("bado", "şaşkın", "Nereye yürüyemiyorsun Pati?"),
            L(O, "sakin", "Söyleyeceğim. Az kaldı. Yanımda durman iyi geldi.")]},
]

# per island: bottles, light piece, postcard box, Pati's place
PLACES = {
 "s3_chapter0": {"sise": [[-24, 19], [24, 21], [-25, -20], [25, -6], [12, -22]], "kart": [9, 20]},
 "s3_chapter1": {"sise": [[-12, 27], [-13, 0], [8, -16], [-10, -46]], "isik": [6, -44], "kart": [8, 17], "pati": [8, 27]},
 "s3_chapter2": {"sise": [[-15, 26], [15, 20], [-10, -2], [15, -26]], "isik": [-12, -16], "kart": [5, 22], "pati": [14, 27]},
 "s3_chapter3": {"sise": [[-9, 27], [12, 12], [-12, -9], [12, -20]], "isik": [10, 0], "kart": [-6, 22], "pati": [12, 27]},
 "s3_chapter4": {"sise": [[-8, 27], [7, 18], [-8, -2], [-8, -12]], "isik": [-8, 16], "kart": [6, 23]},
 "s3_chapter5": {"sise": [[-8, 24], [8, -1], [-8, -17], [8, -31]], "isik": [12, -55], "kart": [-8, -49]},
}
REGIONS = {"s3_chapter0": "Mercan Koyu", "s3_chapter1": "Mürekkep Adası", "s3_chapter2": "Rüzgârlı Kayalıklar",
           "s3_chapter3": "Değişen Kumlar", "s3_chapter4": "Fırtına Kayası", "s3_chapter5": "Kayıp Ada"}

spots, n, p = {}, 0, 0
for i, (scene, pl) in enumerate(PLACES.items()):
    out = []
    for at in pl["sise"]:
        mood, text = NOTES[n]; n += 1
        out.append({"set": "sise", "at": at, "lines": [L(T, mood, text)]})
    if "isik" in pl:
        out.append({"set": "isik", "at": pl["isik"]})
    out.append({"set": "kart", "at": pl["kart"], "needs": "s3_fisek%d" % i, "lines": CARDS[i]})
    if "pati" in pl:
        out.append({"set": "pati", "at": pl["pati"], "face": 0, **PATI[p]}); p += 1
    spots[scene] = out
assert n == 25 and p == 3
path = os.path.join(os.path.dirname(__file__), "..", "content", "s3_side.json")
json.dump({"sets": SETS, "regions": REGIONS, "spots": spots}, open(path, "w"), ensure_ascii=False, indent=1)
print("s3_side.json:", {k: sum(1 for sc in spots.values() for s in sc if s["set"] == k) for k in SETS})

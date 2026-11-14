"""Mercan Bahçesi (s3_garden): the secret region that opens with every
Mesaj Şişesi. No fighting: find Tırıl's family and five Anı Kabuğu."""
import sys, os; sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from s3_pack import *
speakers({"tiril_anne": ("Tırıl'ın Annesi", "berry"), "tiril_baba": ("Tırıl'ın Babası", "honey"),
          "tiril_kardes": ("Tırıl'ın Kardeşi", "spark-green")})
O = "oyuncu"
T = "tiril"
A = "tiril_anne"
B_ = "tiril_baba"
K = "tiril_kardes"
BITTI = "mercan_bahcesi_bitti"
Q = {"id": "mercan_bahcesi", "title": "Mercan Bahçesi", "giver": "tiril", "objectives": [
    {"id": "aile", "text": "Tırıl'ın ailesini bul: anne, baba, kardeş", "type": "meet", "target": "tiril_ailesi", "count": 3},
    {"id": "kabuk", "text": "Beş Anı Kabuğu'nu bul ve aç", "type": "collect", "target": "ani_kabugu", "count": 5}],
    "turn_in": "Ortadaki Işık Kabuğu'na gel", "rewards": {"piril": 150, "xp": 300}}
D = {}
D["tiril"] = [
    {"when": {"flag": BITTI}, "lines": [
        L(T, "mutlu", "Bahçemize hoş geldin! Kapımız sana hep açık."),
        L(T, "mutlu", "Kabukları istediğin kadar aç. Anılar eskimez.")]},
    {"when": {"quest": "mercan_bahcesi", "state": "ready"}, "lines": [
        L(T, "mutlu", "Hepsini buldun! Ortadaki Işık Kabuğu'na gel."),
        L(T, "mutlu", "Ailem orada toplandı. Seni bekliyoruz!")]},
    {"when": {"quest": "mercan_bahcesi", "state": "active"}, "lines": [
        L(T, "sakin", "Ailem bahçeye dağıldı: annem, babam, minik kardeşim."),
        L(T, "mutlu", "Baloncuk sütunları seni yukarı taşır. İçine gir, yeter!"),
        L(T, "sakin", "Düşersen korkma. Burada herkes yavaşça süzülür.")]},
    {"lines": [
        L(T, "mutlu", "Geldin! Burası Mercan Bahçesi. Benim evim."),
        L(O, "şaşkın", "Suyun altında nefes alabiliyorum! Burnum gıdıklanıyor."),
        L(T, "mutlu", "Bütün şişeleri toplayınca kapı sana açıldı."),
        L(T, "utangaç", "Ailemle tanışır mısın? Bir de beş Anı Kabuğu var."),
        L(T, "mutlu", "Baloncuk sütunları seni yukarı taşır. Burada her şey yavaş!")],
     "then": {"start_quest": "mercan_bahcesi"}}]
D["tiril_anne"] = [
    {"when": {"not_flag": "mb_aile_anne"}, "lines": [
        L(A, "mutlu", "Sen Tırıl'ı bulan bekçisin! Gel, sana yakından bakayım."),
        L(A, "sakin", "Her gece Deniz Feneri'ne baktık. Bir gün yanar dedik."),
        L(O, "mutlu", "Yandı! Tırıl da evine geldi.")],
     "then": {"set_flag": "mb_aile_anne"}},
    {"when": {"flag": BITTI}, "lines": [
        L(A, "mutlu", "Tırıl artık ışığını yakıp mışıl mışıl uyuyor. Sayende.")]},
    {"lines": [L(A, "sakin", "Babası karşı kayada. Mercan Kemer'in üstünden geç!")]}]
D["tiril_baba"] = [
    {"when": {"not_flag": "mb_aile_baba"}, "lines": [
        L(B_, "mutlu", "Ho! Misafir! Bahçemize ilk kez bir bekçi geldi."),
        L(B_, "sakin", "Tırıl'ı akıntı götürdü. Aramayı hiç bırakmadık."),
        L(O, "sakin", "O da hep bekledi. Sadece iyi saklanıyordu.")],
     "then": {"set_flag": "mb_aile_baba"}},
    {"when": {"flag": BITTI}, "lines": [
        L(B_, "mutlu", "Mercanları suluyorum. Şaka şaka, zaten suyun altındayız!")]},
    {"lines": [L(B_, "sakin", "Kabuklara bak. Her birinde Tırıl'ın bir anısı saklı.")]}]
D["tiril_kardes"] = [
    {"when": {"not_flag": "mb_aile_kardes"}, "lines": [
        L(K, "mutlu", "Ce-ee! Beni buldun! Saklambaçta çok iyiyimdir."),
        L(K, "şaşkın", "Tırıl da iyi saklanır. Ama sen onu dört kere bulmuşsun!"),
        L(O, "mutlu", "Seni de buldum. Bu ailede herkes mi saklanıyor?")],
     "then": {"set_flag": "mb_aile_kardes"}},
    {"when": {"flag": BITTI}, "lines": [
        L(K, "mutlu", "Bir daha saklanayım mı? Say bakalım: bir, iki, üç...")]},
    {"lines": [L(K, "mutlu", "Baloncuklara bin! Hop diye yukarı çıkarsın. Çok gıdıklar!")]}]
B = {
    "mb_basla": [L(O, "şaşkın", "Vay! Her yer mercan, her yer ışık. Mavi Titreme burada yok."),
                 L(O, "mutlu", "Yüzer gibi yürüyorum. Zıplayınca süzülüyorum!")],
    "mb_baloncuk": [L(O, "mutlu", "Baloncuklar beni yukarı taşıdı! Bir daha, bir daha!")],
    "mb_ani1": [L(T, "mutlu", "Bu kabukta ilk ışığım var. Annem bana 'minik fenerim' demişti."),
                L(T, "sakin", "O gece hiç titremedim. Çünkü elimi tutuyordu.")],
    "mb_ani2": [L(T, "mutlu", "Babam bana baloncuk üflemeyi öğretti. İlki burnumda patladı!"),
                L(T, "mutlu", "Çok güldük. Gülünce ışığım pembe olurdu.")],
    "mb_ani3": [L(T, "mutlu", "Burası bahçenin en yüksek yeri. Kardeşimle yıldız sayardık."),
                L(T, "utangaç", "Ben hep on ikide şaşırırdım. O hiç bozuntuya vermezdi.")],
    "mb_ani4": [L(T, "üzgün", "Fırtınalı bir gece akıntı beni aldı götürdü. Çok uzağa."),
                L(T, "sakin", "Ailem her gece ışık yakmış. Göremedim ama yakmışlar.")],
    "mb_ani5": [L(T, "sakin", "Saklandığım tekne çok karanlıktı. Tek ses bir davuldu."),
                L(T, "mutlu", "Bum... bum... Biri beni arıyormuş. Artık biliyorum.")],
    "mb_hazir": [L(T, "mutlu", "Herkesi buldun, bütün kabukları açtın!"),
                 L(T, "mutlu", "Ortadaki Işık Kabuğu'na gel. Ailem seni bekliyor.")],
    "mb_son1": [L(A, "sakin", "Yıllardır bu bahçenin ışıklarını yakmadık."),
                L(B_, "mutlu", "Bu gece yakıyoruz. Hazır mısınız? Bir, iki, üç!")],
    "mb_son2": [L(K, "mutlu", "Her yer parlıyor! Mercanlar bile gülüyor!"),
                L(T, "mutlu", "Bak, ışığım hiç titremiyor."),
                L(T, "mutlu", "Çünkü biri beni aramaya geldi. Sonra bir daha geldi."),
                L(O, "mutlu", "Yine gelirim. Kimse karanlıkta yalnız kalmaz.")],
    "mb_son3": [L(A, "mutlu", "Bahçemiz artık senin de bahçen. Ne zaman istersen gel.")],
}
pack("s3_garden", "Mercan Bahçesi", "Mercan Bahçesi", [25, 30], [Q], D, B)

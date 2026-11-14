"""Gece Regatası (post-game boat race, scene s3_regatta): Olta is the host."""
import sys; sys.path.insert(0,'/home/user/piriltidiyari/tools')
from s3_pack import *
O="oyuncu"
D={}
D["olta"]=[
 {"when":{"flag":"regata_altin"},"lines":[
   L("olta","mutlu","Miyav! Altın madalyalı kaptan gelmiş. Bıyığım kıvrıldı!"),
   L("olta","sakin","Kayığını süslemek istersen sepetim açık.")],"then":{"open_shop":"regata"}},
 {"when":{"flag":"regata_bronz"},"lines":[
   L("olta","mutlu","Miyav! Yine mi yarış? Balıklar bile seni alkışlıyor."),
   L("olta","sakin","Yelken, kürek, fener... Kayık bunlarla uçar!")],"then":{"open_shop":"regata"}},
 {"lines":[
   L("olta","mutlu","Miyav! Gece Regatası'na hoş geldin, kaptan!"),
   L("olta","sakin","Işıklı kapılardan sırayla geç. Yıldızlı kapı sıradaki."),
   L("olta","mutlu","Kayıkta ne kadar dost varsa o kadar hızlı gider. El ele!"),
   L("olta","sakin","Acele yok. Burada kaybeden olmaz, sadece ıslanan olur.")],"then":{"open_shop":"regata"}}]
B={
 "rg_basla":[L("olta","mutlu","Miyav! Kayık hazır, deniz pırıl pırıl. Yarışalım mı?"),
   L(O,"mutlu","Hazırım! Dostlarım da kayıkta.")],
 "rg_sis":[L("olta","şaşkın","Miyav! Mavi siste kayık kaplumbağa gibi gider."),
   L("olta","sakin","Etrafından dolan ya da Pruva Feneri tak!")],
 "rg_bronz":[L("olta","mutlu","Bitirdin! Bronz madalya senin. Balık kokulu ama güzel!"),
   L("olta","sakin","Bir daha dene. Kapılara düz git, daha da hızlanırsın.")],
 "rg_gumus":[L("olta","mutlu","Miyav miyav! Gümüş madalya! Martılar bile geride kaldı."),
   L("olta","sakin","Altın için dönüşleri kıs. Ya da yelkeni dene!")],
 "rg_altin":[L("olta","mutlu","ALTIN! Miyaaav! Deniz Feneri bile göz kırptı!"),
   L(O,"mutlu","Tek başıma değil. Kayık dost doluydu!")],
 "rg_yine":[L("olta","mutlu","Güzel yarıştı! Madalyan aynı, keyfin yeni.")],
}
S={"regata":{"title":"Olta'nın Kayık Sepeti","items":[{"id":"tekne_yelken","price":120,"once":True},
 {"id":"tekne_kurek","price":90,"once":True},{"id":"tekne_fener","price":90,"once":True},
 {"id":"sicak_kakao","price":15},{"id":"bal_surubu","price":15}]}}
pack("s3_regatta","Gece Regatası","Mercan Koyu",[5,10],[],D,B,S)

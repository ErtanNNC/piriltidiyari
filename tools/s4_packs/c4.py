import sys; sys.path.insert(0,'/home/user/piriltidiyari/tools')
from s4_pack import *
O="oyuncu"
speakers({"kugu":("Kuğu","sky"),"pacali":("Paçalı","spark-yellow"),"diril":("Dırıl","spark-green")})
Q1={"id":"golun_aynalari","title":"Gölün Aynaları","giver":"kugu","objectives":[
 {"id":"ayna","text":"Üç ayna taşına bak, doğru yaprak yolunu bul","type":"collect","target":"ayna","count":3},
 {"id":"alkis","text":"Adacıklardaki sarmaşıkları alkışla","type":"clap","target":"sarmasik","count":2},
 {"id":"tohum","text":"Dikenli adacıktan kıyıya köprü tohumu ek","type":"grow","target":"kopru"},
 {"id":"dikenci","text":"Dikencileri sersemlet, sonra alkışla","type":"breathe","target":"any","count":4}],
 "turn_in":"Kuzey kıyıya yüzen Kuğu ile konuş","rewards":{"piril":45,"xp":70}}
Q2={"id":"sari_ayaklar","title":"Sarı Ayaklar","giver":"kugu","objectives":[
 {"id":"ark","text":"Gölün ark kapağını aç","type":"light","target":"ark"},
 {"id":"pacali","text":"Sazlıktaki Paçalı'yı alkışla","type":"breathe","target":"pacali"},
 {"id":"tohum","text":"Nilüfer Tohumu'nu al","type":"collect","target":"tohum"}],
 "turn_in":"Kuğu ile konuş","rewards":{"piril":55,"xp":90}}
D={}
D["kugu"]=[
 {"when":{"quest":"sari_ayaklar","state":"ready"},"lines":[
   L("kugu","mutlu","Göl yine ayna gibi! Paçalı da bizimle yüzüyor."),
   L("kugu","sakin","Herkesin kendine ait bir güzelliği var. Göl bunu gösterdi."),
   L("kugu","kararlı","Son tohum Gölge Köşesi'nde. Bahar Kapısı çiçek açtı!"),
   L(O,"kararlı","Dırıl orada bekliyor. Tırıl da yanında. Gidiyoruz!")],
  "then":{"complete_quest":"sari_ayaklar","set_flag":"s4_bolum4_bitti","give_items":{"nane_limonata":2}}},
 {"when":{"quest":"sari_ayaklar","state":"active","objective_done":"sari_ayaklar/pacali"},"lines":[
   L("kugu","mutlu","Paçalı gülüyor! Tohum parlıyor, hadi al onu.")]},
 {"when":{"quest":"sari_ayaklar","state":"active","objective_done":"sari_ayaklar/ark"},"lines":[
   L("kugu","mutlu","Su akıyor, sazlığın önündeki dikenler çekildi!"),
   L("kugu","dertli","Paçalı kuzeyde, sazlıkta. Suya hiç bakmıyor."),
   L("kugu","sakin","Yorulunca yanına git, alkışla. Ayaklarına bayılıyoruz!")]},
 {"when":{"quest":"sari_ayaklar","state":"active"},"lines":[
   L("kugu","kararlı","Ark kapağı hemen şurada, doğuda. Çarkını çevir!")]},
 {"when":{"quest":"golun_aynalari","state":"ready"},"lines":[
   L("kugu","mutlu","Gölü geçtin! Ben de peşinden yüzdüm."),
   L("kugu","dertli","Paçalı gölü sarmaşıkla örttü. Bizi görmek istemiyor."),
   L("kugu","sakin","Boynumuz uzun, tüyümüz beyaz diye üzülüyormuş."),
   L("kugu","kararlı","Arkı aç, sazlığa git. Ona kendi güzelliğini gösterelim!")],
  "then":{"complete_quest":"golun_aynalari","start_quest":"sari_ayaklar"}},
 {"when":{"quest":"golun_aynalari","state":"active"},"lines":[
   L("kugu","sakin","Ayna taşına bak. Suda kimi görürsen onun yolundan git."),
   L("kugu","sakin","Öbür yolun yaprakları sallanır, sonra batar. Su zarar vermez.")]},
 {"when":{"quest":"golun_aynalari","state":"none"},"lines":[
   L("kugu","mutlu","Hoş geldin! Burası Ayna Gölü. Ben bir kuğuyum."),
   L("kugu","şaşkın","Bu göle bakan, kendini değil başkasını görür!"),
   L("kugu","dertli","Çatallarda iki yaprak yolu var. Biri sağlam, biri batar."),
   L("kugu","kararlı","Ayna taşına bak: suda kimi görürsen onun yolu sağlam!")],
  "then":{"start_quest":"golun_aynalari"}},
 {"lines":[L("kugu","mutlu","Göl pırıl pırıl. Paçalı'nın ayak izleri her yerde!")]}]
B={
 "s4k4_basla":[L(O,"şaşkın","Ne sakin bir göl! Ama üstü sarmaşık dolu."),
   L(O,"sakin","Kıyıdaki kuğu bize bakıyor. Bir derdi var galiba.")],
 "s4k4_ayna0":[L(O,"şaşkın","Suya baktım... Bana bir kurbağa bakıyor!"),
   L(O,"kararlı","Kurbağanın durduğu yaprak yolu sağlam demek.")],
 "s4k4_ayna1":[L(O,"şaşkın","Bu sefer suda bir kuğu var. Boynu ne uzun!"),
   L(O,"kararlı","Kuğunun beklediği yoldan gidelim.")],
 "s4k4_ayna2":[L(O,"mutlu","Sarmaşık çekildi, ayna göründü. Suda bir balık!"),
   L(O,"kararlı","Balığın yolu sağlam. Son çatal bu!")],
 "s4k4_batti":[L(O,"şaşkın","Yapraklar sallandı, sonra battı! Su beni çatala getirdi."),
   L(O,"sakin","Ayna taşına bakmalıyım. O bana doğru yolu söyler.")],
 "s4k4_su":[L(O,"şaşkın","Şap! Islandım ama canım yanmadı."),
   L(O,"sakin","Göl beni son durduğum adacığa geri bıraktı.")],
 "s4k4_sarmasik":[L(O,"mutlu","Alkışladım, sarmaşık çekildi! Yerinde çiçek kaldı.")],
 "s4k4_tohum":[L(O,"mutlu","Yaprak köprü kıyıya uzandı! Karşıya geçebiliriz.")],
 "s4k4_dikenci":[L(O,"şaşkın","Bu balık pul pul parlıyor, kurbağa da beni taklit ediyor!"),
   L(O,"kararlı","Önce sersemlet, sonra alkışla. Kendi parıltısını görsün.")],
 "s4k4_kugu":[L("kugu","mutlu","Hepsini yaptın! Bekle, yüzerek yanına geliyorum."),
   L(O,"mutlu","Kuğu gölü süzülerek geçti. Ne güzel yüzüyor!")],
 "s4k4_kilit":[L(O,"sakin","Çark dönmüyor. Önce Kuğu'nun işini bitirelim.")],
 "s4k4_ark":[L(O,"mutlu","Su akıyor! Sazlığın önündeki dikenler kurudu.")],
 "s4k4_pacali":[L("pacali","huysuz","Vak! Göle bakma! Orada hep kuğular görünüyor!"),
   L("pacali","dertli","Uzun boyun, beyaz tüy... Bende hiçbiri yok."),
   L(O,"şaşkın","Gölü o örtmüş. Kendi yansımasını hiç görmemiş ki!")],
 "s4k4_sakin":[L("pacali","şaşkın","Beni... alkışladın mı? Neyimi alkışladın ki?"),
   L(O,"mutlu","Gel, göle birlikte bakalım. Sarmaşıklar çekiliyor!")],
 "s4k4_yansima":[L("pacali","şaşkın","Suda sarı sarı kocaman ayaklar var. Onlar... benim mi?"),
   L("kugu","mutlu","Senin! O ayaklara hep bayıldık. Şap şap yürüyorsun!"),
   L("pacali","mutlu","Vak vak! Ayaklarım çok sevimliymiş! Şap! Şap!"),
   L(O,"mutlu","Herkesin kendine ait bir güzelliği var. Seninki de bu!")],
 "s4k4_tohum_al":[L(O,"mutlu","Nilüfer Tohumu! Dördüncü Bahar Tohumu bizde."),
   L(O,"şaşkın","Tohum ışıldıyor... İçinde bir anı var galiba.")],
 "s4k4_ani":[L("diril","dertli","Beni eken çocuk bir gece köşeme bakmaya geldi."),
   L("diril","dertli","O gece fırtına çıktı. Çocuk bir daha hiç gelemedi."),
   L(O,"sakin","Seni unutmadı Dırıl. Sadece yolu kapandı."),
   L(O,"kararlı","Biz geliyoruz. Bu sefer biri seni görecek.")],
}
pack("s4_chapter4","Ayna Gölü","Ayna Gölü",[20,25],[Q1,Q2],D,B,None,theme="light")

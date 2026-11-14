import sys; sys.path.insert(0,'/home/user/piriltidiyari/tools')
from s4_pack import *
O="oyuncu"
speakers({"toprak":("Solucan Dede Toprak","honey"),"boynuz":("Demirci Boynuz","sky"),"kozacik":("Terzi Kozacık","berry"),
 "marul":("Marul Teyze","spark-green"),"turp":("Turp Amca","hp"),"fasulye":("Fasulye","spark-yellow"),
 "korkuluk":("Huysuz Korkuluk","honey"),"yonca":("Yonca","spark-green"),"diril":("Dırıl","spark-green"),
 "vizik":("Çiçekçi Vızık","spark-yellow"),"sikir":("Saksağan Şıkır","sky"),"nihan":("Bülbül Nihan","berry"),
 "circir":("Cırcır","spark-green"),"pitpit":("Pıtpıt","honey"),"pacali":("Paçalı","spark-yellow"),"kugu":("Kuğu","sky"),
 "kabak":("Dev Kabak","hp")})
Q1={"id":"perdeler_acilsin","title":"Perdeler Açılsın","giver":"toprak","objectives":[
 {"id":"alkis","text":"Üç komşunun serasını alkışla","type":"clap","target":"sera","count":3},
 {"id":"dikenci","text":"Dikencileri sersemlet, sonra alkışla","type":"breathe","target":"any","count":4},
 {"id":"tohum","text":"Kanalın başına bir köprü tohumu ek","type":"grow","target":"kopru"}],
 "turn_in":"Solucan Dede Toprak'a dön","rewards":{"piril":30,"xp":40}}
Q2={"id":"huysuz_korkuluk","title":"Huysuz Korkuluk","giver":"toprak","objectives":[
 {"id":"ark","text":"Kasabanın ark kapağını aç","type":"light","target":"ark"},
 {"id":"korkuluk","text":"Bostandaki korkuluğu alkışla","type":"breathe","target":"korkuluk"}],
 "turn_in":"Solucan Dede Toprak'a dön","rewards":{"piril":40,"xp":60}}
D={}
D["toprak"]=[
 {"when":{"quest":"huysuz_korkuluk","state":"ready"},"lines":[
   L("toprak","mutlu","Kuşlar korkuluğun omzunda! Bunu yüz yıldır görmedim."),
   L("toprak","sakin","Toprak herkese aynı suyu verir. Ama herkes aynı gün açmaz."),
   L("toprak","kararlı","İlk tohum Parlak Pazar'da. Bahar Kapısı çiçek açtı!"),
   L(O,"kararlı","Beş tohumu da bulacağız. Tırıl'ı ve Dırıl'ı da!")],
  "then":{"complete_quest":"huysuz_korkuluk","set_flag":"s4_bolum0_bitti","give_items":{"papatya_celengi":2}}},
 {"when":{"quest":"huysuz_korkuluk","state":"active","objective_done":"huysuz_korkuluk/ark"},"lines":[
   L("toprak","mutlu","Su akıyor! Kuzeydeki dikenler de çekildi."),
   L("toprak","dertli","Bostanda bir korkuluk kuşları kovalıyor. Uçamıyor ya, ondan."),
   L("toprak","sakin","Yorulunca yanına git, alkışla. Kimse onu hiç alkışlamadı.")]},
 {"when":{"quest":"huysuz_korkuluk","state":"active"},"lines":[
   L("toprak","kararlı","Ark kapağı kuzeyde, köprünün ötesinde. Çarkı çevir!")]},
 {"when":{"quest":"perdeler_acilsin","state":"ready"},"lines":[
   L("toprak","mutlu","Perdeler açıldı! Komşular yine selamlaşıyor."),
   L("toprak","dertli","Ama arkımız tıkalı. Su gelmezse tohumlar uyanmaz."),
   L("toprak","kararlı","Kapağı aç evlat. Sonra bostandaki huysuza bak.")],
  "then":{"complete_quest":"perdeler_acilsin","start_quest":"huysuz_korkuluk"}},
 {"when":{"quest":"perdeler_acilsin","state":"active"},"lines":[
   L("toprak","sakin","Komşunun serasının önünde dur ve alkışla. Dikenler çekilir."),
   L("toprak","sakin","Dikenci sersemleyince de alkışla. Kendi elindekini görür.")]},
 {"when":{"quest":"perdeler_acilsin","state":"none"},"lines":[
   L("toprak","mutlu","Hoş geldin evlat! Ben Solucan Dede Toprak."),
   L("toprak","dertli","Burası Sera Kasabası. Herkes perdesini kapattı."),
   L("toprak","dertli","Komşusunun bitkisine gizlice bakıyor: 'Onunki daha güzel!'"),
   L("toprak","kararlı","Yeşil Diken böyle büyüyor. Bana bir el... yani bir alkış lazım!")],
  "then":{"start_quest":"perdeler_acilsin"}},
 {"lines":[L("toprak","mutlu","Tohum, gübre, limonata... Toprağın sırları bende. Bak istersen.")],"then":{"open_shop":"toprak"}}]
D["boynuz"]=[{"lines":[L("boynuz","mutlu","Tak! Tak! Boynuzum çekiç gibidir, sorma."),
   L("boynuz","mutlu","Değnek, asa, kılıç... Pırıl'ın varsa bak bakalım.")],"then":{"open_shop":"boynuz"}}]
D["kozacik"]=[{"lines":[L("kozacik","mutlu","İpek mi istersin, yaprak mı? İkisini de diktim!"),
   L("kozacik","sakin","Çiçekli şapkalar, pelerinler... Hepsi el emeği.")],"then":{"open_shop":"kozacik"}}]
for nid,a,b,c in [("marul","Marullarım küçük kaldı. Turp Amca'nınkiler kocaman!","Aa! Dikenler çekildi. Marullarım ne güzelmiş meğer!","Alkışın için sağ ol. Turp'a da el sallayacağım."),
 ("turp","Turplarım solgun. Fasulye'ninkiler göğe uzanıyor!","Sen alkışlayınca baktım: turplarım pespembe!","Komşuya turp götüreceğim. Fazla fazla var."),
 ("fasulye","Fasulyelerim eğri büğrü. Marul Teyze'ninkiler düzgün!","Eğri ama en uzunu benimki! Hiç fark etmemiştim.","Eğri fasulye de tatlıdır. Buyur, tadına bak!")]:
    n={"marul":0,"turp":1,"fasulye":2}[nid]
    D[nid]=[{"when":{"flag":"s4_chapter0_d%d"%n},"lines":[L(nid,"mutlu",b),L(nid,"mutlu",c)]},
            {"lines":[L(nid,"dertli",a),L(O,"sakin","Seranın önünde bir alkış patlatayım, belki iyi gelir.")]}]
B={
 "s4k0_basla":[L(O,"şaşkın","Cam seralar... ama hepsinin perdesi kapalı."),
   L(O,"sakin","Kapının yanındaki dede bizi bekliyor gibi.")],
 "s4k0_sera":[L(O,"mutlu","Alkışlayınca dikenler çekildi! Perde de açıldı.")],
 "s4k0_dikenci":[L(O,"şaşkın","Sırtında diken var, komşunun havucunu kapmış!"),
   L(O,"kararlı","Önce sersemlet. Sonra alkışla: kendi havucunu görsün.")],
 "s4k0_tohum":[L(O,"mutlu","Tohum büyüdü, yaprak köprü oldu! Kanalın ötesine geçebiliriz.")],
 "s4k0_kilit":[L(O,"sakin","Çark dönmüyor. Önce Dede Toprak'ın işini bitirelim.")],
 "s4k0_ark":[L(O,"mutlu","Su akıyor! Dikenler kuruyor, kuzey yolu açıldı.")],
 "s4k0_korkuluk":[L("korkuluk","huysuz","Kışt! Kışt! Uçabiliyorsunuz diye hava atmayın!"),
   L(O,"şaşkın","Kuşları kovalıyor... Yoksa onlar gibi uçmak mı istiyor?")],
 "s4k0_sakin":[L("korkuluk","dertli","Ben hep burada dikiliyorum. Onlar gökte süzülüyor."),
   L(O,"mutlu","Ama bostanı sen bekliyorsun! Sen olmasan lahana kalmazdı."),
   L("korkuluk","şaşkın","Beni... alkışladın mı? Beni ilk kez biri alkışladı."),
   L("korkuluk","mutlu","Kuşlar omzuma kondu! Gıdıklanıyorum! Hih hih!")],
}
S={"toprak":{"title":"Dede Toprak'ın Tohum Kesesi","items":[{"id":"bal_surubu","price":15},{"id":"nane_limonata","price":15},{"id":"yildiz_tozu","price":20},{"id":"gubre_topu","price":30},{"id":"papatya_celengi","price":35}]},
 "boynuz":{"title":"Boynuz'un Örsü","items":[{"id":"isik_degnegi","price":60,"once":True},{"id":"yildiz_asasi","price":150,"once":True},{"id":"kivilcim_kilici","price":280,"once":True},{"id":"isik_sapani","price":80,"once":True},{"id":"isik_tohumu","price":15}]},
 "kozacik":{"title":"Kozacık'ın İpek Sandığı","items":[{"id":"cicek_taci","price":40,"once":True},{"id":"kasif_sapkasi","price":70,"once":True},{"id":"minik_migfer","price":110,"once":True},{"id":"yildiz_pelerini","price":160,"once":True}]}}
pack("s4_chapter0","Sera Kasabası","Sera Kasabası",[1,5],[Q1,Q2],D,B,S,theme="light")

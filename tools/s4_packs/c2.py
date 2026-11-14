import sys; sys.path.insert(0,'/home/user/piriltidiyari/tools')
from s4_pack import *
O="oyuncu"
speakers({"sarki_kurbaga":("Kurbağa Vırvır","spark-green"),"sarki_ordek":("Ördek Cıvıl","spark-yellow"),
 "sarki_tavsan":("Tavşan Tıntın","berry")})
Q1={"id":"cayirin_konseri","title":"Çayırın Konseri","giver":"nihan","objectives":[
 {"id":"ritim","text":"Sesi kısılan üç şarkıcının yanında düzenli ritim tut","type":"ritim","target":"sarkici","count":3},
 {"id":"alkis","text":"Şarkı söyleyen üç şarkıcıyı alkışla","type":"clap","target":"sarkici","count":3},
 {"id":"dikenci","text":"Dikencileri sersemlet, sonra alkışla","type":"breathe","target":"any","count":4},
 {"id":"tohum","text":"Derenin başına bir köprü tohumu ek","type":"grow","target":"kopru"}],
 "turn_in":"Bülbül Nihan'a dön","rewards":{"piril":40,"xp":60}}
Q2={"id":"circirin_ritmi","title":"Cırcır'ın Ritmi","giver":"nihan","objectives":[
 {"id":"ark","text":"Çayırın ark kapağını aç","type":"light","target":"ark"},
 {"id":"circir","text":"Küsen Cırcır'ı alkışla","type":"breathe","target":"circir"},
 {"id":"tohum","text":"Papatya Tohumu'nu al","type":"collect","target":"tohum"}],
 "turn_in":"Bülbül Nihan ile konuş","rewards":{"piril":60,"xp":90}}
D={}
D["nihan"]=[
 {"when":{"quest":"circirin_ritmi","state":"ready"},"lines":[
   L("nihan","mutlu","Ritim olmadan şarkım hep bir yere kaçıyormuş. Şimdi yerinde!"),
   L("nihan","sakin","Onun yeteneği benimkini azaltmadı. İkimiz birlikte daha güzeliz."),
   L("nihan","kararlı","Sıradaki tohum Yuva Ağacı'nda. Bahar Kapısı çiçek açtı!"),
   L(O,"mutlu","Papatya Tohumu cebimde. Şarkınız da kulağımda!")],
  "then":{"complete_quest":"circirin_ritmi","set_flag":"s4_bolum2_bitti","give_items":{"nane_limonata":2}}},
 {"when":{"quest":"circirin_ritmi","state":"active","objective_done":"circirin_ritmi/circir"},"lines":[
   L("nihan","mutlu","Papatya Tohumu sahnenin ortasında parlıyor. Al onu!")]},
 {"when":{"quest":"circirin_ritmi","state":"active","objective_done":"circirin_ritmi/ark"},"lines":[
   L("nihan","mutlu","Su akıyor! Büyük sahnenin dikenleri de çekildi."),
   L("nihan","dertli","Cırcır orada. Herkes beni dinliyor diye çok üzgün."),
   L("nihan","sakin","Vuruşları tam ritimle iner. Uyarıyı gör, bir sayıp kenara çekil."),
   L("nihan","sakin","Yorulup küsünce yanına git, alkışla.")]},
 {"when":{"quest":"circirin_ritmi","state":"active"},"lines":[
   L("nihan","kararlı","Ark kapağı yukarı çayırda, yokuşun ötesinde. Çarkı çevir!")]},
 {"when":{"quest":"cayirin_konseri","state":"ready"},"lines":[
   L("nihan","mutlu","Duydun mu? Çayır yine şarkı söylüyor!"),
   L("nihan","dertli","Ama arkımız tıkalı, papatyalar susuz. Bir de Cırcır var..."),
   L("nihan","dertli","Cırcırıyla herkesin şarkısını bastırıyor. Bence canı sıkkın."),
   L("nihan","kararlı","Önce kapağı aç. Sonra büyük sahnede onu bul.")],
  "then":{"complete_quest":"cayirin_konseri","start_quest":"circirin_ritmi"}},
 {"when":{"quest":"cayirin_konseri","state":"active"},"lines":[
   L("nihan","sakin","Şarkıcının yanında dur. Acele etme: tak... tak... tak... tak."),
   L("nihan","sakin","Dört düzenli vuruş! Sesi gelince de alkışla, dikenler çekilir.")]},
 {"when":{"quest":"cayirin_konseri","state":"none"},"lines":[
   L("nihan","mutlu","Hoş geldin! Ben Bülbül Nihan. Burası Şarkı Çayırı."),
   L("nihan","dertli","Eskiden her taşta bir şarkıcı vardı. Şimdi çıt yok."),
   L("nihan","dertli","Koca bir cırcır sesi hepsini bastırdı. Sesleri kısıldı."),
   L("nihan","kararlı","Onlara ritim lazım! Yanlarında düzenli vur, şarkı geri gelir."),
   L(O,"kararlı","Tak, tak, tak, tak. Tamam, ritim bende!")],
  "then":{"start_quest":"cayirin_konseri"}},
 {"lines":[L("nihan","mutlu","Şarkı söylerken boğaz kurur. Limonata, bal... Bak istersen.")],"then":{"open_shop":"nihan"}}]
for i,(nid,a,b,c,e) in enumerate([
 ("sarki_kurbaga","Vırak diyorum, kimse duymuyor. Cırcır sesi her yerde!","Vırak! Vırak! Sesim geri geldi! Ritmin çok iyi geldi.","Beni alkışladın! Dikenler de utandı, çekildi.","Akşama konser var. En öne sana yer ayırdım!"),
 ("sarki_ordek","Vak diyecektim... Sesim boğazımda kaldı.","Vak vak vaaak! Duydun mu? Şarkım geri geldi!","Alkış en sevdiğim ses! Dikenler bile yol verdi.","Kurbağa kalın söyler, ben ince. İkisi yan yana pek hoş!"),
 ("sarki_tavsan","Ayağımla tempo tutardım. Cırcır başlayınca şaşırdım.","Tıp tıp tıp! Tempom yerine geldi. Sağ ol!","Alkışın kulaklarımı dikti! Dikenler de çekildi.","Büyük sahne ileride. Cırcır orada tek başına çalıyor.")]):
    D[nid]=[{"when":{"flag":"s4_chapter2_d%d"%i},"lines":[L(nid,"mutlu",c),L(nid,"mutlu",e)]},
            {"when":{"flag":"s4c2_sarki%d"%i},"lines":[L(nid,"mutlu",b),L(O,"mutlu","Çok güzel söylüyorsun! Dur, seni bir alkışlayayım.")]},
            {"lines":[L(nid,"dertli",a),L(O,"sakin","Yanında düzenli vurayım. Belki ritim sesini geri getirir.")]}]
B={
 "s4k2_basla":[L(O,"şaşkın","Burası Şarkı Çayırı mı? Hiç şarkı duyulmuyor."),
   L(O,"sakin","Yalnız uzaktan bir ses geliyor: cır cır cır...")],
 "s4k2_dikenci":[L(O,"şaşkın","Kurbağa bağırıyor, sinek 'şşşt' diyor! Kimse kimseyi dinlemiyor."),
   L(O,"kararlı","Önce sersemlet. Sonra alkışla: kendi sesini duysun.")],
 "s4k2_sarki":[L(O,"mutlu","Dört düzenli vuruş, ve şarkı geri geldi!"),
   L(O,"kararlı","Şimdi bir alkış! Güzel şarkı alkışı hak eder.")],
 "s4k2_alkis":[L(O,"mutlu","Alkışlayınca sahnenin dikenleri çekildi. Yol açık!")],
 "s4k2_tohum_kopru":[L(O,"mutlu","Yaprak köprü dereyi geçti! Yukarı çayıra gidebiliriz.")],
 "s4k2_kilit":[L(O,"sakin","Çark dönmüyor. Önce Nihan'ın konserini toparlayalım.")],
 "s4k2_ark":[L(O,"mutlu","Su akıyor! Büyük sahnenin dikenleri kuruyor.")],
 "s4k2_circir":[L("circir","huysuz","Cır cır cır! En yüksek ses benim! Başka şarkı yok!"),
   L(O,"şaşkın","Kulağım çınladı! Ama dur... Ritmi hiç şaşmıyor."),
   L(O,"kararlı","Vuruşları ritimle geliyor. Bir say, sonra kenara çekil!")],
 "s4k2_sakin":[L("circir","dertli","Nihan söyleyince herkes susup dinliyor. Benimki sadece cır cır."),
   L(O,"sakin","Ben seni alkışladım! Çünkü ritmin hiç şaşmadı."),
   L("circir","şaşkın","Ritmim mi? Onu fark eden olmamıştı."),
   L(O,"mutlu","Nihan da geliyor. Birlikte bir deneyin: o söylesin, sen tut!")],
 "s4k2_duet_once":[L("nihan","mutlu","Cırcır! Şarkım hep hızlanıp kaçıyor. Ritmi sen tutar mısın?"),
   L("circir","şaşkın","Ben mi? Seninle mi? Şey... Olur. Bir, iki, üç, dört!")],
 "s4k2_duet":[L("nihan","mutlu","Çayırın en güzel şarkısı bu oldu!"),
   L("circir","mutlu","Sen söyleyince benim ritmim azalmadı. Daha güzel duyuldu!"),
   L(O,"mutlu","Başkasının yeteneği seninkini azaltmaz. İkisi birlikte daha güzel!"),
   L("circir","mutlu","Sahnenin ortasında bir papatya açtı. Tohumu senin olsun!")],
 "s4k2_tohum":[L(O,"mutlu","Papatya Tohumu! İçinden hâlâ şarkı sesi geliyor."),
   L(O,"sakin","Nihan da geldi. Onunla konuşalım.")],
}
S={"nihan":{"title":"Nihan'ın Nota Sepeti","items":[{"id":"nane_limonata","price":15},{"id":"bal_surubu","price":15},{"id":"yildiz_tozu","price":20},{"id":"gubre_topu","price":30},{"id":"papatya_celengi","price":35}]}}
pack("s4_chapter2","Şarkı Çayırı","Şarkı Çayırı",[10,15],[Q1,Q2],D,B,S,theme="light")

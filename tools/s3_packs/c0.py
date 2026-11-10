import sys; sys.path.insert(0,'/home/user/piriltidiyari/tools')
from s3_pack import *
O="oyuncu"
speakers({"mors_dede":("Mors Dede Bıyık","sky"),"kerpeten":("Demirci Kerpeten","hp"),"dantel":("Terzi Dantel","berry"),
 "olta":("Balıkçı Olta","honey"),"koylu":("Köylü","sky"),"balikcil":("Balıkçıl Yavruları","sky"),"carsaf":("Hortlak Çarşaf","sky"),
 "paytak":("Kaşif Paytak","sky"),"murekkep":("Ahtapot Mürekkep","spark-purple"),"pamuk3":("Pamuk","sky"),"bikbik":("Bikbik","honey"),
 "tombik":("Tombik","sky")})
Q1={"id":"gece_bekcileri","title":"Gece Bekçileri","giver":"mors_dede","objectives":[
 {"id":"mesale","text":"Köyün üç meşalesini yak","type":"light","target":"mesale","count":3},
 {"id":"el","text":"Korkan iki köylüyü el ele ateşe getir","type":"el","target":"koylu","count":2},
 {"id":"titrek","text":"Titrekleri ritimle durdur, sakinleştir","type":"titrek","target":"any","count":4}],
 "turn_in":"Deniz Feneri'nde Mors Dede'ye dön","rewards":{"piril":30,"xp":40}}
Q2={"id":"hortlak_carsaf","title":"Hortlak Çarşaf","giver":"mors_dede","objectives":[
 {"id":"carsaf","text":"Çamaşır ipindeki hortlağa el uzat","type":"breathe","target":"carsaf"},
 {"id":"fisek","text":"Koyun İşaret Fişeği'ni yak","type":"light","target":"fisek"}],
 "turn_in":"Mors Dede'ye dön","rewards":{"piril":40,"xp":60}}
D={}
D["mors_dede"]=[
 {"when":{"quest":"hortlak_carsaf","state":"ready"},"lines":[
   L("mors_dede","mutlu","Ho ho! Fişek yandı, koy aydınlandı. Bıyıklarım titredi!"),
   L("mors_dede","dertli","Ama Fener'in beş incisi denize düştü. Beş adaya dağıldı."),
   L("mors_dede","kararlı","İlk inci Mürekkep Adası'nda. Kabuk Kayık seni bekliyor."),
   L(O,"kararlı","Beş inciyi de bulacağız. Hırıl'ı ve Tırıl'ı da!")],
  "then":{"complete_quest":"hortlak_carsaf","set_flag":"s3_bolum0_bitti","give_items":{"cesaret_kurabiyesi":2}}},
 {"when":{"quest":"hortlak_carsaf","state":"active","objective_done":"hortlak_carsaf/carsaf"},"lines":[
   L("mors_dede","mutlu","Hortlak iki yavruymuş demek! Ho ho ho!"),
   L("mors_dede","kararlı","Şimdi fişeği yak. Fenerin dibinde duruyor.")]},
 {"when":{"quest":"hortlak_carsaf","state":"active"},"lines":[
   L("mors_dede","dertli","Çamaşır ipinde bir hortlak uçuşuyor. Herkes ondan korkuyor."),
   L("mors_dede","sakin","Doğuda, avluda. Yorulunca yanına git, el uzat.")]},
 {"when":{"quest":"gece_bekcileri","state":"ready"},"lines":[
   L("mors_dede","mutlu","Meşaleler yandı, köylüler ateşin başında. Aferin!"),
   L("mors_dede","dertli","Ama kimse hâlâ kapısını açmıyor. Bir hortlak varmış!"),
   L("mors_dede","kararlı","Çamaşır ipine bak. O gitmeden fişeği yakamam.")],
  "then":{"complete_quest":"gece_bekcileri","start_quest":"hortlak_carsaf"}},
 {"when":{"quest":"gece_bekcileri","state":"active"},"lines":[
   L("mors_dede","sakin","Önce meşaleler. Sonra korkan köylüleri ateşe getir."),
   L("mors_dede","sakin","Elini uzat, tutarlar. El ele kimse donakalmaz.")]},
 {"when":{"quest":"gece_bekcileri","state":"none"},"lines":[
   L("mors_dede","mutlu","Ho! Gökkuşağı Köyü'nün bekçileri! Ben Mors Dede Bıyık."),
   L("mors_dede","dertli","Mavi Titreme geldiğinden beri gece kimse dışarı çıkmıyor."),
   L("mors_dede","dertli","Feneri tek başıma yakamıyorum. İncileri yok artık."),
   L("mors_dede","kararlı","Önce köye ışık lazım. Gece bekçisi olur musun?")],
  "then":{"start_quest":"gece_bekcileri"}},
 {"lines":[L("mors_dede","mutlu","Annemin tarifi: Cesaret Kurabiyesi. Bir bak istersen.")],"then":{"open_shop":"mors"}}]
D["kerpeten"]=[{"lines":[L("kerpeten","mutlu","Tak tak! Kıskacım çekiç, örsüm hazır."),
   L("kerpeten","mutlu","Değnek, asa, kılıç... Pırıl'ın varsa bak bakalım.")],"then":{"open_shop":"kerpeten"}}]
D["dantel"]=[{"lines":[L("dantel","mutlu","Hoş geldin canım! Deniz için şık bir şey diktim."),
   L("dantel","sakin","Şapkalar, pelerinler... Hepsi dantelli.")],"then":{"open_shop":"dantel"}}]
D["olta"]=[
 {"when":{"flag":"s3_fisek0"},"lines":[L("olta","mutlu","Miyav! Fişek yandı, deniz açıldı. Kayık hazır!"),
   L("olta","sakin","Yol için kavanoz ve kakao al. Denizde gece uzun olur.")],"then":{"open_shop":"olta"}},
 {"lines":[L("olta","dertli","Miyav... Sis kalkmadan kayık iskeleden çıkmaz."),
   L("olta","sakin","Ama yolluk hazır. Bak istersen.")],"then":{"open_shop":"olta"}}]
D["tospik_nine"]=[
 {"when":{"flag":"s3_fisek0"},"lines":[L("tospik_nine","mutlu","Fişek ne güzel yandı! Kakao da hazır, yavrum.")],"then":{"give_items":{}}},
 {"lines":[L("tospik_nine","sakin","Ateşin başındayım. Üşürsen gel, ısın."),
   L("tospik_nine","sakin","Korkan birini gördün mü? Elini uzat, yeter.")]}]
D["tosbi"]=[{"lines":[L("tosbi","utangaç","Ben ateşi beklerim. Sen çağırırsan gelirim!"),
   L("tosbi","kararlı","Korksam bile.")]}]
B={
 "s3k0_basla":[L(O,"şaşkın","Mercan Koyu... Bütün kapılar kilitli."),
   L("tosbi","dertli","Deniz Feneri sönük. Dedem orada biri yaşar derdi.")],
 "s3k0_kilit":[L(O,"dertli","Fişek ıslak ve soğuk. Köy korkarken yanmaz bu.")],
 "s3k0_carsaf":[L("carsaf","şaşkın","Huuu! Huuuu! Buradan gidin, huuu!"),
   L(O,"kararlı","Bir hortlak mı? Bakalım yorulunca ne olacak!")],
 "s3k0_carsaf_yorgun":[L("carsaf","üzgün","Hu... hu... Yoruldum. Vurmayın artık...")],
 "s3k0_carsaf_son":[L("balikcil","mutlu","Hi hi hi! Biziz! Çarşafın altında saklanıyorduk."),
   L("balikcil","utangaç","Karanlıktan korkunca hortlak olduk. Kimse yaklaşmasın diye."),
   L(O,"sakin","Korkunca saklanmak olur. Ama gelin, ateş sıcak.")],
 "s3k0_fisek":[L(O,"mutlu","İşaret Fişeği yandı! Sis denize doğru çekiliyor."),
   L("mors_dede","mutlu","Ho ho! Yıllardır bu koyu böyle aydınlık görmedim!")],
}
S={"mors":{"title":"Mors Dede'nin Fener Dolabı","items":[{"id":"bal_surubu","price":15},{"id":"sicak_kakao","price":15},{"id":"yildiz_tozu","price":20},{"id":"cesaret_kurabiyesi","price":35}]},
 "kerpeten":{"title":"Kerpeten'in Örsü","items":[{"id":"isik_degnegi","price":60,"once":True},{"id":"yildiz_asasi","price":150,"once":True},{"id":"kivilcim_kilici","price":280,"once":True},{"id":"isik_sapani","price":80,"once":True},{"id":"isik_tohumu","price":15}]},
 "dantel":{"title":"Dantel'in Dikiş Sandığı","items":[{"id":"cicek_taci","price":40,"once":True},{"id":"kasif_sapkasi","price":70,"once":True},{"id":"minik_migfer","price":110,"once":True},{"id":"yildiz_pelerini","price":160,"once":True}]},
 "olta":{"title":"Olta'nın Yolluk Sepeti","items":[{"id":"atesbocegi_kavanozu","price":30},{"id":"sicak_kakao","price":15},{"id":"bal_surubu","price":15}]}}
pack("s3_chapter0","Mercan Koyu","Mercan Koyu",[1,5],[Q1,Q2],D,B,S)

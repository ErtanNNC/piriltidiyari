import sys; sys.path.insert(0,'/home/user/piriltidiyari/tools')
from s3_pack import *
O="oyuncu"
speakers({"minik_kol":("Minik Kol","spark-purple"),"kardes":("Kardeş Kol","sky")})
Q1={"id":"isik_yolu","title":"Saklananlara Işık","giver":"minik_kol","objectives":[
 {"id":"mantar","text":"Altı ışık mantarını yak","type":"light","target":"mesale","count":6},
 {"id":"titrek","text":"Titrekleri ritimle durdur, sakinleştir","type":"titrek","target":"any","count":5},
 {"id":"kardes","text":"Minik Kol'un kardeşini el ele ateşe getir","type":"el","target":"kardes"}],
 "turn_in":"İskeledeki ateşin yanında Minik Kol'a dön","rewards":{"piril":50,"xp":80}}
Q2={"id":"murekkebin_isigi","title":"Mürekkep'e Bir Işık","giver":"minik_kol","objectives":[
 {"id":"fisek","text":"Adanın İşaret Fişeği'ni yak","type":"light","target":"fisek"},
 {"id":"murekkep","text":"Mürekkep yorulunca ona el uzat","type":"breathe","target":"murekkep"},
 {"id":"inci","text":"Lacivert İnci'yi al","type":"collect","target":"inci"}],
 "turn_in":"Minik Kol'a dön","rewards":{"piril":60,"xp":120}}
D={}
D["minik_kol"]=[
 {"when":{"quest":"murekkebin_isigi","state":"ready"},"lines":[
   L("minik_kol","mutlu","Mürekkep amca artık saklanmıyor! Ada ilk kez aydınlık."),
   L("minik_kol","sakin","Küçük bir ışık ve bir arkadaş... Karanlığa bu yetermiş."),
   L("minik_kol","kararlı","Sıradaki inci Rüzgârlı Kayalıklar'da. Kabuk Kayık hazır!"),
   L(O,"mutlu","Görüşürüz Minik Kol! Işıklarınız hiç sönmesin.")],
  "then":{"complete_quest":"murekkebin_isigi","set_flag":"s3_bolum1_bitti","give_items":{"atesbocegi_kavanozu":1}}},
 {"when":{"quest":"murekkebin_isigi","state":"active","objective_done":"murekkebin_isigi/murekkep"},"lines":[
   L("minik_kol","mutlu","Mürekkep amca gülümsüyor! Kavanozu çok sevdi."),
   L("minik_kol","sakin","İnci orada parlıyor. Hadi, al onu!")]},
 {"when":{"quest":"murekkebin_isigi","state":"active","flag":"s3_fisek1"},"lines":[
   L("minik_kol","sakin","Sis perdesi açıldı. Mürekkep amca kuzeyde, tek başına."),
   L("minik_kol","dertli","Mürekkep püskürtür ama kötü değil. Sadece çok korkuyor."),
   L("minik_kol","kararlı","Yorulunca yanına git, elini uzat.")]},
 {"when":{"quest":"murekkebin_isigi","state":"active"},"lines":[
   L("minik_kol","sakin","İşaret Fişeği kuzeydeki açıklıkta, ışık yolunun sonunda."),
   L("minik_kol","kararlı","Onu yak, sis çekilsin. Sonra Mürekkep amcaya gideriz.")]},
 {"when":{"quest":"isik_yolu","state":"ready"},"lines":[
   L("minik_kol","mutlu","Mantarlar yandı! Kardeşim de ateşin başında. Sağ ol!"),
   L("minik_kol","dertli","Ama Mürekkep amca hâlâ saklanıyor. Karanlıktan çok korkuyor."),
   L("minik_kol","dertli","Ürkünce mürekkep püskürtüyor. Ada daha da kararıyor."),
   L("minik_kol","kararlı","Kuzeydeki İşaret Fişeği'ni yak. Sonra ona bir ışık götür.")],
  "then":{"complete_quest":"isik_yolu","start_quest":"murekkebin_isigi"}},
 {"when":{"quest":"isik_yolu","state":"active"},"lines":[
   L("minik_kol","sakin","Işık mantarlarını yak. Mürekkep ışıktan çekilir."),
   L("minik_kol","sakin","Kardeşim batıdaki karanlık köşede. Elini uzat, tutar."),
   L("minik_kol","sakin","Titreyenleri görürsen ritim tut. Dinlerler.")]},
 {"when":{"quest":"isik_yolu","state":"none"},"lines":[
   L("minik_kol","şaşkın","Şşşt! Ben Minik Kol. Burada herkes saklanıyor."),
   L("minik_kol","dertli","Bekçimiz Mürekkep amca her yeri mürekkeple kapladı."),
   L("minik_kol","dertli","Mürekkebe basınca insan buz gibi titriyor. Brr!"),
   L("minik_kol","kararlı","Işık mantarlarını yakar mısın? Işıkta mürekkep çekilir."),
   L(O,"kararlı","Yakarız! Kimse karanlıkta tek başına kalmasın.")],
  "then":{"start_quest":"isik_yolu"}},
 {"lines":[L("minik_kol","mutlu","Artık saklambacı sadece oyun olsun diye oynuyoruz!"),
   L("minik_kol","sakin","Mürekkep amcanın tılsımlarına baktın mı?")]}]
D["murekkep"]=[
 {"when":{"flag":"s3_bolum1_bitti"},"lines":[
   L("murekkep","mutlu","Kavanozum hep yanımda. Mürekkebimle artık tılsım yapıyorum!"),
   L("murekkep","sakin","Karanlık için küçük bir ışık yeter. Bak istersen.")],"then":{"open_shop":"murekkep"}},
 {"lines":[L("murekkep","utangaç","Işığım yanımda... Teşekkür ederim.")]}]
B={
 "s3k1_basla":[L(O,"şaşkın","Mürekkep Adası... Burası gece gibi kapkara."),
   L(O,"sakin","Mantarlar sönük. Ateşin yanında minik biri el sallıyor!")],
 "s3k1_bas":[L(O,"şaşkın","Brr! Mürekkebin içi buz gibi. Titreme barım doluyor!"),
   L(O,"kararlı","Yanındaki ışık mantarını yakarsam mürekkep çekilir.")],
 "s3k1_mantar":[L(O,"mutlu","Işık mantarı yandı! Mürekkep ışıktan kaçıyor."),
   L(O,"kararlı","Işıklı yoldan yürürsem titremem. Hadi sıradakine!")],
 "s3k1_kardes":[L("kardes","utangaç","Elin sıcacık... Karanlık artık o kadar büyük değil."),
   L(O,"sakin","El ele gidelim. Ateş çok uzak değil.")],
 "s3k1_kardes_geldi":[L("kardes","mutlu","Ateş! Minik Kol! Geldim! El ele hiç titremedim.")],
 "s3k1_kilit":[L(O,"dertli","Fişek mürekkep içinde. Önce adaya biraz ışık lazım."),
   L(O,"sakin","Minik Kol'un istediklerini bitireyim.")],
 "s3k1_fisek":[L(O,"mutlu","İşaret Fişeği yandı! Sis çekiliyor, perde açıldı."),
   L("minik_kol","sakin","Mürekkep amca kuzeyde. Lütfen kızma ona, sadece korkuyor.")],
 "s3k1_murekkep":[L("murekkep","şaşkın","Yaklaşma! Karanlıkta ne var bilmiyorum! Fışşşt!"),
   L(O,"kararlı","Saklanmana gerek yok. Ama önce biraz yorul bakalım!")],
 "s3k1_yorgun":[L("murekkep","üzgün","Mürekkebim bitti... Artık saklanamam. Çok karanlık...")],
 "s3k1_kavanoz":[L(O,"sakin","Al, bu Ateşböceği Kavanozu senin olsun."),
   L(O,"sakin","Karanlıkta yanında bir ışık olsun yeter."),
   L("murekkep","şaşkın","Işık... Küçücük ama her yeri görebiliyorum!"),
   L("murekkep","utangaç","Saklandıkça adayı daha da karartmışım. Özür dilerim.")],
 "s3k1_inci_dustu":[L("murekkep","mutlu","Bunu mürekkebin içinde saklıyordum. Lacivert İnci senin!")],
 "s3k1_inci":[L(O,"mutlu","Lacivert İnci! Fener'in ilk incisi bizde."),
   L("minik_kol","mutlu","Başardın! Hadi, yanıma gel!")],
}
S={"murekkep":{"title":"Mürekkep'in Tılsım Hokkası","items":[{"id":"murekkep_tilsimi","price":120,"once":True},{"id":"atesbocegi_kavanozu","price":30}]}}
pack("s3_chapter1","Mürekkep Adası","Mürekkep Adası",[5,10],[Q1,Q2],D,B,S)

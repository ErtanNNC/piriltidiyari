import sys; sys.path.insert(0,'/home/user/piriltidiyari/tools')
from s3_pack import *
O="oyuncu"
N="tospik_nine"
speakers({"denizyildizi":("Kayıp Denizyıldızı","honey")})
Q1={"id":"kayan_kumlar","title":"Kayan Kumlar","giver":N,"objectives":[
 {"id":"mesale","text":"Kumların arasında altı meşale yak","type":"light","target":"mesale","count":6},
 {"id":"titrek","text":"Titrekleri ritimle durdur, sakinleştir","type":"titrek","target":"any","count":4},
 {"id":"el","text":"İki kayıp denizyıldızını el ele havuza getir","type":"el","target":"yildiz","count":2}],
 "turn_in":"İskelenin yanında Tospik Nine'ye dön","rewards":{"piril":70,"xp":110}}
Q2={"id":"dar_kabuk","title":"Dar Gelen Kabuk","giver":N,"objectives":[
 {"id":"fisek","text":"Adanın İşaret Fişeği'ni yak","type":"light","target":"fisek"},
 {"id":"bikbik","text":"Keşiş Yengeç Bikbik'e el uzat","type":"breathe","target":"bikbik"},
 {"id":"inci","text":"Kum İncisi'ni al","type":"collect","target":"inci"}],
 "turn_in":"Tospik Nine'ye dön","rewards":{"piril":90,"xp":150}}
D={}
D[N]=[
 {"when":{"quest":"dar_kabuk","state":"ready"},"lines":[
   L(N,"mutlu","Kum İncisi! Bikbik de yeni evine sığdı. Aferin yavrum!"),
   L(N,"sakin","Yeni yer önce korkutur. Sonra bakarsın, ev olmuş."),
   L(N,"kararlı","Sıradaki inci Fırtına Kayası'nda. Kayık iskelede."),
   L(O,"kararlı","Üç inci oldu. Tırıl, az kaldı, geliyoruz!")],
  "then":{"complete_quest":"dar_kabuk","set_flag":"s3_bolum3_bitti","give_items":{"sicak_kakao":2}}},
 {"when":{"quest":"dar_kabuk","state":"active","objective_done":"dar_kabuk/bikbik"},"lines":[
   L(N,"mutlu","Bikbik sakinleşti! İnci arenanın ortasında parlıyor."),
   L(N,"sakin","Al onu, sonra yanıma gel.")]},
 {"when":{"quest":"dar_kabuk","state":"active","objective_done":"dar_kabuk/fisek"},"lines":[
   L(N,"sakin","Perde açıldı. Bikbik kuzeyde, eski kabuğunda sıkışmış."),
   L(N,"sakin","Kızgın değil, yavrum. Korkuyor. Yorulunca elini uzat.")],"then":{"open_shop":"kum_sepeti"}},
 {"when":{"quest":"dar_kabuk","state":"active"},"lines":[
   L(N,"kararlı","Fişek kumların kuzeyinde. Oklara bak, yolu onlar bilir."),
   L(N,"sakin","Yol için kakao ister misin?")],"then":{"open_shop":"kum_sepeti"}},
 {"when":{"quest":"kayan_kumlar","state":"ready"},"lines":[
   L(N,"mutlu","Meşaleler yandı, yıldızlar havuzunda. Ellerine sağlık!"),
   L(N,"dertli","Ama kuzeyden tak tak sesler geliyor. Keşiş Yengeç Bikbik."),
   L(N,"dertli","Eski kabuğuna sığmıyor, bırakmaya da korkuyor. Sıkışmış."),
   L(N,"kararlı","Önce fişeği yak ki sis açılsın. Sonra ona el uzat.")],
  "then":{"complete_quest":"kayan_kumlar","start_quest":"dar_kabuk"}},
 {"when":{"quest":"kayan_kumlar","state":"active"},"lines":[
   L(N,"sakin","Kum tepesi yürüyünce bekle. Bir geçit kapanır, biri açılır."),
   L(N,"sakin","Yıldızların elini tut, havuza getir. Yolluk da bende.")],"then":{"open_shop":"kum_sepeti"}},
 {"when":{"quest":"kayan_kumlar","state":"none"},"lines":[
   L(N,"şaşkın","Aman yavrum! Bu adada kum tepeleri her gece yer değiştirir."),
   L(N,"dertli","Dün çizdiğim harita bugün tutmuyor. Çıtır görse saçını yolar!"),
   L(N,"dertli","İki küçük denizyıldızı kumların arasında yolunu kaybetmiş."),
   L(N,"kararlı","Meşaleleri yak, Titrekleri sakinleştir, yıldızları getir.")],
  "then":{"start_quest":"kayan_kumlar"}},
 {"lines":[L(N,"mutlu","Kumlar yine yürüyor ama artık yol aydınlık, yavrum."),
   L(N,"sakin","Sepetimde kakao var. Bak istersen.")],"then":{"open_shop":"kum_sepeti"}}]
D["tosbi"]=[
 {"when":{"flag":"inci_kum"},"lines":[L("tosbi","mutlu","Bikbik yeni kabuğunda dans ediyor! Gördün mü?"),
   L("tosbi","kararlı","Ben de bir gün daha büyük bir kabuk seçeceğim.")]},
 {"lines":[L("tosbi","utangaç","Kumlar yürüyor... Benim kabuğum en azından yerinde duruyor."),
   L("tosbi","kararlı","Ninemin yanındayım. Çağırırsan gelirim, korksam bile!")]}]
B={
 "s3k3_basla":[L(O,"şaşkın","Değişen Kumlar... Şu kum tepesi az önce orada mıydı?"),
   L(N,"sakin","Burada kumlar yürür, yavrum. Gel, anlatayım.")],
 "s3k3_kum":[L(O,"şaşkın","Kum tepesi kaydı! Bir geçit kapandı, öbürü açıldı."),
   L(O,"kararlı","Direkteki ok açık geçidi gösteriyor. Oka bakarım!")],
 "s3k3_kilit":[L(O,"dertli","Fişeğin içi kum dolmuş. Önce Tospik Nine'nin işini bitireyim.")],
 "s3k3_havuz":[L("denizyildizi","mutlu","Su! Burası evimiz gibi kokuyor!"),
   L("denizyildizi","utangaç","Kumlar yürüyünce yolu şaşırdık. Elimizi tuttun, teşekkürler!")],
 "s3k3_fisek":[L(O,"mutlu","İşaret Fişeği yandı! Sis kumların üstünden çekiliyor."),
   L(O,"kararlı","Kuzeydeki perde açıldı. Bikbik orada olmalı.")],
 "s3k3_bikbik":[L("bikbik","şaşkın","Tak tak! Yaklaşmayın! Kabuğumu almaya mı geldiniz?"),
   L(O,"sakin","Almaya gelmedik. Ama bu kabuk sana dar gelmiş, sıkışmışsın."),
   L("bikbik","dertli","Dar değil! Sadece... biraz sıkı. Çıkmam, çıkamam!")],
 "s3k3_bikbik_yorgun":[L("bikbik","üzgün","Kıskaçlarım yoruldu... Bu kabuktan başka evim yok ki.")],
 "s3k3_bikbik_son":[L("bikbik","şaşkın","Kıskacımı tuttun... Kimse tutmamıştı."),
   L("bikbik","dertli","Bu kabukta büyüdüm. Dışarısı çok büyük, çok yeni."),
   L("tosbi","kararlı","Kabuk bir ev değil, bir başlangıç."),
   L("tosbi","utangaç","Ben de kabuğumdan çıkmaya korkardım. Ama bak, buradayım."),
   L(O,"mutlu","Yenisini birlikte seçelim. Biz yanındayız, Bikbik.")],
 "s3k3_bikbik_son_tosbi":[L("bikbik","şaşkın","Kıskacımı tuttun... Kimse tutmamıştı."),
   L("bikbik","dertli","Bu kabukta büyüdüm. Dışarısı çok büyük, çok yeni."),
   L(O,"kararlı","Kabuk bir ev değil, bir başlangıç."),
   L(O,"utangaç","Ben de kabuğumdan çıkmaya korkardım. Ama bak, buradayım."),
   L(O,"mutlu","Yenisini birlikte seçelim. Ben yanındayım, Bikbik.")],
 "s3k3_kabuk_pembe":[L("bikbik","mutlu","Pembe Sarmal! İçi deniz gibi uğulduyor. Sığdım, sığdım!"),
   L("bikbik","utangaç","Biraz yabancı kokuyor. Ama büyümeye yerim var artık."),
   L("bikbik","mutlu","Eski kabuğumda bir şey saklıyordum. Kum İncisi senin olsun.")],
 "s3k3_kabuk_altin":[L("bikbik","mutlu","Altın Külah! Kıskaçlarım rahat rahat dönüyor. Tak tak!"),
   L("bikbik","utangaç","Biraz yabancı kokuyor. Ama büyümeye yerim var artık."),
   L("bikbik","mutlu","Eski kabuğumda bir şey saklıyordum. Kum İncisi senin olsun.")],
 "s3k3_kabuk_mavi":[L("bikbik","mutlu","Mavi Kubbe! Tavanı gökyüzü kadar yüksek. Yankı yapıyor!"),
   L("bikbik","utangaç","Biraz yabancı kokuyor. Ama büyümeye yerim var artık."),
   L("bikbik","mutlu","Eski kabuğumda bir şey saklıyordum. Kum İncisi senin olsun.")],
 "s3k3_inci":[L(O,"mutlu","Kum İncisi! Avucumda güneşli kum gibi sıcacık."),
   L(O,"şaşkın","Bir dakika... İncinin içinde bir şey parlıyor.")],
 "s3k3_ani":[L("tiril","sakin","Mercan bahçesi... Annem, babam, kardeşlerim. Hep beraberdik."),
   L("tiril","mutlu","Mercanların arasında saklambaç oynardık. Hiç üşümezdim."),
   L(O,"şaşkın","Bu Tırıl'ın sesi! İnci onun ilk anısını saklamış."),
   L(O,"kararlı","Bir ailesi var. Onu bulup evine götüreceğiz.")],
}
S={"kum_sepeti":{"title":"Tospik Nine'nin Yolluk Sepeti","items":[{"id":"sicak_kakao","price":15},{"id":"bal_surubu","price":15},
 {"id":"atesbocegi_kavanozu","price":30},{"id":"cesaret_kurabiyesi","price":35}]}}
pack("s3_chapter3","Değişen Kumlar","Değişen Kumlar",[15,20],[Q1,Q2],D,B,S)

import sys; sys.path.insert(0,'/home/user/piriltidiyari/tools')
from s4_pack import *
O="oyuncu"
speakers({"vizik":("Çiçekçi Vızık","spark-yellow"),"sikir":("Saksağan Şıkır","sky"),
 "ponpon":("Zilci Ponpon","honey"),"tombis":("Bilyeci Tombiş","sky"),"virak":("Fırıldakçı Vırak","berry")})
Q1={"id":"pazar_parlasin","title":"Herkesin Kendi Oyuncağı","giver":"vizik","objectives":[
 {"id":"oyuncak","text":"Kargalardaki üç oyuncağı sahibine götür","type":"collect","target":"s4c1_teslim","count":3},
 {"id":"alkis","text":"Her sahibin KENDİ oyuncağını alkışla","type":"clap","target":"tezgah","count":3},
 {"id":"tohum","text":"Taraçanın dibine merdiven tohumu ek","type":"grow","target":"pazar_merdiveni"}],
 "turn_in":"Çiçekçi Vızık'a dön","rewards":{"piril":45,"xp":70}}
Q2={"id":"sikirin_yuvasi","title":"Şıkır'ın Yuvası","giver":"vizik","objectives":[
 {"id":"ark","text":"Pazarın ark kapağını aç","type":"light","target":"ark"},
 {"id":"sikir","text":"Yuvadaki Saksağan Şıkır'ı alkışla","type":"breathe","target":"sikir"},
 {"id":"tohum","text":"Lale Tohumu'nu al","type":"collect","target":"tohum"}],
 "turn_in":"Çiçekçi Vızık ile konuş","rewards":{"piril":60,"xp":90}}
D={}
D["vizik"]=[
 {"when":{"quest":"sikirin_yuvasi","state":"ready"},"lines":[
   L("vizik","mutlu","Vızz! Lale Tohumu! Pazar yine cıvıl cıvıl."),
   L("vizik","sakin","Çok şeyi olan değil, elindekini seven güler. Arılar bilir."),
   L("vizik","kararlı","Sıradaki tohum Şarkı Çayırı'nda. Bahar Kapısı çiçek açtı!"),
   L(O,"kararlı","Bir tohum tamam. Dört tane kaldı!")],
  "then":{"complete_quest":"sikirin_yuvasi","set_flag":"s4_bolum1_bitti","give_items":{"bal_surubu":2}}},
 {"when":{"quest":"sikirin_yuvasi","state":"active","objective_done":"sikirin_yuvasi/sikir"},"lines":[
   L("vizik","mutlu","Şıkır gülüyor! Tohum yuvanın önünde parlıyor, al hadi.")]},
 {"when":{"quest":"sikirin_yuvasi","state":"active","objective_done":"sikirin_yuvasi/ark"},"lines":[
   L("vizik","mutlu","Su şırıl şırıl! Taraçadaki dikenler de çekildi."),
   L("vizik","dertli","Şıkır yuvasında. Her parlak şeyi oraya taşıdı."),
   L("vizik","sakin","Ama hiçbiriyle oynamıyor. Yorulunca yanına git, alkışla.")]},
 {"when":{"quest":"sikirin_yuvasi","state":"active"},"lines":[
   L("vizik","kararlı","Ark kapağı taraçada, merdivenin üstünde. Çarkı çevir!")]},
 {"when":{"quest":"pazar_parlasin","state":"ready"},"lines":[
   L("vizik","mutlu","Vızz! Herkes kendi oyuncağıyla oynuyor. Ne güzel ses!"),
   L("vizik","dertli","Ama arkımız tıkalı. Çiçeklerim susadı."),
   L("vizik","kararlı","Kapağı aç. Sonra yuvadaki Saksağan Şıkır'a bak.")],
  "then":{"complete_quest":"pazar_parlasin","start_quest":"sikirin_yuvasi"}},
 {"when":{"quest":"pazar_parlasin","state":"active"},"lines":[
   L("vizik","sakin","Kargayı sersemlet, alkışla. Oyuncağı bırakır."),
   L("vizik","sakin","Oyuncağı sahibine götür. Sonra tezgâhının önünde alkışla!")]},
 {"when":{"quest":"pazar_parlasin","state":"none"},"lines":[
   L("vizik","mutlu","Vızz! Hoş geldin. Ben Çiçekçi Arı Vızık."),
   L("vizik","dertli","Burası Parlak Pazar. Herkes komşusunun oyuncağına bakıyor."),
   L("vizik","dertli","Kendi oyuncağıyla oynayan yok! Kargalar da hepsini kaptı."),
   L("vizik","kararlı","Oyuncakları sahiplerine götürür müsün? Bir de alkış lazım!")],
  "then":{"start_quest":"pazar_parlasin"}},
 {"lines":[L("vizik","mutlu","Nadir tohum, taze bal! Vızır vızır taze. Bak istersen.")],"then":{"open_shop":"vizik"}}]
D["sikir"]=[
 {"when":{"flag":"s4_bolum1_bitti"},"lines":[
   L("sikir","mutlu","Şıkır şıkır! Boncuğum bende, gerisini takas ediyorum."),
   L("sikir","sakin","Fazla parlak şey yük olurmuş. Sen de bak, beğendiğini al.")],"then":{"open_shop":"sikir"}},
 {"lines":[L("sikir","mutlu","İlk boncuğum... Hâlâ en güzel şıkırdayan o!")]}]
# [id, thorn index, own toy flag, own toy (accusative), neighbour's toy flag, lines]
for nid,n,own,other,l in [
 ("ponpon",0,"zil","bilye",[
   "Zilimi bir karga kaptı! Gerçi hiç çalmazdım...",
   "Hep Tombiş'in bilyesine bakardım. Ne parlak!",
   "Bak ne buldum! Bu altın zil senin, değil mi?",
   "Zilim! Çın çın! Sesini unutmuşum, ne tatlıymış.",
   "Zilim geri geldi. Ama Tombiş'in bilyesi daha mı parlak acaba?",
   "Ben zilini çok beğendim. Dur, tezgâhının önünde alkışlayayım!",
   "Aa, Tombiş'in bilyesi! Bir kerecik tutsam...",
   "Bu Tombiş'in. Senin zilini de bulacağım, söz!",
   "Çın çın! Alkışlayınca fark ettim: zilim pazarın en neşeli sesi.",
   "Tombiş'e de çaldırırım. Zil paylaşınca eksilmiyor!"]),
 ("tombis",1,"bilye","firildak",[
   "Bilyemi bir karga kaptı! Zaten cebimde dururdu hep.",
   "Ben Vırak'ın fırıldağını isterdim. Fır fır dönüyor!",
   "Bak ne buldum! Bu cam bilye senin, değil mi?",
   "Bilyem! İçinde gökkuşağı varmış. Hiç bakmamışım!",
   "Bilyem geldi. Ama fırıldak dönüyor, benimki sadece duruyor...",
   "Bilyen ışıl ışıl! Dur, tezgâhının önünde alkışlayayım!",
   "Aa, Vırak'ın fırıldağı! Bir kere üflesem...",
   "Bu Vırak'ın. Senin bilyeni de bulacağım, söz!",
   "Alkışlayınca yuvarladım: bilyem herkesten uzağa gidiyor!",
   "Vırak'la bilye oynayacağız. O da fırıldağını getirecek."]),
 ("virak",2,"firildak","zil",[
   "Fırıldağımı bir karga kaptı! Hiç üflememiştim bile.",
   "Aklım hep Ponpon'un zilindeydi. Çın çın!",
   "Bak ne buldum! Bu gümüş fırıldak senin, değil mi?",
   "Fırıldağım! Üfledim, döndü! Vırak vırak!",
   "Fırıldağım geldi. Ama zil ses çıkarıyor, benimki çıkarmıyor...",
   "Fırıldağın rüzgârı yakalıyor! Dur, tezgâhında alkışlayayım!",
   "Aa, Ponpon'un zili! Bir kere sallasam...",
   "Bu Ponpon'un. Senin fırıldağını da bulacağım, söz!",
   "Alkışlayınca üfledim: fırıldağım rüzgârla dans ediyor!",
   "Ponpon zil çalsın, ben döndüreyim. Pazara şenlik gelsin!"])]:
    D[nid]=[
     {"when":{"flag":"s4_chapter1_d%d"%n},"lines":[L(nid,"mutlu",l[8]),L(nid,"mutlu",l[9])]},
     {"when":{"flag":"s4c1_verdi_"+own},"lines":[L(nid,"dertli",l[4]),L(O,"mutlu",l[5])]},
     {"when":{"quest":"pazar_parlasin","state":"active","flag":"s4c1_var_"+own},"lines":[L(O,"mutlu",l[2]),L(nid,"mutlu",l[3])],
      "then":{"advance":"pazar_parlasin/oyuncak","set_flag":"s4c1_verdi_"+own}},
     {"when":{"flag":"s4c1_var_"+other,"not_flag":"s4c1_verdi_"+other},"lines":[L(nid,"şaşkın",l[6]),L(O,"sakin",l[7])]},
     {"lines":[L(nid,"dertli",l[0]),L(nid,"dertli",l[1])]}]
B={
 "s4k1_basla":[L(O,"şaşkın","Bayraklar, tezgâhlar... ama oyuncak sesi yok."),
   L(O,"sakin","Kapının yanındaki arı bize el sallıyor.")],
 "s4k1_karga":[L(O,"şaşkın","Kargalar! Her birinin gagasında parlak bir oyuncak var."),
   L(O,"kararlı","Önce sersemlet, sonra alkışla. Oyuncağı bırakır.")],
 "s4k1_oyuncak":[L(O,"mutlu","Oyuncağı aldım! Kimin tezgâhından gitmişti acaba?")],
 "s4k1_bos":[L(O,"sakin","Tezgâh boş, alkışlayacak oyuncak yok. Önce onu geri getirelim.")],
 "s4k1_tezgah":[L(O,"mutlu","Kendi oyuncağını alkışlayınca dikenler çekildi!")],
 "s4k1_tohum":[L(O,"mutlu","Tohum büyüdü, yaprak yaprak merdiven oldu! Taraçaya çıkabiliriz.")],
 "s4k1_kilit":[L(O,"sakin","Çark dönmüyor. Önce Vızık'ın işini bitirelim.")],
 "s4k1_ark":[L(O,"mutlu","Su akıyor! Dikenler kuruyor, yuvanın yolu açıldı.")],
 "s4k1_sikir":[L("sikir","huysuz","Şıkır şıkır! Hepsi benim! Parlayan ne varsa benim!"),
   L(O,"şaşkın","Yuva tıka basa dolu... Ama hiçbiriyle oynamıyor.")],
 "s4k1_sakin":[L("sikir","dertli","Topladım, topladım... Yine de içim şıkırdamıyor."),
   L("sikir","şaşkın","Beni... alkışladın mı? Bir şey almadan mı?"),
   L(O,"sakin","Şıkır, sana bir şey soracağım.")],
 "s4k1_bilemez":[L("sikir","şaşkın","En sevdiğim mi? Şey... Bu mu? Yok, şu... Bilmiyorum!"),
   L("sikir","dertli","Hepsini aldım ama hiçbirine doya doya bakmadım."),
   L("sikir","şaşkın","Dur. Yuvanın en dibinde bir şey var...")],
 "s4k1_boncuk":[L("sikir","mutlu","İlk boncuğum! Minicik bir yavruyken bulmuştum."),
   L("sikir","mutlu","Çizik, eski... ama benim. En sevdiğim bu!"),
   L(O,"mutlu","Çok şey değil, sevdiğin tek şey yetiyormuş demek."),
   L("sikir","mutlu","Gerisini pazara geri götüreceğim. Bak, bir de tohum çıktı!")],
 "s4k1_tohum_al":[L(O,"mutlu","Lale Tohumu! İlk Bahar Tohumu bizde."),
   L(O,"sakin","Vızık da geliyor. Ona gösterelim.")],
}
S={"vizik":{"title":"Vızık'ın Çiçek Tezgâhı","items":[{"id":"bal_surubu","price":15},{"id":"gubre_topu","price":28},
   {"id":"nane_limonata","price":15},{"id":"papatya_celengi","price":35}]},
 "sikir":{"title":"Şıkır'ın Takas Tezgâhı","items":[{"id":"yildiz_tozu","price":18},{"id":"papatya_celengi","price":30},
   {"id":"gubre_topu","price":25},{"id":"nane_limonata","price":12}]}}
pack("s4_chapter1","Parlak Pazar","Parlak Pazar",[5,10],[Q1,Q2],D,B,S,theme="light")

import sys; sys.path.insert(0,'/home/user/piriltidiyari/tools')
from s4_pack import *
O="oyuncu"
Q1={"id":"golgenin_yolu","title":"Gölgenin Yolu","giver":"yonca","objectives":[
 {"id":"alkis","text":"İki diken kapısını alkışla aç","type":"clap","target":"golge","count":2},
 {"id":"dikenci","text":"Dikencileri sersemlet, sonra alkışla","type":"breathe","target":"any","count":4},
 {"id":"merdiven","text":"Sete çıkmak için merdiven tohumu ek","type":"grow","target":"merdiven"},
 {"id":"gece","text":"Setteki Gece Çiçeği tohumunu ek","type":"collect","target":"gece_tohumu"},
 {"id":"son_cit","text":"Son çitin önüne var","type":"reach","target":"son_cit"}],
 "turn_in":"Ark kapağının yanında seni bekleyenle konuş","rewards":{"piril":60,"xp":80}}
Q2={"id":"dirilin_saati","title":"Dırıl'ın Saati","giver":"yonca","objectives":[
 {"id":"ark","text":"Gölge Köşesi'nin ark kapağını aç","type":"light","target":"ark"},
 {"id":"faz1","text":"Dırıl yorulunca vur, küsünce alkışla","type":"clap","target":"diril"},
 {"id":"cicek","text":"Dört tohumu Dırıl'ın çevresine ek","type":"grow","target":"kalkan","count":4},
 {"id":"diril","text":"Geceyi bekle: Dırıl'ın saati geliyor","type":"listen","target":"diril"},
 {"id":"tohum","text":"Ay Çiçeği Tohumu'nu al","type":"collect","target":"tohum"}],
 "turn_in":"Tırıl ile konuş","rewards":{"piril":120,"xp":150}}


def giver(G):
    return [
     {"when":{"quest":"dirilin_saati","state":"done"},"lines":[
       L(G,"mutlu","Gölge Köşesi'nde çiçek açtı. Buna gece bahçesi diyeceğim!")]},
     {"when":{"quest":"dirilin_saati","state":"ready"},"lines":[
       L(G,"mutlu","Ay Çiçeği açtı! Tırıl seni bekliyor, hadi yanına.")]},
     {"when":{"quest":"dirilin_saati","state":"active","objective_done":"dirilin_saati/ark"},"lines":[
       L(G,"mutlu","Su akıyor, son çit kurudu! Dırıl ortada, Tırıl da yanında."),
       L(G,"sakin","Yorulunca vur. Küsünce alkışla. Sonrası bahçe işi.")]},
     {"when":{"quest":"dirilin_saati","state":"active"},"lines":[
       L(G,"kararlı","Ark kapağı hemen şurada. Çarkı çevir, son çit kurusun!")]},
     {"when":{"quest":"golgenin_yolu","state":"ready"},"lines":[
       L(G,"mutlu","Buraya kadar geldin! Ben de peşinden koştum."),
       L(O,"şaşkın","Gece Çiçeği'ni ektim ama açmadı. Tohum bozuk mu?"),
       L(G,"sakin","Bozuk değil. Onun saati gece. Gündüz ne yapsan açmaz."),
       L(G,"kararlı","Şimdi ark kapağını aç. Son çit kurusun, Dırıl'a varalım.")],
      "then":{"complete_quest":"golgenin_yolu","start_quest":"dirilin_saati"}},
     {"when":{"quest":"golgenin_yolu","state":"active"},"lines":[
       L(G,"sakin","Diken kapısının önünde alkışla. Dikenciler sersemleyince de!"),
       L(G,"sakin","Sette bir Gece Çiçeği toprağı var. Onu da ek, bak ne olacak.")]},
     {"lines":[
       L(G,"dertli","Bu duvarların ardına hiç güneş girmez. Burası Gölge Köşesi."),
       L(G,"sakin","Her levhada aynı soru yazıyor: Neden ben değilim?"),
       L(O,"şaşkın","Bunları Dırıl mı yazmış? Ne kadar da çok sormuş!"),
       L(G,"kararlı","Dikenleri alkışla aç, sete tohumla çık. Ortada Tırıl bekliyor.")],
      "then":{"start_quest":"golgenin_yolu"}}]


D={"yonca":giver("yonca"),"toprak":giver("toprak")}
D["tiril"]=[
 {"when":{"quest":"dirilin_saati","state":"ready"},"lines":[
   L("tiril","mutlu","Işığım tek başına yetmedi. Ay gelince yetti!"),
   L("diril","mutlu","Ben de bir çiçekmişim. Sadece benim saatim gece."),
   L(O,"mutlu","Beş tohum tamam! Bahar Çeşmesi yeniden akacak."),
   L("tiril","kararlı","Hadi köye! Çiçek Şenliği'ne Dırıl da geliyor.")],
  "then":{"complete_quest":"dirilin_saati","set_flag":"s4_bolum5_bitti","goto_scene":"s4_final"}},
 {"when":{"quest":"dirilin_saati","state":"active","objective_done":"dirilin_saati/diril"},"lines":[
   L("tiril","mutlu","Ay Çiçeği Tohumu hemen şurada parlıyor. Al, gidelim!")]},
 {"when":{"quest":"dirilin_saati","state":"active","objective_done":"dirilin_saati/faz1"},"lines":[
   L("tiril","sakin","Dört tohumu çevresine ek. Bekçiler de yanında duracak.")]},
 {"lines":[
   L("tiril","dertli","Günlerdir Dırıl'a ışık tutuyorum. Ama bir tohuma yetmiyor."),
   L("tiril","sakin","Belki ona başka bir ışık lazım. Başka bir saat.")]}]
B={
 "s4k5_basla":[L(O,"şaşkın","Duvarlar ne kadar yüksek! Buraya hiç güneş düşmüyor."),
   L(O,"sakin","Kapının yanında biri bekliyor. Önce ona soralım.")],
 "s4k5_kapi":[L(O,"mutlu","Alkışlayınca dikenler çekildi! Yol açıldı.")],
 "s4k5_dikenci":[L(O,"şaşkın","Diken Topları ve gölgeler! Hepsi aynı soruyu mırıldanıyor."),
   L(O,"kararlı","Önce sersemlet, sonra alkışla. Soru o zaman susuyor.")],
 "s4k5_merdiven":[L(O,"mutlu","Tohum büyüdü, sarmaşık merdiven oldu! Sete çıkabiliriz.")],
 "s4k5_gece":[L(O,"şaşkın","Ektim ama açmıyor. Küçük bir tomurcuk kaldı."),
   L(O,"sakin","Demek bazı çiçekler gündüz açmaz. Gecesini bekler.")],
 "s4k5_kilit":[L(O,"sakin","Çark dönmüyor. Önce bu yolun işini bitirelim.")],
 "s4k5_ark":[L(O,"mutlu","Su akıyor! Son çit de kurudu. Köşenin ortası açıldı.")],
 "s4k5_diril":[L("diril","huysuz","Lale açtı, gül açtı, herkes açtı! Neden ben değilim?"),
   L("tiril","dertli","Dırıl, dur! Onlar sana bakmaya geldi."),
   L(O,"kararlı","Sarmaşıklardan kaçalım. Yorulunca konuşuruz.")],
 "s4k5_faz2":[L("diril","dertli","Alkış mı? Neyi alkışlıyorsun? Ben hiç açmadım ki."),
   L("tiril","sakin","Ona tek alkış yetmiyor. Önce bir bahçe görmesi lazım."),
   L(O,"kararlı","Dört tohumum var. Çevresine ekelim, hep beraber!")],
 "s4k5_cicek_lale":[L("sikir","mutlu","Benim lalem sabah açar. Seninki başka zaman açabilir."),
   L("diril","şaşkın","Başka zaman mı? Öyle bir zaman var mı?")],
 "s4k5_cicek_papatya":[L("circir","mutlu","Benim papatyam öğlen açar. Şarkım da öğlen çıkar zaten."),
   L("diril","sakin","Ben öğlen de denedim. Demek benimki öğlen değil.")],
 "s4k5_cicek_gul":[L("pitpit","mutlu","Benim gülüm geç açtı, kardeşlerimden sonra. Yine de açtı!"),
   L("diril","şaşkın","Geç açan da çiçek sayılıyor mu?")],
 "s4k5_cicek_nilufer":[L("pacali","mutlu","Benim nilüferim suda açar. Herkesin yeri de saati de ayrı."),
   L("diril","sakin","Herkesin saati ayrı... Peki benimki ne zaman?")],
 "s4k5_karardi":[L(O,"şaşkın","Hava kararıyor... Gölge Köşesi'ne gece geliyor!")],
 "s4k5_fener":[L(O,"mutlu","Güneyden mavi bir ışık! Bu bizim Fener'in gece ışığı!"),
   L("tiril","kararlı","Işığımı ona katıyorum. Bak Dırıl, ay doğuyor!")],
 "s4k5_acti":[L("diril","şaşkın","İçim kıpır kıpır... Yapraklarım açılıyor!"),
   L("diril","mutlu","Ben de bir çiçekmişim. Sadece benim saatim gece."),
   L(O,"mutlu","Gümüş bir Ay Çiçeği! Dikenler de çiçek oldu."),
   L("tiril","mutlu","Gece kimse bakmaya gelmemişti. Bu gece herkes burada.")],
 "s4k5_gece_cicegi":[L(O,"mutlu","Bak! Yoldaki Gece Çiçeği de açtı. Saati gelmiş!")],
 "s4k5_tohum":[L(O,"mutlu","Ay Çiçeği Tohumu! Beşinci tohum da tamam."),
   L(O,"sakin","Tırıl ile konuşalım. Eve dönme vakti.")],
}
pack("s4_chapter5","Gölge Köşesi","Gölge Köşesi",[25,30],[Q1,Q2],D,B,None,theme="light")

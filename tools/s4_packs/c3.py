import sys; sys.path.insert(0,'/home/user/piriltidiyari/tools')
from s4_pack import *
O="oyuncu"
A="anne_serce"
speakers({"anne_serce":("Anne Serçe","honey")})
Q1={"id":"dallara_tirman","title":"Dal Dal Yukarı","giver":A,"objectives":[
 {"id":"alkis","text":"Üç yuva evini alkışla","type":"clap","target":"yuva","count":3},
 {"id":"merdiven","text":"Üç sarmaşık merdiven ek, dallara tırman","type":"grow","target":"merdiven","count":3},
 {"id":"dikenci","text":"Dikencileri sersemlet, sonra alkışla","type":"breathe","target":"any","count":4}],
 "turn_in":"Anne Serçe'ye dön","rewards":{"piril":60,"xp":90}}
Q2={"id":"kapali_yuva","title":"Kapalı Yuva","giver":A,"objectives":[
 {"id":"ark","text":"Üst daldaki ark kapağını aç","type":"light","target":"ark"},
 {"id":"pitpit","text":"Tepe yuvadaki Pıtpıt'ı alkışla","type":"breathe","target":"pitpit"},
 {"id":"tohum","text":"Gül Tohumu'nu al","type":"collect","target":"tohum"}],
 "turn_in":"Anne Serçe ile konuş","rewards":{"piril":80,"xp":120}}
D={}
D[A]=[
 {"when":{"quest":"kapali_yuva","state":"ready"},"lines":[
   L(A,"mutlu","Bak şunlara! Pıtpıt kardeşlerine kanat çırpmayı gösteriyor."),
   L(A,"sakin","Yeni bir kardeş gelince sevgi bölünmez. Yuva büyür."),
   L(A,"kararlı","Gül Tohumu sende. Sıradaki bahçe Ayna Gölü!"),
   L(O,"mutlu","Hoşça kal Anne Serçe! Minikler uçunca haber ver.")],
  "then":{"complete_quest":"kapali_yuva","set_flag":"s4_bolum3_bitti","give_items":{"nane_limonata":2}}},
 {"when":{"quest":"kapali_yuva","state":"active","objective_done":"kapali_yuva/pitpit"},"lines":[
   L(A,"mutlu","Gül Tohumu yuvanın önünde parlıyor. Al onu, senin hakkın!")]},
 {"when":{"quest":"kapali_yuva","state":"active","objective_done":"kapali_yuva/ark"},"lines":[
   L(A,"mutlu","Su dallardan akıyor! Tepedeki diken çiti kurudu."),
   L(A,"dertli","Pıtpıt'ım tepe yuvada. Kapıyı dikenle kapattı, kimseyi almıyor."),
   L(A,"sakin","Yorulunca yanına git, alkışla. Ben de arkandan geliyorum.")]},
 {"when":{"quest":"kapali_yuva","state":"active"},"lines":[
   L(A,"kararlı","Ark kapağı üst dalda, batı yanında. Çarkını çevir!")]},
 {"when":{"quest":"dallara_tirman","state":"ready"},"lines":[
   L(A,"mutlu","Yuvalar açıldı, merdivenler hazır! Kanatların yok ama hızlısın."),
   L(A,"dertli","Ama tepeye giden yolu diken çiti kapatıyor."),
   L(A,"kararlı","Üst daldaki ark kapağını aç. Su gelince çit kurur.")],
  "then":{"complete_quest":"dallara_tirman","start_quest":"kapali_yuva"}},
 {"when":{"quest":"dallara_tirman","state":"active"},"lines":[
   L(A,"sakin","Dalın dibindeki toprağa merdiven tohumu ek. Hemen büyür."),
   L(A,"sakin","Düşersen üzülme. Alt dala konarsın, merdiven yerinde durur.")]},
 {"when":{"quest":"dallara_tirman","state":"none"},"lines":[
   L(A,"mutlu","Hoş geldin! Ben Anne Serçe. Burası Yuva Ağacı."),
   L(A,"mutlu","Yumurtalarımdan dört minik çıktı. Cik cik, bütün gün!"),
   L(A,"dertli","Büyük oğlum Pıtpıt o günden beri tepe yuvadan inmiyor."),
   L(A,"dertli","'Artık kimse bana bakmıyor' diyor. Oysa gözüm hep onda."),
   L(A,"kararlı","Ben yavruları bırakamam. Sen dallara tırmanır mısın?")],
  "then":{"start_quest":"dallara_tirman"}},
 {"lines":[L(A,"mutlu","Dört minik, bir de Pıtpıt'ım. Yuvam hiç bu kadar dolu olmamıştı!")]}]
# Bado's side story: with another keeper Bado stands half-way up with Minnoş
D["bado"]=[
 {"when":{"flag":"s4c3_bado_fark"},"lines":[
   L("minnos","mutlu","Abimin sırtı dünyanın en yumuşak yeri!"),
   L("bado","mutlu","Sırtım geniş. İkimize de yer var.")]},
 {"lines":[
   L("bado","dertli","Minnoş doğunca herkes onu kucakladı. Ben kenarda kaldım sandım."),
   L("bado","şaşkın","Pıtpıt'ı duyunca anladım: benim içimde de minik bir diken varmış."),
   L("minnos","mutlu","Ama abi! Ben en çok senin sırtında uyurum."),
   L("bado","mutlu","Öyle mi? Gel bakalım. Sırtımda yerin hep hazır."),
   L(O,"sakin","Kalp de bir yuva Bado. Yeni gelen, önce geleni itmez.")],
  "then":{"set_flag":"s4c3_bado_fark"}}]
# ... and when the keeper IS Bado, Minnoş waits there and Bado says it himself
D["minnos"]=[
 {"when":{"flag":"s4c3_bado_fark"},"lines":[
   L("minnos","mutlu","Abi, inerken beni sırtına alır mısın?"),
   L(O,"mutlu","Alırım tabii. Sırtımda yerin hep hazır.")]},
 {"lines":[
   L("minnos","şaşkın","Abi, Pıtpıt neden küsmüş? Kardeşleri çok tatlı!"),
   L(O,"dertli","Sen doğunca ben de öyle hissettim Minnoş. Kenarda kaldım sandım."),
   L(O,"şaşkın","İçimde minik bir diken varmış. Şimdi fark ettim."),
   L("minnos","mutlu","Ama ben en çok senin sırtında uyurum abi!"),
   L(O,"mutlu","Gel bakalım. Kalbim büyüdü, sana da yer var, bana da.")],
  "then":{"set_flag":"s4c3_bado_fark"}}]
B={
 "s4k3_basla":[L(O,"şaşkın","Kocaman bir ağaç! Her dalında bir yuva evi var."),
   L(O,"sakin","En tepedeki yuvanın kapısı dikenle kapalı. Kim var orada?")],
 "s4k3_yuva":[L(O,"mutlu","Alkışlayınca yuvanın dikenleri çekildi! Kuşlar cıvıldıyor.")],
 "s4k3_dikenci":[L(O,"şaşkın","Civciv somurtmuş, sincap da herkesi dalından itiyor!"),
   L(O,"kararlı","Önce sersemlet, sonra alkışla. Kendi dalını görsün.")],
 "s4k3_merdiven":[L(O,"mutlu","Sarmaşık merdiven oldu! Üst dala çıkabiliriz.")],
 "s4k3_dustum":[L(O,"şaşkın","Pof! Yumuşak düştüm. Merdiven yerinde, yine çıkarım.")],
 "s4k3_kilit":[L(O,"sakin","Çark dönmüyor. Önce Anne Serçe'nin işini bitirelim.")],
 "s4k3_ark":[L(O,"mutlu","Su dallardan aşağı akıyor! Tepedeki diken çiti kurudu.")],
 "s4k3_pitpit":[L("pitpit","huysuz","Gelmeyin! Kapıyı ben kapattım. Burası benim yuvam!"),
   L("pitpit","dertli","Dört kardeş geldi. Artık kimse bana bakmıyor!"),
   L(O,"kararlı","Kanatlarıyla rüzgâr çıkarıyor. Yorulunca yanına gidelim.")],
 "s4k3_sakin":[L("pitpit","dertli","Annem bütün gün onları besliyor. Beni unuttu sandım."),
   L(O,"mutlu","Seni alkışladım Pıtpıt! Kanat çırpışın rüzgâr gibiydi."),
   L("pitpit","şaşkın","Beni mi? Kanat çırpışımı gören oldu mu yani?")],
 "s4k3_tuy":[L(A,"mutlu","Pıtpıt'ım! Bak, bunu hatırlıyor musun?"),
   L(A,"sakin","Sen minicikken düşen ilk tüyün. Onu yuvaya ben ördüm."),
   L(A,"mutlu","Sen benim ilk yuvamsın. Kalbim büyüdü, senin yerin küçülmedi."),
   L("pitpit","mutlu","İlk tüyüm... Bunca zaman saklamışsın anne!")],
 "s4k3_kardes":[L("pitpit","şaşkın","Aa, kardeşlerim! Dördü de bana bakıyor."),
   L("pitpit","kararlı","Daha uçmayı bilmiyorlar. Onlara ben öğreteceğim!"),
   L(A,"mutlu","Abileri gösterirse çabucak kanatlanırlar.")],
 "s4k3_tohum":[L(O,"mutlu","Gül Tohumu! Sevgi paylaşılınca azalmıyor, çoğalıyor.")],
 "s4k3_ani":[L("diril","dertli","Bir kürek toprak... Küçük bir çocuk eli..."),
   L("diril","sakin","Beni gölgeli köşeye bıraktı. 'Burada büyü' dedi."),
   L(O,"şaşkın","Bu Dırıl'ın ilk anısı! Onu bir çocuk ekmiş.")],
}
pack("s4_chapter3","Yuva Ağacı","Yuva Ağacı",[15,20],[Q1,Q2],D,B,theme="light")

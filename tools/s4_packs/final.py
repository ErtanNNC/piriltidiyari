import sys; sys.path.insert(0,'/home/user/piriltidiyari/tools')
from s4_pack import *
O="oyuncu"
speakers({"sarkici_cocuk":("Küçük Şarkıcı","berry")})
C="sarkici_cocuk"
B={
 "s4f_1":[L("toprak","mutlu","Beş tohum da burada! Haydi, çeşmenin çevresine dikelim."),
   L(O,"kararlı","Lale, papatya, gül, nilüfer, ay çiçeği... Hepsi toprağa!")],
 "s4f_2":[L("toprak","mutlu","Su akıyor! Bahar Çeşmesi yine şırıl şırıl!"),
   L("diril","sakin","Ben de bir çiçekmişim. Sadece benim saatim gece.")],
 "s4f_3":[L("tospik_nine","mutlu","Çiçek Yarışması başlıyor! Ama bu yıl yarışmak yok."),
   L("tospik_nine","mutlu","Herkes bahçesinden bir çiçeği başka birine hediye etsin!")],
 "s4f_4":[L("sikir","mutlu","En parlak lalem senin olsun, Cırcır. Bende daha çok var!"),
   L("korkuluk","mutlu","Bana da mı çiçek? Hih hih, şapkama takacağım!")],
 "s4f_odul":[L("tospik_nine","mutlu","Bu yılın ödülü bir bahçeye değil, yardım eden bir ele!"),
   L("tospik_nine","mutlu","Yonca! Herkesin bahçesine en çok sen el verdin.")],
 "s4f_odul2":[L("yonca","şaşkın","Ben mi? Ben sadece tohum ektim..."),
   L("yonca","mutlu","Teşekkür ederim! Bu çelengi hep birlikte kazandık.")],
 "s4f_gece":[L("tospik_nine","sakin","Güneş battı ama bu gece kimse uyumuyor. Şşş, bakın!"),
   L("diril","mutlu","Benim saatim geldi. Bakın... açıyorum!")],
 "s4f_gece2":[L(O,"şaşkın","Ay Çiçeği! Meydanın ortasında ay gibi parlıyor."),
   L("diril","mutlu","Beni görmek için beklediniz mi? Hepiniz mi?")],
 "s4f_dort":[L("miril","mutlu","Ben gökyüzünü aydınlatırım!"),
   L("hiril","mutlu","Ben müziği! Bum, bum, bum!"),
   L("tiril","mutlu","Ben suyu. Bakın, çeşme masmavi!"),
   L("diril","mutlu","Ben de toprağı. Dördümüz ilk kez yan yanayız!")],
 "s4f_fistik":[L("fistik","huysuz","Bu köyde artık herkesin bir türlü ışığı var."),
   L("fistik","huysuz","Benim dikenlerim hariç.")],
 "s4f_pati":[L("fistik","sakin","Bir çırağın yerini kimse alamaz, Pati."),
   L("pati","mutlu","Yonca, ilk dersin benden: Önce esne, sonra zıpla!")],
 "s4f_bado":[L("bado","mutlu","Minnoş'un çiçeği benimkinden büyük çıktı. İlk ben alkışlıyorum!"),
   L("minnos","mutlu","Bahçe ikimizin, Bado! Yarısı senin.")],
 "s4f_citir":[L("citir","mutlu","Paytak ile ortak bir harita çizdik. İki imza yan yana!")],
 "s4f_lumi":[L("lumi","mutlu","Tırıl, ışık dansı! Mavi ile sarı birleşti..."),
   L("tiril","mutlu","Yeşil oldu! Tam bir bahar rengi.")],
 "s4f_tipis_panda":[L("hiril","mutlu","Tıpış, davul sende. Bu sefer ritmi sen tut."),
   L("tipis_panda","mutlu","Bir, iki, üç... Tutuyorum!")],
 "s4f_tosbi":[L("fistik","sakin","Tosbi, artık büyük bekçilerdensin. Takımıma hoş geldin."),
   L("tosbi","mutlu","Kabuğum küçük ama yüreğim kocaman!")],
 "s4f_yonca":[L("yonca","kararlı","Size bir şey göstereceğim: kimseye açmadığım bahçem."),
   L("tospik_nine","şaşkın","Ne güzel bir bahçe! Hep buradaymış da biz görmemişiz.")],
 "s4f_hiril":[L("hiril","mutlu","Davulumla bütün bahçe dans ediyor. Çiçekler bile ritim tutuyor!")],
 "s4f_tiril":[L("tiril","mutlu","Dırıl, ışığımı sana tutuyorum. Ay ışığında aç bakalım!")],
 "s4f_sarki":[L(C,"mutlu","La la laa... Bahar geldi, çiçek açt... Gık!"),
   L("koylu","mutlu","Kıkır kıkır!"),
   L(C,"dertli","Yanlış söyledim... Herkes bana bakıyor.")],
 "s4f_bulut":[L(O,"şaşkın","Pembe bir bulut! Pamuk gibi... Üstüne iniyor."),
   L(O,"sakin","İçine saklandı. Hey, sana gülmedik ki! Çık hadi.")],
 "s4f_son":[L("fistik","şaşkın","Dağların üstünde de pembe bulutlar toplanıyor."),
   L("fistik","kararlı","Bu sefer kimse kaçırılmadı. Kendisi saklanıyor.")],
}
def cam(p,l,t): return {"cam":{"pos":p,"look":l,"time":t}}
def say(b): return {"say":b}
def do(m): return {"do":m}
def wait(s): return {"wait":s}
STEPS=[cam([0,7,13],[0,1.2,-3],0),wait(1.0),say("s4f_1"),do("seeds_planted"),
 cam([0,5,8],[0,1.2,-6],2.0),wait(1.8),do("fountain_runs"),wait(1.6),say("s4f_2"),
 cam([0,8,14],[0,1.0,-2],2.0),say("s4f_3"),do("flowers_swap"),wait(3.0),say("s4f_4"),
 say("s4f_odul"),do("prize"),wait(2.0),say("s4f_odul2"),
 do("night_falls"),wait(3.6),cam([1,4.5,8],[1,1.0,-2],2.0),say("s4f_gece"),
 do("moon_flower"),wait(2.4),say("s4f_gece2"),do("four_friends"),
 cam([0,7,13],[0,1.5,-3],2.5),wait(3.0),say("s4f_dort"),say("s4f_fistik"),
 say("s4f_{keeper}"),wait(2.0),
 {"card":["","Herkes kendi saatinde açar","O gece köyde kimse uyumadı."],"time":4.0},
 do("child_sings"),cam([6.5,3.2,8.5],[8.5,1.0,1.5],2.0),wait(1.6),say("s4f_sarki"),
 do("pink_cloud"),wait(3.4),say("s4f_bulut"),do("far_clouds"),
 cam([2,4,12],[0,11,-44],2.5),wait(1.6),do("fistik_bristles"),say("s4f_son"),
 do("fade_dark"),wait(2.2),do("season_end")]
pack("s4_final","Çiçek Şenliği","Gökkuşağı Köyü",[28,30],[],{},B,None,theme="light",cutscenes={"cicek_senligi":STEPS})

# Pırıltı Diyarı

**Kıvılcım Bekçileri** serisinin ilk oyunu · Just A Game Studios
6–12 yaş için 2.5D aksiyon RPG · Godot 4.7

![Sahne 1: Yıldız Şenliği](docs/ekran/sahne1_konusma.png)

## Kaynaklar

- **Tasarım sistemi:** renkler, yazı, bileşenler, karakterler, sanat yönü
- **Hikâye:** "Oyun Hikâyesi: Prolog, Ana Hikâye ve Dünya"

`design/tokens.json` tasarım sistemindeki `tokens.json`'ın kopyasıdır. Oyun bütün renkleri, yazı boyutlarını, boşlukları ve köşeleri oradan okur. Tasarım sistemi değişince bu dosyayı yenilemek yeter.

## Çalıştırma

```bash
tools/setup_godot.sh          # Godot 4.7.2'yi .tools/ altına indirir (bir kez)
tools/test.sh                 # testler
tools/screenshot.sh out.png --scene=scene4 --at=10   # bir sahneyi açıp 10. saniyede görüntü alır
```

Editörde açmak için Godot 4.7 ile `project.godot` dosyasını aç.

**Kontroller:** WASD / oklar yürür · Boşluk zıplar · J saldırır (diken dönüşü) · E konuşur.
Mobilde sol yarıda sanal joystick, sağda Zıpla / Saldır butonları çıkar.

## Durum

**Prolog baştan sona oynanabilir** (gri kutu modellerle), ardından Bölüm 0'ın ilk görevi:

| Sahne | İçerik | Öğretilen |
| --- | --- | --- |
| Açılış | Just A Game Studios, başlık, Başla / Devam et | |
| 1 · Yıldız Şenliği | Köy, Tospik Nine, üç çocuk, Kayıp Fenerler | yürüme, zıplama, konuşma, Pırıl |
| 2 · Gri Rüzgâr | Pus gelir, Puslu Sümüklü ve Somurtkan Mantar | saldırı, yuvarlanma, Bal Şurubu |
| 3 · Kule'ye Koşu | Düşen kirişler, sarmaşıklar, sallanan fenerler | tırmanma, platform, seviye atlama, Dikenli Dönüş |
| 4 · Pus Baykuşu | 3 fazlı boss: tüyler, dalış, sersemleme | boss dövüşü |
| 5 · Fıstık'ın Seçimi | Ara sahne: Kıvılcım beşe bölünür, Fıstık heykel olur | |
| 6 · Fener'in Seçimi | Tospik'in konuşması, bekçi seçimi, renk, aksesuar, isim | |
| Bölüm 0 | Seçilen bekçiyle: heykeli ziyaret, Dev Somurtkan Mantar | |

Sahne başlarında oyun kaydedilir (`user://kayit.json`); açılıştaki "Devam et" oradan sürer. Kimse ölmez: can biterse "Uykuya daldın", son yanan fenerde uyanılır.

> Pıtı, Tıpış ve Zıpzıp'ın adları ve türleri hikâye dokümanında yoktu; ben verdim.

<p>
<img src="docs/ekran/00_acilis.png" width="49%"> <img src="docs/ekran/02_gri_ruzgar_kiris.png" width="49%">
<img src="docs/ekran/04_pus_baykusu.png" width="49%"> <img src="docs/ekran/06_bekci_secimi.png" width="49%">
</p>

**Kontroller:** WASD / oklar · Boşluk zıpla · J saldır · K yuvarlan · L Dikenli Dönüş · E konuş · 1–4 iksir.
Mobilde: sanal joystick, Zıpla / Saldır / Yuvarlan / Dönüş butonları, iksir yuvalarına dokunma.

### Henüz olmayanlar

- Gerçek modeller, ikonlar, logo, ses ve müzik (her şey ilkel şekillerden yer tutucu)
- Bekçilerin kendi özel yetenekleri (Pençe Kombosu, Kucaklama Kalkanı, Fındık Fırlatma, Işık Patlaması) ve dünya yetenekleri; şimdilik hepsi diken dönüşüyle saldırıyor
- Envanter / dükkân ekranları, ayarlar, Bölüm 1 (Fısıltı Ormanı)

## Proje yapısı

```
content/            hikâye verisi (bölüm paketleri) — kod değişmeden hikâye eklenir
  items.json, speakers.json
  keepers.json        dört bekçi adayı (karakterler.md'den)
  prologue/           chapter.json, quests/, dialogue/, barks.json, cutscenes/
  chapter0/           Bölüm 0 paketi
design/tokens.json  tasarım sistemi token'ları
src/autoload/       Tokens, Content, GameState, InputSetup, DevTools
src/core/           sahneden bağımsız kurallar: PlayerData, Progression, DialogueRules,
                    MobStats, OwlPlan, SaveGame
src/world/          toon shader, kamera, köy parçaları, sahne betikleri
src/actors/         oyuncu, NPC'ler, toplanabilirler (şimdilik ilkel şekillerden modeller)
src/ui/             HUD, diyalog kutusu, barlar, ikonlar, dokunmatik kontroller
scenes/             sahneler (.tscn)
tests/              ekransız testler
```

## Diyalog verisi

Her NPC'nin konuşmaları `content/<bölüm>/dialogue/<npc>.json` dosyasındadır. Koşulu (`when`) tutan ilk konuşma oynar, ardından etkisi (`then`) uygulanır. Son konuşma koşulsuz olmalı. Kurallar `src/core/dialogue_rules.gd` dosyasında, testler bunları ve yazım kurallarını (satır en fazla 70 harf, bilinen konuşan ve eşya) kontrol eder.

## Lisanslar

Baloo 2 ve Nunito: SIL Open Font License (`assets/fonts/OFL-*.txt`).

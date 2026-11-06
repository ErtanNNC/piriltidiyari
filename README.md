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
tools/screenshot.sh out.png   # sanal ekranda oyunu çizip görüntü alır
```

Editörde açmak için Godot 4.7 ile `project.godot` dosyasını aç.

**Kontroller:** WASD / oklar yürür · Boşluk zıplar · J saldırır (diken dönüşü) · E konuşur.
Mobilde sol yarıda sanal joystick, sağda Zıpla / Saldır butonları çıkar.

## Durum

**Prolog · Sahne 1 – Yıldız Şenliği** oynanabilir (gri kutu modeller):

- Gökkuşağı Köyü: Fener Kulesi, evler, kuyu, büyük ağaç, çiçek tarlası, fener direkleri
- Fıstık: yürüme, zıplama, diken dönüşü, konuşma
- Tospik Nine ve üç çocuk (Pıtı, Tıpış, Zıpzıp), **Kayıp Fenerler** görevi
- Pırıl toplama, görev takipçisi, HP/MP/XP barları, Kıvılcım takipçisi, diyalog kutusu
- Görev bitince "Sahne 2 – Gri Rüzgâr" kartı

Görünüm: toon shader (iki ton ve mor gölge tonu), koyu dış çizgi ve akşam şenliği ışığı.

> Pıtı, Tıpış ve Zıpzıp'ın adları ve türleri hikâye dokümanında yok; geçici olarak verildi.

## Proje yapısı

```
content/            hikâye verisi (bölüm paketleri) — kod değişmeden hikâye eklenir
  items.json, speakers.json
  prologue/chapter.json, quests/*.json, dialogue/*.json
design/tokens.json  tasarım sistemi token'ları
src/autoload/       Tokens, Content, GameState, InputSetup, DevTools
src/core/           sahneden bağımsız kurallar: PlayerData, Progression, DialogueRules
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

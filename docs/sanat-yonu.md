# Pırıltı Diyarı — Sanat Yönü (3B modeller için)

Bu belge, oyuna girecek gerçek 3B modellerin (yapay zekâ ile üretilmiş, hazır paket ya da
sanatçı işi) **tek bir oyundan çıkmış gibi** görünmesi içindir. `create-game-assets`
skill'indeki iş akışını Pırıltı Diyarı'na uyarlar. Teknik aktarma: `assets/models/README.md`.

## 1. Hedef görünüm (kilitli)

- **Tarz:** çizgi film, yumuşak ve yuvarlak; sevimli, korkutucu değil. Keskin köşe, diken
  gibi sivri uçlar yok (Fıstık'ın dikenleri bile yuvarlak uçlu).
- **Gölgelendirme:** oyun kendi toon gölgelendiricisini uygular: iki ton (aydınlık + mor
  gölge) ve koyu dış çizgi. Bu yüzden modelin **dokusunda ışık/gölge olmamalı** (düz renk
  dokular, "albedo only", "no baked lighting").
- **Oranlar (chibi):** kafa ≈ gövde. Bekçiler oyunda ~2 m (kafanın üstüne kadar). Büyük
  gözler, küçük ağız, pembe yanaklar. Kollar ve bacaklar kısa ve tombul.
- **Siluet:** her karakter küçükken bile tanınmalı (Pati: üçgen kulaklar; Bado: yuvarlak
  kulaklar ve kalkan; Çıtır: kocaman kuyruk; Lumi: kanatlar ve parlayan kuyruk).
- **Dış çizgi:** oyun ekler (`outline` = #2a2140). Modelde siyah çizgi boyamayın.

## 2. Renk paleti

Renkler tasarım sistemi token'larıdır (`design/tokens.json`). Modellerde bu tonlara yakın
kalın; yeni parlak renk eklemeyin.

| Token | Renk | Kullanım |
|---|---|---|
| honey | #ffc53d | Fıstık, Fener ışığı, kıvılcım kolyesi |
| berry | #ff6b8a | Pati'nin imza rengi, yanaklar, kalp |
| sky | #4aa8ff | Çıtır'ın imza rengi, su, bilgi |
| leaf | #2f9e4f | Bado'nun imza rengi, doğa |
| xp | #9b6bff | Lumi'nin imza rengi |
| spark-green/blue/yellow/white/purple | #3fbf5f · #4cc3ff · #ffe066 · #e8f1ff · #b07cff | Beş Kıvılcım ve bölgeleri |
| pus | #9a97a6 | Pus'lu (gri) yaratıklar |
| outline | #2a2140 | Oyunun çizdiği dış çizgi |

**Pus kuralı:** Pus'taki yaratıklar gri-mordur ama kendi renklerinin silik bir izini taşır;
sakinleşince kendi rengine döner. Bir yaratık için **iki doku** (Pus'lu ve renkli) ya da tek
renkli model + oyunun gri tonlaması yeterli.

## 3. Aileler (birlikte üretilecek gruplar)

Aynı aileyi **aynı araçla, aynı istemle, aynı oturumda** üretin; sonra yan yana bakın.

1. **Bekçiler:** pati, bado, citir, lumi (+ fistik). Aynı boy, aynı göz stili.
2. **Köylüler:** turtle (Tospik Nine), owl_teacher (Hu), mole (Kazma), spider (Dikiş),
   frog (Tıkır), gull_captain (Pırpır), snowman (Bilge Kuzey), bunny, duckling.
3. **Yaratıklar:** sumuklu, mantar, kirpi_topu, karga, kristal_bocek, yarasa,
   firtina_yumagi, korsan_marti, kar_tavsani, buz_dikeni (her biri ~1–1.5 m).
4. **Bosslar:** Pus Baykuşu, Kütük Kral, Kıskaç, Rüzgâr, Dondurma, Mırıl (3–5 m).

## 4. Teknik bütçe

| | Üçgen | Doku | Animasyon |
|---|---|---|---|
| Bekçi | 8–20 bin | 1024 px, tek malzeme tercih | idle, walk, run, jump, attack |
| Köylü | 5–12 bin | 512–1024 px | idle (+ wave) |
| Yaratık | 3–8 bin | 512 px | idle, walk, attack |
| Boss | 15–30 bin | 1024 px | idle, attack, (tired) |

Dosya: **GLB (glTF 2.0)**, metre ölçeği, yüz +Z'ye bakar, ayaklar en altta. Ad = oyundaki
kimlik (`pati.glb`, `turtle.glb`).

## 5. Üretim istemi (Meshy / Tripo / Rodin)

Görselden 3B üretirken referans: tasarım sistemindeki karakter çizimi, **önden, düz zemin,
kollar hafif açık**. Metin istemi örneği:

> cute chibi {hayvan} game character, big head, big glossy eyes, small smile, rosy cheeks,
> rounded soft shapes, {imza rengi} {kıyafet}, toon style, flat colors, no baked lighting,
> no outlines, A-pose, front view, low poly, game ready

Rig + animasyon: aracın kendi "rig/animate" seçeneği ya da Mixamo / AccuRIG.

## 6. Kalite kapısı (her model için)

1. `assets/models/<ad>.glb` olarak koy.
2. `tools/screenshot.sh out.png --scene=preview` (bekçiler) / `--demo=npcs` (köylüler):
   boy, yön, renk ve dış çizgi doğru mu?
3. Oyun kamerasından bak (yukarıdan ~50°): `--scene=chapter1 --at=6`. Küçükken tanınıyor mu?
4. Aileyi yan yana karşılaştır: biri ötekilerden parlak/koyu/detaylı mı?
5. Telefonda dene: kare hızı düştüyse üçgen veya doku boyutunu küçült.
6. Lisansı not et (ücretsiz planlar atıf isteyebilir).

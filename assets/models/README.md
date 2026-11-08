# Gerçek 3B modeller

Tarz, renkler, bütçe ve kalite adımları için önce **[docs/sanat-yonu.md](../../docs/sanat-yonu.md)**.

Bu klasöre `.glb` dosyası koymak yeter; oyun ilkel şekillerle yapılmış yer
tutucu yerine onu kullanır, kod değişmez.

| Dosya adı | Kim |
|---|---|
| `pati.glb`, `bado.glb`, `citir.glb`, `lumi.glb` | dört bekçi |
| `fistik.glb` | Fıstık (heykel hâli hariç) |
| `turtle.glb`, `bunny.glb`, `owl_teacher.glb`, `mole.glb`, `gull_captain.glb`, `snowman.glb` … | köylüler (`NpcModels` türleri) |

Oyun modeli kendisi hazırlar (`src/actors/model_import.gd`):

- Boyunu ayarlar (bekçiler ~2 m) ve ayaklarını yere oturtur.
- Malzemelerin rengini ve dokusunu oyunun çizgi film gölgelendiricisine
  aktarır, koyu dış çizgiyi ekler.
- `idle`, `walk`, `run`, `jump`, `attack` adlı animasyonları (büyük/küçük harf
  ve önek fark etmez, ör. `Armature|Walk`) yürürken, zıplarken ve saldırırken oynatır.
  Animasyon yoksa nefes alma ve esneme yine çalışır.

İsteğe bağlı ayar dosyası `<ad>.json`:

```json
{"height": 2.0, "facing": 180, "outline": 0.03}
```

`facing`: model arkasını dönüyorsa 180 yaz. `outline`: dış çizgi kalınlığı.

## Model üretirken

- Yapay zekâ araçları (Meshy, Tripo, Rodin): tasarım sistemindeki karakter
  görselini ver, **GLB** olarak indir. Telefonda akıcı olması için
  5–20 bin üçgen ve en fazla 1024 px doku yeterli.
- İskelet ve animasyon: araç “rig/animate” sunuyorsa idle, walk, run, jump,
  attack seç. Yoksa Mixamo’da otomatik iskelet + animasyon alınabilir
  (FBX gelir, Blender’da GLB’ye çevrilir).
- Yüz önden (+Z) bakmalı, ayaklar en altta olmalı.

Kontrol: `tools/screenshot.sh out.png --scene=preview` (bekçiler yan yana),
`--demo=npcs` (köylüler). Aktarma zincirinin testi:
`godot --headless --path . -- --scene=preview --demo=import`.

## Deneme: `deneme/pati.glb` (Kasım 2026)

Oyunun kendi Pati'sinin referans görselinden (`--scene=preview --demo=ref
--model=pati`) Higgsfield → Tripo H3.1 ile üretildi (9 kredi, 14,8 bin üçgen,
2048 px doku). Oyunda **kullanılmıyor**; denemek için `pati.glb` ve
`pati.json` dosyalarını bu klasöre taşı. Öğrenilenler:

- Yön: Tripo modeli +X'e bakıyor → `"facing": -90`.
- Işık: referans ışıklı çizilince ışık dokuya işlendi, renkler sarıya kaçtı
  (`"tint"` ile düzeltildi). Referans artık ışıksız, düz renkli çiziliyor.
- Kabarık yüz ayrıntılarında dış çizgi kalın durdu → `"outline": 0.012`.
- Kendi basit modelimizi referans vermek kaliteyi pek artırmıyor (aynı tasarımın
  biraz pürüzlü kopyası). Asıl fark için referans, profesyonel bir karakter
  çizimi olmalı.
- Dışarıdan gelen bekçi modeli dükkân kıyafetlerini, aletleri ve renk
  seçeneklerini göstermez (bunlar parça parça kurulan modele takılıyor).

## Pati (oyunda, Kasım 2026)

`pati.glb`: Higgsfield'da GPT Image 2.6 ile çizilen karakter görselinden
Tripo H3.1 ile üretildi (çizim 0,25 + model 9 kredi, 19,5 bin üçgen).
`pati.json`: yön (-90), renk düzeltmesi, ince dış çizgi ve kıyafet/alet
çapaları (`anchors`: Head, head_r, hat_scale, Body, HandL, HandR; metre
cinsinden, model yerde ve +Z'ye bakarken). Kontrol:
`--scene=preview --demo=looks --model=pati`.
Kürk rengi seçenekleri (beyaz/gri) dokulu modelde uygulanmaz.

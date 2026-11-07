# Gerçek 3B modeller

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

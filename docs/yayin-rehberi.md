# Pırıltı Diyarı — Google Play yayın rehberi

Bu klasörde hazır olanlar ve senin yapman gereken adımlar.

## Hazır olanlar

| Ne | Nerede |
|---|---|
| Uygulama ikonu (512×512, mağaza için) | `assets/icon/icon_512.png` |
| Telefon ikonları (192 ve uyarlanabilir 432) | `assets/icon/` (APK'da kullanılıyor) |
| Tanıtım görseli (1024×500) | `docs/play/tanitim_1024x500.png` |
| Ekran görüntüleri (6 adet, 16:9) | `docs/play/*.png` |
| Paket adı | `com.justagamestudios.piriltidiyari` |
| Gizlilik politikası metni | aşağıda |
| Mağaza metinleri | aşağıda |

## Senin yapman gerekenler

1. **Google Play Console hesabı** aç (tek seferlik 25 ABD doları):
   https://play.google.com/console — "Kuruluş" hesabı açarsan şirket bilgileri
   istenir; kişisel hesapta yeni hesaplar için 12 test kullanıcısıyla 14 gün
   kapalı test şartı vardır.
2. **Yayın imza anahtarı** oluştur ve güvenli bir yerde sakla (kaybolursa
   güncelleme yayınlayamazsın):

   ```sh
   keytool -genkeypair -v -keystore piriltidiyari-release.jks \
     -alias pirilti -keyalg RSA -keysize 4096 -validity 10000
   ```

   Anahtarı depoya koyma. Play Console'da "Play Uygulama İmzalama"yı açık bırak.
3. **AAB dosyası:** Google Play yeni uygulamalarda APK değil **AAB** ister.
   AAB, Godot'nun "Gradle ile derleme" seçeneğiyle üretilir; bunun için
   Android SDK ve Java gerekir. Bu ortamda yok. İki yol var:
   - Bilgisayarına Godot 4.7 + Android Studio kur, projeyi aç, Proje →
     Android Derleme Şablonunu Yükle, Dışa Aktar → Android → "Use Gradle
     Build" açık, biçim **AAB**, yayın anahtarınla dışa aktar.
   - Ya da GitHub Actions'ta AAB üreten bir iş akışı kurmamı iste (Android
     SDK orada hazır); anahtarını GitHub "Secrets" kısmına koyarsın.
4. **Mağaza kaydını doldur:** aşağıdaki metinleri, ikonu, tanıtım görselini ve
   ekran görüntülerini yükle.
5. **İçerik derecelendirme anketi:** şiddet "çizgi film tarzı, kimse
   yaralanmaz (uykuya dalar)", reklam yok, uygulama içi satın alma yok, veri
   toplama yok. Hedef yaş grubu: **5–8 ve 9–12** → "Aileler" politikası
   geçerli olur.
6. **Veri güvenliği formu:** "Veri toplanmıyor, paylaşılmıyor" seç
   (kayıtlar yalnızca cihazda tutuluyor, internet izni yok).

## Gizlilik politikası (Türkçe)

> **Pırıltı Diyarı Gizlilik Politikası**
>
> Pırıltı Diyarı, çocuklar için hazırlanmış bir oyundur. Oyun hiçbir kişisel
> veri toplamaz, saklamaz ya da paylaşmaz. Oyunda reklam, analiz aracı,
> hesap açma veya uygulama içi satın alma yoktur ve oyun internete bağlanmaz.
> Oyun ilerlemesi (kayıtlar ve ses ayarları) yalnızca cihazın kendi
> hafızasında tutulur; oyun silindiğinde bunlar da silinir.
>
> Sorularınız için: [e-posta adresin]
>
> Son güncelleme: [tarih]

Bu metni herkese açık bir sayfada (ör. GitHub Pages, Google Sites) yayınlayıp
bağlantısını Play Console'a girmen gerekir.

## Gizlilik politikası (İngilizce)

> **Pırıltı Diyarı Privacy Policy**
>
> Pırıltı Diyarı is a game made for children. The game does not collect,
> store or share any personal data. It has no ads, no analytics, no accounts
> and no in-app purchases, and it does not connect to the internet. Game
> progress (saves and sound settings) is kept only on the device and is
> removed when the game is uninstalled.
>
> Contact: [your e-mail]

## Mağaza metinleri

**Uygulama adı (30 karakter):** Pırıltı Diyarı

**Kısa açıklama (80 karakter):**
Renkleri geri getir! Sevimli bekçilerle fenerleri yak, Pus'u dağıt.

**Uzun açıklama:**

> Gökkuşağı Köyü'nün renklerini gri bir Pus kapladı! Pati, Bado, Çıtır ve
> Lumi'den birini seç, fenerleri yak ve beş Kıvılcım'ı geri getir.
>
> ✨ Fısıltı Ormanı'ndan Şekerleme Mağaraları'na, Bulut Limanı'ndan Uyku
> Dağı'na uzanan büyülü bir macera
> ✨ Her bekçinin kendine özgü yeteneği: çift zıplama, kalkan, tırmanma, uçma
> ✨ Kimse yaralanmaz: yaramaz yaratıklar sakinleşir, bosslar "uyanır"
> ✨ Dükkândan kıyafetler, sevimli aletler ve renk seçenekleri
> ✨ Reklam yok, satın alma yok, internet gerekmez
>
> 5–10 yaş çocuklar için, dokunmatik kontrollerle kolayca oynanır.

## Ses lisansı (unutma)

Bazı ses efektleri Oculus Audio Pack'ten (CC BY 4.0). Mağaza açıklamasının
sonuna şu satırı ekle: "Bazı ses efektleri: Oculus Audio Pack (Meta), CC BY 4.0."
Ayrıntı: `assets/audio/CREDITS.md`.

## Sürüm notu örneği

> Yeni: gerçek 3B karakterler ve bosslar, yeni müzikler ve sesler, rüzgârda
> sallanan çimler ve ağaçlar, kelebekler, yeni köy evleri ve fenerler.

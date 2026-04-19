# 🏇 Atistik — Tahmin Algoritması Yol Haritası (v3.0)

> **Başlangıç Tarihi:** 05 Mart 2026  
> **Son Güncelleme:** 19 Nisan 2026  
> **Durum:** Faz 1-3 ✅ Tamamlandı — **Faz 4 (Master Algoritma) ✅ TAMAMLANDI** — Faz 5 🔴 SIRADA

---

## 🧠 Uygulamanın Kalbi: Master Tahmin Algoritması

Bu doküman, Atistik uygulamasının nihai amacını gerçekleştirmek için tasarlanmış **Master Tahmin Algoritmasını** detaylıca tanımlar. Hedef:

> **Henüz koşulmamış bir yarışta, tüm atların mevcut verilerini işleyerek kazanmaya en yakın atı tespit etmek ve güvenilir bir sıralama üretmek.**

---

## 📊 Elimizdeki Veri Envanteri (TJK'dan Çektiğimiz Her Şey)

Algoritmayı tasarlamadan önce, TJK'dan her bir at için çekebildiğimiz tüm veri noktalarını envanterleyelim:

### A. Yarış Günü Bilgileri (Koşu Kartı)
| # | Veri | Kaynak | Durum |
|---|------|--------|-------|
| 1 | Koşu mesafesi (1000m-2400m) | `DailyRaceModel.distance` | ✅ Alınıyor |
| 2 | Pist tipi (Çim/Kum/Sentetik) | `DailyRaceModel.trackType` | ✅ Alınıyor |
| 3 | Koşu grubu/cinsi (Maiden/Şartlı/KV/Handikap/Grup) | `DailyRaceModel.raceName` | ✅ Alınıyor |
| 4 | At numarası (kulvar sırası) | `RunningHorse.no` | ✅ Alınıyor |
| 5 | Kilo (sıklet) | `RunningHorse.weight` | ✅ Alınıyor |
| 6 | Jokey adı | `RunningHorse.jockey` | ✅ Alınıyor |
| 7 | Antrenör adı | `RunningHorse.trainer` | ✅ Alınıyor |
| 8 | Yaş | `RunningHorse.age` | ✅ Alınıyor |
| 9 | Son 6 yarış sonucu | `RunningHorse.last6` | ✅ Alınıyor |
| 10 | En iyi derece (best rating) | `RunningHorse.bestRating` | ✅ Alınıyor |
| 11 | AGF oranı | `RunningHorse.agf` | ✅ Alınıyor |
| 12 | HP (handikap puanı) | `RunningHorse.hp` | ✅ Alınıyor |
| 13 | KGS (kapalı gözlük, takı bilgisi) | `RunningHorse.kgs` | ✅ Alınıyor |
| 14 | S20 (son 20 yarış istatistiği) | `RunningHorse.s20` | ✅ Alınıyor |
| 15 | Baba/Anne bilgisi | `RunningHorse.father/mother` | ✅ Alınıyor |
| 16 | Koşu ID (idman verisi çekmek için) | `DailyRaceModel.raceId` | ✅ Alınıyor |
| 17 | At detay linki | `RunningHorse.detailLink` | ✅ Alınıyor |

### B. Geçmiş Yarış Verileri (At Detay Sayfasından — `fetch_horse_details_safe`)
| # | Veri | Sütun | Durum |
|---|------|-------|-------|
| 1 | Tarih | `cells[0]` | ✅ Alınıyor |
| 2 | Şehir (hipodrom) | `cells[1]` | ✅ Alınıyor |
| 3 | Mesafe | `cells[2]` | ✅ Alınıyor |
| 4 | Pist tipi + durumu (Kum Normal / Çim Ağır) | `cells[3]` | ✅ Alınıyor + Ayrıştırılıyor |
| 5 | Sıralama (sonuç) | `cells[4]` | ✅ Alınıyor |
| 6 | Derece (süre) | `cells[5]` | ✅ Alınıyor + Saniyeye çevriliyor |
| 7 | Sıklet (kilo) | `cells[6]` | ✅ Alınıyor |
| 8 | Takı bilgisi | `cells[7]` | 🔸 Çekilebilir (henüz kullanılmıyor) |
| 9 | Jokey | `cells[8]` | ✅ Alınıyor |
| 10 | Start pozisyonu | `cells[9]` | 🔸 Çekilebilir (kullanılmıyor) |
| 11 | Ganyan | `cells[10]` | 🔸 Çekilebilir (kullanılmıyor) |
| 12 | Grup (yaş/ırk grubu) | `cells[11]` | ✅ Alınıyor |
| 13 | Koşu No-Adı | `cells[12]` | 🔸 Çekilebilir (kullanılmıyor) |
| 14 | Koşu Cinsi (Maiden/KV/Handikap) | `cells[13]` | ✅ Alınıyor → Class Factor |
| 15 | Antrenör | `cells[14]` | 🔸 Çekilebilir (kullanılmıyor) |
| 16 | Sahip | `cells[15]` | 🔸 Çekilebilir (kullanılmıyor) |
| 17 | HP | `cells[16]` | 🔸 Çekilebilir (kullanılmıyor) |
| 18 | İkramiye | `cells[17]` | ✅ Alınıyor |
| 19 | S20 | `cells[18]` | 🔸 Çekilebilir (kullanılmıyor) |

### C. İdman Verileri (`fetch_training_data_by_race_id` — KTip=5)
| # | Veri | Durum |
|---|------|-------|
| 1 | At adı | ✅ Alınıyor |
| 2 | Mesafe süreleri (200m-2200m, 11 ayrı kolon) | ✅ Alınıyor |
| 3 | İdman tarihi | ✅ Alınıyor |
| 4 | Pist (Kum/Çim) | ✅ Alınıyor |
| 5 | Hipodrom | ✅ Alınıyor |
| 6 | İdman jokeyi | ✅ Alınıyor |

---

## 🔬 MASTER ALGORİTMA MİMARİSİ

### Felsefe

Algoritma, **"Bağlama Duyarlı Normalize Edilmiş Güç Skoru (Context-Aware Normalized Power Score — CANPS)"** felsefesiyle çalışır. Bir atın "2.05 koşmuş olması" tek başına bir şey ifade etmez. Önemli olan:

1. **Hangi pistte, hangi durumda** 2.05 koştu? (Kum Normal mi, Çim Ağır mı?)
2. **Hangi grup yarışında** 2.05 koştu? (Maiden mi, KV-8 mi?)
3. **Kaç kilo taşıyordu** o yarışta?
4. **Son yarışlarında trend neydi?** İyileşiyor mu, geriliyor mu?
5. **Bu mesafede tecrübesi var mı?** Sprint atı mı, uzun mesafe atı mı?
6. **Jokeyi ile uyumu nasıl?** Kaç yarış birlikte kazandılar?
7. **İdmanda nasıl performans gösterdi?** Yarıştaki sürelerine yakın mı idmanda?
8. **Ne kadar dinlendi?** Son yarışından bu yana geçen süre ideal mi?

### Mimari: 11-Katmanlı Güç Skoru Sistemi (Dinamik Ağırlıklı)

> ⚠️ **Ağırlıklar SABİT değildir!** Aşağıdaki yüzdeler "varsayılan" (default) ağırlıklardır.
> Dinamik Ağırlık Sistemi, her at için veri durumuna göre ağırlıkları otomatik ayarlar.
> Detay: [Dinamik Ağırlık Sistemi](#-dinamik-ağırlık-sistemi-ağırlık-neden-sabit-değil) bölümüne bak.

```
╔══════════════════════════════════════════════════════════════════╗
║                    MASTER TAHMİN MOTORU                         ║
║                                                                  ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │  KATMAN 1: Normalize Edilmiş Hız Skoru (Speed Figure)   │    ║
║  │  ► Derece → Class Factor → Pist Durumu → NORMALIZE      │    ║
║  │  ► Varsayılan Ağırlık: %22                              │    ║
║  └─────────────────────────────────────────────────────────┘    ║
║                                                                  ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │  KATMAN 2: Mesafe Uygunluk Endeksi (Distance Index)     │    ║
║  │  ► Hedef mesafedeki geçmiş performans analizi            │    ║
║  │  ► Varsayılan Ağırlık: %10                              │    ║
║  └─────────────────────────────────────────────────────────┘    ║
║                                                                  ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │  KATMAN 3: Pist Uygunluk Endeksi (Track Index)          │    ║
║  │  ► Çim/Kum/Sentetik + Normal/Islak/Ağır performansı     │    ║
║  │  ► Ağırlık: %10                                         │    ║
║  └─────────────────────────────────────────────────────────┘    ║
║                                                                  ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │  KATMAN 4: Form ve Momentum Analizi                      │    ║
║  │  ► Son 5 yarış trendi + derece eğrisi                    │    ║
║  │  ► Varsayılan Ağırlık: %11                              │    ║
║  └─────────────────────────────────────────────────────────┘    ║
║                                                                  ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │  KATMAN 5: İdman Performansı ve Projeksiyon              │    ║
║  │  ► İdman süreleri → yarış projeksiyonu + zamanlama       │    ║
║  │  ► Ağırlık: %10                                         │    ║
║  └─────────────────────────────────────────────────────────┘    ║
║                                                                  ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │  KATMAN 6: Sıklet (Kilo) Performans Endeksi             │    ║
║  │  ► Kilo değişimi x mesafe etkileşimi                     │    ║
║  │  ► Varsayılan Ağırlık: %6                               │    ║
║  └─────────────────────────────────────────────────────────┘    ║
║                                                                  ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │  KATMAN 7: Jokey Analizi                                 │    ║
║  │  ► Jokey-at uyumu + jokeyin hipodrom başarısı            │    ║
║  │  ► Jokey değişimi bonus/ceza                             │    ║
║  │  ► Varsayılan Ağırlık: %7                               │    ║
║  └─────────────────────────────────────────────────────────┘    ║
║                                                                  ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │  KATMAN 8: Dinlenme & Kondisyon (Bounce Effect)          │    ║
║  │  ► Son yarıştan bu yana geçen gün sayısı analizi         │    ║
║  │  ► Yarış sıklığı = aşırı koşma cezası                   │    ║
║  │  ► Ağırlık: %6                                          │    ║
║  └─────────────────────────────────────────────────────────┘    ║
║                                                                  ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │  KATMAN 9: Koşu Temposu Senaryosu (Pace Scenario)       │    ║
║  │  ► Kaçak at sayısı → tempo tahmini                       │    ║
║  │  ► Bekleme vs Kaçak stil uyumu                           │    ║
║  │  ► Ağırlık: %5                                          │    ║
║  └─────────────────────────────────────────────────────────┘    ║
║                                                                  ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │  KATMAN 10: İstikrar ve Güvenilirlik                     │    ║
║  │  ► Derece standart sapması + sıralama tutarlılığı        │    ║
║  │  ► Varsayılan Ağırlık: %4                               │    ║
║  └─────────────────────────────────────────────────────────┘    ║
║                                                                  ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │  KATMAN 11: Pedigri / Kan Hattı Analizi 🧬 [YENİ]       │    ║
║  │  ► Babanın yavru performansı × pist × mesafe             │    ║
║  │  ► ⚡ DİNAMİK AĞIRLIK: %3 → %15 (veri azlığına göre)    │    ║
║  │  ► Az veri = pedigri çok önemli, çok veri = tamamlayıcı  │    ║
║  └─────────────────────────────────────────────────────────┘    ║
║                                                                  ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │  ▼▼▼ NİHAİ ÇIKTI ▼▼▼                                    │    ║
║  │  CANPS = Σ(Katman_i × DİNAMİK_Ağırlık_i) → 0-100 Skor  │    ║
║  │  Sıralama + Tahmin Etiketi + Güven Yüzdesi               │    ║
║  └─────────────────────────────────────────────────────────┘    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 📐 Her Katmanın Detaylı Matematik Formülü

### KATMAN 1: Normalize Edilmiş Hız Skoru (Speed Figure) — %22 (varsayılan)
> **En kritik katman.** Atın geçmişteki ham derecelerini anlamlı, karşılaştırılabilir bir puana çevirir.

**Mevcut Durum:** `calculate_degree_stats()` + `apply_class_factor_to_degrees()` ile basit normalizasyon yapılıyor.

**Hedef Formül:**
```
SpeedFigure(yarış) = HamDerece(sn) / ClassMultiplier / TrackConditionMultiplier

Burada:
  • ClassMultiplier = get_class_multiplier(raceType) → 0.96 - 1.10 arası [✅ MEVCUT]
  • TrackConditionMultiplier = Pist durumuna göre düzeltme:
      - Normal     → 1.00 (baz)
      - Sulu       → 0.98 (süre uzar, düzelt)
      - Islak      → 0.96
      - Ağır       → 0.93
      - Yumuşak    → 0.95

SpeedScore = Yarış grubundaki en iyi ortalama SpeedFigure'e göre göreceli skor (0-100)
```

**Yeni Hesaplanacak Veriler:**
- `trackConditionMultiplier`: Pist durumu verisi `trackCondition` alanından → `[✅ VERİ MEVCUT]`
- Aynı mesafeyedeki geçmiş yarışlara öncelik → `[✅ filteredRaces MEVCUT]`

---

### KATMAN 2: Mesafe Uygunluk Endeksi — %10 (varsayılan)
> At bu mesafede tecrübeli mi? Bu mesafede nasıl koşuyor?

**Formül:**
```
MesafeSkoru = f(hedef_mesafe_yarışları)

1. Hedef mesafe ± 200m toleranstaki geçmiş yarışları filtrele
2. Bu yarışlardaki ortalama sıralama → MesafeSıralamaSkoru
3. Bu yarışlardaki galibiyet oranı → MesafeGalibiyetBonus
4. Mesafe tecrübesi (kaç yarış koşmuş) → TecrübeÇarpanı
   - 0 yarış → 0.7 çarpan (veri yok cezası)
   - 1-2 yarış → 0.85
   - 3-4 yarış → 1.0
   - 5+ yarış → 1.1 (tecrübe bonusu)

MesafeEndeksi = (MesafeSıralamaSkoru × 0.6 + MesafeGalibiyetBonus × 0.4) × TecrübeÇarpanı
```

**Mevcut Durum:** `calculate_distance_suitability()` mevcut ama sadece sıralama bazlı. Derece bazlı hale getirilecek.

---

### KATMAN 3: Pist Uygunluk Endeksi — %10
> Çim mi, Kum mu? Normal mi, Ağır mı? At bu pistte nasıl performans gösteriyor?

**Formül:**
```
PistSkoru = f(hedef_pist_yarışları, pist_durumu)

1. Hedef pist tipindeki (Çim/Kum/Sentetik) geçmiş yarışları filtrele
2. Eğer pist durumu da biliniyorsa (Ağır, Islak vs.), o durumadaki yarışlara bonus ver
3. Bu yarışlardaki ortalama sıralama vs diğer pist tiplerindeki ortalama
4. Pist tipi deneyimi (kaç yarışmış) → TecrübeBonus

YENI: Pist durumu katmanı
  - Hedef pist durumu "Ağır" ise:
    - Geçmişte "Ağır" pistte koşmuş mu? → Deneyim bonusu
    - Orada nasıl koşmuş? → Ortalama performans
  - Hedef pist durumu "Normal" ise:
    - At "Normal" pistte daha mı iyi koşuyor? Karşılaştır
```

**Mevcut Durum:** `calculate_track_suitability()` mevcut. Pist durumu derinliği (Ağır/Islak) eklenmeli.

---

### KATMAN 4: Form ve Momentum — %11 (varsayılan)
> At yükselişte mi, düşüşte mi? Son yarışlar neler söylüyor?

**Formül:**
```
FormSkoru = f(son_5_yarış_trendi, derece_eğrisi)

1. Sıralama Trendi: Son 5 yarışın sıralamalarına lineer regresyon
   - Negatif slope = sıralama düşüyor = performans artıyor
   - trend_value = -slope

2. Derece Trendi: Son 5 yarışın sürelerine lineer regresyon
   - Negatif slope = süre düşüyor = hızlanıyor
   - degree_trend = -slope

3. Son Yarış Etkisi (recency bonus):
   - Son yarış 1. → +15 puan
   - Son yarış 2. → +10 puan
   - Son yarış 3. → +6 puan
   - Son yarış 4-5. → +2 puan

4. Momentum Çarpanı:
   - Üst üste 3 yarış iyileşme → 1.15x
   - Üst üste 3 yarış kötüleşme → 0.85x

FormSkoru = (SıralamaSkoru × 0.4 + DereceSkoru × 0.4 + SonYarışBonus × 0.2) × MomentumÇarpanı
```

**Mevcut Durum:** `calculate_form_trend()` ve trend/stability skorları mevcut. Momentum çarpanı ve son yarış etkisi eklenmeli.

---

### KATMAN 5: İdman Performansı — %10
> İdmanda ne yaptı? Yarıştaki sürelerine yakın mı? İdman zamanlaması ideal mi?

**Formül:**
```
İdmanSkoru = f(idman_projeksiyon, idman_zamanlama, idman_jokey)

1. İdman Projeksiyon Skoru:
   - İdman sürelerini yarış mesafesine genişlet (lineer projeksiyon)
   - Projeksiyonu atın kendi ortalama derece ile karşılaştır
   - Projeksiyon < Ortalama Derece → Hızlı İdman (+bonus)
   - Projeksiyon ≈ Ortalama Derece → Uyumlu İdman (nötr)
   - Projeksiyon > Ortalama Derece → Yavaş İdman (-ceza)

2. Zamanlama Skoru:
   - Yarışa 2-5 gün kala idman yapılmışsa → Mükemmel (+25)
   - 1-7 gün → İyi (+15)
   - 7-10 gün → Kabul Edilebilir (+5)
   - 10+ gün → Olumsuz (-10)

3. İdman Jokeyi Etkisi: [YENİ]
   - İdman jokeyi = yarış jokeyi → +5 bonus (tanışıklık)
   - İdman jokeyi ≠ yarış jokeyi → 0 (nötr)

İdmanSkoru = ProjeksiyonSkoru × 0.5 + ZamanlamaSkoru × 0.35 + JokeyBonus × 0.15
```

**Mevcut Durum:** `calculate_training_fitness()` ve `project_training_to_race_distance()` mevcut. `[✅ ÇALIŞIYOR]`

---

### KATMAN 6: Sıklet (Kilo) Performans Endeksi — %6 (varsayılan) [YENİ]
> Kilo değişimi mesafe uzadıkça daha önemli hale gelir.

**Formül:**
```
SıkletSkoru = f(kilo_değişimi, mesafe_etkileşimi)

1. Kilo Değişimi Hesapla:
   kilo_diff = bugünkü_kilo - son_yarış_kilosu

2. Mesafe Çarpanı (kilo etkisi mesafe uzadıkça artar):
   mesafe_carpani = 1.0 + (mesafe - 1200) / 2400
   Örnek: 1200m → 1.0, 1600m → 1.17, 2000m → 1.33, 2400m → 1.50

3. Kilo Etkisi:
   - Kilo düşmüş (kilo_diff < 0): +bonus (hafifleşmiş)
     etki = abs(kilo_diff) × 3 × mesafe_carpani
   - Kilo artmış (kilo_diff > 0): -ceza (ağırlaşmış)
     etki = kilo_diff × 4 × mesafe_carpani (ceza daha sert)
   - Kilo aynı: 0

4. AT'ın genel kilo performans profili:
   - Geçmiş yarışlardaki kilo-sıralama korelasyonu
   - Düşük kilolarda daha mı iyi koşuyor?

SıkletSkoru = 50 + etki (min 0, max 100)
```

**Mevcut Durum:** Kilo değişimi hesaplanıyor ve ekranda gösteriliyor ama skora dahil DEĞİL. → `[EKLENECEK]`

---

### KATMAN 7: Jokey Analizi — %7 (varsayılan) [GELİŞTİRİLECEK]
> Jokey-at uyumu, jokeyin hipodrom/mesafe başarısı ve jokey değişimi etkisi.

**Formül:**
```
JokeySkoru = f(jokey_at_uyum, jokey_değişimi, jokey_genel)

1. Jokey-At Uyum Skoru:
   - Bu jokeyle kaç yarış koşmuş? → uyum_sayısı
   - Bu jokeyle galibiyet oranı → uyum_galibiyet
   - JokeyAtUyum = uyum_galibiyet × min(uyum_sayısı/5, 1.0)

2. Jokey Değişim Etkisi:
   - Jokey değişti mi? Son yarıştaki jokey ≠ bugünkü jokey
   - Değiştiyse:
     - Yeni jokey daha iyi bir jokey mi? (genel istatistik)
     - Daha iyi jokey geldi → +10 bonus
     - Daha kötü jokey geldi → -5 ceza
     - Bilgi yok → 0 (nötr)

3. İdman Jokeyi = Yarış Jokeyi Bonusu:
   - Aynı jokey idmanı yaptı → +5 puan (ata alışık)

JokeySkoru = JokeyAtUyum × 0.5 + JokeyDeğişimEtkisi × 0.3 + İdmanJokeyBonus × 0.2
```

**Mevcut Durum:** Jokey istatistikleri hesaplanıyor, jokey değişimi tespit ediliyor ama skora sadece ekran bilgisi olarak yansıyor. → `[GELİŞTİRİLECEK]`

---

### KATMAN 8: Dinlenme & Kondisyon (Bounce Effect) — %6 [YENİ]
> Son yarıştan bu yana geçen süre: çok kısa = yorgun, çok uzun = pas tutmuş.

**Formül:**
```
DinlenmeSkoru = f(son_yarış_günü, yarış_sıklığı, son_yarış_efor)

1. Dinlenme Süresi Analizi:
   gün_farkı = bugün - son_yarış_tarihi

   İdeal aralıklar (İngiliz atlar için):
   - 14-28 gün → Mükemmel (100)
   - 10-13 gün → İyi (85)
   - 29-42 gün → Kabul Edilebilir (75)
   - 7-9 gün → Riskli (60) — çok kısa dinlenme
   - 43-60 gün → Uzun ara (55) — form kaybı riski
   - 61+ gün → Çok uzun ara (35) — ciddi form kaybı
   - 0-6 gün → Çok kısa (40) — fiziksel yorgunluk

   NOT: Arap atları için aralıklar biraz farklı olabilir (daha sık koşabilirler)

2. Bounce Effect (Sıçrama Etkisi):
   Eğer at son yarışında:
   - 1. bitirdiyse VE çok hızlı derece yaptıysa (kendi ortalamasının %3 altında)
     → bounce_ceza = -10 (pil bitmiş olma riski)
   - Son 30 günde 3+ yarış koşmuşsa
     → aşırı_koşma_ceza = -15

3. İlk Yarış:
   - At hayatında ilk kez koşuyorsa (maiden ilk koşu)
   - → maiden_first_penalty = -5 (bilinmezlik cezası, idman verisine daha çok ağırlık)

DinlenmeSkoru = DinlenmeSüreSkoru + BounceCeza + AşırıKoşmaCeza
```

**Mevcut Durum:** İdman zamanlaması var ama son yarıştan bu yana geçen gün hesaplanmıyor. → `[YENİ EKLENECEK]`

---

### KATMAN 9: Koşu Temposu Senaryosu (Pace Scenario) — %5 [YENİ-VİZYON]
> Yarıştaki atların profilleri (Kaçak/Bekleme) analiz edilerek tempo tahmini.

**Formül:**
```
TempoSkoru = f(at_stilleri, stil_uyumu)

1. Her At İçin Koşu Stili Belirleme:
   - Son 5 yarıştaki sıralama değişimlerinden stil çıkar:
     - Genelde ön sıralarda bitiyor + hızlı derece → "KAÇAK"
     - Genelde arkadan gelip ön sıralara yerleşiyor → "BEKLEME"
     - Orta sıralarda tutarak devam → "TAKİPÇİ"

   Early Speed Score (ESS) = Son 5 yarıştaki ağırlıklı sıralama
   - ESS > 75 → KAÇAK
   - 40 < ESS < 75 → TAKİPÇİ
   - ESS < 40 → BEKLEME

2. Yarış Tempo Tahmini:
   kaçak_sayısı = koşudaki KAÇAK profilli at sayısı
   
   - kaçak_sayısı >= 3 → SICAK TEMPO (Fast Pace)
     → Bekleme atlarına +15 bonus, Kaçak atlara -10 ceza
   - kaçak_sayısı == 1 → SOĞUK TEMPO (Slow Pace)
     → O tek Kaçak ata +15 bonus (tempoyu kontrol eder)
   - kaçak_sayısı == 0 → ÇOK SOĞUK TEMPO
     → Koçan/en iyi sıralamalı at +10 bonus (kimse çekmeyecek, o çeker)
   - kaçak_sayısı == 2 → NORMAL TEMPO
     → Nötr (±0)

TempoSkoru = 50 + tempo_ayarlaması_bonusu_veya_cezası
```

**Mevcut Durum:** `calculate_early_speed()` ve `calculate_late_kick()` fonksiyonları VAR ama AI Score'a dahil DEĞİL. → `[ENTEGRE EDİLECEK]`

---

### KATMAN 10: İstikrar ve Güvenilirlik — %4 (varsayılan)
> At ne kadar tutarlı? Her yarışta benzer performans mı veriyor, yoksa sürprizci mi?

**Formül:**
```
İstikrarSkoru = f(derece_std_dev, sıralama_std_dev)

1. Derece İstikrarı:
   std_dev = son 6 yarışın derecelerinin standart sapması
   - std_dev < 1.0 → Çok istikrarlı (90)
   - std_dev < 2.0 → İstikrarlı (75)
   - std_dev < 3.5 → Normal (55)
   - std_dev >= 3.5 → Değişken (35)

2. Sıralama İstikrarı:
   rank_std = son 6 yarışın sıralamalarının standart sapması
   - rank_std < 1.5 → Çok istikrarlı
   - rank_std < 3.0 → Normal
   - rank_std >= 3.0 → Sürprizci

İstikrarSkoru = Dereceİstikrarı × 0.6 + Sıralamaİstikrarı × 0.4
```

**Mevcut Durum:** `calculate_consistency()` ve `degreeStdDev` mevcut. → `[OPTİMİZE EDİLECEK]`

---

### KATMAN 11: Pedigri / Kan Hattı Analizi 🧬 — DİNAMİK AĞIRLIK (%3 → %15) [YENİ]
> Atın babası ve annesinin genetik profili. **Pist ve mesafe bazlı dinamik ağırlıkla** çalışır.

**Temel Felsefe:**
- At hakkında ne kadar az yarış verisi varsa → pedigri o kadar önemli
- At ilk kez bir pist tipinde koşuyorsa → babasının o pistteki yavru performansı TEK referans
- At tecrübeli ve o pistte çok koşmuşsa → pedigri sadece tamamlayıcı

**Pist Bazlı Dinamik Ağırlık Sistemi:**
```
PedigriAğırlık = f(hedef_pist_tecrübesi, hedef_mesafe_tecrübesi, toplam_yarış_sayısı)

1. Hedef Pist Tecrübesi Kontrolü:
   hedef_pistte_yarış_sayısı = at'ın Çim/Kum/Sentetik'te koştuğu yarış sayısı

   Eğer hedef_pistte_yarış_sayısı == 0:  → İLK KEZ BU PİSTTE
     pist_pedigri_ağırlık = 0.15 (%15)   → Max ağırlık!
     (Babanın bu pistteki yavru performansı TEK rehber)

   Eğer hedef_pistte_yarış_sayısı == 1-2:  → AZ TECRÜBELİ
     pist_pedigri_ağırlık = 0.10 (%10)
     (Hem az veri hem pedigri birlikte değerlendirilir)

   Eğer hedef_pistte_yarış_sayısı == 3-5:  → ORTA TECRÜBELİ
     pist_pedigri_ağırlık = 0.06 (%6)
     (Yeterli veri var ama pedigri hala değerli)

   Eğer hedef_pistte_yarış_sayısı > 5:    → TECRÜBELİ
     pist_pedigri_ağırlık = 0.03 (%3)
     (Kendi verisi yeterli, pedigri sadece bonus)

2. Mesafe Tecrübesi Kontrolü (Benzer mantık):
   hedef_mesafede_yarış_sayısı = at'ın ±200m toleransta koştuğu yarış sayısı

   Eğer hedef_mesafede_yarış_sayısı == 0:  → İLK KEZ BU MESAFEDE
     mesafe_pedigri_bonus = +0.05 (%5 ek ağırlık)
     (Babanın yavruları bu mesafede nasıl koşuyor? Kritik!)
     Özellikle sprint→uzun mesafe geçişlerinde çok önemli.

   Eğer hedef_mesafede_yarış_sayısı >= 3:  → MESAFE TECRÜBELİ
     mesafe_pedigri_bonus = 0

3. Nihai Pedigri Ağırlığı:
   pedigri_ağırlık = pist_pedigri_ağırlık + mesafe_pedigri_bonus
   pedigri_ağırlık = min(pedigri_ağırlık, 0.20)  → Max %20
   pedigri_ağırlık = max(pedigri_ağırlık, 0.03)  → Min %3
```

**Pedigri Skoru Hesaplama (İçerik):**
```
PedigriSkoru = f(baba_yavru_performansı, baba_pist_profili, baba_mesafe_profili)

1. Baba → Yavru Genel Performans Skoru:
   - TJK'dan babanın adını al
   - Babanın diğer yavrularının geçmiş yarışlarını topla
   - Ortalama sıralama, galibiyet oranı hesapla
   - Yüksek galibiyet oranı = yüksek pedigri skoru

2. Baba → Pist Profili:
   - Babanın yavrularının Çim vs Kum performans karşılaştırması
   - Hedef pist Çim ise ve babanın yavruları Çimde daha iyiyse → bonus
   - Hedef pist Kum ise ve babanın yavruları Kumda kötüyse → ceza

3. Baba → Mesafe Profili:
   - Babanın yavrularının mesafe bazlı performansı
   - Sprint babası mı (1000-1400m), Orta mesafe mi (1400-1800m), Uzun mu (1800+)?
   - Hedef mesafe ile uyum → bonus/ceza

4. İlk Koşu Bonusu:
   - At hayatında hiç koşmamışsa (Maiden ilk yarış):
     → Pedigri ağırlığı otomatik MAX (%15-20)
     → Çünkü tek referans genetik profil

PedigriSkoru = BabaGenelPrf × 0.40 + BabaPistPrf × 0.35 + BabaMesafePrf × 0.25
```

**Pratik Örnekler:**

| Senaryo | Pist Tecrübesi | Mesafe Tecrübesi | Pedigri Ağırlığı | Açıklama |
|---------|---------------|-----------------|-----------------|----------|
| At ilk kez Çim'e çıkıyor | 0 Çim yarışı | 3 yarış bu mesafede | **%15** | Babanın çim profili hayati |
| At ilk kez Çim + ilk kez 2400m | 0 Çim | 0 bu mesafede | **%20** (MAX) | Pedigri = tek rehber |
| At Kum'da 8 yarış koşmuş, Kum'da koşacak | 8 Kum yarışı | 5 yarış bu mesafede | **%3** (MIN) | Kendi verisi yeterli |
| Maiden ilk koşu | 0 | 0 | **%20** (MAX) | Hiç yarış tecrübesi yok |
| At 3 Çim + 5 Kum yarışı, Çim'de koşacak | 3 Çim | 2 yarış bu mesafede | **%6 + %5 = %11** | Orta tecrübe |

**Mevcut Durum:** Baba/Anne verisi `RunningHorse.father/mother` olarak ÇEKİLİYOR ama algoritmaya dahil DEĞİL. → `[YENİ EKLENECEK]`

**Gerekli Veri:**
- `RunningHorse.father` → ✅ Günlük program tablosundan alınıyor
- `RunningHorse.mother` → ✅ Günlük program tablosundan alınıyor
- Babanın yavru performansları → 🔸 TJK'dan çekilebilir (ek scraping gerekir)

---

## ⚡ Dinamik Ağırlık Sistemi (Ağırlık Neden SABİT Değil?)

> **Kritik İnovasyon:** Sabit ağırlıklı bir sistem, tüm atlara aynı formülü uygular.
> Ama gerçek hayatta bir maiden (ilk koşu) atıyla 50 yarışlık tecrübeli bir atı
> aynı ağırlıklarla değerlendirmek YANLIŞTIR.

### Felsefe
Her at için hangi verinin mevcut ve ne kadar güvenilir olduğuna bağlı olarak,
katman ağırlıkları **otomatik olarak yeniden dengelenir**.

**Temel Kural:** Veri yoksa → o katmanın ağırlığı düşer → diğer katmanlar ağırlık devralır.

### Dinamik Ağırlık Hesaplama Tablosu

```
┌──────────────────────────────────────────────────────────────────────────┐
│              DİNAMİK AĞIRLIK DEĞİŞİM SENARYOLARI                      │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│ SENARYO 1: Tecrübeli At (6+ yarış, aynı pist, aynı mesafe)            │
│ ─────────────────────────────────────────────────────────               │
│ Hız Skoru: %24   (↑ çok veri = güvenilir)                              │
│ Mesafe:    %11   (↑ tecrübeli)                                         │
│ Pist:      %10   (baz)                                                 │
│ Form:      %12   (↑ trend verisi bol)                                  │
│ İdman:     %10   (baz)                                                 │
│ Kilo:      %6    (baz)                                                 │
│ Jokey:     %7    (baz)                                                 │
│ Dinlenme:  %6    (baz)                                                 │
│ Tempo:     %5    (baz)                                                 │
│ İstikrar:  %5    (↑ std_dev güvenilir)                                 │
│ Pedigri:   %3    (↓ kendi verisi yeterli)                              │
│ TOPLAM:    %100 ✓  (Güven: 🟢 Yüksek)                                 │
│                                                                        │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│ SENARYO 2: İlk Kez Çim'e Çıkan At (5 Kum yarışı var)                  │
│ ─────────────────────────────────────────────────────                   │
│ Hız Skoru: %18   (↓ çim verisi yok, sadece kum)                        │
│ Mesafe:    %9    (baz)                                                 │
│ Pist:      %6    (↓ hedef pistte VERİ YOK)                             │
│ Form:      %10   (baz)                                                 │
│ İdman:     %12   (↑ idman verisi daha önemli)                          │
│ Kilo:      %6    (baz)                                                 │
│ Jokey:     %7    (baz)                                                 │
│ Dinlenme:  %6    (baz)                                                 │
│ Tempo:     %5    (baz)                                                 │
│ İstikrar:  %4    (baz)                                                 │
│ Pedigri:   %15   (↑↑↑ PATLADI — babanın çim profili TEK REHBER)        │
│ TOPLAM:    %100 ✓  (Güven: 🟡 Orta — pist değişimi riski)             │
│                                                                        │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│ SENARYO 3: Maiden İlk Koşu (Hiç yarış yok)                            │
│ ─────────────────────────────────────────────────────                   │
│ Hız Skoru: %0    (↓↓ VERİ YOK — devre dışı)                           │
│ Mesafe:    %0    (↓↓ VERİ YOK — devre dışı)                           │
│ Pist:      %0    (↓↓ VERİ YOK — devre dışı)                           │
│ Form:      %0    (↓↓ VERİ YOK — devre dışı)                           │
│ İdman:     %30   (↑↑↑ TEK GERÇEK VERİ KAYNAĞI)                        │
│ Kilo:      %5    (baz — genel kilo verisi)                             │
│ Jokey:     %10   (↑ jokey kalitesi çok önemli)                         │
│ Dinlenme:  %0    (↓↓ VERİ YOK)                                        │
│ Tempo:     %5    (baz)                                                 │
│ İstikrar:  %0    (↓↓ VERİ YOK)                                        │
│ Pedigri:   %20   (↑↑↑ MAX — genetik profil = TEK TAHMİN)              │
│               ├─ Baba pist profili                                     │
│               ├─ Baba mesafe profili                                   │
│               └─ Baba genel yavru başarısı                             │
│ AGF Oranı: %30  (↑↑↑ Piyasa beklentisi — veri yetersiz olduğunda)     │
│ TOPLAM:    %100 ✓  (Güven: 🔴 Düşük — veri çok az)                    │
│                                                                        │
└──────────────────────────────────────────────────────────────────────────┘
```

### Dinamik Ağırlık Yeniden Dengeleme Algoritması

```python
def calculate_dynamic_weights(horse_data, target_track, target_distance):
    """
    Her at için veri durumuna göre 11 katmanın ağırlıklarını dinamik hesaplar.
    Toplam her zaman 1.0 (%100) olmalıdır.
    """
    races = horse_data.get('races', [])
    total_races = len(races)
    
    # Hedef pistteki yarış sayısı
    track_races = len([r for r in races if target_track.lower() in r.get('track','').lower()])
    
    # Hedef mesafedeki yarış sayısı (±200m)
    target_dist = int(target_distance)
    dist_races = len([r for r in races 
                      if abs(int(r.get('distance','0')) - target_dist) <= 200])
    
    has_training = horse_data.get('trainingInfo', {}).get('hasData', False)
    
    # === VARSAYILAN AĞIRLIKLAR ===
    w = {
        'speed_figure':  0.22,
        'distance':      0.10,
        'track':         0.10,
        'form':          0.11,
        'training':      0.10,
        'weight':        0.06,
        'jockey':        0.07,
        'bounce':        0.06,
        'pace':          0.05,
        'consistency':   0.04,
        'pedigree':      0.03,  # Varsayılan MIN
    }
    
    # === PİST TECRÜBESİNE GÖRE PEDİGRİ AYARI ===
    if track_races == 0:
        pedigree_boost = 0.12  # İlk kez bu pistte → %3 + %12 = %15
    elif track_races <= 2:
        pedigree_boost = 0.07  # Az tecrübe → %10
    elif track_races <= 5:
        pedigree_boost = 0.03  # Orta → %6
    else:
        pedigree_boost = 0.00  # Tecrübeli → %3 kalsın
    
    # === MESAFE TECRÜBESİNE GÖRE EK AYAR ===
    if dist_races == 0:
        pedigree_boost += 0.05  # İlk kez bu mesafede → ek %5
    
    w['pedigree'] = min(0.20, w['pedigree'] + pedigree_boost)
    
    # === VERİ YOKLUĞU → KATMANLARI KAPAT, AĞIRLIĞI DAĞIT ===
    if total_races == 0:  # Maiden ilk koşu — yarış verisi 0
        w['speed_figure'] = 0
        w['distance'] = 0
        w['track'] = 0
        w['form'] = 0
        w['bounce'] = 0
        w['consistency'] = 0
        w['training'] = 0.30 if has_training else 0
        w['pedigree'] = 0.20
        w['jockey'] = 0.10
    
    elif total_races <= 2:  # Çok az yarış
        w['speed_figure'] *= 0.6   # Güvenilirliği düşük
        w['form'] *= 0.5
        w['consistency'] *= 0.3
        w['training'] *= 1.3 if has_training else 0.5
    
    # === İDMAN VERİSİ YOKSA ===
    if not has_training:
        redistributed = w['training']
        w['training'] = 0
        w['speed_figure'] += redistributed * 0.5  # Yarış derecesine aktar
        w['form'] += redistributed * 0.3
        w['pedigree'] += redistributed * 0.2
    
    # === TOPLAMI %100'E NORMALİZE ET ===
    total = sum(w.values())
    if total > 0:
        w = {k: v / total for k, v in w.items()}
    
    return w
```

### Veri Doluluk Kontrolü (Güven Metriği)
```
Her katman için veri var mı yok mu kontrol:
- Geçmiş yarış verisi var mı? (en az 3 yarış)
- İdman verisi var mı?
- Mesafe bazlı filtrelenmiş yarış var mı?
- Hedef pistte koşmuş mu?
- Pedigri verisi çekilebilmiş mi?
- Jokey istatistiği yeterli mi?

Veri doluluk yüzdesi (0-1 arası) = mevcut veri noktası / toplam veri noktası
- %80+ → "Yüksek Güven 🟢" — tahmin güvenilir
- %50-80 → "Orta Güven 🟡" — kısmi verilerle tahmin
- %50 altı → "Düşük Güven 🔴" — veri yetersiz, dikkatli ol
```

---

## 🏗️ UYGULAMA PLANI (FAZ BAZLI)

### ✅ TAMAMLANAN FAZLAR

| Faz | Açıklama | Durum |
|-----|----------|-------|
| Faz 1.1 | Mesafe Bazlı Yarış Geçmişi Çekme | ✅ Tamamlandı |
| Faz 1.2 | Derece Analiz Motoru | ✅ Tamamlandı |
| Faz 1.3 | Grup Bazlı Analiz | ✅ Tamamlandı |
| Faz 1.4 | Pist Durumu Analizi | ✅ Tamamlandı |
| Faz 1.5 | Frontend Yeniden Tasarım | ✅ Tamamlandı |
| Faz 2.1 | Son İdman Verisi Çekme | ✅ Tamamlandı |
| Faz 2.2 | İdman Projeksiyon | ✅ Tamamlandı |
| Faz 2.3 | Frontend İdman Kartı | ✅ Tamamlandı |
| Faz 3.1 | Class Factor (Grup Zorluk Çarpanı) | ✅ Tamamlandı |

---

### 🔴 FAZ 4 — MASTER ALGORİTMA (KALBİN İNŞASI)

> **Öncelik:** 🔴 EN YÜKSEK — Uygulamanın varlık sebebi  
> **Hedef:** 11 katmanlı dinamik ağırlıklı tahmin motorunun tam entegrasyonu  

#### Faz 4.1 — Pist Durumu Çarpanı (Track Condition Factor) ⭐
> `[ ]` Planlandı

**Amaç:** Mevcut Class Factor'e ek olarak, pist durumunu (Normal/Sulu/Islak/Ağır) da derece normalizasyonuna dahil etmek.

**Backend Değişiklikler:**
- `[ ]` `get_track_condition_multiplier(condition)` — Pist durumundan çarpan üreten yeni fonksiyon
- `[ ]` `apply_class_factor_to_degrees()` → pist durumu çarpanını da dahil edecek şekilde güncelleme
- `[ ]` `fetch_horse_details_safe()` → `trackCondition` verisini zaten çekiyor ✅

**Gerekli Veri:** `trackCondition` alanı (cells[3]) → Zaten parse ediliyor ✅

---

#### Faz 4.2 — Sıklet Performans Endeksi (Weight Impact) ⭐
> `[ ]` Planlandı

**Amaç:** Kilo değişimini mesafe ile etkileşim dahilinde AI Score'a dahil etmek.

**Backend Değişiklikler:**
- `[ ]` `calculate_weight_impact(current_weight, last_weight, target_distance)` — Yeni fonksiyon
- `[ ]` `calculate_ai_score()` → weight_impact parametresi ekleme

**Gerekli Veri:** `weight` → ✅ Hem koşu kartından hem geçmiş yarışlardan alınıyor

---

#### Faz 4.3 — Gelişmiş Jokey Analizi ⭐
> `[ ]` Planlandı

**Amaç:** Jokey-at uyumunu, jokey değişimini ve idman jokeyi faktörünü skora dahil etmek.

**Backend Değişiklikler:**
- `[ ]` `calculate_jockey_score(jockey_stats, jockey_changed, training_jockey, race_jockey)` — Yeni fonksiyon
- `[ ]` `calculate_ai_score()` → jockey_score parametresi ekleme

**Gerekli Veri:** 
- `jockey_stats` → ✅ Zaten hesaplanıyor
- `jockey_changed` → ✅ Zaten tespit ediliyor
- `trainingJockey` → ✅ İdman verisinden alınıyor

---

#### Faz 4.4 — Bounce Effect (Dinlenme Analizi) 🔥
> `[ ]` Planlandı

**Amaç:** Son yarıştan bu yana geçen gün sayısını ve yarış sıklığını AI Score'a dahil etmek.

**Backend Değişiklikler:**
- `[ ]` `calculate_bounce_score(races, current_date)` — Yeni fonksiyon
  - Son yarış tarihi → gün farkı hesaplama
  - Son 60 günde koşulan yarış sayısı → aşırı koşma kontrolü
  - Son yarış performansı → bounce riski
- `[ ]` `calculate_ai_score()` → bounce_score parametresi ekleme

**Gerekli Veri:** `race['date']` → ✅ Tüm geçmiş yarış tarihleri mevcut

---

#### Faz 4.5 — Koşu Temposu Senaryosu (Pace Simulation) 🧠
> `[ ]` Planlandı

**Amaç:** Yarıştaki tüm atları profillendirip (Kaçak/Bekleme/Takipçi), koşunun tempo senaryosuna göre bonus/ceza uygulamak.

**Backend Değişiklikler:**
- `[ ]` `determine_running_style(races)` — Atın koşu stilini belirle
- `[ ]` `calculate_pace_scenario(all_horses_styles)` — Koşu temposunu tahmin et
- `[ ]` `calculate_pace_score(horse_style, pace_scenario)` — Stile göre skor
- `[ ]` `analyze_race()` → İlk geçişte tüm atların stilleri belirlenir, ikinci geçişte pace scenario uygulanır

**Gerekli Veri:** 
- `early_speed` → ✅ Mevcut `calculate_early_speed()` fonksiyonu
- Atların geçmiş sıralamaları → ✅ Mevcut

**Önemli Not:** Bu katman, diğer katmanlardan farklı olarak **tek bir ata değil, koşudaki TÜM atlara** bağımlıdır. Önce tüm atların stilleri belirlenip, sonra koşu senaryosu çıkarılmalıdır.

---

#### Faz 4.6 — Pedigri / Kan Hattı Analizi 🧬 [TAMAMLANDI ✅]
> `[x]` Tamamlandı — 19 Nisan 2026

**Amaç:** Babanın yavru performanslarını TJK'dan çekip, pist × mesafe bazlı dinamik ağırlıklı pedigri skoru üretmek.

**Backend Değişiklikler:**
- `[ ]` `fetch_sire_offspring_stats(sire_name)` — Babanın yavrularının performanslarını TJK'dan çek
  - Babanın adıyla TJK arama → yavru listesi → geçmiş yarışları topla
  - Pist bazlı galibiyet oranı (Çim vs Kum vs Sentetik)
  - Mesafe bazlı ortalama sıralama (Sprint vs Uzun)
- `[ ]` `calculate_pedigree_score(sire_stats, target_track, target_distance)` — Pedigri skoru (0-100)
- `[ ]` `calculate_dynamic_weights(horse_data, target_track, target_distance)` — Dinamik ağırlık hesaplayıcı

**Gerekli Veri:**
- `RunningHorse.father` → ✅ Zaten çekiliyor
- `RunningHorse.mother` → ✅ Zaten çekiliyor
- Babanın yavru listesi → 🔸 TJK arama ile çekilecek (ek istek gerekir)

**Performans Notu:** Babanın yavru verilerini her analiz için tekrar çekmek yavaş olabilir → Basit bir cache mekanizması (dict) kullanılacak.

---

#### Faz 4.7 — Master `calculate_ai_score()` Yeniden Yazımı 🔴
> `[ ]` Planlandı — Bu adım tüm Faz 4.x'lerin tamamlanmasını bekler

**Amaç:** Mevcut basit ağırlıklı ortalama sistemini, 11-katmanlı dinamik ağırlıklı Master Tahmin Motoruyla değiştirmek.

**Backend Değişiklikler:**
- `[ ]` `calculate_master_score(metrics, dynamic_weights)` — Yeni 11 katmanlı hesaplama
- `[ ]` `generate_prediction()` → Güncel tahmin etiketleri
- `[ ]` `generate_insight()` → Daha zengin, veri-destekli insight'lar
- `[ ]` Güven Yüzdesi (data completeness) hesaplama
- `[ ]` `analyze_race()` → 2-pass mimari: 1) veri toplama + stil + pedigri, 2) dinamik ağırlık + skor

---

#### Faz 4.8 — Frontend Master Algoritma Entegrasyonu 🎨
> `[ ]` Planlandı — Backend tamamlandıktan sonra

**Amaç:** 11-katmanlı dinamik ağırlıklı skor verilerini kullanıcıya zengin, anlaşılır bir UI ile sunmak.

**Frontend Değişiklikler:**
- `[ ]` Güven Metriği (🟢🟡🔴) badge'i per at
- `[ ]` Katman bazlı skor breakdown'u (genişleyebilir kart)
- `[ ]` Pedigri bilgi kartı (baba profili, pist/mesafe uyumu)
- `[ ]` Dinamik ağırlık gösterimi (hangi katmana neden kaç % verildi)
- `[ ]` Koşu Tempo Senaryosu özeti (yarış seviyesinde)
- `[ ]` Bounce/Dinlenme uyarı ikonları
- `[ ]` Tahmin etiketi ve yüzdesel olasılık

---

## 📊 Master Algoritma İlerleme Özeti

| Faz | Alt Faz | Katman | Durum | Açıklama |
|-----|---------|--------|-------|----------|
| ✅ 1-3 | — | — | `[x]` | Temel altyapı (derece, idman, class factor) |
| ✅ 4 | 4.1 | K1 | `[x]` | Pist Durumu Çarpanı `get_track_condition_multiplier()` ✅ |
| ✅ 4 | 4.2 | K6 | `[x]` | Sıklet Performans Endeksi `calculate_weight_impact()` ✅ |
| ✅ 4 | 4.3 | K7 | `[x]` | Gelişmiş Jokey Analizi `calculate_jockey_score()` ✅ |
| ✅ 4 | 4.4 | K8 | `[x]` | Bounce Effect / Dinlenme `calculate_bounce_score()` ✅ |
| ✅ 4 | 4.5 | K9 | `[x]` | Koşu Temposu Senaryosu `determine_running_style()` + `calculate_pace_scenario()` ✅ |
| ✅ 4 | 4.6 | K11 | `[x]` | 🧬 Pedigri / Kan Hattı Analizi ✅ |
| ✅ 4 | 4.7 | TÜMÜ | `[x]` | Master Score + Dinamik Ağırlık Yeniden Yazımı ✅ |
| ✅ 4 | 4.8 | — | `[x]` | Frontend Entegrasyonu ✅ |

---

## ⚙️ Etkilenen Dosyalar

### Backend
| Dosya | Değişiklik | Faz |
|-------|-----------|-----|
| `api_server.py` → `get_track_condition_multiplier()` | ✅ Yeni | 4.1 |
| `api_server.py` → `apply_class_factor_to_degrees()` | ♻️ Güncelleme | 4.1 |
| `api_server.py` → `calculate_weight_impact()` | ✅ Yeni | 4.2 |
| `api_server.py` → `calculate_jockey_score()` | ✅ Yeni | 4.3 |
| `api_server.py` → `calculate_bounce_score()` | ✅ Yeni | 4.4 |
| `api_server.py` → `determine_running_style()` | ✅ Yeni | 4.5 |
| `api_server.py` → `calculate_pace_scenario()` | ✅ Yeni | 4.5 |
| `api_server.py` → `fetch_sire_offspring_stats()` | ✅ Yeni | 4.6 |
| `api_server.py` → `calculate_pedigree_score()` | ✅ Yeni | 4.6 |
| `api_server.py` → `calculate_dynamic_weights()` | ✅ Yeni (kritik) | 4.7 |
| `api_server.py` → `calculate_master_score()` | ✅ Yeni (ana fonksiyon) | 4.7 |
| `api_server.py` → `analyze_race()` | ♻️ Büyük Güncelleme | 4.7 |

### Frontend
| Dosya | Değişiklik | Faz |
|-------|-----------|-----|
| `lib/screens/race_analysis_screen.dart` | ♻️ UI Güncelleme | 4.8 |
| `lib/widgets/` → Yeni widget'lar | ✅ Yeni | 4.8 |

---

## 📌 Kritik Kurallar

1. **Veri önce, skor sonra.** Hiçbir katman veri olmadan skor üretmez — varsayılan 50 (nötr) ile devam eder.
2. **Göreceli normalizasyon.** Tüm skorlar koşu içindeki atlar arasında göreceli olarak normalize edilir. 100 = koşudaki en iyi, 0 = koşudaki en kötü.
3. **Backend önce, Frontend sonra.** Her faz önce backend'de tamamlanır, test edilir, sonra frontend'e yansıtılır.
4. **Geriye uyumluluk.** Yeni master skor, mevcut API response yapısını bozmaz — yeni alanlar olarak eklenir.
5. **Faz sırası korunur.** 4.1 → 4.2 → 4.3 → 4.4 → 4.5 → 4.6 (Pedigri) → 4.7 (Master + Dinamik Ağırlık) → 4.8 (Frontend).
6. **Her katman bağımsız test edilir.** Her yeni fonksiyon ayrı ayrı doğrulanır.
7. **Dinamik ağırlıklar toplam 1.0 (=%100).** Bir katmanın ağırlığı artarsa diğerleri otomatik düşer.

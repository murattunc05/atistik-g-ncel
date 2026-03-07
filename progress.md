# 🏇 Atistik v2.0 — Büyük Güncelleme İlerleme Planı

> **Başlangıç Tarihi:** 05 Mart 2026  
> **Durum:** ✅ Faz 1 Tamamlandı — Faz 2.1 Tamamlandı — Faz 2.2 Tamamlandı — Faz 2.3 Tamamlandı

---

## 📋 Güncelleme Özeti

Bu güncelleme ile uygulamanın analiz motoru baştan aşağı değiştirilecektir. **Atın sıralaması** yerine **derecesi** (koşu süresi) temel metrik haline gelecektir. Ayrıca mesafe bazlı filtreleme, pist durumu analizi ve idman verisi genişletme gibi kritik yenilikler eklenecektir.

---

## 🔴 FAZ 1 — Yarış Derecesi Sistemi (KRİTİK)

> **Öncelik:** En yüksek — Bu faz tamamlanmadan Faz 2'ye geçilmeyecektir.  
> **Durum:** `[x]` Tamamlandı

Bu faz, uygulamanın tüm analiz motorunu **sıralama bazlı** sistemden **derece (süre) bazlı** sisteme geçirecektir.

### Faz 1.1 — Mesafe Bazlı Yarış Geçmişi Çekme
> `[x]` Tamamlandı

**Amaç:** Gelecek koşunun mesafesine göre (örn: 2000m) atın **sadece o mesafedeki** geçmiş yarışlarını çekmek.

#### Backend Değişiklikler:
- `[x]` `api_server.py` → `fetch_horse_details_safe()` fonksiyonunu yeniden yaz:
  - Son 5 yarış sınırını kaldır → **Tüm yarış geçmişini** çek
  - `target_distance` parametresi ekle
  - Sadece eşleşen mesafedeki yarışları filtrele ve döndür
  - Her yarış için **derece (süre)** verisini zorunlu olarak al
- `[x]` Yeni endpoint veya mevcut `/api/analyze-race` endpoint'ini güncelle:
  - İstek gövdesinden `targetDistance` oku
  - Bu mesafeye göre filtreleme yap

#### Frontend Değişiklikler:
- `[x]` `race_analysis_screen.dart` → Analiz isteğinde `targetDistance` bilgisini backend'e gönder
- `[x]` Analiz sonuçlarında derece (süre) bilgisini göster (sıralama yerine)

#### Veri Yapısı:
```
Yarış Verisi (her at için):
{
  "horseName": "BOLD PILOT",
  "targetDistance": 2000,
  "filteredRaces": [
    {
      "date": "15.02.2026",
      "distance": 2000,
      "degree": "2.05.34",        // ← TEMEL VERİ: 2 dk 5 sn 34 salise
      "degreeInSeconds": 125.34,   // ← Hesaplanmış saniye değeri
      "group": "Maiden",           // ← Grup bilgisi
      "track": "Kum",             // ← Pist tipi
      "trackCondition": "Normal",  // ← Pist durumu
      "city": "İstanbul"
    },
    ...
  ],
  "stats": {
    "avgDegree": 126.50,           // Ortalama derece (saniye)
    "bestDegree": 124.12,          // En iyi derece (saniye)
    "worstDegree": 129.80,         // En kötü derece (saniye)
    "raceCount": 8,                // Bu mesafede kaç yarış koşmuş
    "avgDegreeFormatted": "2.06.50",
    "bestDegreeFormatted": "2.04.12"
  }
}
```

---

### Faz 1.2 — Derece Analiz Motoru
> `[x]` Tamamlandı

**Amaç:** Her at için mesafe bazlı derece istatistiklerini hesaplamak.

#### Backend Değişiklikler:
- `[x]` Yeni fonksiyon: `calculate_degree_stats(races, target_distance)`
  - Ortalama derece (saniye cinsinden)
  - En iyi derece
  - En kötü derece
  - Derece trendi (son yarışlara doğru iyileşme/kötüleşme)
  - Standart sapma (istikrar)
- `[x]` `calculate_seconds()` fonksiyonunu iyileştir — daha sağlam parse
- `[x]` Mevcut `calculate_ai_score()` fonksiyonunu güncelle:
  - **Sıralama bazlı** metrikleri kaldır veya ağırlığını düşür
  - **Derece bazlı** metrikleri ana metrik yap

#### Yeni Skorlama Ağırlıkları:
| Metrik | Eski Ağırlık | Yeni Ağırlık |
|--------|-------------|-------------|
| Derece (süre) ortalaması | ❌ Yok | **%35** |
| Derece trendi | ❌ Yok | **%15** |
| Derece istikrarı | ❌ Yok | **%10** |
| İdman fitness | %10 | %15 |
| Pist uyumu | %15 | %10 |
| Form trend | %15 | %10 |
| Mesafe uygunluğu | %15 | **%5** (artık direkt filtre) |
| Early Speed | %15 | ❌ Kaldır |
| Late Kick | %15 | ❌ Kaldır |

---

### Faz 1.3 — Grup Bazlı Analiz
> `[x]` Tamamlandı

**Amaç:** Atın bu mesafedeki derecelerini hangi grup koşularında yaptığını analiz etmek.

#### Backend Değişiklikler:
- `[x]` Yarış verisi çekerken **grup bilgisini** (Maiden, Şartlı, Handikap vb.) al
  - TJK HTML tablosundan grup sütununu parse et
- `[x]` `filteredRaces` içine `group` alanı ekle
- `[x]` Grup bazlı derece karşılaştırması yap:
  - Maiden yarışındaki derece vs Şartlı yarışındaki derece
  - Daha zor gruplarda benzer dereceyi yapmak daha değerli

---

### Faz 1.4 — Pist Durumu Analizi
> `[x]` Tamamlandı

**Amaç:** Atın derecelerini pist durumuna göre sınıflandırmak.

#### Pist Durumu Kategorileri:
| Pist Tipi | Durumlar |
|-----------|----------|
| **Kum** | Sulu, Islak, Nemli, Normal |
| **Çim** | Çok Ağır, Ağır, Yumuşak, Normal, Sert |
| **Sentetik** | (Tek kategori) |

#### Backend Değişiklikler:
- `[x]` Yarış verisi çekerken **pist tipi** ve **pist durumu** bilgisini ayrı ayrı al
- `[x]` `filteredRaces` içine `track` (Kum/Çim/Sentetik) ve `trackCondition` (Sulu/Normal vb.) alanları ekle
- `[x]` Mevcut `calculate_track_suitability()` fonksiyonunu tamamen yeniden yaz:
  - Pist durumuna göre derece normalizasyonu yap
  - Örn: Islak kumda 2.08 = Normal kumda ~2.05 gibi bir katsayı sistemi

#### Frontend Değişiklikler:
- `[x]` Pist durumu bilgisini analiz sonuçlarında göster
- `[ ]` Filtreleme opsiyonu ekle (sadece kum yarışları, sadece çim yarışları vb.)

---

### Faz 1.5 — Frontend Yeniden Tasarım (Derece Bazlı)
> `[x]` Tamamlandı

**Amaç:** Tüm analiz ekranlarını derece bazlı sisteme uyumlu hale getirmek.

#### Frontend Değişiklikler:
- `[x]` `race_analysis_screen.dart` → Derece bazlı yeni UI:
  - Sıralama yerine derece bilgisi göster
  - Mesafe bazlı filtrelenmiş yarış listesi
  - Ortalama / En iyi / En kötü derece kartları
  - Grup ve pist bazlı alt istatistikler
- `[x]` **UI Yeniden Tasarım:** Genişleyen kart → Bottom sheet popup (sekmeli: Yarışlar / İstatistikler)
- `[ ]` `models/` → Yeni model sınıfları:
  - `DegreeAnalysisModel` — Derece istatistikleri
  - Mevcut modeli güncelle veya genişlet
- `[ ]` `services/` → API servislerini güncelle:
  - Yeni veri yapısına uyumlu hale getir

---

## 🟡 FAZ 2 — İdman İstatistiği (Faz 1 Tamamlandıktan Sonra)

> **Öncelik:** Yüksek — Faz 1 tamamlandıktan sonra başlanacak  
> **Durum:** `[/]` Devam Ediyor

### Faz 2.1 — Son İdman Verisi Çekme
> `[x]` Tamamlandı

**Amaç:** Sadece son idman verisini çekmek (son idman jokeyi dahil).

#### Backend Değişiklikler:
- `[x]` `fetch_training_data_by_race_id()` fonksiyonu zaten son idman verisini döndürüyor (değişiklik gerekmedi)
- `[x]` `calculate_training_fitness()` fonksiyonuna `best_distance` return değeri eklendi
- `[x]` `trainingInfo` çıktısına `bestTrainingTime`, `bestTrainingDistance`, `bestTrainingTimeSeconds` eklendi
- `[x]` İdman jokeyi bilgisi chip olarak dahil edildi

---

### Faz 2.2 — İdman Derece Genişletme (Mesafe Bazlı Projeksiyon)
> `[x]` Tamamlandı

**Amaç:** İdman verisini yarış mesafesine oranlayarak tahmini yarış derecesi hesaplamak.

#### Hesaplama Mantığı:
```
Örnek:
- Gelecek koşu mesafesi: 2000m
- İdman verisi: 500m'de 45 saniye
- Hesaplama: (2000 / 500) × 45 = 180 saniye = 3 dakika
- Projeksiyon derecesi: "3.00.00"
```

#### Backend Değişiklikler:
- `[x]` Yeni fonksiyon: `project_training_to_race_distance(training_data, target_distance)`
  - İdman mesafesini ve süresini al
  - Hedef yarış mesafesine lineer olarak genişlet
  - ⚠️ **Not:** Lineer genişletme basit bir yaklaşımdır; uzun mesafelerde tempodaki düşüşü hesaba katacak bir katsayı (mesafe düzeltme faktörü) eklenebilir
- `[x]` Bu projeksiyon derecesini Faz 1’deki yarış dereceleri ile karşılaştır:
  - İdman projeksiyon derecesi vs Yarış ortalaması → Form durumu tahmini

#### Frontend Değişiklikler:
- `[x]` İdman projeksiyon derecesini analiz ekranında göster
- `[x]` Yarış derecesi ortalaması ile karşılaştırma widgetı

---

### Faz 2.3 — Frontend İdman Kartı Yeniden Tasarım
> `[x]` Tamamlandı

- `[x]` İdman bilgisi kartını güncelle:
  - Son idman tarihi, jokeyi, pist durumu
  - İdman derecesi ve mesafe bazlı projeksiyon
  - Yarış ortalaması ile görsel karşılaştırma (progress bar veya chart)

---

## 📊 İlerleme Özeti

| Faz | Alt Faz | Durum | Açıklama |
|-----|---------|-------|----------|
| 🔴 1 | 1.1 | `[x]` | Mesafe bazlı yarış geçmişi çekme |
| 🔴 1 | 1.2 | `[x]` | Derece analiz motoru |
| 🔴 1 | 1.3 | `[x]` | Grup bazlı analiz |
| 🔴 1 | 1.4 | `[x]` | Pist durumu analizi |
| 🔴 1 | 1.5 | `[x]` | Frontend yeniden tasarım |
| 🟡 2 | 2.1 | `[x]` | Son idman verisi çekme |
| 🟡 2 | 2.2 | `[x]` | İdman derece genişletme |
| 🟡 2 | 2.3 | `[x]` | Frontend idman kartı |

---

## ⚙️ Etkilenen Dosyalar

### Backend
| Dosya | Değişiklik Tipi | Faz |
|-------|----------------|-----|
| `api_server.py` → `fetch_horse_details_safe()` | ♻️ Yeniden Yazım | 1.1 |
| `api_server.py` → `analyze_race()` | ♻️ Yeniden Yazım | 1.2 |
| `api_server.py` → `calculate_ai_score()` | ♻️ Yeniden Yazım | 1.2 |
| `api_server.py` → `calculate_track_suitability()` | ♻️ Yeniden Yazım | 1.4 |
| `api_server.py` → `calculate_early_speed()` | ❌ Kaldır | 1.2 |
| `api_server.py` → `calculate_late_kick()` | ❌ Kaldır | 1.2 |
| `api_server.py` → Yeni: `calculate_degree_stats()` | ✅ Yeni | 1.2 |
| `api_server.py` → Yeni: `project_training_to_race_distance()` | ✅ Yeni | 2.2 |
| `api_server.py` → `fetch_training_data_by_race_id()` | ♻️ Güncelle | 2.1 |
| `prediction_logic.py` | ♻️ Yeniden Yazım | 1.2 |

### Frontend
| Dosya | Değişiklik Tipi | Faz |
|-------|----------------|-----|
| `lib/screens/race_analysis_screen.dart` | ♻️ Yeniden Yazım | 1.5, 2.3 |
| `lib/models/` → yeni model dosyaları | ✅ Yeni | 1.5 |
| `lib/services/` → API servis güncellemeleri | ♻️ Güncelle | 1.5, 2.3 |
| `lib/widgets/` → yeni derece widgetları | ✅ Yeni | 1.5 |

---

## 📌 Önemli Kurallar

1. **Faz 1 tamamlanmadan Faz 2'ye geçilmez.**
2. **Her alt faz bittiğinde test edilir ve onaylanır.**
3. **Backend değişiklikleri frontend'den önce yapılır** (her alt faz içinde).
4. **Mevcut fonksiyonellik korunur** — yeni sistem paralel olarak eklenir, eskisi kademeli olarak kaldırılır.
5. **Mesafe filtrelemesinde tüm yarışlar dahil edilir** — derece verisi olmasa bile mesafe eşleşen yarışlar gösterilir.

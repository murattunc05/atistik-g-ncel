# FAZ 6 — Algoritma İyileştirme Yol Haritası
> Oluşturulma: 20.04.2026
> Sonraki Test: 22.04.2026 İstanbul Koşuları

## Mevcut Durum
- İlk test: 20.04.2026 Bursa — 5 koşuda 2 kazanan bilindi (%40)
- FAZ 6.1 uygulandı: HP ters formül, recency-weighted derece, form trend ağırlık artışı
- Render'a deploy edildi ✅

## 22 Nisan Test Sonrasına Göre Yol Haritası

### Seviye 1: Hızlı Kalibrasyon (oran %40-50 arası kalırsa)
- Softmax temperature: 12.0 → 16-20 arası test
- Koşu tipine özel ağırlıklar (Maiden vs Şartlı vs Handikap ayrı ağırlık seti)
- Form trend ve derece ağırlıklarında ince ayar

### Seviye 2: Yeni Veri Katmanları (oran %50'nin altında kalırsa)
- K13: Antrenör win-rate katmanı (TJK'dan son 6 ay)
- AGF (ganyan) verilerini yeni katman olarak entegre et
- Koşu sınıfı × HP etkileşim fonksiyonunu geliştir

### Seviye 3: Makine Öğrenmesi (kalıcı çözüm)
- Son 6 ayın TJK yarış sonuçlarını backtesting dataset olarak çek
- 12 metriği feature olarak kullanarak XGBoost/LightGBM eğit
- Rule-based skor + ML skoru %60/%40 blend
- Otomatik ağırlık optimizasyonu (elle ayar döngüsünden çıkış)

## Hedefler
| Aşama | Hedef İsabet | Zaman |
|-------|-------------|-------|
| FAZ 6.1 (şu an) | %50+ | ✅ Deploy edildi |
| Seviye 1 | %55 | 1 gün |
| Seviye 2 (AGF) | %60 | 2-3 gün |
| Seviye 3 (ML) | %60-65 | 1 hafta |

> Not: Sektör ortalaması %20-25 civarı. %50+ zaten çok iyi.

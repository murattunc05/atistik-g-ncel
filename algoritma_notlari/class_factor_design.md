# 🏆 Sınıf/Grup Zorluk Çarpanı (Class Factor) — Tasarım Dokümanı

> **Tarih:** 11 Mart 2026
> **Durum:** Faz 3.1 — Geliştirme

---

## Problem

Atın geçmiş yarış derecesi (`2.05.34`) tek başına bir anlam ifade etmez. Bu dereceyi **hangi sınıf/grup yarışında** yaptığı, o derecenin gerçek değerini belirler.

**Örnek:**
- **At A:** Maiden yarışında (acemi atlar) `2.05` koştu → Rakipleri zayıf, zorluk düşük
- **At B:** KV-8 yarışında (elit seviye) `2.05` koştu → Rakipleri çok güçlü, zorluk yüksek

Bu iki `2.05`, aynı derece olmasına rağmen **eşit değildir**. At B'nin derecesi çok daha değerlidir.

---

## TJK Grup Hiyerarşisi

TJK'nın yarış sınıflandırma sistemi aşağıdan yukarıya şöyledir:

| Sıra | Grup Adı | Açıklama | Zorluk |
|------|----------|----------|--------|
| 1 | **Maiden** | İlk kez kazanacak atlar | En düşük |
| 2 | **Şartlı (Ş-1, Ş-2, Ş-3...)** | Belirli kazanç sınırındaki atlar | Düşük-Orta |
| 3 | **Handikap** | Kilo farkıyla dengelenen, karışık seviye | Orta |
| 4 | **Kısa Vade (KV-5, KV-6, KV-7, KV-8)** | Yüksek kazançlı, deneyimli atlar | Yüksek |
| 5 | **Açık / Grup (G1, G2, G3)** | En seçkin atlar, en prestijli yarışlar | En yüksek |

---

## Çarpan Sistemi

### Temel Formül

```
Ayarlanmış Derece (saniye) = Ham Derece / Class Multiplier
```

**Mantık:** Daha zorlu grup yarışlarında elde edilen dereceler, çarpan sayesinde "daha hızlı" olarak normalize edilir.

### Çarpan Tablosu

| Grup | Multiplier | Etki | Örnek: 2.05 (125s) |
|------|-----------|------|---------------------|
| Maiden | 0.96 | Dereceyi "yavaşlatır" | → 130.2s (2.10.2) |
| Şartlı (1-3) | 1.00 | Baz seviye (değişmez) | → 125.0s (2.05.0) |
| Handikap | 1.02 | Hafif bonus | → 122.5s (2.02.5) |
| KV (5-8) | 1.05 | Kayda değer bonus | → 119.0s (1.59.0) |
| Açık/Grup (G1-3) | 1.10 | Maksimum bonus | → 113.6s (1.53.6) |

### Alt-Grup Ayrıntıları

Şartlı ve KV yarışları kendi içinde numaralandırılır. Numara büyüdükçe zorluk artar:

```python
# Şartlı alt grupları
"Ş-1" / "Şartlı 1"  → 0.98
"Ş-2" / "Şartlı 2"  → 1.00  (baz seviye)
"Ş-3" / "Şartlı 3"  → 1.01
"Ş-4" / "Şartlı 4"  → 1.02

# KV alt grupları
"KV-5"  → 1.04
"KV-6"  → 1.05
"KV-7"  → 1.06
"KV-8"  → 1.08
```

---

## Kullanım Yeri

### Derece İstatistiklerinde (Mevcut `calculate_degree_stats`)
Class factor **derece hesaplanmadan önce** uygulanır:

```
1. At'ın filtrelenmiş yarış listesini al
2. Her yarış için grup bilgisini oku → çarpanı bul
3. Ayarlanmış derece = ham_derece / çarpan
4. İstatistikleri (ortalama, best, trend) ayarlanmış dereceler üzerinden hesapla
```

### AI Score'da
Class factor'ün AI Score'a etkisi dolaylıdır:
- Ayarlanmış derece ortalaması → `degreeScore` → %35 ağırlıklı AI Score
- Yani zor grupta iyi derece yapan at otomatik olarak daha yüksek AI Score alır

---

## Gelecek Geliştirmeler

### Faz 3.2 — Kilo Performans Endeksi
Sıklet değişimini mesafe ile birlikte puana çevirme. 2400m'de +2kg = ciddi ceza.

### Faz 3.3 — Pist Hız İndeksi (Track Variant)
Aynı gündeki diğer yarışların dereceleriyle pistin hız katsayısını hesaplama.

### Faz 3.4 — Koşu Temposu Senaryosu (Pace Simulator)
Koşudaki atların profillerini (kaçak/bekleme) analiz edip yarış senaryo tahmini üretme.

### Faz 3.5 — Bounce Effect (Dinlenme Cezası)
Son yarıştan bu yana geçen süreyi AI Score'a dahil etme. Çok sık koşan at = yorgun, çok nadir koşan at = uyumsuz.

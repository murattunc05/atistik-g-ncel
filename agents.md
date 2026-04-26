# Atistik: Proje Rehberi (agents.md)

## Proje Hakkında
"Atistik", yarış atı istatistikleri, analizleri ve tahminlerine odaklanan, kullanıcıların atları ve yarışları inceleyip karşılaştırabileceği bir mobil uygulamadır. Gerekli veriler, Python tabanlı bir backend servisi aracılığıyla çekilmekte ve Flutter tabanlı mobil uygulama ile kullanıcılara sunulmaktadır.

### Temel Özellikler:
- Günlük koşuların listesi ve detayları
- At bazlı geçmiş performanslar ve idman (antrenman) verileri bilgileri
- Puanlama algoritması ve tahmin yeteneği (`prediction_logic.py`)
- Kapsamlı koşu analizleri ve detaylı arama (At, Jokey, Yarış)

---

## Dosya ve Dizin Yapısı

Proje temel olarak iki ana bölüme ayrılmıştır: **Frontend (Flutter)** ve **Backend (Python)**.

### 1. Frontend (Flutter/Dart)
Projenin mobil arayüzü `lib/` klasörü içerisinde yer almaktadır.
- `lib/screens/`: Ana gezinme ve görünüm sayfalarını içerir (`home_screen.dart`, `race_detail_screen.dart`, `horse_detail_screen.dart`, `comparison_screen.dart` vb.).
- `lib/widgets/`: Sayfalar içinde tekrar kullanılabilir UI yapıtaşlarıdır.
- `lib/services/`: Backend ile iletişim kuran API istek servisleridir.
- `lib/models/`: Sunucudan gelen JSON formatındaki veri model sınıflarını (Dart Class) barındırır.
- `lib/utils/` ve `lib/theme/`: Genel fonksiyonlar, string formatlayıcılar ve tasarım renk temalarını içerir.

### 2. Backend (Python/Flask)
Sunucu tarafı `backend-deploy/` ve root dizininde yer alan `.py` dosyalarında konumlanır.
- `api_server.py`: Uygulamanın API uç noktalarını sağlayan ana Flask API dosyasıdır.
- `prediction_logic.py`: Atların kazanma ihtimallerini analiz eden, tahmin skorlamalarının yapıldığı mantık dosyasıdır.
- `requirements.txt`: Python uygulama bağımlılıkları (BeautifulSoup4, requests, pandas, numpy, Flask).
- `check_tjk_data.py`, `explore_tjk.py` vb: Muhtemelen TJK verilerini çekmek veya yapısını doğrulamak için kullanılan helper/deneme scriptleridir.

---

## Kod Yazım Rehberi ve Standartlar

### Frontend (Flutter)
- **Modüler Mimari:** İlgili sayfayı (Screen) olabildiğince temiz tutmak adına yapılar karmaşıklaştığında, küçük görsel öğeleri `widgets/` altına parçalayın. 
- **Veri Yükleme ve Hata Kontrolü:** Uygulamada veriyi doğrudan ekrana basmadan önce daima null/yükleniyor (loading)/hata kontrollerini (try-catch, state) ekleyiniz. 
- **Modern Görsellik:** Standart tasarımlardan ziyade gölgeler, yumuşak kenarlar, akıcı geçişler ve Premium renk paketleri ile dinamik bir kullanıcı deneyimi sunmaya özen gösterin.

### Backend (Python)
- **Güvenli Scraping (Kazıma):** HTML tabanlı veriler farklılık gösterebilir veya boş gelebilir. AttributeError veya KeyError olası çökme sebepleridir; DOM bileşenlerini ve kazınan objeleri mutlaka `"None"` durumlarına karşı "try/except" veya if/else şartlarıyla yönetin.
- **Ayrıştırılmış Mantık:** Algoritmik veya matematik işlemleri (`prediction_logic` içerisindeki karmaşık veri setlerinin yönetimi) ile endpoint rotalarını (app.route vb) birbirinden ayrı dosyalarda veya fonksiyonlarda tutun.
- **RESTful Düzeni:** Hata durumlarında uygun mesajla birlikte doğru HTTP status referanslarını (404, 500) geri dönün ve uygulamanın veri işleyişinin JSON cevaplarında aksamamasına (kısmi veri de olsa başarılı formatta gitmesine) dikkat edin.

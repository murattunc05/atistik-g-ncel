# TJK Verileri Işığında Mükemmel Algoritma Kapasitemiz

Sadece Türkiye Jokey Kulübü (TJK) web sitesindeki herkese açık verileri kullanarak "Mükemmel Algoritma"nın ne kadarını inşa edebileceğimizi analiz ettim.

TJK çok zengin bir veri kaynağı sunsa da, bazı modern biyomekanik ve taktiksel verileri (GPS takipleri, anlık tempo bilgileri vs.) sağlamamaktadır.

İşte TJK verileriyle yapabileceklerimiz ve yapamayacaklarımız:

---

## ✅ %100 Sağlayabildiğimiz Veriler (Sistemimizde Olan/Olabilen)

Bunlar TJK'dan şeffaf bir şekilde çekebildiğimiz ve algoritmamıza dahil edebileceğimiz net verilerdir:

### 1. Temel Geçmiş Performans ve Derece Biyomekaniği
- **Geçmiş Dereceler (Süreler):** Atın koştuğu tüm yarışlardaki saniye bazlı dereceleri. *(Şu an kullanıyoruz - %35 ağırlık)*
- **Pist Tipi ve Durumu:** Çim/Kum/Sentetik ve Ağır/Islak/Sulu/Normal durumları. *(Şu an kullanıyoruz)*
- **Mesafe Uygunluğu:** Hangi mesafelerde daha iyi koştuğu. *(Şu an kullanıyoruz)*
- **İstikrar (Standart Sapma):** Derece dalgalanmaları. *(Şu an kullanıyoruz)*
- **Sıklet (Kilo) Değişimi:** Atın son yarışına göre kaç kilo aldığı/verdiği. *(Şu an ekranda gösteriyoruz, puana dahil edebiliriz)*
- **Jokey İstatistiği ve Değişimi:** Atın o jokeyle uyumu ve jokey değişikliği durumu. *(Şu an ekranda gösteriyoruz, puana dahil edebiliriz)*
- **Sınıf (Class) Farkı:** Atın Şartlı-2 mi yoksa Grup-1 mi kazandığı. TJK bunu "Grup" sütununda açıkça veriyor. *(Şu an ekranda gösteriyoruz, **puana dahil etmeliyiz**)*.

### 2. İdman ve Form Verileri
- **Güncel İdman Dereceleri (Galoplar):** TJK idman sürelerini veriyor. *(Faz 2.2 ile bunu yarış mesafesine projeksiyon yaparak kullanmaya başladık)*
- **Form Trendi:** Son yarışlarındaki sıralama gelişimi. *(Şu an kullanıyoruz)*
- **Kondisyon (Fitness):** Son yarışını ne zaman koştuğu, idmanını kaç gün önce yaptığı. *(Şu an kullanıyoruz)*

---

## 🟨 Kısmen Sağlayabildiğimiz veya Üretebileceğimiz Veriler (Zorlu/Dolaylı Yollar)

Bu veriler TJK'da direkt "şu kadar puan" diye yazmaz ama mevcut TJK verilerini işleyerek biz üretebiliriz:

### 1. Pist İndeksi (Track Variant - Hız Katsayısı)
**TJK Durumu:** "Bugün pist saniyede 0.5 metre yavaşlatıyor" gibi bir veri vermez. Sadece "Normal" veya "Ağır" der ama her "Ağır" pist aynı ağırlıkta değildir.
**Biz Ne Yapabiliriz?:** Eğer o gün koşulan *tüm* yarışların derecelerini çekersek, o günkü rekor süreye veya genel ortalamaya göre kendimiz matematiksel bir "Pist Hız Katsayısı" hesaplayabiliriz. Bu çok ciddi sunucu gücü gerektirir ama imkansız değildir.

### 2. Tempo Analizi (Pace Analysis / Erken Hız)
**TJK Durumu:** TJK'nın "Yarış Raporu" kısımlarında "X atı numarayı aldı..." gibi metinler veya "Geçiş zamanları (400m, 800m, 1000m dereceleri)" mevcuttur. Rapor sayfalarında yarışın santim santim nasıl koşulduğuna dair PDF bültenler vardır ama bunu otomatik API ile çekmek olağanüstü zordur.
**Biz Ne Yapabiliriz?:** TJK Geçmiş yarış sıralamalarını yorumlayabiliriz. At 1. gitmiş ve 1. bitirmişse "Kaçak", 9. gidip 1. bitirmişse "Bekleme" atı diyebiliriz. (Eski algoritmamızda *Early Speed* ve *Late Kick* olarak bunu yapmaya çalışıyorduk).

### 3. Pedigri ve Kan Hattı Uyumu
**TJK Durumu:** Baba ve Anne bilgilerini veriyor. Annenin babasını da veriyor.
**Biz Ne Yapabiliriz?:** Çok büyük bir veritabanı kurup "X Aygırının (baba) yavruları %80 çimde kazanıyor" gibi bir analiz çıkarabiliriz. Bu, devasa bir TJK geçmiş veri kazıma (scraping) işlemi gerektirir.

---

## ❌ Sağlayamayacağımız Veriler (TJK'da Olmayanlar)

Ne yazık ki TJK'nın teknik altyapısı aşağıdaki modern analiz verilerini dışarıya sunmamaktadır:

1. **GPS Takip Verileri (Sectional Timing):**
   Amerika (Equibase) veya Hong Kong jokey kulüpleri, atların eğerindeki GPS sensörleri ile son 400 metreyi tam olarak kaç saniyede (örn: 22.4sn), saatte kaç km/h hızla geçtiğini milisaniyesine kadar verir. TJK'da bu veri halka açık dijital bir api/tabloda saniye saniye parçalanmış (sectional) halde bulunmaz.

2. **Atın Kendi Vücut Ağırlığı:**
   Dünyadaki elit analiz sistemleri "Atın Kilosu" (Örn: 520kg) ile "Taşıdığı Sıklet" (Örn: 60kg) oranını hesaplar. TJK atların günlük tartı kilosunu bültenlerde sistematik bir veri olarak yayınlamaz.

3. **Uzman/Veteriner Raporları ve Ekipman Değişimi Detayları:**
   TJK "KG" (Kapalı Gözlük) veya "DB" (Dil Bağı) gibi takıları verir ancak atın o gün neden bu takıyı taktığına dair antrenör notları veya veteriner ameliyat kayıtları dinamik olarak mevcut değildir.

4. **Kulvar ve Rüzgar Etkisi:**
   Her ne kadar hava durumunu bilebilsek de, TJK'nın anlık "Karşıdan 15km hızla lodos esiyor" veya "İç kulvar bugün %10 daha yavaş" gibi yarış anı metrikleri yoktur.

---

## 🎯 Sonuç: TJK Verisiyle Ne Kadar "Mükemmel" Olabiliriz?

TJK'daki mevcut (Çekebildiğimiz HTML) veriler ile **Dünya standartlarında bir derecelendirme algoritmasının %70 - %80'ini** kurabiliriz. 

GPS çipleri veya at kilosuna sahip olmasak da, elimizdeki:
1. Normalize Edilmiş Derece (Süre)
2. İdman Projeksiyonu
3. İstikrar & Form
4. **Sınıf (Grup) Çarpanı**

Bu dörtlü bileşim, sadece sıralama ve ganyan okuyarak bahis yapan halkın %95'inden çok daha akıllı ve istikrarlı bir matematiksel üstünlük kurmamıza yeterlidir.

### 📌 İlk Aksiyon Planda Ne Olmalı?
Bir önceki adımdaki tespitiniz doğrultusunda, TJK'nın bize "Grup" (Maiden, Şartlı, KV, Grup) olarak sunduğu bu değerli veriyi şu an sadece *ekranda süs olarak* gösteriyoruz. Bunu alıp, "Bu dereceyi KV-8'de mi yaptı, Şartlı-2'de mi?" sorusunu yapay zeka skoruna direkt etki edecek bir **"Sınıf Çarpanı (Class Factor)"** olarak kodlarsak, elimizdeki TJK verisinden maksimum %80'lik verimi almış oluruz.

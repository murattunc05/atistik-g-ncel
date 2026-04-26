# Mükemmel Bir At Yarışı Yapay Zeka (AI) Algoritması Nasıl Olmalı?

At yarışlarında sonucu tahmin etmek, sadece hız ve süre hesaplaması değil; fizik, biyoloji, psikoloji ve istatistiğin birleştirildiği devasa bir kaos yönetimidir. "Mükemmel" bir algoritma tasarlamak isteseydik, bu sistemin temel felsefesi **"Bağlama (Context) Duyarlı Normalize Edilmiş Güç Skoru" (Context-Aware Normalized Power Score)** üretmek olurdu.

İşte böyle bir algoritmanın adım adım nasıl tasarlanacağı, nelere dikkat etmesi gerektiği ve mimarisi:

---

## 1. Temel Felsefe: Süre Değil, Şartlar Altındaki Efor Önemlidir
Bir atın 2000 metreyi 2.05'te koşması tek başına bir anlam ifade etmez. Mükemmel algoritma şu soruyu sorar: **"Hangi şartlar altında 2.05 koştu?"**

- **Hava nasıldı?** Rüzgar karşıdan mı esiyordu?
- **Pist nasıldı?** Yağmurdan ağırlaşmış çim miydi, yoksa taş gibi sert bir kum muydu?
- **Tempo nasıldı?** Yarış çok yavaş başlayıp son 400'de mi hızlandı (Sprint yarışı), yoksa baştan sona intihar temposunda mı gidildi?
- **Rakipler kimdi?** Tek başına, zorlanmadan jokeyi tutarak mı 2.05 yaptı, yoksa 3 at kıyasıya mücadele ederek (kamçılayarak) mi bu dereceyi çıkardılar?

---

## 2. Sistemin Kalbi: Girdi Verileri (Feature Engineering)
Algoritmanın beslenmesi gereken veri noktaları 4 ana kategoriye ayrılır:

### A. Biyomekanik ve Form Verileri (Atın Kendisi)
1. **Güncel Kondisyon (Fitness):** Son idman dereceleri, idmandaki jokeyi, idman sıklığı, yarışlar arası dinlenme süresi (Bounce Teorisi: At bir yarışta çok efor sarfettiyse sonraki yarışta pili bitebilir).
2. **Kilo (Sıklet) Dinamikleri:** Atın taşıdığı kilo. Ancak sadece kilo değil, "Kilo / Atın kendi vücut ağırlığı" oranı (Maalesef TJK atın kendi kilosunu vermiyor ama yurt dışı modelleri kullanır).
3. **Yaş ve Gelişim Eğrisi:** 2 yaşlı bir İngiliz atı her ay gelişir (pozitif eğri), 7 yaşındaki bir Arap atı ise plato çizmiştir (stabil eğri).
4. **Pedigri (Kan Hattı):** Atın babası (Sire) ve annesinin babası (Broodmare Sire) hangi mesafelere yatkın? (Özellikle hayatında ilk kez uzun mesafe koşacak veya ilk kez çime çıkacak atlar için kan hattı tahmini hayati önem taşır).

### B. Çevresel ve Pist Faktörleri
1. **Pist İndeksi (Track Variant):** O günkü pistin ne kadar "hızlı" veya "yavaş" olduğunun matematiksel katsayısı. (Aynı gün koşulan diğer yarışların dereceleriyle kıyaslanarak pistin o günkü hızı hesaplanır).
2. **Kulvar Sırası (Draw Bias):** Hipodroma ve mesafeye göre değişir. Bazı hipodromlarda iç kulvardan çıkmak %15 avantaj sağlarken, bazılarında dezavantajdır.
3. **Hava Durumu:** Sıcaklık (Arap atları sıcağı İngilizlerden farklı tolere eder), rüzgar yönü ve şiddeti.

### C. Taktiksel Faktörler (Koşu Gidişatı - Pace Scenario)
1. **Tempo Analizi (Pace Analysis):** Koşuda kaç tane "kaçak" (önde gitmeyi seven) at var? 
   - Eğer koşuda 4 tane kaçak at varsa, önde birbirlerini bitirirler ve yarış "Bekleme" yapan (Late Kick) ata yarar.
   - Eğer koşuda hiç kaçak at yoksa, öne çıkan tek bir at tempoyu rölantiye alır ve son düzlükte enerjisini harcamadığı için asla geçilmez. (Bu, elit algoritmaların en büyük sırrıdır).
2. **Jokey/Antrenör İstatistiği:** Jokeyin o hipodromdaki başarısı, jokeyin atın stiline uygunluğu (Bazı jokeyler önde kaçan atlara iyi biner, bazıları bekleme atlarına).

### D. Rekabet Faktörü (Class / Sınıf)
1. **Sınıf Derecelendirmesi (Class Rating):** Atın yarıştığı grubun zorluk derecesi. (Şartlı 2 vs Grup 1). "Class is permanent, form is temporary" (Sınıf kalıcıdır, form geçicidir) kuralı.

---

## 3. Mükemmel Algoritmanın Çalışma Mantığı (Adım Adım)

Mükemmel bir sistem, basit ağırlıklı ortalamalar (`calculate_ai_score` gibi) yerine, makine öğrenmesi algoritmalarını (XGBoost, Random Forest veya Deep Neural Networks) kullanarak şu adımları izler:

### Adım 1: Geçmiş Derecelerin Standardizasyonu (Beyer Speed Figure Mantığı)
Atın geçmişteki her yarışına basit bir derece (2.05.30) kullanmak yerine, o dereceyi **Pist İndeksi, Kilo ve Mesafeye göre düzeltilmiş tek bir Rakam (Hız Skoru - Speed Figure)** haline getiririz.
- Örn: Islak kumda 2.08 yapan atın Hız Skoru = 95
- Kuru kumda 2.04 yapan atın Hız Skoru = 92 (Çünkü o gün pist zaten çok hızlıydı).

### Adım 2: Gidişat (Pace) Simülasyonu
Algoritma koşudaki tüm atların "Stil" verilerini alır:
- At 1: Erken Hız (Early Speed) yüksek, Kaçak
- At 2: Bekleme (Closer)
- At 3: Kaçak
Algoritma şunu tespit eder: "Bu yarışta erken hız çok yüksek, tempo patlayacak (Fast Pace). Bu yüzden ön gruptaki atların (At 1 ve At 3) kazanma şansı %40 düşecek, sonradan gelecek At 2'nin şansı %60 artacak."

### Adım 3: Sınıf ve Form Çarpanı
Algoritma, At 1'in elde ettiği 95 Hız Skorunu hangi grupta yaptığına bakar. Eğer zayıf bir gruptaysa bu skora (Penaltı x0.9) çarpanı uygular. Güçlü bir grupta ezilmesine rağmen yakın ara bitirdiyse (Bonus x1.1) uygular. Son idmanında geliştirdiği efora göre Form Çarpanı ekler.

### Adım 4: Monte Carlo Simülasyonu ile Olasılık Üretimi
At yarışlarında 1 yarış yoktur, aynı yarış 100 kere koşulsa 10 farklı at kazanabilir. Mükemmel algoritma, yukarıdaki tüm istatistikleri kullanarak yarışı kafasında (bilgisayarda) **10.000 defa** sanal olarak koşturur.
- 10.000 yarışın 6.500'ünü At A kazandı. -> Kazanma İhtimali: %65 (Oran: 1.50)
- 10.000 yarışın 2.000'ini At B kazandı. -> Kazanma İhtimali: %20 (Oran: 5.00)

Sonuç olarak algoritma size "Şu at kazanacak" demez. Size **"Gerçek Kazanma Olasılıklarını" (True Odds)** verir.

---

## 4. Değer (Value) Bahsi Mantığı (Algoritmanın Paraya Dönüşmesi)

Mavi hapı mı kırmızı hapı mı alacağınız yer burasıdır.
Mükemmel algoritma kimin kazanacağını bulmaya çalışmaz, **halkın (ve ganyan oranlarının) nerede yanıldığını bulmaya çalışır.**

- Algoritmanız At C'nin kazanma ihtimalini **%20** buldu. (Buna göre adil oran 5.00 olmalıdır).
- Türkiye Jokey Kulübü (TJK) sonuçlarına göre halk bu ata pek inanmamış ve ganyanı **12.00** olarak belirlenmiş.
- Mükemmel algoritma alarm verir: **Değer Bahsi Bulundu! (Value Bet)**. Algoritma gidip banko olan favoriye oynamaz, matematiksel olarak avantajlı olan (değer barındıran) bu ata oynar. Uzun vadede kasayı katlayan tek felsefe budur.

---

## 5. Uygulamamız (Atistik) Bu Sistemin Neresinde?

Şu anki yazdığımız `atistik` algoritması (Faz 1 ve Faz 2 ile oluşturduğumuz motor), mükemmel sistemin **Adım 1 ve Adım 3'ünün yaklaşık bir prototipini** simüle etmektedir:
1. **Mesafe ve Pist Bazlı Süre Karşılaştırması:** (Beyer Speed Figure'ün en ilkel halini ortalama süreler üzerinden yapıyoruz).
2. **Form ve İdman Etkisi:** Form trendi ve idman projeksiyonu hesaplamalarımız var.
3. **Tutarlılık (Standart Sapma):** Atın performans stabilitesini ölçüyoruz.

### Şu anki sistemde EKSİK olan ve Mükemmel Sistemde OLMASI GEREKENLER (Gelecek Vizyonu):
1. **Sınıf (Class) Farkı Çarpanı (Sizin az önce belirttiğiniz o çok kritik nokta).** Zayıf atları geçen ile güçlü atlarla savaşan arasındaki ayrım.
2. **Pace (Tempo) Analizi:** Kim kaçacak, kim bekleyecek simülasyonu (TJK'dan detaylı veri çekmeden çok zordur).
3. **Pist İndeksi Hesaplaması:** "O gün kum pist saniyede kaç metre daha yavaşlatıyordu?" matematiği.
4. **Jokey/Antrenör/Sıklet Etkilerinin Yapay Zeka ile Ağırlıklandırılması.** (Şu an bunları sadece ekrana yazdırıyoruz, skora dinamik bir ceza/ödül olarak matematiksel katmıyoruz).

Özetle mükemmel bir sistem tek bir satırlık if-else zinciri değil, atın geçmişindeki her yarışı bağlamına (zorluk, tempo, pist hızı) göre normalize edip, gelecekteki tek bir yarışı olasılık kümeleriyle simüle eden bir ekosistemdir.

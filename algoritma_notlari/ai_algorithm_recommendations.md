# Gelecek Yarış Tahmininde Olması Gereken Kritik Faktörler

Sadece mevcut sistemimizi değil, dünya standartlarındaki yarış analiz yapılarını referans aldığımda; sistemin bir atı birinci seçebilmesi (Yapay Zeka Skorunu verebilmesi) için **mutlaka** hesaplanması gereken faktörler şunlardır:

### 1) Sınıf / Grup Zorluk Çarpanı (Class Factor) 🔴 *(Mevcut ama Puanlamada Yok)*
Dünyadaki en iyi at yarışçıların bir kuralı vardır: *"İyi bir atı, kötü atlarla koştuğu derece ile yargılama."* 
Şartlı-3 yarışında çok iyi derece yapan at, KV-8 (Kısa Vade 8) yarışında büyük ihtimalle ezilir. Çünkü grup yarışlarında tempo baştan çok daha sert konur.
**Önerim:** Geçmiş dereceleri *(örneğin 2.05'i)* puana çevirirken atın bu dereceyi; Açık/Grup yarışında mı, Kısa Vade mi, Handikap mı yoksa Şartlı/Maiden'da mı yaptığına göre bir **"Zorluk Çarpanı" (Multiplier)** uygulamalıyız. 

### 2) Kilo Performans Endeksi (Weight Impact) 🟡 *(Göstergeden Analize)*
Atların taşıdığı sıkletler (kilolar) mesafe uzadıkça çok daha kritik hale gelir. 1600 metrede 2 kilo fark pek önemli değildir, ancak 2400 metrede o 2 kilo atın son düzlükteki sprintini (Late Kick) tamamen bitirir. 
**Önerim:** Gelecek koşunun mesafesine ve atın geçen yarışından bugüne gelen "Kilo Değişimine" (Weight Change) bakarak, eğer mesafe uzun ve kilo artmışsa AI Skorundan minik cezalar kesmeliyiz.

### 3) Pist Hız İndeksi (Track Variant) 🔥 *(Zor ama Şart)*
Bu, tahmin sistemlerinin Kutsal Kasesi'dir. Dün İstanbul'da kum pistte koşulan bir 2.05 ile bugün İzmir'de koşulan 2.05 aynı değildir. Hatta bugün yağan yağmurdan dolayı sabahtan akşama bile pistin hızı (Track Variant) değişir.
**Önerim:** Koşulacak pistin tipini ve *durumunu (Sulu, Normal vs.)* alıyoruz ama bunu atın geçmişteki **benzer koşullardaki** hız katsayısıyla (Normalleştirilmiş Skor) daha dinamik kıyaslamalıyız. (Şu anki *Track Suitability* modülümüz güzel ama sadece "Çim seviyor" diyor. Bunu "Çok Ağır Çimde Uçuyor" şekline getirmeliyiz).

### 4) Koşu Temposu Senaryosu (Pace Scenario) 🧠 *(Geleceğin Vizyonu)*
Bir yarışta "kimin kazanacağını" genellikle "kimin tempoyu belirleyeceği" söyler. 
Eğer koşuda 3 tane fuleli "Kaçak" at varsa, bu atlar ilk 800 metrede birbirini yer bitirir, enerji sarfiyatı maksimuma çıkar ve son 400'de dururlar. Böyle bir yarışta %100 "Bekleme (Closer)" yapan bir at kazanacaktır.
**Önerim:** Atların profillerini çıkartıp (Erken Hızlarına göre), o yarışın "Hızlı Tempo" mu yoksa "Yavaş Tempo" mu geçeceğini tahmin eden bir "Yarış Senaryosu" (Pace Simulator) modülü eklenmelidir.

### 5) Güncel İdman ve Form Momentum (Bounce Effect) ✅ *(Şu An Çok İyi Çalışıyor)*
Bir at geçen yarışında inanılmaz bir direnç gösterip rekor bir dereceyle kazandıysa, bir sonraki yarışında pili bitmiş (Bounce teorisi) olma ihtimali çok yüksektir. 
**Önerim:** İdman projeksiyonumuzu şu an (Faz 2 ile) mükemmel oturttuk. Bunu bozmadan, son yarışla bugün arasındaki gün sayısını (dinlenme periyodunu) formüle biraz daha sert bir ceza/ödül olarak ekleyebiliriz (çok sık koşmak = negatif momentum).

### Özetle;
Eğer bu mükemmel algoritmayı Atistik'te ayağa kaldırmak istiyorsak, **ilk adımımız** kesinlikle sizin parmak bastığınız **"Sınıf/Grup Puanlaması (Class Factor)"** olmalıdır. Çünkü bu, TJK'dan zaten alabildiğimiz ama şu an skorlamaya katmadığımız tek net, altın değerindeki faktördür. Diğerleri (Tempo Senaryosu veya Pist Hızı) çok daha karmaşık yapay zeka/matematik modelleri gerektirecektir.

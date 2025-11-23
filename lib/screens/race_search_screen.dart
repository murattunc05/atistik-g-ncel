import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../theme/app_theme.dart';

class RaceSearchScreen extends StatefulWidget {
  const RaceSearchScreen({super.key});

  @override
  State<RaceSearchScreen> createState() => _RaceSearchScreenState();
}

class _RaceSearchScreenState extends State<RaceSearchScreen> {
  final _distanceController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();

  bool _showResults = false;
  bool _isLoading = false;

  // --- Tarih Değişiklikleri ---
  // _selectedDate, _startDate olarak yeniden adlandırıldı ve varsayılan olarak bugünün tarihi atandı
  DateTime _startDate = DateTime.now();
  // Bitiş tarihi eklendi, başlangıçta null (isteğe bağlı)
  DateTime? _endDate;
  // --- Değişiklik Sonu ---

  List<String> _selectedHippodromes = []; // Çoklu hipodrom seçimi için
  String _selectedRaceType = 'Tümü';

  // yarış sorgula.txt dosyasından çıkarıldı
  final List<String> _allHippodromes = [
    'Adana',
    'Ankara',
    'Antalya',
    'Bursa',
    'Diyarbakır',
    'Elazığ',
    'İstanbul',
    'İzmir',
    'Kocaeli',
    'Şanlıurfa',
  ];

  final List<String> _raceTypes = [
    'Tümü',
    'Handikap', // Kolaylık olması için tüm Handikap türlerini içerir
    'Maiden',
    'Grup', // G1, G2, G3 içerir
    'KV', // Tüm KV türlerini içerir
    'Şartlı', // Tüm Şartlı türlerini içerir
    'Satış', // Tüm Satış türlerini içerir
    // Gerekirse 'Amatör' vb. eklenebilir
  ];

  List<Map<String, dynamic>> _searchResults = [];

  // --- Yeni Tarih Seçici Fonksiyonları ---

  // Başlangıç tarihini seçme fonksiyonu
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000), // Makul başlangıç tarihi
      // Bitiş tarihi seçiliyse, başlangıç tarihi bitiş tarihinden sonra olamaz
      lastDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Başlangıç tarihi değiştiğinde, bitiş tarihi başlangıçtan önceyse sıfırla
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  // Bitiş tarihini seçme fonksiyonu
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      // Bitiş tarihi seçilmediyse bugünü veya başlangıç tarihini öner
      initialDate: _endDate ?? _startDate,
      // Bitiş tarihi, başlangıç tarihinden önce olamaz
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)), // Bir yıl sonrasına kadar seçime izin ver
    );
    // if (picked != null && picked != _endDate) { // Bu satır null atamayı engelliyor
    // Kullanıcı aynı tarihi seçse bile veya null seçse bile güncelle
    if (picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }
  // --- Fonksiyon Sonu ---


  // Çoklu seçim hipodrom iletişim kutusunu gösterme fonksiyonu
  void _showHippodromeSelectionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // İletişim kutusu içindeki onay kutularının durumunu yönetmek için bir StatefulWidget kullanın
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.surfaceLightMode,
              title: const Text('Hipodrom Seçiniz'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allHippodromes.length,
                  itemBuilder: (context, index) {
                    final hippodrome = _allHippodromes[index];
                    return CheckboxListTile(
                      activeColor: AppTheme.primary,
                      title: Text(hippodrome),
                      value: _selectedHippodromes.contains(hippodrome),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedHippodromes.add(hippodrome);
                          } else {
                            _selectedHippodromes.remove(hippodrome);
                          }
                        });
                        // Ana sayfanın durumunu da güncelle
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('İptal'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Tamam'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yarış Sorgula',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Güncellenmiş Tarih Seçici Alanı (Yan Yana) ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Başlangıç Tarihi Kolonu ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Başlangıç Tarihi',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.calendar_today_outlined, size: 18),
                              label: Text(
                                dateFormat.format(_startDate), // Sadece tarihi göster
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14), // Font boyutunu ayarla
                                overflow: TextOverflow.ellipsis, // Taşmayı engelle
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: isDark ? AppTheme.textLight : AppTheme.textLightMode,
                                backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.surfaceLightMode,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Padding ayarı
                                minimumSize: const Size(double.infinity, 50), // Genişliği doldur
                                alignment: Alignment.centerLeft, // Metni sola hizala
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isDark ? AppTheme.border : AppTheme.borderLightMode,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () => _selectStartDate(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // --- Bitiş Tarihi Kolonu ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bitiş Tarihi (İsteğe Bağlı)',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                _endDate == null
                                    ? '(Seçilmedi)' // Daha kısa metin
                                    : dateFormat.format(_endDate!),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14), // Font boyutunu ayarla
                                overflow: TextOverflow.ellipsis, // Taşmayı engelle
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: isDark ? AppTheme.textLight : AppTheme.textLightMode,
                                backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.surfaceLightMode,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Padding ayarı
                                minimumSize: const Size(double.infinity, 50), // Genişliği doldur
                                alignment: Alignment.centerLeft, // Metni sola hizala
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isDark ? AppTheme.border : AppTheme.borderLightMode,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () => _selectEndDate(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // --- Tarih Alanı Sonu ---
                  const SizedBox(height: 16),

                  // --- Hipodrom Seçici (Çoklu Seçim) ---
                   Text(
                    'Hipodrom Seçiniz (İsteğe Bağlı)',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                   const SizedBox(height: 6),
                   GestureDetector(
                     onTap: _showHippodromeSelectionDialog,
                     child: InputDecorator(
                       decoration: InputDecoration(
                         filled: true,
                         fillColor: isDark ? AppTheme.backgroundDark : AppTheme.surfaceLightMode,
                         border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(8),
                           borderSide: BorderSide(
                             color: isDark ? AppTheme.border : AppTheme.borderLightMode,
                           ),
                         ),
                         enabledBorder: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(8),
                           borderSide: BorderSide(
                             color: isDark ? AppTheme.border : AppTheme.borderLightMode,
                           ),
                         ),
                         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                       ),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Expanded(
                            child: Text(
                              _selectedHippodromes.isEmpty
                                  ? 'Hipodrom Seç'
                                  : _selectedHippodromes.join(', '),
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                          const Icon(Icons.arrow_drop_down),
                         ],
                       ),
                     ),
                   ),
                  const SizedBox(height: 16),

                  // --- Diğer Alanlar ---
                   Row(
                    children: [
                       Expanded(
                         child: _buildDropdown(
                           'Koşu Cinsi (İsteğe Bağlı)',
                           _selectedRaceType,
                           _raceTypes,
                           (value) => setState(() => _selectedRaceType = value!),
                         ),
                       ),
                       const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          'Mesafe (İsteğe Bağlı)',
                          'Örn: 1200',
                          _distanceController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    'Baba Adı (İsteğe Bağlı)',
                    'Baba Adı Giriniz',
                    _fatherNameController,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    'Anne Adı (İsteğe Bağlı)',
                    'Anne Adı Giriniz',
                    _motherNameController,
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Yarışları Bul',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_showResults)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Arama Sonuçları',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSearchResults(),
                  ],
                ),
              ),
             const SizedBox(height: 32), // En alta biraz boşluk ekle
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14, // Daha küçük ipucu
              color: isDark ? AppTheme.textDark.withOpacity(0.7) : AppTheme.textDarkMode.withOpacity(0.7),
            ),
            filled: true,
            fillColor: isDark ? AppTheme.backgroundDark : AppTheme.surfaceLightMode,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppTheme.border : AppTheme.borderLightMode,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppTheme.border : AppTheme.borderLightMode,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5), // Daha ince odak çerçevesi
            ),
             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), // Ayarlanmış dolgu
          ),
          style: const TextStyle(fontSize: 14), // Giriş metin boyutunu ayarla
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: isDark ? AppTheme.backgroundDark : AppTheme.surfaceLightMode,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppTheme.backgroundDark : AppTheme.surfaceLightMode,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppTheme.border : AppTheme.borderLightMode,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppTheme.border : AppTheme.borderLightMode,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5), // Daha ince odak çerçevesi
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), // Ayarlanmış dolgu
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)), // Menü öğesi metin boyutunu ayarla
            );
          }).toList(),
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14), // Seçilen değer metin boyutunu ayarla
        ),
      ],
    );
  }

 void _performSearch() async {
    setState(() {
      _isLoading = true;
      _showResults = true;
      _searchResults = [];
    });

    final dateFormat = DateFormat('dd/MM/yyyy');
    final apiDateFormat = DateFormat('dd.MM.yyyy');

    String startDateString = dateFormat.format(_startDate);
    DateTime effectiveEndDate = _endDate ?? _startDate;
    String endDateString = dateFormat.format(effectiveEndDate);

    try {
      // TJK web sitesinden direkt HTML çek
      final url = Uri.parse('https://www.tjk.org/TR/YarisSever/Query/Page/KosuSorgulama');
      final queryParams = {
        'QueryParameter_Tarih_Start': startDateString,
        'QueryParameter_Tarih_End': endDateString,
        'QueryParameter_SehirId': '-1', // Tüm şehirler
      };
      
      if (_distanceController.text.isNotEmpty) {
        queryParams['QueryParameter_Mesafe'] = _distanceController.text;
      }
      if (_fatherNameController.text.isNotEmpty) {
        queryParams['QueryParameter_BabaIsmi'] = _fatherNameController.text;
      }
      if (_motherNameController.text.isNotEmpty) {
        queryParams['QueryParameter_AnneIsmi'] = _motherNameController.text;
      }

      final urlWithParams = url.replace(queryParameters: queryParams);
      
      final response = await http.get(
        urlWithParams,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('TJK sayfası yüklenemedi: ${response.statusCode}');
      }

      // HTML'i parse et
      final document = html_parser.parse(response.body);
      
      // Tablo gövdesini bul
      final table = document.getElementById('queryTable');
      final tbody = table?.querySelector('tbody');
      
      if (tbody == null) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Tüm satırları al
      final rows = tbody.querySelectorAll('tr');
      List<Map<String, dynamic>> races = [];

      for (var row in rows) {
        try {
          final cells = row.querySelectorAll('td');
          
          if (cells.length >= 8) {
            // Detay linkini bul
            final linkElem = cells[0].querySelector('a');
            final detailLink = linkElem?.attributes['href'] ?? '';
            
            // Tarih hücresinden sadece metni al
            final dateText = cells[0].text.trim();
            
            final race = {
              'date': dateText,
              'city': cells[1].text.trim(),
              'raceNumber': cells[2].text.trim(),
              'group': cells[3].text.trim(),
              'raceType': cells[4].text.trim(),
              'apprenticeType': cells[5].text.trim(),
              'distance': cells[6].text.trim(),
              'track': cells[7].text.trim(),
              'detailLink': detailLink,
            };
            
            races.add(race);
          }
        } catch (e) {
          print('Satır parse hatası: $e');
          continue;
        }
      }

      if (!mounted) return;

      // Filtreleme
      List<Map<String, dynamic>> filteredRaces = races;

      // 1. Hipodrom Filtrelemesi
      if (_selectedHippodromes.isNotEmpty) {
        filteredRaces = filteredRaces.where((race) {
          final raceCity = (race['city'] as String? ?? '').trim();
          return _selectedHippodromes.any(
            (selectedCity) => raceCity.toLowerCase() == selectedCity.toLowerCase()
          );
        }).toList();
      }

      // 2. Tarih Filtrelemesi
      try {
        DateTime startDayOnly = DateTime(_startDate.year, _startDate.month, _startDate.day);
        DateTime endDayOnly = DateTime(effectiveEndDate.year, effectiveEndDate.month, effectiveEndDate.day);

        filteredRaces = filteredRaces.where((race) {
          String? dateStr = race['date'];
          if (dateStr == null || dateStr.isEmpty) return false;

          try {
            DateTime raceDate = apiDateFormat.parse(dateStr);
            DateTime raceDayOnly = DateTime(raceDate.year, raceDate.month, raceDate.day);
            return !raceDayOnly.isBefore(startDayOnly) && !raceDayOnly.isAfter(endDayOnly);
          } catch (e) {
            return false;
          }
        }).toList();
      } catch (e) {
        print('Tarih filtreleme hatası: $e');
      }

      setState(() {
        _searchResults = filteredRaces;
        _isLoading = false;
      });
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Widget _buildSearchResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 24),
              Text(
                'Yarışlar aranıyor...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                'TJK veritabanında arama yapılıyor',
                style: TextStyle(fontSize: 14, color: AppTheme.textDark),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: AppTheme.textDark),
              SizedBox(height: 16),
              Text(
                'Sonuç bulunamadı',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                'Arama kriterlerinizi değiştirip tekrar deneyin',
                style: TextStyle(fontSize: 14, color: AppTheme.textDark),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Şehre göre grupla
    Map<String, List<Map<String, dynamic>>> groupedRaces = {};
    for (var race in _searchResults) {
      final city = race['city'] as String? ?? 'Bilinmeyen Şehir';
      if (groupedRaces[city] == null) {
        groupedRaces[city] = [];
      }
      groupedRaces[city]!.add(race);
    }

    // Şehirleri alfabetik olarak sırala
     var sortedCities = groupedRaces.keys.toList()..sort();

    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: sortedCities.map((city) {
          final racesInCity = groupedRaces[city]!;
         // Şehir içindeki yarışları yarış numarasına göre sırala
         racesInCity.sort((a, b) {
            int raceNumA = int.tryParse(a['raceNumber'] ?? '0') ?? 0;
            int raceNumB = int.tryParse(b['raceNumber'] ?? '0') ?? 0;
            return raceNumA.compareTo(raceNumB);
         });

         return Padding(
           padding: const EdgeInsets.only(bottom: 24.0), // Şehir grupları arasında boşluk
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Padding(
                 padding: const EdgeInsets.only(bottom: 12.0),
                 child: Text(
                   city,
                   style: TextStyle(
                     fontSize: 20,
                     fontWeight: FontWeight.bold,
                     color: isDark ? AppTheme.textLight : AppTheme.textLightMode,
                   ),
                 ),
               ),
               ListView.separated(
                 shrinkWrap: true, // Bir Column içinde önemli
                 physics: const NeverScrollableScrollPhysics(), // İç liste için kaydırmayı devre dışı bırak
                 itemCount: racesInCity.length,
                 itemBuilder: (context, index) {
                   return _buildRaceCard(racesInCity[index]);
                 },
                 separatorBuilder: (context, index) => const SizedBox(height: 12),
               ),
             ],
           ),
         );
       }).toList(),
     );
  }


  Widget _buildRaceCard(Map<String, dynamic> race) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : AppTheme.surfaceLightMode,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.border : AppTheme.borderLightMode,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  // Şehir ve koşu no başlıkta
                  'Koşu ${race['raceNumber'] ?? '?'}',
                  style: const TextStyle(
                    fontSize: 16, // Biraz daha küçük
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: AppTheme.primary.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(4),
                 ),
                 child: Text(
                  // Tarihi burada göster
                   race['date'] ?? '',
                   style: const TextStyle(
                     fontSize: 12,
                     color: AppTheme.primary,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
               ),

            ],
          ),
          const SizedBox(height: 10), // Biraz daha az boşluk
          // --- Düzeltme: Sütun eşleştirmeleri ve alanlar ---
          _buildInfoRow('Grup', race['group'] ?? '-'),
          _buildInfoRow('Koşu Cinsi', race['raceType'] ?? '-'),
          _buildInfoRow('Apr. Koş. Cinsi', race['apprenticeType'] ?? '-'),
          _buildInfoRow('Mesafe', race['distance'] ?? '-'),
          _buildInfoRow('Pist', race['track'] ?? '-'),
          // --- Düzeltme Sonu ---
        ],
      ),
    );
  }


  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (value.isEmpty || value == '-') return const SizedBox.shrink(); // Boş satırları gösterme

    return Padding(
      padding: const EdgeInsets.only(bottom: 5), // Biraz daha az boşluk
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70, // Etiket için biraz daha az genişlik
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13, // Boyutu koru
                color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
              ),
            ),
          ),
          const SizedBox(width: 8), // Biraz daha fazla boşluk
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13, // Boyutu koru
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    super.dispose();
  }
}


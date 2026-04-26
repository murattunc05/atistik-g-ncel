import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../models/daily_race_model.dart';

class DailyRaceScraperService {
  static const String _baseUrl = 'https://www.tjk.org';
  static const String _programUrl = '$_baseUrl/TR/YarisSever/Info/Page/GunlukYarisProgrami';
  static const String _cityUrl = '$_baseUrl/TR/YarisSever/Info/Sehir/GunlukYarisProgrami';

  // Daha kapsamlı header'lar - TJK bazen bağlantıyı kesiyor
  static final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Referer': 'https://www.tjk.org/',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'same-origin',
    'Sec-Ch-Ua': '"Not_A Brand";v="8", "Chromium";v="120"',
    'Sec-Ch-Ua-Mobile': '?0',
    'Sec-Ch-Ua-Platform': '"Windows"',
    'Upgrade-Insecure-Requests': '1',
    'Cache-Control': 'max-age=0',
  };

  /// Fetches the list of cities that have races on the given date.
  /// Returns a list of maps with 'name' and 'id' keys.
  Future<List<Map<String, String>>> getCitiesForDate(String date) async {
    try {
      final uri = Uri.parse(_programUrl).replace(queryParameters: {
        'QueryParameter_Tarih': date,
      });
      
      print('Fetching cities from: $uri');

      // Timeout ekle
      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));
      print('Cities response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _parseCities(response.body);
      }
      throw Exception('Failed to fetch cities: ${response.statusCode}');
    } catch (e) {
      print('Error fetching cities: $e');
      rethrow;
    }
  }

  List<Map<String, String>> _parseCities(String htmlContent) {
    List<Map<String, String>> cities = [];
    var document = parser.parse(htmlContent);

    // Look for links that contain "SehirId"
    var links = document.querySelectorAll('a[href*="SehirId"]');
    
    for (var link in links) {
      var href = link.attributes['href'] ?? '';
      var uri = Uri.tryParse(href);
      if (uri != null) {
        var sehirId = uri.queryParameters['SehirId'];
        var sehirAdi = uri.queryParameters['SehirAdi'];
        
        // Fallback: Try to get name from text if not in param
        if (sehirAdi == null || sehirAdi.isEmpty) {
          sehirAdi = link.text.trim();
        }

        if (sehirId != null && sehirAdi != null) {
          // Clean up city name (remove extra spaces, newlines)
          sehirAdi = sehirAdi.replaceAll(RegExp(r'\s+'), ' ').trim();
          
          // Avoid duplicates
          if (!cities.any((c) => c['id'] == sehirId)) {
            cities.add({
              'id': sehirId,
              'name': sehirAdi,
            });
          }
        }
      }
    }
    print('Parsed cities: $cities');
    return cities;
  }

  Future<List<DailyRaceModel>> getRacesForDate(String date, String cityId, String cityName) async {
    try {
      // Construct URL with query parameters
      final uri = Uri.parse(_cityUrl).replace(queryParameters: {
        'SehirId': cityId,
        'QueryParameter_Tarih': date,
        'SehirAdi': cityName,
        'Era': 'today'
      });
      
      print('Fetching races from: $uri');

      // Aynı kapsamlı header'ları kullan
      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));
      print('Races response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _parseRaces(response.body, cityId);
      } else {
        throw Exception('Failed to load races: ${response.statusCode}');
      }
    } catch (e) {
      print('Error scraping races: $e');
      rethrow;
    }
  }

  List<DailyRaceModel> _parseRaces(String htmlContent, String cityId) {
    List<DailyRaceModel> races = [];
    var document = parser.parse(htmlContent);

    // Check if we got redirected to login page
    var title = document.head?.querySelector('title');
    if (title != null && title.text.contains('e-Bayi')) {
      print('HATA: Login sayfasına yönlendi');
      return [];
    }

    // Get full text and clean it
    String fullText = document.body?.text ?? "";
    
    // Find all race headers - pattern: "1. Koşu 18.30" or "1. Koşu 18:30"
    final raceHeaderRegex = RegExp(r'(\d+)\.\s*Koşu\s*(\d{2})[:.ː](\d{2})');
    var matches = raceHeaderRegex.allMatches(fullText).toList();
    
    print('Found ${matches.length} races');
    
    // Find race IDs from anchor links (format: #221703)
    // TJK uses anchor links like href="...#221703" for each race
    var raceIdMap = <String, String>{};  // Map: raceNo -> raceId
    var allLinks = document.querySelectorAll('a[href*="#"]');
    for (var link in allLinks) {
      var href = link.attributes['href'] ?? '';
      // Extract the anchor part (after #)
      if (href.contains('#')) {
        var anchor = href.split('#').last;
        // Check if it's a numeric race ID (typically 6 digits)
        if (anchor.isNotEmpty && RegExp(r'^\d{5,7}$').hasMatch(anchor)) {
          // Try to find which race this belongs to by looking at the link text
          var linkText = link.text.trim();
          var raceMatch = RegExp(r'(\d+)\.\s*Koşu').firstMatch(linkText);
          if (raceMatch != null) {
            var raceNo = raceMatch.group(1)!;
            raceIdMap[raceNo] = anchor;
            print('Found raceId: $anchor for race $raceNo');
          }
        }
      }
    }

    // PASS 1: Create race objects with basic info (number, time, and raceId)
    for (int i = 0; i < matches.length; i++) {
      var match = matches[i];
      String raceNo = match.group(1)!;
      String time = '${match.group(2)}:${match.group(3)}';
      String raceId = raceIdMap[raceNo] ?? '';  // Get raceId from map
      
      if (raceId.isNotEmpty) {
        print('Race $raceNo: raceId = $raceId');
      }

      races.add(DailyRaceModel(
        time: time,
        raceNo: raceNo,
        raceName: '',
        distance: '',
        trackType: '',
        prize: '',
        city: cityId,
        raceId: raceId,  // İdman bilgileri için gerekli
      ));
    }

    print('Pass 1 complete: Created ${races.length} race objects');

    // PASS 2: Look for "Tüm Koşular" section which contains all race details
    int tumKosularIndex = fullText.indexOf('Tüm Koşular');
    if (tumKosularIndex == -1) {
      tumKosularIndex = fullText.indexOf('Tum Kosular');
    }
    
    if (tumKosularIndex != -1) {
      print('Found "Tüm Koşular" section at index $tumKosularIndex');
      
      // Extract the detailed section
      String detailSection = fullText.substring(tumKosularIndex);
      
      // Find all race detail blocks: "X. Koşu:HH.MM RACE_NAME ... kg, DIST TRACK ... Ikramiye: ..."
      // We'll iterate through each race and try to find its details
      for (var race in races) {
        // Convert time back to dot format: "20:20" -> "20.20"
        String timeInDots = race.time.replaceAll(':', '.');
        
        // Pattern: "1. Koşu:20.20" or "1. Koşu :20.20" or "1.Koşu :20.20"
        String racePattern = '${race.raceNo}\\.\\s*Koşu\\s*:?\\s*$timeInDots';
        
        print('  Searching for Race ${race.raceNo} with pattern: "$racePattern"');
        
        var raceDetailMatch = RegExp(racePattern).firstMatch(detailSection);
        
        if (raceDetailMatch != null) {
          print('  ✓ Found match at position ${raceDetailMatch.start}');
          // Get text block for this race detail
          int start = raceDetailMatch.start;
          int nextRaceNum = int.parse(race.raceNo) + 1;
          String nextPattern = '$nextRaceNum\\. Koşu\\s*:';
          var nextMatch = RegExp(nextPattern).firstMatch(detailSection.substring(start + 10));
          int end = nextMatch != null ? start + 10 + nextMatch.start : detailSection.length;
          
          String raceDetail = detailSection.substring(start, end);
          String cleanDetail = raceDetail.replaceAll(RegExp(r'\s+'), ' ').trim();
          
          print('Race ${race.raceNo} detail: ${cleanDetail.substring(0, cleanDetail.length > 200 ? 200 : cleanDetail.length)}...');

          // Extract distance and track
          var distTrackMatch = RegExp(r'kg\s*,\s*(\d{3,4})\s+(Çim|Kum|Sentetik|Tapeta)', caseSensitive: false).firstMatch(cleanDetail);
          if (distTrackMatch != null) {
            race.distance = distTrackMatch.group(1)!;
            race.trackType = distTrackMatch.group(2)!;
            if (race.trackType.toLowerCase() == 'tapeta') race.trackType = 'Sentetik';
            print('  ✓ Distance: ${race.distance}, Track: ${race.trackType}');
          }

          // Extract race name
          var nameMatch = RegExp(r'(ŞARTLI\s*\d+|Maiden|MAIDEN|Handikap|KV-\d+|SATIŞ|MAIDEN SATIŞ KOŞUSU)', caseSensitive: false).firstMatch(cleanDetail);
          if (nameMatch != null) {
            race.raceName = nameMatch.group(0)!;
          }

          // Extract prize
          var prizeMatch = RegExp(r'(?:Ikramiye|İkramiye)[^\d]*1\.\)\s*([\d.]+)\s*([t\$€£]|TL|EUR|GBP)?', caseSensitive: false).firstMatch(cleanDetail);
          if (prizeMatch != null) {
            race.prize = prizeMatch.group(1)!;
            String? currency = prizeMatch.group(2);
            if (currency != null && currency.isNotEmpty) {
              // Map currency codes to symbols
              if (currency.toLowerCase() == 't' || currency.toUpperCase() == 'TL') {
                race.prize += ' ₺';
              } else if (currency.toUpperCase() == 'EUR') {
                race.prize += ' €';
              } else if (currency.toUpperCase() == 'GBP') {
                race.prize += ' £';
              } else {
                race.prize += ' $currency';
              }
            }
            print('  ✓ Prize: ${race.prize}');
          }
        } else {
          print('Could not find detail for Race ${race.raceNo}');
        }
      }
    } else {
      print('Warning: "Tüm Koşular" section not found, trying individual race blocks');
      
      // Fallback: Try to parse from individual race blocks (old logic)
      for (int i = 0; i < matches.length; i++) {
        var match = matches[i];
        int start = match.start;
        int end = (i < matches.length - 1) ? matches[i+1].start : fullText.length;
        String raceText = fullText.substring(start, end);
        String cleanText = raceText.replaceAll(RegExp(r'\s+'), ' ').trim();

        var race = races[i];
        
        // Extract distance and track
        var distTrackMatch = RegExp(r'kg\s*,\s*(\d{3,4})\s+(Çim|Kum|Sentetik|Tapeta)', caseSensitive: false).firstMatch(cleanText);
        if (distTrackMatch != null) {
          race.distance = distTrackMatch.group(1)!;
          race.trackType = distTrackMatch.group(2)!;
          if (race.trackType.toLowerCase() == 'tapeta') race.trackType = 'Sentetik';
        }

        // Extract race name
        var nameMatch = RegExp(r'(ŞARTLI\s*\d+|Maiden|MAIDEN|Handikap|KV-\d+|SATIŞ)', caseSensitive: false).firstMatch(cleanText);
        if (nameMatch != null) {
          race.raceName = nameMatch.group(0)!;
        }

        // Extract prize
        var prizeMatch = RegExp(r'(?:Ikramiye|İkramiye)[^\d]*1\.\)\s*([\d.]+)\s*([t\$€£]|TL|EUR|GBP)?', caseSensitive: false).firstMatch(cleanText);
        if (prizeMatch != null) {
          race.prize = prizeMatch.group(1)!;
          String? currency = prizeMatch.group(2);
          if (currency != null && currency.isNotEmpty) {
            // Map currency codes to symbols
            if (currency.toLowerCase() == 't' || currency.toUpperCase() == 'TL') {
              race.prize += ' ₺';
            } else if (currency.toUpperCase() == 'EUR') {
              race.prize += ' €';
            } else if (currency.toUpperCase() == 'GBP') {
              race.prize += ' £';
            } else {
              race.prize += ' $currency';
            }
          }
        }
      }
    }
    
    print('Parsed ${races.length} races successfully');

    // PASS 3: Parse Horses
    try {
      var tables = document.querySelectorAll('table');
      // Filter tables that look like race tables (contain "At İsmi" and "Jokey")
      var raceTables = tables.where((t) {
        var text = t.text.toLowerCase();
        return text.contains('at ismi') && text.contains('jokey');
      }).toList();

      print('Found ${raceTables.length} potential race tables');

      if (raceTables.length >= races.length) {
        for (int i = 0; i < races.length; i++) {
          print('Parsing horses for Race ${races[i].raceNo} from table $i');
          races[i].horses = _parseHorsesFromTable(raceTables[i]);
          print('Koşu ${races[i].raceNo} için ${races[i].horses.length} at bulundu.');
        }
      } else {
        print('Warning: Found ${raceTables.length} tables but expected ${races.length} races. Trying to map available tables.');
        for (int i = 0; i < raceTables.length && i < races.length; i++) {
           races[i].horses = _parseHorsesFromTable(raceTables[i]);
        }
      }
    } catch (e) {
      print('Error parsing horses: $e');
    }

    return races;
  }

  List<RunningHorse> _parseHorsesFromTable(Element table) {
    List<RunningHorse> horses = [];
    
    // Get all rows directly from table, ignoring tbody structure which might be missing/parsed differently
    var rows = table.querySelectorAll('tr');
    print('Bulunan Satır Sayısı: ${rows.length}');

    for (var row in rows) {
      // Skip header rows (rows with th or no td)
      if (row.querySelectorAll('td').isEmpty || row.querySelectorAll('th').isNotEmpty) {
        continue;
      }

      // At No: .gunluk-GunlukYarisProgrami-SiraId
      var noCell = row.querySelector('.gunluk-GunlukYarisProgrami-SiraId');
      String no = noCell?.text.trim() ?? '';
      
      // At İsmi: .gunluk-GunlukYarisProgrami-AtAdi a
      var nameCell = row.querySelector('.gunluk-GunlukYarisProgrami-AtAdi');
      // Try to get text from <a> tag first, if not found use cell text but be careful
      var nameAnchor = nameCell?.querySelector('a');
      String name = nameAnchor?.text.trim() ?? '';
      String detailLink = nameAnchor?.attributes['href'] ?? ''; // YENİ: At detay linki
      
      if (name.isEmpty && nameCell != null) {
         // Fallback: get text but might include other garbage, try to clean
         name = nameCell.text.trim();
      }

      if (name.isEmpty) {
         print('UYARI: At ismi bulunamadı. Satır: ${row.outerHtml.substring(0, 100)}...');
         continue;
      }
      
      // Yaş: .gunluk-GunlukYarisProgrami-Yas
      String age = row.querySelector('.gunluk-GunlukYarisProgrami-Yas')?.text.trim() ?? '';
      
      // Kilo: .gunluk-GunlukYarisProgrami-Kilo
      String weight = row.querySelector('.gunluk-GunlukYarisProgrami-Kilo')?.text.trim() ?? '';
      
      // Jokey: .gunluk-GunlukYarisProgrami-JokeAdi a
      String jockey = row.querySelector('.gunluk-GunlukYarisProgrami-JokeAdi a')?.text.trim() ?? 
                      row.querySelector('.gunluk-GunlukYarisProgrami-JokeAdi')?.text.trim() ?? '';
      
      // Sahip: .gunluk-GunlukYarisProgrami-SahipAdi a
      String owner = row.querySelector('.gunluk-GunlukYarisProgrami-SahipAdi a')?.text.trim() ?? 
                     row.querySelector('.gunluk-GunlukYarisProgrami-SahipAdi')?.text.trim() ?? '';
      
      // Son 6 Yarış: .gunluk-GunlukYarisProgrami-Son6Yaris
      String last6 = row.querySelector('.gunluk-GunlukYarisProgrami-Son6Yaris')?.text.trim() ?? '';

      // Antrenör: .gunluk-GunlukYarisProgrami-AntronorAdi
      String trainer = row.querySelector('.gunluk-GunlukYarisProgrami-AntronorAdi')?.text.trim() ?? '';

      // HP: .gunluk-GunlukYarisProgrami-Hc
      String hp = row.querySelector('.gunluk-GunlukYarisProgrami-Hc')?.text.trim() ?? '';

      // KGS: .gunluk-GunlukYarisProgrami-KGS
      String kgs = row.querySelector('.gunluk-GunlukYarisProgrami-KGS')?.text.trim() ?? '';

      // s20: .gunluk-GunlukYarisProgrami-s20 (Guessing selector based on pattern, or standard TJK class)
      // Usually it is s20 or S20. Let's try case insensitive or standard casing.
      String s20 = row.querySelector('.gunluk-GunlukYarisProgrami-s20')?.text.trim() ?? 
                   row.querySelector('.gunluk-GunlukYarisProgrami-S20')?.text.trim() ?? '';

      // Derece (Best Rating): .gunluk-GunlukYarisProgrami-DERECE
      String rawBestRating = row.querySelector('.gunluk-GunlukYarisProgrami-DERECE')?.text.trim() ?? '';
      // Extract only the time (e.g., 2.04.96) using regex or split
      // Assuming format is like "2.04.96 (12.10.2023)" or just "2.04.96"
      String bestRating = rawBestRating.split(' ')[0].trim(); 
      // If split result is empty or not a valid looking time, fallback to raw but cleaner
      if (bestRating.isEmpty) bestRating = rawBestRating;

      // AGF: .gunluk-GunlukYarisProgrami-AGFORAN
      String agf = row.querySelector('.gunluk-GunlukYarisProgrami-AGFORAN')?.text.trim() ?? '';

      // Orijin (Baba - Anne): .gunluk-GunlukYarisProgrami-Baba
      String rawOrigin = row.querySelector('.gunluk-GunlukYarisProgrami-Baba')?.text ?? '';
      // Clean up excessive whitespace (newlines, tabs, multiple spaces) -> single space
      String origin = rawOrigin.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      String father = '';
      String mother = '';
      if (origin.contains(' - ')) {
        var parts = origin.split(' - ');
        if (parts.length >= 2) {
          father = parts[0].trim();
          mother = parts[1].trim();
          // Remove any trailing "/" or extra info from mother's name
          mother = mother.split('/')[0].trim();
        } else {
          father = origin;
        }
      } else {
        father = origin;
      }
      
      if (name.isNotEmpty && no.isNotEmpty) {
        horses.add(RunningHorse(
          no: no, 
          name: name, 
          jockey: jockey, 
          weight: weight,
          age: age,
          owner: owner,
          last6: last6,
          father: father,
          mother: mother,
          trainer: trainer,
          hp: hp,
          kgs: kgs,
          s20: s20,
          bestRating: bestRating,
          agf: agf,
          detailLink: detailLink, // YENİ: At detay linki eklendi
        ));
        print('At Eklendi: $name (Link: $detailLink)');
      }
    }
    return horses;
  }
}

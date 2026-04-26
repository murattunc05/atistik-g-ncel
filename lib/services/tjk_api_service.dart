import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TjkApiService {
  // ── 24 Saatlik Analiz Önbelleği ─────────────────────────────
  // RAM'de sıcak katman: uygulama açıkken anında erişim
  static final Map<String, Map<String, dynamic>> _memCache = {};

  static const String _prefPrefix = 'analysis_cache_';
  static const String _prefTsPrefix = 'analysis_ts_';
  static const Duration _cacheTtl = Duration(hours: 24);

  /// Disk önbelleğindeki girişi oku (süresi geçmediyse)
  static Future<Map<String, dynamic>?> _readFromDisk(String raceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt('$_prefTsPrefix$raceId');
      if (ts == null) return null;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > _cacheTtl.inMilliseconds) {
        // Süresi dolmuş — temizle
        prefs.remove('$_prefPrefix$raceId');
        prefs.remove('$_prefTsPrefix$raceId');
        return null;
      }
      final raw = prefs.getString('$_prefPrefix$raceId');
      if (raw == null) return null;
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  /// Disk önbelleğine yaz
  static Future<void> _writeToDisk(String raceId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefPrefix$raceId', jsonEncode(data));
      await prefs.setInt('$_prefTsPrefix$raceId', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  // API base URL - PRODUCTION (Render.com)
  static const String baseUrl = 'https://atistik-backend.onrender.com';

  // TJK direct URLs - For daily races (no backend needed)
  static const String tjkBaseUrl = 'https://www.tjk.org';
  
  /// At arama
  static Future<Map<String, dynamic>> searchHorses({
    String? horseName,
    String? breed,
    String? gender,
    String? age,
    String? country,
    String? fatherName,
    String? motherName,
    String? ownerName,
    String? trainerName,
    String? breederName,
    bool includeDeadHorses = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/search-horses'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'horseName': horseName ?? '',
          'breed': breed ?? 'Tümü',
          'gender': gender ?? 'Tümü',
          'age': age ?? '',
          'country': country ?? 'Tümü',
          'fatherName': fatherName ?? '',
          'motherName': motherName ?? '',
          'ownerName': ownerName ?? '',
          'trainerName': trainerName ?? '',
          'breederName': breederName ?? '',
          'includeDeadHorses': includeDeadHorses,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        return {
          'success': false,
          'error': 'Sunucu hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Bağlantı hatası: $e',
      };
    }
  }
  
  /// At detay bilgilerini getir
  static Future<Map<String, dynamic>> getHorseDetails(String detailLink) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/horse-details'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'detailLink': detailLink,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        return {
          'success': false,
          'error': 'Sunucu hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Bağlantı hatası: $e',
      };
    }
  }
  
  /// Yarış Analizi - Gelişmiş AI Engine
  /// Aynı raceId 24 saat içinde analiz edildiyse diskten anında döner.
  static Future<Map<String, dynamic>> analyzeRace({
    required List<Map<String, dynamic>> horses,
    String targetDistance = '',
    String targetTrack = '',
    String raceId = '',
    String raceType = '',
  }) async {
    if (raceId.isNotEmpty) {
      // 1. RAM kontrol
      if (_memCache.containsKey(raceId)) return _memCache[raceId]!;
      // 2. Disk kontrol
      final cached = await _readFromDisk(raceId);
      if (cached != null) {
        _memCache[raceId] = cached; // RAM'e de al
        return cached;
      }
    }

    // 3. Sunucu çağrısı
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/analyze-race'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'horses': horses,
          'targetDistance': targetDistance,
          'targetTrack': targetTrack,
          'raceId': raceId,
          'raceType': raceType,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (raceId.isNotEmpty && data['success'] == true) {
          _memCache[raceId] = data;
          _writeToDisk(raceId, data); // Arka planda kaydet
        }
        return data;
      } else {
        return {'success': false, 'error': 'Sunucu hatası: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Bağlantı hatası: $e'};
    }
  }

  /// Belirtilen koşunun önbelleğini temizle
  static Future<void> clearCache(String raceId) async {
    _memCache.remove(raceId);
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('$_prefPrefix$raceId');
    prefs.remove('$_prefTsPrefix$raceId');
  }

  /// Tüm önbelleği temizle
  static Future<void> clearAllCache() async {
    _memCache.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefPrefix) || k.startsWith(_prefTsPrefix));
    for (final k in keys) prefs.remove(k);
  }

  /// Yarış arama
  static Future<Map<String, dynamic>> searchRaces({
    String? startDate,
    String? endDate,
    String? city,
    String? raceType,
    String? distance,
    String? fatherName,
    String? motherName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/search-races'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'startDate': startDate ?? '',
          'endDate': endDate ?? '',
          'city': city ?? '',
          'raceType': raceType ?? '',
          'distance': distance ?? '',
          'fatherName': fatherName ?? '',
          'motherName': motherName ?? '',
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        return {
          'success': false,
          'error': 'Sunucu hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Bağlantı hatası: $e',
      };
    }
  }
  
  /// Günün koşularını Backend üzerinden getir
  static Future<Map<String, dynamic>> getDailyRaces(DateTime date, {String cityId = '1'}) async {
    try {
      final String formattedDate = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      final response = await http.get(
        Uri.parse('$baseUrl/daily-program?date=$formattedDate&cityId=$cityId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        return {'success': false, 'error': 'Sunucu hatası: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Bağlantı hatası: $e'};
    }
  }

  /// FAZ 7: Koşu sonuçlarını at geçmişinden otomatik çek
  /// Her atın TJK geçmişine bakarak o günkü bitiş sırasını bulur.
  static Future<Map<String, dynamic>> fetchRaceResults({
    required String raceDate,   // "24.04.2026"
    required String raceNo,     // "3"
    required List<Map<String, dynamic>> horses, // [{"name": "...", "detailLink": "..."}]
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/fetch-race-results'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'race_date': raceDate,
          'race_no':   raceNo,
          'horses':    horses,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        return {'success': false, 'error': 'Sunucu hatası: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Bağlantı hatası: $e'};
    }
  }


  /// Sunucu sağlık kontrolü
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// FAZ 7: Gerçek yarış sonuçlarını ML eğitimi için gönder
  /// [raceId] — analyze_race'de backend'in kaydettiği race_id
  /// [results] — [{'horse_name': 'ERDEK', 'finish_pos': 1}, ...]
  static Future<Map<String, dynamic>> submitResults({
    required String raceId,
    required List<Map<String, dynamic>> results,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/submit-results'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'race_id': raceId,
          'results': results,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        return {
          'success': false,
          'error': 'Sunucu hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Bağlantı hatası: $e'};
    }
  }
}

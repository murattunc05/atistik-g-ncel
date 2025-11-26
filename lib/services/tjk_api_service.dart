import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class TjkApiService {
  // API base URL - Production (Railway) - For horse/race search features
  static const String baseUrl = 'https://web-production-09256.up.railway.app';
  
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
  
  /// Yarış Analizi
  static Future<Map<String, dynamic>> analyzeRace(List<Map<String, String>> horses) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/analyze-race'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'horses': horses,
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
      // Tarihi formatla: dd/MM/yyyy
      final String formattedDate = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      
      final response = await http.get(
        Uri.parse('$baseUrl/daily-program?date=$formattedDate&cityId=$cityId'),
        headers: {'Content-Type': 'application/json'},
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
  
  /// Sunucu sağlık kontrolü
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

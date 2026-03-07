import 'package:flutter/material.dart';
import '../services/tjk_api_service.dart';
import '../theme/app_theme.dart';

class RaceAnalysisScreen extends StatefulWidget {
  final List<Map<String, dynamic>> horses;
  final String raceName;
  final String distance;
  final String trackType;
  final String prize;
  final String raceType; // maiden, şartlı, handikap vs.
  final String raceId;   // YENİ: İdman bilgileri için koşu ID'si

  const RaceAnalysisScreen({
    super.key,
    required this.horses,
    this.raceName = '',
    this.distance = '',
    this.trackType = '',
    this.prize = '',
    this.raceType = '',
    this.raceId = '',
  });

  @override
  State<RaceAnalysisScreen> createState() => _RaceAnalysisScreenState();
}

class _RaceAnalysisScreenState extends State<RaceAnalysisScreen> 
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _results = [];
  double _processTime = 0;
  late AnimationController _animController;
  int? _expandedIndex; // Artık kullanılmıyor ama referans kalmışsa hata vermesin

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _fetchAnalysis();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnalysis() async {
    try {
      final result = await TjkApiService.analyzeRace(
        horses: widget.horses.map((h) => {
          'name': h['name']?.toString() ?? '',
          'detailLink': h['detailLink']?.toString() ?? '',
          'no': h['no']?.toString() ?? '',
          'jockey': h['jockey']?.toString() ?? '',
          'weight': h['weight']?.toString() ?? '',
        }).toList(),
        targetDistance: widget.distance,
        targetTrack: widget.trackType,
        raceId: widget.raceId,  // İdman bilgileri için
      );

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _results = result['results'] ?? [];
            _processTime = (result['processTime'] as num?)?.toDouble() ?? 0;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result['error'] ?? 'Bilinmeyen hata';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.backgroundLight : AppTheme.backgroundLightMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Yarış Analizi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor)),
        actions: [
          if (!_isLoading && _error == null)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${_processTime}s', style: TextStyle(color: subtextColor, fontSize: 12)),
            ),
        ],
      ),
      body: _isLoading 
          ? _buildLoading(isDark) 
          : _error != null 
              ? _buildError(isDark) 
              : _buildResults(isDark),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // TODO: Gelecekte buraya koşan at animasyonu eklenecek
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text('Analiz ediliyor...', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('${widget.horses.length} at için veri çekiliyor', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(_error ?? '', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () { setState(() { _isLoading = true; _error = null; }); _fetchAnalysis(); },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Tekrar Dene'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    if (_results.isEmpty) return Center(child: Text('Sonuç yok', style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600])));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _results.length + 2, // +2 for race info header and prediction card
      itemBuilder: (context, index) {
        if (index == 0) return _buildRaceInfoHeader(isDark); // Yarış bilgisi üstüne
        if (index == 1) return _buildPredictionCard(isDark);  // Tahmin kartı altına
        return _buildHorseCard(_results[index - 2], index - 2, isDark);
      },
    );
  }

  Widget _buildPredictionCard(bool isDark) {
    if (_results.isEmpty) return const SizedBox.shrink();
    
    // Kazanan at bilgilerini al
    final winner = _results.first;
    final name = winner['name']?.toString() ?? 'Bilinmiyor';
    // At numarasını temizle
    String winnerNo = winner['no']?.toString() ?? '';
    winnerNo = winnerNo.replaceAll(RegExp(r'[()\\s]'), '').trim();
    final aiScore = (winner['aiScore'] as num?)?.toDouble() ?? 0;
    final stats = winner['stats'] as Map<String, dynamic>? ?? {};
    final jockeyStats = winner['jockeyStats'] as Map<String, dynamic>?;
    final raceCount = winner['raceCount'] ?? 0;
    final formIndex = winner['formIndex'] as Map<String, dynamic>?;
    final bestTime = winner['bestTime']?.toString();
    final weightChange = winner['weightChange'] as num?;
    final raceHistory = winner['raceHistory'] as List<dynamic>? ?? [];
    final trainingInfo = winner['trainingInfo'] as Map<String, dynamic>?;
    
    // Açıklama metni oluştur - Daha detaylı
    List<Map<String, dynamic>> reasons = [];
    
    // Pist ve mesafe galibiyetleri
    if (stats['trackWins'] != null && stats['trackWins'] > 0) {
      reasons.add({'icon': Icons.location_on, 'text': 'Bu pistte ${stats['trackWins']} galibiyet', 'highlight': true});
    }
    if (stats['distanceWins'] != null && stats['distanceWins'] > 0) {
      reasons.add({'icon': Icons.straighten, 'text': 'Bu mesafede ${stats['distanceWins']} galibiyet', 'highlight': true});
    }
    
    // Kazanma ve podyum oranları
    if (stats['winRate'] != null && stats['winRate'] > 0) {
      reasons.add({'icon': Icons.emoji_events, 'text': '%${stats['winRate']} kazanma oranı', 'highlight': stats['winRate'] >= 20});
    }
    if (stats['podiumRate'] != null && stats['podiumRate'] > 0) {
      reasons.add({'icon': Icons.looks_3, 'text': '%${stats['podiumRate']} ilk 3\'e girme oranı', 'highlight': stats['podiumRate'] >= 40});
    }
    
    // Ortalama sıralama
    if (stats['avgRank'] != null) {
      final avgRank = stats['avgRank'] as num;
      reasons.add({'icon': Icons.leaderboard, 'text': 'Ortalama sıralama: ${avgRank.toStringAsFixed(1)}', 'highlight': avgRank <= 3});
    }
    
    // Jokey performansı
    if (jockeyStats != null && jockeyStats['wins'] != null && jockeyStats['totalRaces'] != null) {
      final jockeyWinRate = jockeyStats['totalRaces'] > 0 
          ? ((jockeyStats['wins'] / jockeyStats['totalRaces']) * 100).toStringAsFixed(0)
          : '0';
      reasons.add({
        'icon': Icons.person, 
        'text': 'Jokey: ${jockeyStats['name'] ?? 'Bilinmiyor'} (%$jockeyWinRate - ${jockeyStats['wins']}/${jockeyStats['totalRaces']})', 
        'highlight': (jockeyStats['wins'] as num) > 0
      });
    }
    
    // Form trendi
    if (formIndex != null && formIndex['trend'] != null) {
      final trend = formIndex['trend'].toString();
      if (trend == 'UP') {
        reasons.add({'icon': Icons.trending_up, 'text': 'Form yükseliş trendinde', 'highlight': true});
      }
    }
    
    // En iyi derece
    if (bestTime != null && bestTime.isNotEmpty && bestTime != 'null') {
      reasons.add({'icon': Icons.timer, 'text': 'En iyi derece: $bestTime', 'highlight': false});
    }
    
    // Kilo avantajı
    if (weightChange != null && weightChange < 0) {
      reasons.add({'icon': Icons.fitness_center, 'text': 'Kilo avantajı: ${weightChange}kg', 'highlight': true});
    }
    
    // İdman bilgileri
    if (trainingInfo != null && trainingInfo['hasData'] == true) {
      final daysSince = trainingInfo['daysSinceTraining'] as int?;
      final fitnessScore = trainingInfo['fitnessScore'] as num?;
      final trainingDate = trainingInfo['trainingDate']?.toString() ?? '';
      
      if (daysSince != null && daysSince >= 1 && daysSince <= 7) {
        reasons.add({
          'icon': Icons.directions_run, 
          'text': '$daysSince gün önce idman yaptı${fitnessScore != null && fitnessScore >= 65 ? ' (iyi form)' : ''}', 
          'highlight': daysSince >= 2 && daysSince <= 5
        });
      } else if (trainingDate.isNotEmpty) {
        reasons.add({
          'icon': Icons.directions_run, 
          'text': 'Son idman: $trainingDate', 
          'highlight': false
        });
      }
    }
    
    // Tutarlılık - son yarışlarda sürekli iyi derecelere bakalım
    if (raceHistory.isNotEmpty) {
      final goodFinishes = raceHistory.take(5).where((r) {
        final rank = int.tryParse(r['rank']?.toString() ?? '99') ?? 99;
        return rank <= 3;
      }).length;
      if (goodFinishes >= 3) {
        reasons.add({'icon': Icons.verified, 'text': 'Son 5 yarışın ${goodFinishes}\'inde podyum', 'highlight': true});
      }
    }
    
    // Yarış sayısı (son çare)
    if (reasons.isEmpty && raceCount > 0) {
      reasons.add({'icon': Icons.analytics, 'text': '$raceCount yarış verisi analiz edildi', 'highlight': false});
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header - Kırmızı başlık
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'TAHMİN ANALİZİ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Puan: ${aiScore.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Body - Kazanan bilgisi
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İstatistiklere göre en yüksek performans beklentisi:',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (winnerNo.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text('#$winnerNo', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 9, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (reasons.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.insights, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Öne Çıkan Faktörler',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...reasons.map((reason) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                reason['icon'] as IconData, 
                                size: 14, 
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  reason['text'] as String,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
                
                // Disclaimer
                const SizedBox(height: 12),
                Text(
                  '* Bu analiz yalnızca geçmiş verilere dayalı matematiksel bir çıkarımdır. Kesinlik içermez ve yatırım tavsiyesi değildir.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceInfoHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yarış Tipi (Maiden, Şartlı, Handikap vs)
          if (widget.raceType.isNotEmpty)
            Text(
              widget.raceType.toUpperCase(),
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          const SizedBox(height: 8),
          
          // Bilgi satırları - Grid style
          Row(
            children: [
              // Mesafe
              Expanded(
                child: _buildInfoItem(Icons.straighten, 'Mesafe', widget.distance, isDark),
              ),
              const SizedBox(width: 12),
              // Pist
              Expanded(
                child: _buildInfoItem(Icons.terrain, 'Pist', widget.trackType, isDark),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // At Sayısı
              Expanded(
                child: _buildInfoItem(Icons.pets, 'Katılımcı', '${_results.length} at', isDark),
              ),
              const SizedBox(width: 8),
              // Ödül
              Expanded(
                child: _buildInfoItem(Icons.emoji_events, 'Ödül', widget.prize.isNotEmpty ? widget.prize : '-', isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    fontSize: 9,
                  ),
                ),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    // Artık kullanım dışı, _buildRaceInfoHeader kullanılıyor
    return const SizedBox.shrink();
  }

  Widget _buildHorseCard(dynamic horse, int index, bool isDark) {
    final aiScore = (horse['aiScore'] as num?)?.toDouble() ?? 0;
    final rank = horse['rank'] ?? (index + 1);
    final name = horse['name']?.toString() ?? '';
    String horseNo = horse['no']?.toString() ?? '';
    horseNo = horseNo.replaceAll(RegExp(r'[()\\s]'), '').trim();
    final formTrend = horse['formIndex']?['trend']?.toString() ?? '';
    final isWinner = rank == 1;
    final degreeStats = horse['degreeStats'] as Map<String, dynamic>? ?? {};
    final bestDegree = degreeStats['bestDegreeFormatted']?.toString() ?? '';

    Color scoreColor = Colors.grey;
    if (aiScore >= 70) scoreColor = Colors.green;
    else if (aiScore >= 50) scoreColor = Colors.orange;
    else if (aiScore >= 30) scoreColor = Colors.red[400]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161618) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isWinner 
            ? Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5) 
            : isDark ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: () => _showHorseDetailSheet(horse, isDark),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: isWinner ? LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)]) : null,
                  color: isWinner ? null : (isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: isWinner 
                    ? const Icon(Icons.emoji_events, color: Colors.white, size: 18)
                    : Text('$rank', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              
              // Name, form and best degree
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name, 
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: isWinner ? FontWeight.bold : FontWeight.w500, fontSize: isWinner ? 15 : 14), 
                      overflow: TextOverflow.ellipsis, maxLines: 1,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (horseNo.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text('#$horseNo', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 9, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (formTrend.isNotEmpty && formTrend != '-') ...[
                          Icon(
                            formTrend == 'UP' ? Icons.trending_up : formTrend == 'DOWN' ? Icons.trending_down : Icons.trending_flat,
                            size: 12,
                            color: formTrend == 'UP' ? Colors.green : formTrend == 'DOWN' ? Colors.red[400] : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formTrend == 'UP' ? 'Yükselişte' : formTrend == 'DOWN' ? 'Düşüşte' : 'Stabil',
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                        if (bestDegree.isNotEmpty && bestDegree != '-') ...[
                          const SizedBox(width: 6),
                          Icon(Icons.timer_outlined, size: 11, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Text(bestDegree, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scoreColor.withOpacity(0.3)),
                ),
                child: Text(aiScore.toStringAsFixed(0), style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // === BOTTOM SHEET POP-UP ===
  void _showHorseDetailSheet(dynamic horse, bool isDark) {
    final name = horse['name']?.toString() ?? 'Bilinmiyor';
    final aiScore = (horse['aiScore'] as num?)?.toDouble() ?? 0;
    String horseNo = horse['no']?.toString() ?? '';
    horseNo = horseNo.replaceAll(RegExp(r'[()\\s]'), '').trim();
    final formTrend = horse['formIndex']?['trend']?.toString() ?? '';
    final prediction = horse['prediction']?.toString() ?? '';
    final insight = horse['insight']?.toString() ?? '';
    final raceHistory = horse['raceHistory'] as List<dynamic>? ?? [];
    final filteredRaces = horse['filteredRaces'] as List<dynamic>? ?? [];
    final degreeStats = horse['degreeStats'] as Map<String, dynamic>? ?? {};
    final stats = horse['stats'] as Map<String, dynamic>? ?? {};
    final raceCount = horse['raceCount'] ?? 0;
    final filteredRaceCount = horse['filteredRaceCount'] ?? 0;
    final jockeyStats = horse['jockeyStats'] as Map<String, dynamic>?;
    final weightChange = horse['weightChange'] as num?;

    Color scoreColor = Colors.grey;
    if (aiScore >= 70) scoreColor = Colors.green;
    else if (aiScore >= 50) scoreColor = Colors.orange;
    else if (aiScore >= 30) scoreColor = Colors.red[400]!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                ),

                // === HEADER ===
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (horseNo.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                        child: Text('#$horseNo', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (formTrend.isNotEmpty && formTrend != '-') ...[
                                      Icon(
                                        formTrend == 'UP' ? Icons.trending_up : formTrend == 'DOWN' ? Icons.trending_down : Icons.trending_flat,
                                        size: 14, color: formTrend == 'UP' ? Colors.green : formTrend == 'DOWN' ? Colors.red[400] : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        formTrend == 'UP' ? 'Yükselişte' : formTrend == 'DOWN' ? 'Düşüşte' : 'Stabil',
                                        style: TextStyle(color: formTrend == 'UP' ? Colors.green : formTrend == 'DOWN' ? Colors.red[400] : Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // AI Skor
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: scoreColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: scoreColor.withOpacity(0.4)),
                            ),
                            child: Column(
                              children: [
                                Text(aiScore.toStringAsFixed(0), style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 22)),
                                Text('AI Skor', style: TextStyle(color: scoreColor.withOpacity(0.7), fontSize: 9)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (prediction.isNotEmpty && prediction != 'Veri Yok') ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prediction, style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                              if (insight.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(insight, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // === DERECE İSTATİSTİKLERİ ===
                if (degreeStats.isNotEmpty && degreeStats['avgDegree'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: _buildDegreeStatBox('Ortalama', degreeStats['avgDegreeFormatted']?.toString() ?? '-', isDark, icon: Icons.speed)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildDegreeStatBox('En İyi', degreeStats['bestDegreeFormatted']?.toString() ?? '-', isDark, icon: Icons.emoji_events, isHighlight: true)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildDegreeStatBox('En Kötü', degreeStats['worstDegreeFormatted']?.toString() ?? '-', isDark, icon: Icons.speed)),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // === SEKME BAŞLIKLARI ===
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontSize: 13),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerHeight: 0,
                    tabs: const [
                      Tab(text: 'Yarışlar', height: 38),
                      Tab(text: 'İstatistikler', height: 38),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // === SEKME İÇERİĞİ ===
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildRacesTab(filteredRaces, raceHistory, raceCount, filteredRaceCount, isDark, scrollController),
                      _buildStatsTab(horse, stats, jockeyStats, weightChange, degreeStats, isDark, scrollController),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === YARIŞLAR SEKME İÇERİĞİ ===
  Widget _buildRacesTab(List<dynamic> filteredRaces, List<dynamic> raceHistory, int raceCount, int filteredRaceCount, bool isDark, ScrollController controller) {
    // SADECE mesafe bazlı filtrelenmiş yarışları göster
    final racesToShow = filteredRaces;
    final isFiltered = filteredRaces.isNotEmpty;

    if (racesToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 40, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text('Bu mesafede yarış verisi bulunamadı', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 4),
            Text('(±100m tolerans aralığı)', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: racesToShow.length + 1,
      itemBuilder: (context, index) {
        if (index == racesToShow.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                isFiltered ? '$filteredRaceCount/$raceCount yarış (mesafe bazlı)' : '$raceCount yarış verisi',
                style: TextStyle(color: Colors.grey[600], fontSize: 10, fontStyle: FontStyle.italic),
              ),
            ),
          );
        }

        final race = racesToShow[index];
        final rank = race['rank']?.toString() ?? '-';
        final degree = race['degree']?.toString() ?? '-';
        final date = race['date']?.toString() ?? '';
        final city = race['city']?.toString() ?? '';
        final group = race['group']?.toString() ?? '';
        final trackCond = race['trackCondition']?.toString() ?? '';
        final distance = race['distance']?.toString() ?? '';
        final jockey = race['jockey']?.toString() ?? '';


        Color rankColor = Colors.grey;
        if (rank == '1') rankColor = Colors.green;
        else if (rank == '2') rankColor = Colors.blue;
        else if (rank == '3') rankColor = Colors.orange;
        else if (rank == '0' || rank.contains('k')) rankColor = Colors.red[700]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: rankColor, borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text(rank == '0' ? 'X' : rank, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(degree, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (group.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(group, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 9, fontWeight: FontWeight.w500)),
                          ),
                        if (group.isNotEmpty && distance.isNotEmpty) const SizedBox(width: 4),
                        if (distance.isNotEmpty)
                          Text('${distance}m', style: TextStyle(color: Colors.grey[500], fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
              if (jockey.isNotEmpty)
                Expanded(
                  flex: 2,
                  child: Text(jockey, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(date, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 10)),
                    if (city.isNotEmpty) Text(city, style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500], fontSize: 9)),
                    if (trackCond.isNotEmpty)
                      Text(trackCond, style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[500], fontSize: 8)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // === ISTATISTIKLER SEKME ICERIGI ===
  Widget _buildStatsTab(dynamic horse, Map<String, dynamic> stats, Map<String, dynamic>? jockeyStats, num? weightChange, Map<String, dynamic> degreeStats, bool isDark, ScrollController controller) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        if (jockeyStats != null && jockeyStats['name'] != null && jockeyStats['name'].toString().isNotEmpty) ...[
          _buildSectionTitle('Jokey', isDark),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildDetailInfoBox(Icons.person, 'Jokey', jockeyStats['name'].toString(), subtitle: '${jockeyStats['wins']}/${jockeyStats['totalRaces']} galibiyet', isDark: isDark)),
              if (weightChange != null && weightChange != 0) ...[
                const SizedBox(width: 8),
                Expanded(child: _buildDetailInfoBox(weightChange > 0 ? Icons.arrow_upward : Icons.arrow_downward, 'Kilo Değişimi', '${weightChange > 0 ? '+' : ''}${weightChange}kg', isDark: isDark, isPositive: weightChange < 0, isNegative: weightChange > 0)),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],

        if (stats.isNotEmpty) ...[
          _buildSectionTitle('Yarış İstatistikleri', isDark),
          const SizedBox(height: 6),
          Row(
            children: [
              if (stats['winRate'] != null) Expanded(child: _buildMiniStat('Kazanma', '${stats['winRate']}%', isDark)),
              if (stats['podiumRate'] != null) Expanded(child: _buildMiniStat('İlk 3', '${stats['podiumRate']}%', isDark)),
              if (stats['avgRank'] != null) Expanded(child: _buildMiniStat('Ort. Sıra', stats['avgRank'].toStringAsFixed(1), isDark)),
            ],
          ),
          const SizedBox(height: 16),
        ],

        if (degreeStats.isNotEmpty && degreeStats['degreeTrend'] != null) ...[
          _buildSectionTitle('Derece Detayları', isDark),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildMiniStat('Trend', (degreeStats['degreeTrend'] as num) > 0 ? 'Iyilesiyor' : (degreeStats['degreeTrend'] as num) < 0 ? 'Kotulesiyor' : 'Stabil', isDark)),
              Expanded(child: _buildMiniStat('İstikrar', '${((degreeStats['degreeStdDev'] ?? 0) as num).toStringAsFixed(2)}s', isDark)),
              Expanded(child: _buildMiniStat('Yarış', '${degreeStats['raceCount'] ?? 0}', isDark)),
            ],
          ),
          const SizedBox(height: 16),
        ],

        if (horse['trainingInfo'] != null && horse['trainingInfo']['hasData'] == true) ...[
          _buildSectionTitle('İdman Bilgileri', isDark),
          const SizedBox(height: 6),
          Builder(builder: (context) {
            final ti = horse['trainingInfo'] as Map<String, dynamic>;
            final daysSince = ti['daysSinceTraining'] as int?;
            final fitnessLabel = ti['fitnessLabel']?.toString() ?? '';
            final fitnessScore = (ti['fitnessScore'] as num?)?.toDouble() ?? 0;
            final trainingDate = ti['trainingDate']?.toString() ?? '';
            final hippodrome = ti['hippodrome']?.toString() ?? '';
            final trackCondition = ti['trackCondition']?.toString() ?? '';
            final trainingJockey = ti['trainingJockey']?.toString() ?? '';
            final times = ti['times'] as Map<String, dynamic>? ?? {};
            final bestTrainingTime = ti['bestTrainingTime']?.toString() ?? '';
            final bestTrainingDistance = ti['bestTrainingDistance']?.toString() ?? '';

            // Fitness rengi
            Color fitnessColor = AppTheme.primary;
            if (fitnessScore >= 75) fitnessColor = Colors.green;
            else if (fitnessScore >= 50) fitnessColor = Colors.orange;
            else if (fitnessScore < 35) fitnessColor = Colors.red[400]!;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === HEADER: Tarih + Hipodrom + Fitness Badge ===
                  Row(
                    children: [
                      if (trainingDate.isNotEmpty) ...[
                        Icon(Icons.calendar_today, size: 11, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(trainingDate, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                      if (hippodrome.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.location_on, size: 11, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                        const SizedBox(width: 3),
                        Text(hippodrome, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11)),
                      ],
                      const Spacer(),
                      // Fitness badge
                      if (fitnessLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: fitnessColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: fitnessColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                fitnessScore >= 75 ? Icons.fitness_center : fitnessScore >= 50 ? Icons.trending_flat : Icons.warning_amber,
                                size: 10, color: fitnessColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$fitnessLabel${daysSince != null ? ' ($daysSince gün)' : ''}',
                                style: TextStyle(color: fitnessColor, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  // Ayırıcı çizgi
                  Container(height: 1, color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
                  const SizedBox(height: 10),

                  // === ANA İSTATİSTİK GRID: En İyi İdman + Jokey + Pist ===
                  Row(
                    children: [
                      // En İyi İdman - Büyük vurgulu kutu
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.12), AppTheme.primary.withOpacity(0.05)]),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.speed, size: 13, color: AppTheme.primary),
                                  const SizedBox(width: 4),
                                  Text('En İyi İdman', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 9)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    bestTrainingTime.isNotEmpty ? bestTrainingTime : '-',
                                    style: TextStyle(color: AppTheme.primary, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  if (bestTrainingDistance.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                        child: Text(bestTrainingDistance, style: TextStyle(color: AppTheme.primary, fontSize: 9, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Jokey + Pist kolonu
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            if (trainingJockey.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Jokey', style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[500], fontSize: 8)),
                                    const SizedBox(height: 2),
                                    Text(trainingJockey, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            if (trackCondition.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Pist', style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[500], fontSize: 8)),
                                    const SizedBox(height: 2),
                                    Text(trackCondition, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // === PROJEKSİYON KARTI (Faz 2.2) ===
                  if (ti['projectedDegree'] != null && ti['projectedDegree'].toString().isNotEmpty && ti['projectedDegree'] != '-') ...[
                    const SizedBox(height: 10),
                    Builder(builder: (context) {
                      final projectedDegree = ti['projectedDegree'].toString();
                      final projectedFromDist = ti['projectedFromDistance']?.toString() ?? '';
                      final projectionLabel = ti['projectionLabel']?.toString() ?? '';
                      final projectionDiff = (ti['projectionDiff'] as num?)?.toDouble();
                      final projectedSecs = (ti['projectedDegreeSeconds'] as num?)?.toDouble() ?? 0;
                      final avgDegFmt = (horse['degreeStats'] as Map<String, dynamic>?)?['avgDegreeFormatted']?.toString() ?? '';
                      final avgDegSecs = ((horse['degreeStats'] as Map<String, dynamic>?)?['avgDegree'] as num?)?.toDouble() ?? 0;

                      Color lColor = AppTheme.primary;
                      IconData lIcon = Icons.compare_arrows;
                      if (projectionLabel.contains('Hızlı')) { lColor = Colors.green; lIcon = Icons.bolt; }
                      else if (projectionLabel.contains('Yavaş')) { lColor = Colors.red[400]!; lIcon = Icons.speed; }
                      else if (projectionLabel.contains('Uyumlu')) { lColor = Colors.orange; lIcon = Icons.check_circle_outline; }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [lColor.withOpacity(0.10), lColor.withOpacity(0.04)]),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: lColor.withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Icon(Icons.timeline, size: 14, color: lColor),
                                const SizedBox(width: 5),
                                Text('Projeksiyon', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 9)),
                                const Spacer(),
                                if (projectedFromDist.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(color: lColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                    child: Text('$projectedFromDist\'den', style: TextStyle(color: lColor, fontSize: 8, fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Derece + fark
                            Row(
                              children: [
                                Text(projectedDegree, style: TextStyle(color: lColor, fontSize: 17, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                if (projectionDiff != null) ...[
                                  Icon(projectionDiff < 0 ? Icons.arrow_downward : projectionDiff > 0 ? Icons.arrow_upward : Icons.remove, size: 11,
                                    color: projectionDiff < 0 ? Colors.green : projectionDiff > 0 ? Colors.red[400] : Colors.grey),
                                  Text('${projectionDiff > 0 ? '+' : ''}${projectionDiff.toStringAsFixed(2)}s',
                                    style: TextStyle(color: projectionDiff < 0 ? Colors.green : projectionDiff > 0 ? Colors.red[400] : Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                                const Spacer(),
                                // Etiket
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(color: lColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(lIcon, size: 10, color: lColor),
                                    const SizedBox(width: 3),
                                    Text(projectionLabel, style: TextStyle(color: lColor, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ]),
                                ),
                              ],
                            ),
                            // Karşılaştırma barı
                            if (avgDegSecs > 0 && projectedSecs > 0) ...[
                              const SizedBox(height: 8),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text('İdman Proj.', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 8)),
                                Text('Yarış Ort.', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 8)),
                              ]),
                              const SizedBox(height: 3),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: SizedBox(
                                  height: 6,
                                  child: Stack(children: [
                                    Container(decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200, borderRadius: BorderRadius.circular(3))),
                                    FractionallySizedBox(
                                      widthFactor: (() {
                                        final mn = projectedSecs < avgDegSecs ? projectedSecs : avgDegSecs;
                                        final mx = projectedSecs > avgDegSecs ? projectedSecs : avgDegSecs;
                                        return mx > 0 ? (mn / mx).clamp(0.0, 1.0) : 0.5;
                                      })(),
                                      child: Container(decoration: BoxDecoration(color: lColor.withOpacity(0.6), borderRadius: BorderRadius.circular(3))),
                                    ),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(projectedDegree, style: TextStyle(color: lColor, fontSize: 9, fontWeight: FontWeight.bold)),
                                Text(avgDegFmt, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 9, fontWeight: FontWeight.bold)),
                              ]),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],

                  // === MESAFE SÜRELERİ GRID ===
                  if (times.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(height: 1, color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
                    const SizedBox(height: 8),
                    Text('Mesafe Süreleri', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 9, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 5, children: times.entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.primary.withOpacity(0.10) : AppTheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(e.key, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 9)),
                          const SizedBox(width: 5),
                          Text(e.value.toString(), style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                        ]),
                      );
                    }).toList()),
                  ],
                ],
              ),
            );
          }),
        ],

      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(title, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3));
  }

  Widget _buildDetailInfoBox(IconData icon, String label, String value, {
    required bool isDark,
    String? subtitle,
    String? badge,
    bool isPositive = false,
    bool isNegative = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: isPositive ? Colors.green : isNegative ? Colors.red[400] : (isDark ? Colors.grey[500] : Colors.grey[600])),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 10)),
              if (badge != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(3)),
                  child: Text(badge, style: TextStyle(color: AppTheme.primary, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            color: isPositive ? Colors.green : isNegative ? Colors.red[400] : (isDark ? Colors.white : Colors.black87),
            fontSize: 13, fontWeight: FontWeight.bold,
          )),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[500], fontSize: 9)),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[500], fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildDegreeStatBox(String label, String value, bool isDark, {IconData? icon, bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppTheme.primary.withOpacity(0.08)
            : (isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight
              ? AppTheme.primary.withOpacity(0.3)
              : (isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          if (icon != null)
            Icon(icon, size: 14, color: isHighlight ? AppTheme.primary : (isDark ? Colors.grey[500] : Colors.grey[600])),
          if (icon != null) const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? AppTheme.primary : (isDark ? Colors.white : Colors.black87),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[500], fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildTrainingChip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: isDark ? Colors.grey[500] : Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 10)),
        ],
      ),
    );
  }
}




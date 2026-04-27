import 'package:flutter/material.dart';
import '../models/daily_race_model.dart';
import '../theme/app_theme.dart';
import 'race_analysis_screen.dart';

class RaceDetailScreen extends StatefulWidget {
  final DailyRaceModel race;
  final String raceDate; // FAZ 7: ML log için (dd.MM.yyyy format)

  const RaceDetailScreen({super.key, required this.race, this.raceDate = ''});

  @override
  State<RaceDetailScreen> createState() => _RaceDetailScreenState();
}

class _RaceDetailScreenState extends State<RaceDetailScreen> {
  int? _expandedIndex;

  DailyRaceModel get race => widget.race;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundLight : AppTheme.backgroundLightMode,
      appBar: AppBar(
        title: Text('${race.time} - ${race.city}'),
      ),
      body: Column(
        children: [
          _buildInfoCard(context, isDark),
          Expanded(
            child: _buildHorseList(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, bool isDark) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: isDark ? 4 : 2,
      color: isDark ? AppTheme.backgroundDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              race.raceName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(Icons.straighten, race.distance),
                _buildInfoItem(Icons.terrain, race.trackType),
                _buildInfoItem(Icons.emoji_events, race.prize),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // At listesini Map olarak hazırla - backend için tüm gerekli bilgiler
                  final horseMaps = race.horses.map((h) => {
                    'name': h.name,
                    'no': h.no,
                    'detailLink': h.detailLink,
                    'jockey': h.jockey,
                    'weight': h.weight,
                    'father': h.father,   // FAZ 4.6: Pedigri analizi için
                    'hp': h.hp,           // FAZ 5.2: Handikap Puanı
                    'agf': h.agf,         // FAZ 5.2: AGF
                  }).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RaceAnalysisScreen(
                        horses: horseMaps,
                        raceName: race.raceName,
                        distance: race.distance,
                        trackType: race.trackType,
                        prize: race.prize,
                        raceType: race.raceName, // Maiden, Şartlı vs. raceName içinde
                        raceId: race.raceId,     // İdman bilgileri için
                        raceDate: widget.raceDate, // FAZ 7
                        raceNo: race.raceNo,       // FAZ 7
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.psychology),
                label: const Text('ANALİZ ET'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildHorseList(BuildContext context, bool isDark) {
    if (race.horses.isEmpty) {
      return Center(
        child: Text(
          'Bu koşu için at listesi bulunamadı.',
          style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: race.horses.length,
      itemBuilder: (context, index) {
        final horse = race.horses[index];
        return _buildHorseCard(horse, index, isDark);
      },
    );
  }

  Widget _buildHorseCard(RunningHorse horse, int index, bool isDark) {
    final isExpanded = _expandedIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            horse.no,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Name and jockey - use Expanded to take remaining space
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              horse.name,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (horse.age.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      horse.age, 
                                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 9),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    horse.jockey,
                                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Weight info - fixed width to prevent overflow
                      SizedBox(
                        width: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _cleanWeight(horse.weight),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (horse.agf.isNotEmpty && !horse.agf.contains('Fazla'))
                              Text(
                                horse.agf,
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey[600], size: 20),
                    ],
                  ),
                ),
              ),
              
              if (isExpanded) _buildExpandedHorseDetails(horse, isDark),
            ],
          ),
        );
  }


  Widget _buildExpandedHorseDetails(RunningHorse horse, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          
          // Row 1: Orijin ve Antrenör
          Row(
            children: [
              Expanded(
                child: _buildDetailBox(Icons.family_restroom, 'Orijin', '${horse.mother} - ${horse.father}', isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailBox(Icons.person, 'Antrenör', horse.trainer.isNotEmpty ? horse.trainer : '-', isDark),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Row 2: HP, KGS, s20 - Grid görünümü
          Row(
            children: [
              Expanded(child: _buildMiniStatBox('HP', horse.hp, isDark)),
              Expanded(child: _buildMiniStatBox('KGS', horse.kgs, isDark)),
              Expanded(child: _buildMiniStatBox('s20', horse.s20, isDark)),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Row 3: Son 6 ve Derece
          Row(
            children: [
              Expanded(
                child: _buildDetailBox(Icons.history, 'Son 6', _formatLast6(horse.last6), isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDetailBox(Icons.timer, 'Derece', horse.bestRating.isNotEmpty ? horse.bestRating : '-', isDark, valueColor: AppTheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBox(IconData icon, String label, String value, bool isDark, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 9)),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? (isDark ? Colors.white : Colors.black87),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

  Widget _buildMiniStatBox(String label, String value, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(value.isNotEmpty ? value : '-', style: TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 9)),
        ],
      ),
    );
  }

  String _formatLast6(String last6) {
    if (last6.isEmpty) return '-';
    return last6.split('').join('-');
  }

  String _cleanWeight(String weight) {
    if (weight.isEmpty) return '-';
    // "56+1.80Fazla Kilo" gibi gelen değerleri temizle, sadece ilk sayıyı al
    final match = RegExp(r'^(\d+)').firstMatch(weight);
    if (match != null) {
      return '${match.group(1)} kg';
    }
    // Eğer sayı bulamazsan olduğu gibi döndür
    return weight.replaceAll('Fazla Kilo', '').replaceAll('kg', '').trim() + ' kg';
  }
}

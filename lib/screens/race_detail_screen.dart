import 'package:flutter/material.dart';
import '../models/daily_race_model.dart';
import 'race_analysis_screen.dart';

class RaceDetailScreen extends StatelessWidget {
  final DailyRaceModel race;

  const RaceDetailScreen({super.key, required this.race});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${race.time} - ${race.city}'),
      ),
      body: Column(
        children: [
          _buildInfoCard(context),
          Expanded(
            child: _buildHorseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
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
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // At listesini hazırla
                  final horses = race.horses.map((h) => {
                    'name': h.name,
                    'detailLink': h.detailLink,
                  }).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RaceAnalysisScreen(horses: horses),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('DETAYLI ANALİZ ET'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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

  Widget _buildHorseList() {
    if (race.horses.isEmpty) {
      return const Center(
        child: Text('Bu koşu için at listesi bulunamadı.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: race.horses.length,
      itemBuilder: (context, index) {
        final horse = race.horses[index];
        return Card(
          color: const Color(0xFF202022),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                child: Text(
                  horse.no,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: RichText(
                text: TextSpan(
                  text: horse.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  children: [
                    if (horse.age.isNotEmpty)
                      TextSpan(
                        text: ' (${horse.age})',
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
              subtitle: Text(
                horse.jockey,
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${horse.weight} kg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (horse.agf.isNotEmpty)
                    Text(
                      horse.agf,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      
                      // Row 1: Origin
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Orijin',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${horse.mother} - ${horse.father}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Row 2: Trainer
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Antrenör',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            horse.trainer.isNotEmpty ? horse.trainer : '-',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Row 2: Critical Stats (HP | KGS | s20)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFocusStat('HP', horse.hp),
                          _buildFocusStat('KGS', horse.kgs),
                          _buildFocusStat('s20', horse.s20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Row 3: Performance (Last 6 & Degree)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Text(
                                  'Son 6: ',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                                Expanded(
                                  child: Text(
                                    _formatLast6(horse.last6),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                'Derece: ',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                              Text(
                                horse.bestRating.isNotEmpty ? horse.bestRating : '-',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFocusStat(String label, String value) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            value.isNotEmpty ? value : '-',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatLast6(String last6) {
    if (last6.isEmpty) return '-';
    return last6.split('').join('-');
  }
}

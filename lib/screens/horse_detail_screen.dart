import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tjk_api_service.dart';
import '../services/comparison_service.dart';
import '../widgets/comparison_bottom_sheet.dart';

class HorseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> horseData;
  
  const HorseDetailScreen({super.key, required this.horseData});

  @override
  State<HorseDetailScreen> createState() => _HorseDetailScreenState();
}

class _HorseDetailScreenState extends State<HorseDetailScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _raceHistory = [];
  
  @override
  void initState() {
    super.initState();
    _loadRaceHistory();
  }
  
  Future<void> _loadRaceHistory() async {
    if (widget.horseData['detailLink'] != null && widget.horseData['detailLink'].isNotEmpty) {
      final result = await TjkApiService.getHorseDetails(widget.horseData['detailLink']);
      
      if (result['success'] == true && mounted) {
        setState(() {
          _raceHistory = (result['races'] as List<dynamic>)
              .map((race) => race as Map<String, dynamic>)
              .toList();
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('At Detayı', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: () {
              // Atı karşılaştırma listesine ekle
              // Yarış geçmişini de ekle ki backend tekrar çekmek zorunda kalmasın
              final horseWithRaces = Map<String, dynamic>.from(widget.horseData);
              horseWithRaces['races'] = _raceHistory;
              
              ComparisonService().addHorse(horseWithRaces);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.horseData['name']} karşılaştırma listesine eklendi'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      bottomSheet: const ComparisonBottomSheet(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // Bottom sheet için boşluk
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHorseName(isDark),
              const SizedBox(height: 24),
              _buildIdentitySection(isDark),
              const SizedBox(height: 24),
              _buildStatisticsSection(isDark),
              const SizedBox(height: 24),
              _buildRaceHistorySection(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorseName(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surface : AppTheme.backgroundDarkMode,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.horseData['name'] ?? 'Bilinmiyor',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.horseData['breed'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Atı karşılaştırma listesine ekle
              final horseWithRaces = Map<String, dynamic>.from(widget.horseData);
              horseWithRaces['races'] = _raceHistory;
              
              ComparisonService().addHorse(horseWithRaces);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.horseData['name']} karşılaştırma listesine eklendi'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.compare_arrows),
            label: const Text('KARŞILAŞTIRMA LİSTESİNE EKLE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentitySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kimlik Bilgileri',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surface : AppTheme.backgroundDarkMode,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              if (widget.horseData['age']?.isNotEmpty ?? false)
                _buildInfoRow(isDark, 'Yaş', widget.horseData['age']),
              if (widget.horseData['gender']?.isNotEmpty ?? false)
                _buildInfoRow(isDark, 'Cinsiyet', widget.horseData['gender']),
              if (widget.horseData['father']?.isNotEmpty ?? false)
                _buildInfoRow(isDark, 'Baba', widget.horseData['father']),
              if (widget.horseData['mother']?.isNotEmpty ?? false)
                _buildInfoRow(isDark, 'Anne', widget.horseData['mother']),
              if (widget.horseData['owner']?.isNotEmpty ?? false)
                _buildInfoRow(isDark, 'Sahip', widget.horseData['owner']),
              _buildInfoRow(isDark, 'Antrenör', widget.horseData['trainer'] ?? 'Bilinmiyor', isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(bool isDark, String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
                ),
              ),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (!isLast) Divider(
          color: isDark ? AppTheme.border : AppTheme.borderLightMode,
          height: 1,
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(bool isDark) {
    final totalRaces = _raceHistory.length;
    final firstPlaces = _raceHistory.where((race) => race['position'] == '1').length;
    final winPercentage = totalRaces > 0 ? ((firstPlaces / totalRaces) * 100).toStringAsFixed(0) : '0';
    final tabela = _raceHistory.where((race) {
      final pos = race['position'];
      return pos == '1' || pos == '2' || pos == '3';
    }).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İstatistikler',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(isDark, 'Toplam Koşu', totalRaces.toString()),
            _buildStatCard(isDark, 'Toplam Kazanç', widget.horseData['prize'] ?? '0'),
            _buildStatCard(isDark, 'Kazanma %', '$winPercentage%'),
            _buildStatCard(isDark, 'Tabela', tabela.toString()),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(bool isDark, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : AppTheme.backgroundDarkMode,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceHistorySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Geçmiş Koşuları',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_raceHistory.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Yarış geçmişi bulunamadı',
                style: TextStyle(
                  color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
                ),
              ),
            ),
          )
        else
          ..._raceHistory.map((race) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRaceHistoryCard(
              isDark,
              race['date'] ?? '',
              race['position'] ?? '',
              race['city'] ?? '',
              race['jockey'] ?? '',
              race['distance'] ?? '',
              race['track'] ?? '',
              race['grade'] ?? '',
              race['prize'] ?? '',
            ),
          )).toList(),
      ],
    );
  }

  Widget _buildRaceHistoryCard(bool isDark, String date, String position, String city, String jockey, String distance, String track, String grade, String prize) {
    Color positionColor;
    if (position == '1') {
      positionColor = Colors.amber;
    } else if (position == '2') {
      positionColor = Colors.grey.shade400;
    } else if (position == '3') {
      positionColor = Colors.brown.shade300;
    } else {
      positionColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : AppTheme.backgroundDarkMode,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: position == '1' ? AppTheme.primary.withOpacity(0.3) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      city,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: positionColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    position,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildRaceInfoRow(isDark, 'Mesafe:', distance),
              _buildRaceInfoRow(isDark, 'Pist:', track),
              _buildRaceInfoRow(isDark, 'Derece:', grade),
              _buildRaceInfoRow(isDark, 'Jokey:', jockey),
              if (prize.isNotEmpty)
                _buildRaceInfoRow(isDark, 'İkramiye:', prize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRaceInfoRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textLight : AppTheme.textDarkMode,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
            ),
          ),
        ],
      ),
    );
  }
}

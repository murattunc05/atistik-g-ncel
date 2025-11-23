import 'package:flutter/material.dart';
import '../services/tjk_api_service.dart';
import '../services/comparison_service.dart';
import '../services/prediction_service.dart';
import '../theme/app_theme.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  List<Map<String, dynamic>> _comparedHorses = [];
  
  // Search related
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _updateComparison();
  }

  void _updateComparison() {
    final selectedHorses = ComparisonService().selectedHorses;
    if (selectedHorses.isNotEmpty) {
      setState(() {
        _comparedHorses = PredictionService.calculateWinningProbability(selectedHorses);
      });
    } else {
      setState(() {
        _comparedHorses = [];
      });
    }
  }

  Future<void> _searchHorses(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _showSearchResults = true;
    });

    final result = await TjkApiService.searchHorses(horseName: query);

    if (mounted) {
      setState(() {
        _isSearching = false;
        if (result['success'] == true) {
          _searchResults = result['horses'] ?? [];
          if (_searchResults.isEmpty) {
            _searchError = 'Sonuç bulunamadı';
          }
        } else {
          _searchError = result['error'] ?? 'Bir hata oluştu';
        }
      });
    }
  }

  Future<void> _addHorse(Map<String, dynamic> horse) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (horse['detailLink'] != null) {
        final detailResult = await TjkApiService.getHorseDetails(horse['detailLink']);
        if (detailResult['success'] == true) {
          final horseWithDetails = Map<String, dynamic>.from(horse);
          horseWithDetails['races'] = detailResult['races'];
          ComparisonService().addHorse(horseWithDetails);
        } else {
          ComparisonService().addHorse(horse);
        }
      } else {
        ComparisonService().addHorse(horse);
      }
      
      if (mounted) Navigator.pop(context);
      
      setState(() {
        _searchController.clear();
        _showSearchResults = false;
        _searchResults = [];
      });
      
      _updateComparison();
      
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ekleme hatası: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _calculateStats(Map<String, dynamic> horse) {
    final races = horse['races'] as List<dynamic>? ?? [];
    int totalRaces = races.length;
    int wins = 0;
    int places = 0; // Top 3
    int top5 = 0;
    
    for (var race in races) {
      try {
        String posStr = race['position'].toString().replaceAll('.', '');
        int pos = int.tryParse(posStr) ?? 99;
        
        if (pos == 1) wins++;
        if (pos <= 3) places++;
        if (pos <= 5) top5++;
      } catch (e) {
        // Ignore
      }
    }
    
    double winRate = totalRaces > 0 ? (wins / totalRaces * 100) : 0;
    double placeRate = totalRaces > 0 ? (places / totalRaces * 100) : 0;
    double top5Rate = totalRaces > 0 ? (top5 / totalRaces * 100) : 0;
    
    return {
      'totalRaces': totalRaces,
      'wins': wins,
      'places': places,
      'winRate': winRate.toStringAsFixed(1),
      'placeRate': placeRate.toStringAsFixed(1),
      'top5Rate': top5Rate.toStringAsFixed(1),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCount = ComparisonService().selectedHorses.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('At Karşılaştırma', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (selectedCount > 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _updateComparison,
              tooltip: 'Yenile',
            ),
          if (selectedCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                ComparisonService().clear();
                setState(() {
                  _comparedHorses = [];
                });
              },
              tooltip: 'Tümünü Temizle',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Karşılaştırmak için at ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchHorses('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? AppTheme.backgroundDark : Colors.grey[100],
              ),
              onChanged: (value) {
                if (value.length > 2) {
                  _searchHorses(value);
                } else if (value.isEmpty) {
                  _searchHorses('');
                }
              },
            ),
          ),
          
          Expanded(
            child: _showSearchResults
                ? _buildSearchResults(isDark)
                : _buildComparisonView(isDark, selectedCount),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_searchError!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'Sonuç bulunamadı',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final horse = _searchResults[index];
        final isSelected = ComparisonService().isSelected(horse['name']);
        
        return ListTile(
          title: Text(
            horse['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${horse['breed'] ?? ''} - ${horse['age'] ?? ''}'),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Colors.green)
              : ElevatedButton.icon(
                  onPressed: () => _addHorse(horse),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ekle'),
                ),
        );
      },
    );
  }

  Widget _buildComparisonView(bool isDark, int selectedCount) {
    if (selectedCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows,
              size: 80,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Karşılaştırılacak at seçilmedi',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yukarıdan arama yaparak at ekleyebilirsiniz',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (_comparedHorses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Winning Probability Cards
          _buildProbabilityCards(isDark),
          const SizedBox(height: 24),
          
          // Statistics Comparison
          _buildStatisticsSection(isDark),
          const SizedBox(height: 24),
          
          // Basic Info
          _buildBasicInfoSection(isDark),
        ],
      ),
    );
  }

  Widget _buildProbabilityCards(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kazanma Olasılıkları',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...List.generate(_comparedHorses.length, (index) {
          final horse = _comparedHorses[index];
          final prob = double.tryParse(horse['winningProbability'] ?? '0') ?? 0;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.1),
                  AppTheme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: index == 0 ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: index == 0 ? AppTheme.primary : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        horse['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${horse['breed'] ?? ''} • ${horse['age'] ?? ''}',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '%${prob.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: index == 0 ? AppTheme.primary : null,
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 4,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.grey[300],
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: prob / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: index == 0 ? AppTheme.primary : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatisticsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İstatistikler',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildStatCard(isDark, 'Toplam Koşu', (h) {
          final stats = _calculateStats(h);
          return stats['totalRaces'].toString();
        }),
        const SizedBox(height: 8),
        _buildStatCard(isDark, 'Birinci', (h) {
          final stats = _calculateStats(h);
          return '${stats['wins']} (${stats['winRate']}%)';
        }),
        const SizedBox(height: 8),
        _buildStatCard(isDark, 'İlk 3', (h) {
          final stats = _calculateStats(h);
          return '${stats['places']} (${stats['placeRate']}%)';
        }),
        const SizedBox(height: 8),
        _buildStatCard(isDark, 'İlk 5 Oranı', (h) {
          final stats = _calculateStats(h);
          return '${stats['top5Rate']}%';
        }),
        const SizedBox(height: 8),
        _buildStatCard(isDark, 'Toplam Kazanç', (h) => h['prize'] ?? '-'),
      ],
    );
  }

  Widget _buildBasicInfoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Temel Bilgiler',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildStatCard(isDark, 'Cinsiyet', (h) => h['gender'] ?? '-'),
        const SizedBox(height: 8),
        _buildStatCard(isDark, 'Sahip', (h) => h['owner'] ?? '-'),
        const SizedBox(height: 8),
        _buildStatCard(isDark, 'Antrenör', (h) => h['trainer'] ?? '-'),
      ],
    );
  }

  Widget _buildStatCard(bool isDark, String label, String Function(Map<String, dynamic>) getValue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _comparedHorses.map((horse) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        horse['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getValue(horse),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/daily_race_model.dart';
import '../services/daily_race_scraper_service.dart';
import '../theme/app_theme.dart';
import '../screens/race_detail_screen.dart';

class DailyRaceSectionWidget extends StatefulWidget {
  const DailyRaceSectionWidget({super.key});

  @override
  State<DailyRaceSectionWidget> createState() => _DailyRaceSectionWidgetState();
}

class _DailyRaceSectionWidgetState extends State<DailyRaceSectionWidget> {
  final DailyRaceScraperService _scraperService = DailyRaceScraperService();
  
  // State
  bool _isLoading = false;
  List<DailyRaceModel> _races = [];
  String _errorMessage = '';
  
  // Selections
  DateTime _selectedDate = DateTime.now();
  
  // Dynamic City Data
  List<Map<String, String>> _availableCities = [];
  String? _selectedCityId;
  String? _selectedCityName;

  @override
  void initState() {
    super.initState();
    _loadCitiesAndRaces();
  }

  Future<void> _loadCitiesAndRaces() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _races = [];
      _availableCities = [];
      _selectedCityId = null;
      _selectedCityName = null;
    });

    try {
      // Format date: dd/MM/yyyy
      final String formattedDate = "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";
      
      // 1. Fetch Cities
      final cities = await _scraperService.getCitiesForDate(formattedDate);
      
      if (!mounted) return;

      if (cities.isEmpty) {
        setState(() {
          _isLoading = false;
          _availableCities = [];
        });
        return;
      }

      // 2. Select first city by default
      final firstCity = cities.first;
      final cityId = firstCity['id']!;
      final cityName = firstCity['name']!;

      setState(() {
        _availableCities = cities;
        _selectedCityId = cityId;
        _selectedCityName = cityName;
      });

      // 3. Fetch Races for the selected city
      await _loadRacesForCity(formattedDate, cityId, cityName);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Veri çekilemedi: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRacesForCity(String date, String cityId, String cityName) async {
    setState(() {
      _isLoading = true;
      _races = []; // Clear previous races while loading new ones
    });
    
    try {
      final races = await _scraperService.getRacesForDate(date, cityId, cityName);
      
      if (!mounted) return;

      setState(() {
        _races = races;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Koşular yüklenemedi: $e';
        _isLoading = false;
      });
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadCitiesAndRaces();
  }

  void _onCityChanged(String? cityName) {
    if (cityName != null) {
      final city = _availableCities.firstWhere((c) => c['name'] == cityName);
      setState(() {
        _selectedCityName = city['name'];
        _selectedCityId = city['id'];
      });
      
      final String formattedDate = "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";
      _loadRacesForCity(formattedDate, _selectedCityId!, _selectedCityName!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Combined Date and City Selector
        _buildDateAndCitySelector(context, isDark),
        const SizedBox(height: 16),
        
        // Content Section (Loading, Error, or Data)
        _buildContent(context, isDark),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadCitiesAndRaces();
    }
  }

  Widget _buildDateAndCitySelector(BuildContext context, bool isDark) {
    final formattedDate = "${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}";
    final containerColor = isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade200;
    final iconColor = isDark ? Colors.white : Colors.grey.shade700;
    final cityTextColor = isDark ? Colors.white : Colors.black87;
    
    return Row(
      children: [
        // Date Selection Section - Left Side (Flex 6)
        Expanded(
          flex: 6,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, size: 16, color: iconColor),
                  onPressed: () => _changeDate(-1),
                ),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 16, color: iconColor),
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
          ),
        ),
        
        // Spacer
        const SizedBox(width: 8),
        
        // City Selection Section - Right Side (Flex 4)
        if (_availableCities.isNotEmpty) ...[
          Expanded(
            flex: 4,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCityName,
                  isExpanded: true,
                  alignment: Alignment.center,
                  icon: Icon(Icons.arrow_drop_down, color: iconColor),
                  dropdownColor: containerColor,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cityTextColor,
                  ),
                  items: _availableCities.map((city) {
                    return DropdownMenuItem<String>(
                      value: city['name'],
                      child: Center(child: Text(city['name']!)),
                    );
                  }).toList(),
                  onChanged: _onCityChanged,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    if (_isLoading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(
              'Hata Oluştu',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.red[700]),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadCitiesAndRaces,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_races.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Bu tarih/şehir için koşu bulunamadı.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: _races.length,
        itemBuilder: (context, index) {
          return _buildRaceCard(context, _races[index], isDark);
        },
      ),
    );
  }

  Widget _buildRaceCard(BuildContext context, DailyRaceModel race, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias, // Ensure ripples don't overflow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${race.raceNo}. KOŞU',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          race.time,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Card Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoRow(Icons.straighten, 'Mesafe', race.distance, isDark),
                    _buildInfoRow(Icons.terrain, 'Pist', race.trackType, isDark),
                    _buildInfoRow(Icons.emoji_events, 'Ödül', race.prize, isDark),
                  ],
                ),
              ),
            ),
            
            // Card Footer
            Material(
              color: Colors.transparent, // Ensure transparent for ripple
              child: InkWell(
                onTap: () {
                  print('Detayları Gör tapped for Race ${race.raceNo}'); // Debug log
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RaceDetailScreen(
                        race: race,
                        raceDate: "${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}",
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Detayları Gör',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

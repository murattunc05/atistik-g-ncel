import 'package:flutter/material.dart';
import '../models/daily_race_model.dart';
import '../services/daily_race_scraper_service.dart';
import '../services/tjk_api_service.dart';
import '../theme/app_theme.dart';

/// FAZ 7 — ML Eğitim Sonuç Giriş Ekranı
class SubmitResultsScreen extends StatefulWidget {
  const SubmitResultsScreen({super.key});

  @override
  State<SubmitResultsScreen> createState() => _SubmitResultsScreenState();
}

class _SubmitResultsScreenState extends State<SubmitResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final _scraperService = DailyRaceScraperService();

  // Tarih & Şehir — Günün programıyla aynı mantık
  DateTime _selectedDate = DateTime.now();
  List<Map<String, String>> _availableCities = [];
  String? _selectedCityId;
  String? _selectedCityName;

  // Günlük program
  bool _loadingProgram = true;
  String? _programError;
  List<DailyRaceModel> _races = [];

  // Seçili koşu
  DailyRaceModel? _selectedRace;
  bool _fetching = false;
  String? _fetchError;

  // Sonuçlar
  List<Map<String, dynamic>> _results = [];
  String? _raceId;
  bool _submitting = false;
  bool _submitted = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadCitiesAndRaces();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Veri — Günün Programıyla Aynı Mantık ─────────────────────

  String get _formattedDate =>
      '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

  String get _displayDate =>
      '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}';

  Future<void> _loadCitiesAndRaces() async {
    setState(() {
      _loadingProgram = true;
      _programError = null;
      _races = [];
      _availableCities = [];
      _selectedCityId = null;
      _selectedCityName = null;
      _selectedRace = null;
    });

    try {
      final cities = await _scraperService.getCitiesForDate(_formattedDate);
      if (!mounted) return;

      if (cities.isEmpty) {
        setState(() { _loadingProgram = false; _programError = 'Bu tarih için koşu bulunamadı.'; });
        return;
      }

      final first = cities.first;
      setState(() {
        _availableCities = cities;
        _selectedCityId = first['id'];
        _selectedCityName = first['name'];
      });

      await _loadRacesForCity(_formattedDate, first['id']!, first['name']!);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingProgram = false; _programError = 'Yükleme hatası: $e'; });
    }
  }

  Future<void> _loadRacesForCity(String date, String cityId, String cityName) async {
    setState(() { _loadingProgram = true; _races = []; });
    try {
      final races = await _scraperService.getRacesForDate(date, cityId, cityName);
      if (!mounted) return;
      setState(() { _races = races; _loadingProgram = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingProgram = false; _programError = 'Koşular yüklenemedi: $e'; });
    }
  }

  void _changeDate(int days) {
    setState(() { _selectedDate = _selectedDate.add(Duration(days: days)); });
    _loadCitiesAndRaces();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() { _selectedDate = picked; });
      _loadCitiesAndRaces();
    }
  }

  void _onCityChanged(String? cityName) {
    if (cityName == null) return;
    final city = _availableCities.firstWhere((c) => c['name'] == cityName);
    setState(() {
      _selectedCityName = city['name'];
      _selectedCityId = city['id'];
    });
    _loadRacesForCity(_formattedDate, city['id']!, city['name']!);
  }

  // ── Sonuç Çekme ──────────────────────────────────────────────

  Future<void> _fetchResults(DailyRaceModel race) async {
    setState(() {
      _selectedRace = race;
      _fetching = true;
      _fetchError = null;
      _results = [];
      _submitted = false;
      _submitError = null;
    });

    final d = _selectedDate;
    final raceDate = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    final horseList = race.horses
        .where((h) => h.name.isNotEmpty)
        .map((h) => {'name': h.name, 'detailLink': h.detailLink})
        .toList();

    if (horseList.isEmpty) {
      setState(() { _fetching = false; _fetchError = 'Bu koşu için at listesi bulunamadı.'; });
      return;
    }

    final resp = await TjkApiService.fetchRaceResults(
      raceDate: raceDate,
      raceNo: race.raceNo,
      horses: horseList,
    );
    if (!mounted) return;

    if (resp['success'] == true) {
      setState(() {
        _raceId  = race.raceId.isNotEmpty ? race.raceId : (resp['race_id'] ?? '$raceDate-${race.raceNo}');
        _results = (resp['results'] as List).cast<Map<String, dynamic>>();
        _fetching = false;
      });
    } else {
      setState(() { _fetching = false; _fetchError = resp['error'] ?? 'Sonuçlar çekilemedi.'; });
    }
  }

  Future<void> _submitResults() async {
    if (_results.isEmpty || _raceId == null) return;
    setState(() { _submitting = true; _submitError = null; });

    final resp = await TjkApiService.submitResults(raceId: _raceId!, results: _results);
    if (!mounted) return;

    if (resp['success'] == true) {
      setState(() { _submitting = false; _submitted = true; });
    } else {
      setState(() { _submitting = false; _submitError = resp['error'] ?? 'Gönderim hatası.'; });
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundDarkMode,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sonuç Gir', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: _submitted
            ? _buildSuccessView(isDark)
            : _selectedRace != null
                ? _buildResultsView(isDark)
                : _buildRaceList(isDark),
      ),
    );
  }

  // ── 1. Tarih + Şehir Seçici ───────────────────────────────────

  Widget _buildDateAndCitySelector(bool isDark) {
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade200;
    final iconColor = isDark ? Colors.white : Colors.grey.shade700;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Row(
      children: [
        // Tarih
        Expanded(
          flex: 6,
          child: Container(
            height: 50,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, size: 16, color: iconColor),
                  onPressed: () => _changeDate(-1),
                ),
                GestureDetector(
                  onTap: _selectDate,
                  child: Text(
                    _displayDate,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent),
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
        if (_availableCities.isNotEmpty) ...[
          const SizedBox(width: 8),
          // Şehir
          Expanded(
            flex: 4,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCityName,
                  isExpanded: true,
                  alignment: Alignment.center,
                  icon: Icon(Icons.arrow_drop_down, color: iconColor),
                  dropdownColor: bg,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  items: _availableCities.map((city) => DropdownMenuItem<String>(
                    value: city['name'],
                    child: Center(child: Text(city['name']!)),
                  )).toList(),
                  onChanged: _onCityChanged,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── 1. Koşu Listesi ───────────────────────────────────────────

  Widget _buildRaceList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarih/Şehir Seçici
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _buildDateAndCitySelector(isDark),
        ),

        if (_loadingProgram)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_programError != null)
          Expanded(child: _buildErrorView(_programError!, _loadCitiesAndRaces, isDark))
        else if (_races.isEmpty)
          Expanded(
            child: Center(
              child: Text('Bu tarih/şehir için koşu bulunamadı.',
                  style: TextStyle(color: Colors.grey[400])),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              'Bir koşuya dokun — sonuçlar otomatik çekilecek.',
              style: TextStyle(fontSize: 13, color: Colors.grey[isDark ? 400 : 600]),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _races.length,
              itemBuilder: (_, i) => _buildRaceCard(_races[i], isDark),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRaceCard(DailyRaceModel race, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(race.raceNo,
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16)),
        ),
        title: Text(
          race.raceName.isNotEmpty ? race.raceName : '${race.raceNo}. Koşu',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          [
            if (race.distance.isNotEmpty) '${race.distance}m',
            if (race.trackType.isNotEmpty) race.trackType,
            if (race.horses.isNotEmpty) '${race.horses.length} at',
            if (race.time.isNotEmpty) race.time,
          ].join(' · '),
          style: TextStyle(fontSize: 12, color: Colors.grey[isDark ? 400 : 600]),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _fetchResults(race),
      ),
    );
  }

  // ── 2. Sonuçlar ───────────────────────────────────────────────

  Widget _buildResultsView(bool isDark) {
    if (_fetching) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Her atın geçmişi kontrol ediliyor...',
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ]),
      );
    }

    if (_fetchError != null) {
      return _buildErrorView(_fetchError!, () => setState(() { _selectedRace = null; }), isDark, backLabel: 'Geri Dön');
    }

    return Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_selectedRace!.raceNo}. Koşu sonuçları bulundu.\nKontrol edip onaylamanı bekliyorum.',
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _results.length,
          itemBuilder: (_, i) {
            final r = _results[i];
            final pos = r['finish_pos'] as int? ?? 0;
            final posColor = pos == 1 ? Colors.amber : pos == 2 ? Colors.grey[400]! : pos == 3 ? Colors.brown[300]! : Colors.grey[600]!;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: pos == 1 ? Border.all(color: Colors.amber.withOpacity(0.4)) : null,
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: posColor.withOpacity(0.15), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(pos > 90 ? 'K' : '$pos',
                      style: TextStyle(fontWeight: FontWeight.bold, color: posColor)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(r['horse_name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                if (pos == 1) const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18),
              ]),
            );
          },
        ),
      ),
      if (_submitError != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(_submitError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _submitting ? null : () => setState(() { _selectedRace = null; }),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Geri'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _submitting || _results.isEmpty ? null : _submitResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('ML için Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ── 3. Başarı ─────────────────────────────────────────────────

  Widget _buildSuccessView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.green, size: 44),
          ),
          const SizedBox(height: 24),
          const Text('Kaydedildi!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'ML modelimiz bu koşudan öğrendi.\nNe kadar çok koşu eklersen tahminler o kadar iyileşir.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[isDark ? 400 : 600], height: 1.6),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 50,
            child: OutlinedButton(
              onPressed: () => setState(() { _selectedRace = null; _results = []; _submitted = false; _raceId = null; }),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Başka Koşu Ekle'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
              ),
              child: const Text('Tamam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Hata ─────────────────────────────────────────────────────

  Widget _buildErrorView(String error, VoidCallback onRetry, bool isDark, {String backLabel = 'Tekrar Dene'}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(backLabel),
          ),
        ]),
      ),
    );
  }
}

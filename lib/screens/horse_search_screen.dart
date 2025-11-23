import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tjk_api_service.dart';

class HorseSearchScreen extends StatefulWidget {
  const HorseSearchScreen({super.key});

  @override
  State<HorseSearchScreen> createState() => _HorseSearchScreenState();
}

class _HorseSearchScreenState extends State<HorseSearchScreen> {
  final _horseNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _trainerNameController = TextEditingController();
  final _breederNameController = TextEditingController();
  final _ageController = TextEditingController();
  
  bool _showResults = false;
  bool _isLoading = false;
  bool _includeDeadHorses = false; // Ölen atları da dahil et
  bool _isAdvancedSearchExpanded = false; // Gelişmiş arama durumu
  
  String _selectedBreed = 'Tümü'; // Irk
  String _selectedGender = 'Tümü'; // Cinsiyet
  String _selectedCountry = 'Tümü'; // Ülke
  
  final List<String> _breeds = ['Tümü', 'İngiliz', 'Arap'];
  final List<String> _genders = ['Tümü', 'Erkek', 'Dişi', 'İğdiş'];
  final List<String> _countries = ['Tümü', 'Türkiye', 'İngiltere', 'Fransa', 'ABD', 'İrlanda'];
  
  // Arama sonuçları
  List<Map<String, dynamic>> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('At Sorgula', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField('At Adı (İsteğe Bağlı)', 'At Adı Giriniz', _horseNameController),
                  const SizedBox(height: 16),
                  
                  _buildDeadHorsesCheckbox(),
                  const SizedBox(height: 16),

                  // Gelişmiş Arama Toggle
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isAdvancedSearchExpanded = !_isAdvancedSearchExpanded;
                      });
                    },
                    child: Row(
                      children: [
                        Text(
                          'Gelişmiş Arama',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          _isAdvancedSearchExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isAdvancedSearchExpanded) ...[
                    Row(
                      children: [
                        Expanded(child: _buildDropdown('Irk (İsteğe Bağlı)', _selectedBreed, _breeds, (value) {
                          setState(() => _selectedBreed = value!);
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDropdown('Cinsiyet (İsteğe Bağlı)', _selectedGender, _genders, (value) {
                          setState(() => _selectedGender = value!);
                        })),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Yaş (İsteğe Bağlı)', 'Yaş Giriniz', _ageController)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDropdown('Ülke (İsteğe Bağlı)', _selectedCountry, _countries, (value) {
                          setState(() => _selectedCountry = value!);
                        })),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Baba Adı (İsteğe Bağlı)', 'Baba Adı Giriniz', _fatherNameController)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField('Anne Adı (İsteğe Bağlı)', 'Anne Adı Giriniz', _motherNameController)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: _buildTextField('Sahip Adı (İsteğe Bağlı)', 'Sahip Adı Giriniz', _ownerNameController)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField('Antrenör Adı (İsteğe Bağlı)', 'Antrenör Adı Giriniz', _trainerNameController)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTextField('Yetiştirici Adı (İsteğe Bağlı)', 'Yetiştirici Adı Giriniz', _breederNameController),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Atları Bul',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_showResults)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Arama Sonuçları',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSearchResults(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
            ),
            filled: true,
            fillColor: isDark ? AppTheme.backgroundDark : AppTheme.surfaceLightMode,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppTheme.border : AppTheme.borderLightMode,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppTheme.border : AppTheme.borderLightMode,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: isDark ? AppTheme.backgroundDark : AppTheme.surfaceLightMode,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppTheme.backgroundDark : AppTheme.surfaceLightMode,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppTheme.border : AppTheme.borderLightMode,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppTheme.border : AppTheme.borderLightMode,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDeadHorsesCheckbox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : AppTheme.surfaceLightMode,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.border : AppTheme.borderLightMode,
        ),
      ),
      child: CheckboxListTile(
        title: const Text(
          'Ölen atları da dahil et',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        value: _includeDeadHorses,
        activeColor: AppTheme.primary,
        onChanged: (bool? value) {
          setState(() {
            _includeDeadHorses = value ?? false;
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  void _performSearch() async {
    setState(() {
      _isLoading = true;
      _showResults = true;
      _searchResults = [];
    });
    
    try {
      // TJK API'den at verilerini çek
      final result = await TjkApiService.searchHorses(
        horseName: _horseNameController.text,
        breed: _selectedBreed,
        gender: _selectedGender,
        age: _ageController.text,
        country: _selectedCountry,
        fatherName: _fatherNameController.text,
        motherName: _motherNameController.text,
        ownerName: _ownerNameController.text,
        trainerName: _trainerNameController.text,
        breederName: _breederNameController.text,
        includeDeadHorses: _includeDeadHorses,
      );
      
      if (result['success'] == true) {
        final horses = result['horses'] as List<dynamic>;
        final searchTerm = _horseNameController.text.trim().toUpperCase();
        
        // Sonuçları map'le
        final mappedResults = horses.map((horse) => {
          'name': horse['name'] ?? '',
          'breed': horse['breed'] ?? '',
          'gender': horse['gender'] ?? '',
          'age': horse['age'] ?? '',
          'father': horse['father'] ?? '',
          'mother': horse['mother'] ?? '',
          'owner': horse['owner'] ?? '',
          'trainer': horse['trainer'] ?? '',
          'lastRace': horse['lastRace'] ?? '',
          'prize': horse['prize'] ?? '',
          'detailLink': horse['detailLink'] ?? '',
        }).toList();
        
        // Sıralama: Önce tam eşleşenler, sonra kısmi eşleşenler
        if (searchTerm.isNotEmpty) {
          mappedResults.sort((a, b) {
            final nameA = (a['name'] as String).toUpperCase();
            final nameB = (b['name'] as String).toUpperCase();
            
            // Tam eşleşme kontrolü
            final isExactA = nameA == searchTerm;
            final isExactB = nameB == searchTerm;
            
            if (isExactA && !isExactB) return -1;
            if (!isExactA && isExactB) return 1;
            
            // İkisi de tam eşleşme değilse, alfabetik sırala
            return nameA.compareTo(nameB);
          });
        }
        
        setState(() {
          _searchResults = mappedResults;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Bir hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            children: [
              CircularProgressIndicator(
                color: AppTheme.primary,
              ),
              SizedBox(height: 24),
              Text(
                'Atlar aranıyor...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'TJK veritabanında arama yapılıyor',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppTheme.textDark,
              ),
              SizedBox(height: 16),
              Text(
                'Sonuç bulunamadı',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Arama kriterlerinizi değiştirip tekrar deneyin',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: _searchResults.map((horse) => _buildHorseCard(horse)).toList(),
    );
  }
  
  Widget _buildHorseCard(Map<String, dynamic> horse) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : AppTheme.surfaceLightMode,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.border : AppTheme.borderLightMode,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/horse-detail',
            arguments: horse,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  horse['name']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    horse['breed']!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Cinsiyet', horse['gender']!),
            _buildInfoRow('Yaş', horse['age']!),
            _buildInfoRow('Baba', horse['father']!),
            _buildInfoRow('Anne', horse['mother']!),
            _buildInfoRow('Sahip', horse['owner']!),
            _buildInfoRow('Antrenör', horse['trainer']!),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Son Koşu',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        horse['lastRace']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Toplam İkramiye',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      horse['prize']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _horseNameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _ownerNameController.dispose();
    _trainerNameController.dispose();
    _breederNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}

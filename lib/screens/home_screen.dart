import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../widgets/daily_race_section_widget.dart';
import 'submit_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Atistik',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _openSubmitResults(context),
            child: Text(
              'Sonuç Gir',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: _buildSettingsDrawer(context, isDark),


      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Günün Programı',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDateLocationRow(context, isDark),
              const SizedBox(height: 24),
              // New Isolated Daily Race Section
              const DailyRaceSectionWidget(),
              const SizedBox(height: 32),
              _buildRecentWinners(context),
            ],
          ),
        ),
      ),
    );
  }

  void _openSubmitResults(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubmitResultsScreen()),
    );
  }

  Widget _buildDateLocationRow(BuildContext context, bool isDark) {

    final now = DateTime.now();
    final formattedDate = "${now.day}.${now.month}.${now.year}";
    final dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final dayName = dayNames[now.weekday - 1];
    
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          '$formattedDate - $dayName',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentWinners(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Son Kazananlar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildWinnerCard(context, 'Gülbahar', '1. Koşu', '15.000 TL'),
        _buildWinnerCard(context, 'Rüzgarın Kızı', '3. Koşu', '12.500 TL'),
        _buildWinnerCard(context, 'Altın Kalp', '5. Koşu', '18.000 TL'),
      ],
    );
  }

  Widget _buildWinnerCard(
      BuildContext context, String name, String race, String prize) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundDarkMode,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                race,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.textDark : AppTheme.textDarkMode,
                ),
              ),
            ],
          ),
          Text(
            prize,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsDrawer(BuildContext context, bool isDark) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ayarlar',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Tema'),
              subtitle: Text(isDark ? 'Koyu Tema' : 'Aydınlık Tema'),
              trailing: Switch(
                value: isDark,
                activeColor: AppTheme.primary,
                onChanged: (value) {
                  Navigator.pop(context);
                  HipodromCepteApp.of(context)?.toggleTheme();
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profil'),
              subtitle: const Text('Yakında eklenecek'),
              trailing: const Icon(Icons.chevron_right),
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }
}

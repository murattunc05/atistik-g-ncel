import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/horse_search_screen.dart';
import 'screens/horse_detail_screen.dart';
import 'screens/race_search_screen.dart';
import 'screens/comparison_screen.dart';
import 'widgets/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? true;
  runApp(HipodromCepteApp(isDarkMode: isDark));
}

class HipodromCepteApp extends StatefulWidget {
  final bool isDarkMode;
  const HipodromCepteApp({super.key, required this.isDarkMode});

  @override
  State<HipodromCepteApp> createState() => _HipodromCepteAppState();

  static _HipodromCepteAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_HipodromCepteAppState>();
  }
}

class _HipodromCepteAppState extends State<HipodromCepteApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDarkMode', _isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atistik',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      home: const MainScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/horse-detail') {
          final horseData = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => HorseDetailScreen(horseData: horseData),
          );
        }
        return null;
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HorseSearchScreen(),
    const RaceSearchScreen(),
    const ComparisonScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

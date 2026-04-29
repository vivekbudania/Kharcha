import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/add_screen.dart';
import 'screens/history_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'providers/locale_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const KharchaApp(),
    ),
  );
}

class KharchaApp extends StatelessWidget {
  const KharchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<SettingsProvider>().isDark;
    return MaterialApp(
      title: 'Kharcha',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(nextScreen: HomeShell()),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _idx = 0;
  final _screens = const [
    AddScreen(), HistoryScreen(), InsightsScreen(), SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: AppTheme.amber.withOpacity(0.18),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.add_circle_outline), selectedIcon: const Icon(Icons.add_circle), label: loc.t('nav_add')),
          NavigationDestination(icon: const Icon(Icons.history_outlined), selectedIcon: const Icon(Icons.history), label: loc.t('nav_history')),
          NavigationDestination(icon: const Icon(Icons.pie_chart_outline), selectedIcon: const Icon(Icons.pie_chart), label: loc.t('nav_insights')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: loc.t('nav_settings')),
        ],
      ),
    );
  }
}

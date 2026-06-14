import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _savingsController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _incomeController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  void _finishOnboarding() async {
    final sp = context.read<SettingsProvider>();
    double? income = double.tryParse(_incomeController.text.trim());
    double? savings = double.tryParse(_savingsController.text.trim());

    if (income != null) await sp.setMonthlyIncome(income);
    if (savings != null) await sp.setSavingsGoal(savings);
    await sp.setOnboardingCompleted(true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bg : const Color(0xFFF5F5F7);

    final slides = [
      _OnboardingSlide(
        emoji: '👁️',
        title: loc.locale == 'hi' ? 'अपने हर पैसे का हिसाब रखें।' : 'Know where every penny goes.',
        description: loc.locale == 'hi'
            ? 'बिना किसी झंझट के अपने खर्चों की पूरी जानकारी प्राप्त करें और अपने वित्तीय व्यवहार को समझें।'
            : 'Gain complete visibility over your spending habits and understand exactly where your cash flows.',
      ),
      _OnboardingSlide(
        emoji: '⚡',
        title: loc.locale == 'hi' ? 'सेकंडों में खर्चे दर्ज करें।' : 'Track expenses in seconds.',
        description: loc.locale == 'hi'
            ? 'हमारा सुपर-फास्ट कीपैड और स्मार्ट सुझाव बिना किसी समय की बर्बादी के खर्च जोड़ना आसान बनाते हैं।'
            : 'Our ultra-fast custom numpad and category predictions let you log a transaction in less than 3 seconds.',
      ),
      _OnboardingSlide(
        emoji: '🔍',
        title: loc.locale == 'hi' ? 'पैसे की बर्बादी वाली जगहों को पहचानें।' : 'Discover your biggest money leaks.',
        description: loc.locale == 'hi'
            ? 'क्या आप काफी सारा पैसा कॉफी या बाहर खाने पर खर्च कर रहे हैं? हमारी स्मार्ट इनसाइट्स आपको सचेत करेंगी।'
            : 'Identify recurring high-frequency expenses and leaks that quietly drain your budget over time.',
      ),
      _OnboardingSlide(
        emoji: '🛡️',
        title: loc.locale == 'hi' ? 'सहजता से वित्तीय नियंत्रण हासिल करें।' : 'Build financial awareness effortlessly.',
        description: loc.locale == 'hi'
            ? 'कोई जटिल बजटिंग नहीं। केवल दैनिक स्वास्थ्य स्कोर जो आपको ट्रैक पर रखने में मदद करता है।'
            : 'No complex spreadsheets or hard budgets. Just a simple spending mirror that helps you stay in control.',
      ),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Header progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KHARCHA',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: AppTheme.amber,
                    ),
                  ),
                  if (_currentPage < 4)
                    TextButton(
                      onPressed: () {
                        // Jump to setup screen directly
                        _pageController.animateToPage(
                          4,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        loc.t('cancel'),
                        style: const TextStyle(
                          color: AppTheme.fgMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (idx) {
                    setState(() => _currentPage = idx);
                  },
                  children: [
                    ...slides.map((slide) => slide),
                    // Form Page
                    _SetupSlide(
                      incomeController: _incomeController,
                      savingsController: _savingsController,
                      currencySymbol: context.watch<SettingsProvider>().currency,
                      loc: loc,
                    ),
                  ],
                ),
              ),
              // Footer Controls
              if (_currentPage < 4) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppTheme.amber
                            : AppTheme.fgMuted.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Final Start Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _finishOnboarding,
                    child: const Text(
                      'Start Awareness Journey',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text(
                      'Skip and log custom amounts',
                      style: TextStyle(
                        color: AppTheme.fgMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.amber.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.amber.withOpacity(0.15)),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 48),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: AppTheme.fgMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SetupSlide extends StatelessWidget {
  final TextEditingController incomeController;
  final TextEditingController savingsController;
  final String currencySymbol;
  final LocaleProvider loc;

  const _SetupSlide({
    required this.incomeController,
    required this.savingsController,
    required this.currencySymbol,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.card : Colors.white;
    final inputBg = isDark ? AppTheme.card2 : Colors.black.withOpacity(0.04);
    final borderCol = isDark ? AppTheme.border : Colors.grey.shade300;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                '⚙️',
                style: TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Let\'s build your baseline',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Provide your targets to unlock spending health meters. You can change these anytime in Settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.fgMuted,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Income (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: incomeController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '$currencySymbol ',
                      filled: true,
                      fillColor: inputBg,
                      hintText: 'e.g., 50,000',
                      hintStyle: const TextStyle(color: AppTheme.fgMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Monthly Savings Goal (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: savingsController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '$currencySymbol ',
                      filled: true,
                      fillColor: inputBg,
                      hintText: 'e.g., 10,000',
                      hintStyle: const TextStyle(color: AppTheme.fgMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

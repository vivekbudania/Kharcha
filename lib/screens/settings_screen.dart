import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/translations.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const currencies = [
    {'name': 'Indian Rupee', 'code': 'INR', 'symbol': '₹'},
    {'name': 'US Dollar', 'code': 'USD', 'symbol': '\$'},
    {'name': 'Euro', 'code': 'EUR', 'symbol': '€'},
    {'name': 'British Pound', 'code': 'GBP', 'symbol': '£'},
    {'name': 'Japanese Yen', 'code': 'JPY', 'symbol': '¥'},
    {'name': 'South Korean Won', 'code': 'KRW', 'symbol': '₩'},
    {'name': 'Thai Baht', 'code': 'THB', 'symbol': '฿'},
    {'name': 'Canadian Dollar', 'code': 'CAD', 'symbol': 'C\$'},
    {'name': 'Australian Dollar', 'code': 'AUD', 'symbol': 'A\$'},
    {'name': 'Swiss Franc', 'code': 'CHF', 'symbol': 'Fr'},
  ];

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final loc = context.watch<LocaleProvider>();

    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(loc.t('settings_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),

        _Section(title: loc.t('general'), children: [
          SwitchListTile(
            value: sp.isDark, onChanged: sp.setTheme,
            title: Text(loc.t('dark_mode'), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(loc.t('dark_mode_desc')),
            activeColor: AppTheme.amber,
          ),
          ListTile(
            title: Text(loc.t('language'), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(appTranslations[loc.locale]?['lang_name'] ?? 'English'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => _editLanguage(context, loc),
          ),
          ListTile(
            title: Text(loc.t('currency'), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(sp.currency),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () => _editCurrency(context, sp, loc),
          ),
        ]),

        const SizedBox(height: 12),

        _Section(title: loc.t('support_about'), children: [
          ListTile(
            title: Text(loc.t('support_email'), style: const TextStyle(fontWeight: FontWeight.w600)),
            leading: const Icon(Icons.email_outlined, size: 20),
            onTap: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'kharcha.app.help@gmail.com',
                query: 'subject=Kharcha Support Request', // optional, provides prefilled subject
              );
              try {
                if (!await launchUrl(emailLaunchUri)) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open email client')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open email client')),
                );
              }
            },
          ),
          ListTile(
            title: Text(loc.t('terms'), style: const TextStyle(fontWeight: FontWeight.w600)),
            leading: const Icon(Icons.description_outlined, size: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsScreen()),
              );
            },
          ),
          ListTile(
            title: Text(loc.t('privacy_policy'), style: const TextStyle(fontWeight: FontWeight.w600)),
            leading: const Icon(Icons.privacy_tip_outlined, size: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
        ]),

        const SizedBox(height: 24),
        Center(child: Text('Kharcha v1.0.0', style: TextStyle(fontSize: 12, color: AppTheme.fgMuted))),
      ]),
    ));
  }

  void _editCurrency(BuildContext context, SettingsProvider sp, LocaleProvider loc) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(alignment: Alignment.centerLeft, child: Text(loc.t('select_currency'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: currencies.map((c) {
                  final isSelected = sp.currency == c['symbol'];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    title: Text('${c['name']} (${c['code']})', style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c['symbol']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        if (isSelected) const SizedBox(width: 12),
                        if (isSelected) const Icon(Icons.check_circle, color: AppTheme.amber),
                      ],
                    ),
                    onTap: () {
                      sp.setCurrency(c['symbol']!);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ]),
      );
    });
  }

  void _editLanguage(BuildContext context, LocaleProvider loc) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(alignment: Alignment.centerLeft, child: Text(loc.t('select_language'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: appTranslations.keys.map((langCode) {
                  final isSelected = loc.locale == langCode;
                  final langName = appTranslations[langCode]?['lang_name'] ?? langCode;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    title: Text(langName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.amber) : null,
                    onTap: () {
                      loc.setLocale(langCode);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ]),
      );
    });
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
        color: AppTheme.fgMuted, letterSpacing: 0.8)),
    ),
    Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(children: children),
    ),
  ]);
}

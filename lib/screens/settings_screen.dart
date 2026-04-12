import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

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

    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),

        _Section(title: 'Appearance', children: [
          SwitchListTile(
            value: sp.isDark, onChanged: sp.setTheme,
            title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Switch between dark and light theme'),
            activeColor: AppTheme.amber,
          ),
        ]),

        const SizedBox(height: 12),

        _Section(title: 'Currency', children: [
          ListTile(
            title: const Text('Select Currency', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Current: ${sp.currency}'),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () => _editCurrency(context, sp),
          ),
        ]),

        const SizedBox(height: 24),
        Center(child: Text('Kharcha v1.0.0', style: TextStyle(fontSize: 12, color: AppTheme.fgMuted))),
      ]),
    ));
  }

  void _editCurrency(BuildContext context, SettingsProvider sp) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(alignment: Alignment.centerLeft, child: Text('Select Currency', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
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

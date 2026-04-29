import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/locale_provider.dart';

class StreakBadge extends StatelessWidget {
  final int streak;
  final VoidCallback? onTap;
  const StreakBadge({super.key, required this.streak, this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.amber.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text('$streak ${streak == 1 ? loc.t('day') : loc.t('days')}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.amber)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppTheme.amber),
        ]),
      ),
    );
  }
}

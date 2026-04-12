import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StreakBadge extends StatelessWidget {
  final int streak;
  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.amber.withOpacity(0.13),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.amber.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('🔥', style: TextStyle(fontSize: 14)),
      const SizedBox(width: 5),
      Text('$streak Day${streak == 1 ? "" : "s"}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.amber)),
    ]),
  );
}

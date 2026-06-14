import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/locale_provider.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';

void showWeeklySummarySheet(BuildContext context, ExpenseProvider ep, SettingsProvider sp, LocaleProvider loc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WeeklySummarySheet(ep: ep, sp: sp, loc: loc),
  );
}

void showMonthlyReportSheet(BuildContext context, ExpenseProvider ep, SettingsProvider sp, LocaleProvider loc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MonthlyReportSheet(ep: ep, sp: sp, loc: loc),
  );
}

// ── WEEKLY SNAPSHOT SHEET ──
class _WeeklySummarySheet extends StatelessWidget {
  final ExpenseProvider ep;
  final SettingsProvider sp;
  final LocaleProvider loc;

  const _WeeklySummarySheet({required this.ep, required this.sp, required this.loc});

  @override
  Widget build(BuildContext context) {
    final cur = sp.currency;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate this week's expenses (past 7 days including today)
    final thisWeekList = ep.expenses.where((e) {
      if (e.type != 'expense') return false;
      final d = DateTime.parse('${e.date}T12:00:00');
      return d.isAfter(today.subtract(const Duration(days: 7)));
    }).toList();
    final thisWeekTotal = thisWeekList.fold(0.0, (s, e) => s + e.amount);

    // Calculate last week's expenses (days 8 to 14 ago)
    final lastWeekList = ep.expenses.where((e) {
      if (e.type != 'expense') return false;
      final d = DateTime.parse('${e.date}T12:00:00');
      return d.isAfter(today.subtract(const Duration(days: 14))) &&
             d.isBefore(today.subtract(const Duration(days: 6)));
    }).toList();
    final lastWeekTotal = lastWeekList.fold(0.0, (s, e) => s + e.amount);

    // Top Category this week
    final thisWeekCats = <String, double>{};
    for (final e in thisWeekList) {
      thisWeekCats[e.category] = (thisWeekCats[e.category] ?? 0.0) + e.amount;
    }
    final topCatId = thisWeekCats.entries.isNotEmpty
        ? (thisWeekCats.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key
        : null;
    final topCat = topCatId != null ? getCat(topCatId) : null;
    final topCatLabel = topCat != null ? sp.catLabel(topCat.id, topCat.label) : 'None';
    final topCatAmount = topCatId != null ? thisWeekCats[topCatId]! : 0.0;

    // Largest Transaction this week
    final largestTxn = thisWeekList.isNotEmpty
        ? (thisWeekList.toList()..sort((a, b) => b.amount.compareTo(a.amount))).first
        : null;
    final largestTxnCat = largestTxn != null ? getCat(largestTxn.category) : null;
    final largestTxnLabel = largestTxnCat != null ? sp.catLabel(largestTxnCat.id, largestTxnCat.label) : 'None';

    // Week-over-Week Change
    final diff = thisWeekTotal - lastWeekTotal;
    final wowPct = lastWeekTotal > 0 ? (diff / lastWeekTotal * 100) : 0.0;

    // Recommendation
    String recText = "Track consistently to get personalized saving recommendations.";
    if (diff < 0) {
      recText = "Amazing effort! You spent ${wowPct.abs().toStringAsFixed(0)}% less than last week. Your wallet is smiling. 🌟";
    } else if (diff > 0 && lastWeekTotal > 0) {
      recText = "You spent ${wowPct.toStringAsFixed(0)}% more than last week. Consider looking at your top spending category next week. 🔍";
    } else if (thisWeekTotal > 0) {
      recText = "Nice job logging. Stay aware of your daily average to maintain a healthy spending rhythm! 📈";
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bg : const Color(0xFFF5F5F7);
    final cardBg = isDark ? AppTheme.card : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.fgMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(
            loc.locale == 'hi' ? 'साप्ताहिक रिपोर्ट' : 'WEEKLY REFLECTION',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Reflect on your habits over the past 7 days.',
            style: TextStyle(fontSize: 12, color: AppTheme.fgMuted),
          ),
          const SizedBox(height: 20),

          // ── Screenshot-friendly Share Card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.amber.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.amber.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'KHARCHA',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: AppTheme.amber,
                      ),
                    ),
                    const Text('🔥 WEEKLY STATS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.fgMuted)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Total Spent This Week', style: TextStyle(fontSize: 12, color: AppTheme.fgMuted)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$cur${NumberFormat('#,##,###').format(thisWeekTotal)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 8),
                    if (lastWeekTotal > 0)
                      Text(
                        diff <= 0 
                            ? '↓ ${wowPct.abs().toStringAsFixed(0)}% vs last week'
                            : '↑ ${wowPct.toStringAsFixed(0)}% vs last week',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: diff <= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppTheme.border),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Top Category', style: TextStyle(fontSize: 11, color: AppTheme.fgMuted)),
                          const SizedBox(height: 4),
                          Text(
                            topCat != null ? '${topCat.emoji} $topCatLabel' : 'None',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          if (topCat != null)
                            Text(
                              '$cur${NumberFormat('#,##,###').format(topCatAmount)}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.fgMuted, fontFamily: 'monospace'),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Largest Transaction', style: TextStyle(fontSize: 11, color: AppTheme.fgMuted)),
                          const SizedBox(height: 4),
                          Text(
                            largestTxn != null ? '${largestTxnCat?.emoji} $largestTxnLabel' : 'None',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          if (largestTxn != null)
                            Text(
                              '$cur${NumberFormat('#,##,###').format(largestTxn.amount)}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.fgMuted, fontFamily: 'monospace'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.border.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    recText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Screenshot hint instruction
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_camera_outlined, size: 16, color: AppTheme.fgMuted),
              SizedBox(width: 8),
              Text(
                'Take a screenshot to save or share your weekly progress!',
                style: TextStyle(fontSize: 12, color: AppTheme.fgMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it, thanks!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}


// ── MONTHLY REPORT SHEET ──
class _MonthlyReportSheet extends StatelessWidget {
  final ExpenseProvider ep;
  final SettingsProvider sp;
  final LocaleProvider loc;

  const _MonthlyReportSheet({required this.ep, required this.sp, required this.loc});

  @override
  Widget build(BuildContext context) {
    final cur = sp.currency;
    final now = DateTime.now();
    final currentMonthStr = ep.thisMonth;

    // Monthly expenses
    final totalSpent = ep.monthlyExpenses;

    // Top Category this month
    final topCatEntry = ep.categoryTotals.entries.isNotEmpty
        ? (ep.categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first
        : null;
    final topCat = topCatEntry != null ? getCat(topCatEntry.key) : null;
    final topCatLabel = topCat != null ? sp.catLabel(topCat.id, topCat.label) : 'None';
    final topCatAmount = topCatEntry != null ? topCatEntry.value : 0.0;

    // Calculate tracked active days in month
    final streakDates = ep.streakDates;
    final activeDaysCount = streakDates.where((d) => d.startsWith(currentMonthStr)).length;
    final daysElapsed = now.day;
    final consistencyScore = daysElapsed > 0 ? (activeDaysCount / daysElapsed * 100) : 0.0;

    // Daily totals to find best & worst day
    final dailyTotals = <String, double>{};
    for (final e in ep.expenses.where((e) => e.type == 'expense' && e.date.startsWith(currentMonthStr))) {
      dailyTotals[e.date] = (dailyTotals[e.date] ?? 0.0) + e.amount;
    }
    
    final bestDayEntry = dailyTotals.entries.isNotEmpty
        ? (dailyTotals.entries.toList()..sort((a, b) => a.value.compareTo(b.value))).first
        : null;
    final worstDayEntry = dailyTotals.entries.isNotEmpty
        ? (dailyTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first
        : null;

    final String monthName = DateFormat('MMMM').format(now);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bg : const Color(0xFFF5F5F7);
    final cardBg = isDark ? AppTheme.card : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.fgMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(
            loc.locale == 'hi' ? 'मासिक रिपोर्ट कार्ड' : 'MONTHLY REPORT CARD',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Financial snapshot for $monthName ${now.year}',
            style: const TextStyle(fontSize: 12, color: AppTheme.fgMuted),
          ),
          const SizedBox(height: 20),

          // ── Screenshot-friendly Share Card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.amber.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.amber.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'KHARCHA',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: AppTheme.amber,
                      ),
                    ),
                    Text(
                      '💎 ${monthName.toUpperCase()} CARD',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.fgMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Spent', style: TextStyle(fontSize: 11, color: AppTheme.fgMuted)),
                        const SizedBox(height: 4),
                        Text(
                          '$cur${NumberFormat('#,##,###').format(totalSpent)}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Consistency Score', style: TextStyle(fontSize: 11, color: AppTheme.fgMuted)),
                        const SizedBox(height: 4),
                        Text(
                          '${consistencyScore.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.amber, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppTheme.border),
                const SizedBox(height: 12),

                // Grid of stats
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Top Leak Category', style: TextStyle(fontSize: 11, color: AppTheme.fgMuted)),
                          const SizedBox(height: 4),
                          Text(
                            topCat != null ? '${topCat.emoji} $topCatLabel' : 'None',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          if (topCat != null)
                            Text(
                              '$cur${NumberFormat('#,##,###').format(topCatAmount)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.fgMuted, fontFamily: 'monospace'),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tracked Days', style: TextStyle(fontSize: 11, color: AppTheme.fgMuted)),
                          const SizedBox(height: 4),
                          Text(
                            '$activeDaysCount / $daysElapsed Days',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'active logging days',
                            style: TextStyle(fontSize: 11, color: AppTheme.fgMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Most Expensive Day', style: TextStyle(fontSize: 11, color: AppTheme.fgMuted)),
                          const SizedBox(height: 4),
                          Text(
                            worstDayEntry != null
                                ? DateFormat('dd MMM').format(DateTime.parse('${worstDayEntry.key}T12:00:00'))
                                : 'None',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          if (worstDayEntry != null)
                            Text(
                              '$cur${NumberFormat('#,##,###').format(worstDayEntry.value)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.fgMuted, fontFamily: 'monospace'),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Best Spending Day', style: TextStyle(fontSize: 11, color: AppTheme.fgMuted)),
                          const SizedBox(height: 4),
                          Text(
                            bestDayEntry != null
                                ? DateFormat('dd MMM').format(DateTime.parse('${bestDayEntry.key}T12:00:00'))
                                : 'None',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          if (bestDayEntry != null)
                            Text(
                              '$cur${NumberFormat('#,##,###').format(bestDayEntry.value)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.fgMuted, fontFamily: 'monospace'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Screenshot hint instruction
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_camera_outlined, size: 16, color: AppTheme.fgMuted),
              SizedBox(width: 8),
              Text(
                'Take a screenshot to save or share your monthly summary!',
                style: TextStyle(fontSize: 12, color: AppTheme.fgMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it, thanks!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

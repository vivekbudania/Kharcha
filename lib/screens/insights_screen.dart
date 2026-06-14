import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/locale_provider.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../widgets/report_sheets.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<ExpenseProvider>();
    final sp = context.watch<SettingsProvider>();
    final loc = context.watch<LocaleProvider>();
    final catTotals = ep.categoryTotals;
    final total = ep.monthlyExpenses;
    final cur = sp.currency;

    final pieData = catTotals.entries.map((e) {
      return PieChartSectionData(
        value: e.value,
        color: AppTheme.catColor(e.key),
        radius: 64,
        showTitle: false,
      );
    }).toList();

    // Weekly comparison calculations
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final thisW = ep.expenses
        .where((e) =>
            e.type == 'expense' &&
            DateTime.parse('${e.date}T00:00:00')
                .isAfter(weekStart.subtract(const Duration(days: 1))))
        .fold(0.0, (s, e) => s + e.amount);
    final lastW = ep.expenses
        .where((e) =>
            e.type == 'expense' &&
            !DateTime.parse('${e.date}T00:00:00').isBefore(lastWeekStart) &&
            DateTime.parse('${e.date}T00:00:00').isBefore(weekStart))
        .fold(0.0, (s, e) => s + e.amount);
    final diff = thisW - lastW;

    // ── Spending Health Calculation ──
    final hasIncome = sp.monthlyIncome != null && sp.monthlyIncome! > 0;
    double recommendedDaily = 0;
    double dailyAvg = 0;
    double burnRatePct = 0;
    String healthStatus = "On Track";
    Color healthColor = const Color(0xFF22C55E);

    if (hasIncome) {
      recommendedDaily = ep.getRecommendedDailySpend(sp.monthlyIncome!, sp.savingsGoal ?? 0.0);
      dailyAvg = ep.currentDailyAverage;
      burnRatePct = ep.getBurnRate(sp.monthlyIncome!, sp.savingsGoal ?? 0.0);

      if (dailyAvg <= recommendedDaily) {
        healthStatus = "On Track";
        healthColor = const Color(0xFF22C55E);
      } else if (dailyAvg <= 1.2 * recommendedDaily) {
        healthStatus = "Watch Spending";
        healthColor = const Color(0xFFF59E0B);
      } else {
        healthStatus = "Overspending";
        healthColor = const Color(0xFFEF4444);
      }
    }

    // ── Generate Dynamic Insights ──
    final allInsights = ep.generateAllInsights(
      currency: cur,
      monthlyIncome: sp.monthlyIncome,
      savingsGoal: sp.savingsGoal,
    ).take(3).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.t('monthly_insights'),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),

            // ── Spending Health Dashboard ──
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SPENDING HEALTH',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.fgMuted,
                            letterSpacing: 0.8),
                      ),
                      if (hasIncome)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: healthColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: healthColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            healthStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: healthColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (hasIncome) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Target Daily Spend', style: TextStyle(fontSize: 12, color: AppTheme.fgMuted)),
                              const SizedBox(height: 4),
                              Text(
                                '$cur${recommendedDaily.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current Daily Avg', style: TextStyle(fontSize: 12, color: AppTheme.fgMuted)),
                              const SizedBox(height: 4),
                              Text(
                                '$cur${dailyAvg.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                  color: dailyAvg > recommendedDaily ? const Color(0xFFEF4444) : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.border),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly Burn Rate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${burnRatePct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (burnRatePct / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppTheme.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          burnRatePct > 100 ? const Color(0xFFEF4444) : AppTheme.amber,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You have consumed ${burnRatePct.toStringAsFixed(0)}% of your available spend limit this month.',
                      style: const TextStyle(fontSize: 11, color: AppTheme.fgMuted),
                    ),
                  ] else ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Text('⚙️', style: TextStyle(fontSize: 32)),
                            SizedBox(height: 8),
                            Text(
                              'Spending Health setup needed',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Configure your monthly income and savings goal in Settings to unlock real-time spending health status metrics.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.fgMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Dynamic Top 3 Spending Insights ──
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SPENDING INSIGHTS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.fgMuted,
                        letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 16),
                  if (allInsights.isEmpty)
                    const Text(
                      'No insights available yet. Log more expenses to discover patterns!',
                      style: TextStyle(color: AppTheme.fgMuted, fontSize: 13),
                    )
                  else
                    ...allInsights.map((insight) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•', style: TextStyle(fontSize: 18, color: AppTheme.amber)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                insight,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Pie chart card ──────────────────────────────
            if (pieData.isNotEmpty) ...[
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.t('exp_by_cat'),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 160,
                      child: PieChart(
                        PieChartData(
                          sections: pieData,
                          centerSpaceRadius: 40,
                          sectionsSpace: 3,
                          startDegreeOffset: -90,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Category breakdown card (separate!) ────────
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.t('top_categories'),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    ...catTotals.entries.map((e) {
                      final cat = getCat(e.key);
                      final pct = total > 0
                          ? (e.value / total * 100).toStringAsFixed(1)
                          : '0';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppTheme.catColor(e.key),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(sp.catEmoji(cat.id, cat.emoji),
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  sp.catLabel(cat.id, cat.label, localizedLabel: loc.t('cat_${cat.id}').startsWith('cat_') ? null : loc.t('cat_${cat.id}')),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              ),
                              Text(
                                '$cur${NumberFormat('#,##,###').format(e.value)}',
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 42,
                                child: Text('$pct%',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.fgMuted)),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: total > 0 ? e.value / total : 0,
                                minHeight: 4,
                                backgroundColor: AppTheme.border,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.catColor(e.key)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Weekly comparison card ──────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.t('weekly_comparison'),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                        child: _WeekBox(
                            label: loc.t('this_week'),
                            value:
                                '$cur${NumberFormat('#,##,###').format(thisW)}')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _WeekBox(
                            label: loc.t('last_week'),
                            value:
                                '$cur${NumberFormat('#,##,###').format(lastW)}')),
                  ]),
                  if (thisW > 0 || lastW > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: diff <= 0
                            ? const Color(0xFF22C55E).withOpacity(0.12)
                            : const Color(0xFFEF4444).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        diff == 0
                            ? '✓ ${loc.t('same_as_last_week')}'
                            : '${diff < 0 ? "↓" : "↑"} $cur${NumberFormat('#,##,###').format(diff.abs())} ${diff < 0 ? loc.t('less_than_last_week') : loc.t('more_than_last_week')}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: diff <= 0
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'REPORTS & SNAPSHOTS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.fgMuted,
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => showWeeklySummarySheet(context, ep, sp, loc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Column(
                        children: [
                          Text('📅', style: TextStyle(fontSize: 24)),
                          SizedBox(height: 6),
                          Text('Weekly Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('WoW trends & leaks', style: TextStyle(fontSize: 11, color: AppTheme.fgMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => showMonthlyReportSheet(context, ep, sp, loc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Column(
                        children: [
                          Text('💎', style: TextStyle(fontSize: 24)),
                          SizedBox(height: 6),
                          Text('Monthly Snapshot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Consistency & cards', style: TextStyle(fontSize: 11, color: AppTheme.fgMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: child,
      );
}

class _WeekBox extends StatelessWidget {
  final String label, value;
  const _WeekBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.card2
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.fgMuted : Colors.black54,
                  letterSpacing: 0.6)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }
}

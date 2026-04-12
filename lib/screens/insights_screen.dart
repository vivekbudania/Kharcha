import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _showPieChart = true;

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<ExpenseProvider>();
    final sp = context.watch<SettingsProvider>();
    final catTotals = ep.categoryTotals;
    final total = ep.monthlyExpenses;
    final cur = sp.currency;

    final pieData = catTotals.entries.map((e) {
      return PieChartSectionData(
        value: e.value, color: AppTheme.catColor(e.key),
        radius: 72, showTitle: false,
      );
    }).toList();

    // Weekly comparison
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final thisW = ep.expenses.where((e) => e.type == 'expense' &&
        DateTime.parse('${e.date}T00:00:00').isAfter(weekStart.subtract(const Duration(days: 1))))
        .fold(0.0, (s, e) => s + e.amount);
    final lastW = ep.expenses.where((e) => e.type == 'expense' &&
        !DateTime.parse('${e.date}T00:00:00').isBefore(lastWeekStart) &&
        DateTime.parse('${e.date}T00:00:00').isBefore(weekStart))
        .fold(0.0, (s, e) => s + e.amount);
    final diff = thisW - lastW;

    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Insights', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),

        // Month summary
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('THIS MONTH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.fgMuted, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Text('$cur${NumberFormat('#,##,###').format(total)}',
            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text('${ep.expenses.where((e) => e.type == "expense" && e.date.startsWith(ep.thisMonth)).length} expenses recorded',
            style: const TextStyle(fontSize: 13, color: AppTheme.fgMuted)),
        ])),
        const SizedBox(height: 12),

        // Chart
        if (pieData.isNotEmpty) ...[
          _Card(child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('By Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: Icon(_showPieChart ? Icons.bar_chart : Icons.pie_chart, color: AppTheme.amber, size: 20),
                  onPressed: () => setState(() => _showPieChart = !_showPieChart),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: _showPieChart ? 'Show Bar Chart' : 'Show Pie Chart',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: _showPieChart 
                ? PieChart(PieChartData(
                    sections: pieData, centerSpaceRadius: 50,
                    sectionsSpace: 3, startDegreeOffset: -90,
                  ))
                : BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: catTotals.values.isEmpty ? 1 : catTotals.values.reduce((a, b) => a > b ? a : b) * 1.2,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value.toInt() < 0 || value.toInt() >= catTotals.length) return const SizedBox.shrink();
                            String emoji = getCat(catTotals.keys.elementAt(value.toInt())).emoji;
                            return Padding(padding: const EdgeInsets.only(top: 6), child: Text(emoji, style: const TextStyle(fontSize: 14)));
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: catTotals.entries.toList().asMap().entries.map((em) {
                      return BarChartGroupData(
                        x: em.key,
                        barRods: [
                          BarChartRodData(
                            toY: em.value.value,
                            color: AppTheme.catColor(em.value.key),
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ],
                      );
                    }).toList(),
                  )),
            ),
            const SizedBox(height: 16),
            ...catTotals.entries.map((e) {
              final cat = getCat(e.key);
              final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(
                    color: AppTheme.catColor(e.key), borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(cat.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                  Text('$cur${NumberFormat('#,##,###').format(e.value)}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  SizedBox(width: 42, child: Text('$pct%', textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, color: AppTheme.fgMuted))),
                ]),
              );
            }),
          ])),
          const SizedBox(height: 12),
        ],

        // Weekly comparison
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Weekly Comparison', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _WeekBox(label: 'This Week', value: '$cur${NumberFormat('#,##,###').format(thisW)}')),
            const SizedBox(width: 10),
            Expanded(child: _WeekBox(label: 'Last Week', value: '$cur${NumberFormat('#,##,###').format(lastW)}')),
          ]),
          if (thisW > 0 || lastW > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: diff <= 0 ? const Color(0xFF22C55E).withOpacity(0.13) : const Color(0xFFEF4444).withOpacity(0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                diff == 0 ? '✓ Same as last week'
                    : '${diff < 0 ? "↓" : "↑"} $cur${NumberFormat('#,##,###').format(diff.abs())} ${diff < 0 ? "less" : "more"} than last week',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: diff <= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
              ),
            ),
          ],
        ])),
      ]),
    ));
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.border),
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
        color: isDark ? AppTheme.card2 : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: isDark ? AppTheme.fgMuted : Colors.black54, letterSpacing: 0.6)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'monospace',
          color: Theme.of(context).colorScheme.onSurface)),
      ]),
    );
  }
}

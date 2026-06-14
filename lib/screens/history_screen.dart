import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/locale_provider.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _dateLabel(String s, LocaleProvider loc) {
    final t = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final y = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
    if (s == t) return loc.t('today');
    if (s == y) return loc.t('yesterday');
    return DateFormat('dd MMM yyyy').format(DateTime.parse('${s}T12:00:00'));
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<ExpenseProvider>();
    final sp = context.watch<SettingsProvider>();
    final loc = context.watch<LocaleProvider>();
    final grouped = ep.groupedByDate;
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    if (ep.expenses.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📝', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(loc.t('no_txns'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(loc.t('swipe_hint'), style: const TextStyle(color: AppTheme.fgMuted), textAlign: TextAlign.center),
      ]));
    }

    // Calculations
    final topCatEntry = ep.categoryTotals.entries.isNotEmpty
        ? (ep.categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first
        : null;
    final topCatName = topCatEntry != null
        ? sp.catLabel(topCatEntry.key, getCat(topCatEntry.key).label, localizedLabel: loc.t('cat_${topCatEntry.key}').startsWith('cat_') ? null : loc.t('cat_${topCatEntry.key}'))
        : 'None';

    final trendPct = ep.monthlyTrendPercentage;
    final trendStr = trendPct == 0.0
        ? '0%'
        : '${trendPct > 0 ? "↑" : "↓"} ${trendPct.abs().toStringAsFixed(0)}%';

    return SafeArea(child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(children: [
          Text(loc.t('txn_history'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('${ep.expenses.length} entries', style: const TextStyle(color: AppTheme.fgMuted, fontSize: 13)),
        ]),
      ),
      // Aggregated Header Cards
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardW = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HistoryStatCard(
                  width: cardW,
                  title: loc.locale == 'hi' ? 'इस महीने कुल' : 'This Month Total',
                  value: '${sp.currency}${NumberFormat('#,##,###').format(ep.monthlyExpenses)}',
                ),
                _HistoryStatCard(
                  width: cardW,
                  title: loc.locale == 'hi' ? 'दैनिक औसत' : 'Avg Daily Spend',
                  value: '${sp.currency}${NumberFormat('#,##,###').format(ep.currentDailyAverage)}',
                ),
                _HistoryStatCard(
                  width: cardW,
                  title: loc.locale == 'hi' ? 'शीर्ष श्रेणी' : 'Largest Category',
                  value: topCatName,
                ),
                _HistoryStatCard(
                  width: cardW,
                  title: loc.locale == 'hi' ? 'ट्रेंड' : 'Recent Trend',
                  value: trendStr,
                  valueColor: trendPct > 0
                      ? const Color(0xFFEF4444)
                      : (trendPct < 0 ? const Color(0xFF22C55E) : null),
                ),
              ],
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dates.length,
        itemBuilder: (ctx, i) {
          final date = dates[i];
          final entries = grouped[date]!..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final dayTotal = entries.where((e) => e.type == 'expense').fold(0.0, (s, e) => s + e.amount);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Text(_dateLabel(date, loc), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.fgMuted, letterSpacing: 0.8)),
                const Spacer(),
                if (dayTotal > 0) Text('${sp.currency}${NumberFormat('#,##,###').format(dayTotal)}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.fgMuted, fontFamily: 'monospace')),
              ]),
            ),
            ...entries.map((e) => _ExpenseTile(expense: e, currency: sp.currency, loc: loc)),
            const SizedBox(height: 6),
          ]);
        },
      )),
    ]));
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String currency;
  final LocaleProvider loc;
  const _ExpenseTile({required this.expense, required this.currency, required this.loc});

  @override
  Widget build(BuildContext context) {
    final ep = context.read<ExpenseProvider>();
    final sp = context.read<SettingsProvider>();
    final cat = getCat(expense.category);
    final t = loc.t('cat_${cat.id}');
    final catLabel = sp.catLabel(cat.id, cat.label, localizedLabel: t.startsWith('cat_') ? null : t);
    final catEmoji = sp.catEmoji(cat.id, cat.emoji);
    final color = AppTheme.catColor(expense.category);
    final isInc = expense.type == 'income';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        key: ValueKey(expense.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(onPressed: (_) => _showEdit(context, ep), icon: Icons.edit_outlined,
              backgroundColor: AppTheme.amber, foregroundColor: Colors.black, borderRadius: const BorderRadius.horizontal(left: Radius.circular(14))),
            SlidableAction(onPressed: (_) => ep.remove(expense.id), icon: Icons.delete_outline,
              backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, borderRadius: const BorderRadius.horizontal(right: Radius.circular(14))),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(
              color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(catEmoji, style: const TextStyle(fontSize: 20)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(catLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(isInc ? loc.t('income') : loc.t('expenses'), style: const TextStyle(fontSize: 12, color: AppTheme.fgMuted)),
            ])),
            Text('${isInc ? "+" : "-"}$currency${NumberFormat('#,##,###.##').format(expense.amount)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'monospace',
                color: isInc ? const Color(0xFF22C55E) : Theme.of(context).colorScheme.onSurface)),
          ]),
        ),
      ),
    );
  }

  void _showEdit(BuildContext context, ExpenseProvider ep) {
    final amtCtrl = TextEditingController(text: expense.amount.toString());
    String cat = expense.category;
    DateTime date = DateTime.parse('${expense.date}T12:00:00');
    final cats = expense.type == 'expense' ? expenseCategories : incomeCategories;

    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) {
      return StatefulBuilder(builder: (ctx, ss) {
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 22, 18, MediaQuery.of(ctx).viewInsets.bottom + 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(expense.type == 'expense' ? loc.t('edit_expense') : loc.t('edit_income'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            TextField(controller: amtCtrl, keyboardType: TextInputType.number,
              decoration: InputDecoration(prefixText: '$currency ', labelText: loc.t('amount'))),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: cats.map((c) => ChoiceChip(
              label: Text('${c.emoji} ${c.label}'), selected: cat == c.id,
              onSelected: (_) => ss(() => cat = c.id),
              selectedColor: AppTheme.amber.withOpacity(0.2),
            )).toList()),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                label: Text(loc.t('cancel'), style: const TextStyle(color: Color(0xFFEF4444))),
                onPressed: () { ep.remove(expense.id); Navigator.pop(ctx); },
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.amber, foregroundColor: Colors.black),
                onPressed: () {
                  ep.update(expense.id, amount: double.tryParse(amtCtrl.text), category: cat,
                    date: DateFormat('yyyy-MM-dd').format(date));
                  Navigator.pop(ctx);
                },
                child: Text(loc.t('update'), style: const TextStyle(fontWeight: FontWeight.w800)),
              )),
            ]),
          ]),
        );
      });
    });
  }
}

class _HistoryStatCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final Color? valueColor;

  const _HistoryStatCard({
    required this.width,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.card : Colors.white;
    final titleCol = isDark ? AppTheme.fgMuted : Colors.black54;

    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: titleCol,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

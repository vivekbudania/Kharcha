import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _dateLabel(String s) {
    final t = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final y = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
    if (s == t) return 'Today';
    if (s == y) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(DateTime.parse('${s}T12:00:00'));
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<ExpenseProvider>();
    final sp = context.watch<SettingsProvider>();
    final grouped = ep.groupedByDate;
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    if (ep.expenses.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('📝', style: TextStyle(fontSize: 48)),
        SizedBox(height: 16),
        Text('No expenses yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text('Add your first expense!', style: TextStyle(color: AppTheme.fgMuted)),
      ]));
    }

    return SafeArea(child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(children: [
          Text('History', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('${ep.expenses.length} entries', style: const TextStyle(color: AppTheme.fgMuted, fontSize: 13)),
        ]),
      ),
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
                Text(_dateLabel(date), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.fgMuted, letterSpacing: 0.8)),
                const Spacer(),
                if (dayTotal > 0) Text('${sp.currency}${NumberFormat('#,##,###').format(dayTotal)}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.fgMuted, fontFamily: 'monospace')),
              ]),
            ),
            ...entries.map((e) => _ExpenseTile(expense: e, currency: sp.currency)),
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
  const _ExpenseTile({required this.expense, required this.currency});

  @override
  Widget build(BuildContext context) {
    final ep = context.read<ExpenseProvider>();
    final cat = getCat(expense.category);
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
              child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 20)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cat.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(isInc ? 'Income' : 'Expense', style: const TextStyle(fontSize: 12, color: AppTheme.fgMuted)),
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
            const Text('Edit Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            TextField(controller: amtCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: '₹ ', labelText: 'Amount')),
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
                label: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
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
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
              )),
            ]),
          ]),
        );
      });
    });
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../widgets/numpad.dart';
import '../widgets/category_grid.dart';
import '../widgets/streak_badge.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});
  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  String _type = 'expense';
  String _amt = '';
  DateTime _date = DateTime.now();

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());
  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);
  String get _dateLabel {
    final t = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final y = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
    if (_dateStr == t) return 'Today';
    if (_dateStr == y) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(_date);
  }

  void _onKey(String k) {
    setState(() {
      if (k == '⌫') { if (_amt.isNotEmpty) _amt = _amt.substring(0, _amt.length - 1); return; }
      if (k == '.') { if (!_amt.contains('.')) _amt += '.'; return; }
      final parts = _amt.split('.');
      if (parts.length > 1 && parts[1].length >= 2) return;
      if (_amt.length >= 10) return;
      _amt = (_amt == '0' && k != '.') ? k : _amt + k;
    });
  }

  Future<void> _pick(Category cat) async {
    if (_amt.isEmpty || double.tryParse(_amt) == null || double.parse(_amt) <= 0) return;
    final ep = context.read<ExpenseProvider>();

    await ep.addAndGetId(
      amount: double.parse(_amt),
      category: cat.id,
      date: _dateStr,
      type: _type,
    );
    setState(() => _amt = '');
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<ExpenseProvider>();
    final sp = context.watch<SettingsProvider>();
    final List<Category> cats = sp.getCategoryList(_type, _type == 'expense' ? expenseCategories : incomeCategories);
    final balance = sp.monthlyIncome + ep.monthlyIncomeTxn - ep.monthlyExpenses;
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: SizedBox(
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('   '), // Spacer equivalent logic if needed, but centering relies on Stack
                ),
                Text('Kharcha', style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900, letterSpacing: -1,
                )),
                if (ep.streak > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: StreakBadge(streak: ep.streak),
                  ),
              ],
            ),
          ),
        ),

        // Balance card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Balance', style: TextStyle(fontSize: 11, color: AppTheme.fgMuted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${sp.currency}${NumberFormat('#,##,###').format(balance)}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: balance >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444))),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Spent', style: TextStyle(fontSize: 11, color: AppTheme.fgMuted)),
                Text('${sp.currency}${NumberFormat('#,##,###').format(ep.monthlyExpenses)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
        ),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(children: [
            // Type toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12)),
              child: Row(children: ['expense', 'income'].map((t) {
                final on = t == _type;
                final color = t == 'expense' ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: on ? color.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(t[0].toUpperCase() + t.substring(1),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: on ? color : AppTheme.fgMuted)),
                  ),
                ));
              }).toList()),
            ),

            const SizedBox(height: 10),

            // Date selector
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context, initialDate: _date,
                  firstDate: DateTime(2020), lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surface, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(children: [
                  Text(_dateLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Icon(Icons.calendar_today_outlined, size: 15, color: AppTheme.fgMuted),
                ]),
              ),
            ),

            const SizedBox(height: 10),

            // Amount display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: cs.surface, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(children: [
                Expanded(child: Text(
                  _amt.isEmpty ? '${sp.currency}0' : '${sp.currency}$_amt',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: _amt.length > 7 ? 28 : 38,
                    color: _amt.isEmpty ? AppTheme.fgMuted : null,
                  ),
                )),
                if (_amt.isNotEmpty) GestureDetector(
                  onTap: () => setState(() => _amt = ''),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppTheme.card2, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 13, color: AppTheme.fgMuted),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 12),
            CategoryGrid(
              categories: cats, 
              type: _type,
              enabled: _amt.isNotEmpty && double.tryParse(_amt) != null && double.parse(_amt) > 0, 
              onPick: _pick,
            ),
            const SizedBox(height: 12),
            Numpad(onKey: _onKey),
            const SizedBox(height: 16),
          ]),
        )),
      ]),
    );
  }
}

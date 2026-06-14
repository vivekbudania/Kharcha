import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/locale_provider.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../widgets/numpad.dart';
import '../widgets/category_grid.dart';
import '../widgets/streak_badge.dart';
import '../widgets/streak_calendar.dart';
import '../main.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});
  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  String _type = 'expense';
  String _amt = '';
  DateTime _date = DateTime.now();

  // Lend / Borrow extra fields
  final _personCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  DateTime? _dueDate;

  // Post-Save Notification State
  String? _successMessage;
  String? _successSubmessage;

  @override
  void dispose() {
    _personCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool get _isLoanType => _type == 'lend' || _type == 'borrow';

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  String _dateLabel(LocaleProvider loc) {
    final t = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final y = DateFormat('yyyy-MM-dd').format(
        DateTime.now().subtract(const Duration(days: 1)));
    if (_dateStr == t) return loc.t('today');
    if (_dateStr == y) return loc.t('yesterday');
    return DateFormat('dd MMM yyyy').format(_date);
  }

  void _onKey(String k) {
    setState(() {
      if (k == '⌫') {
        if (_amt.isNotEmpty) _amt = _amt.substring(0, _amt.length - 1);
        return;
      }
      if (k == '.') {
        if (!_amt.contains('.')) _amt += '.';
        return;
      }
      final parts = _amt.split('.');
      if (parts.length > 1 && parts[1].length >= 2) return;
      if (_amt.length >= 10) return;
      _amt = (_amt == '0' && k != '.') ? k : _amt + k;
    });
  }

  // ── Save expense / income ────────────────────────────────────────────────────

  Future<void> _pick(Category cat) async {
    if (_amt.isEmpty || double.tryParse(_amt) == null || double.parse(_amt) <= 0) return;
    final ep = context.read<ExpenseProvider>();
    final sp = context.read<SettingsProvider>();

    final amountSaved = double.parse(_amt);

    await ep.addAndGetId(
      amount: amountSaved,
      category: cat.id,
      date: _dateStr,
      type: _type,
    );

    setState(() {
      _amt = '';
      _successMessage =
          '✓ Added ${sp.currency}${NumberFormat('#,##,###').format(amountSaved)}';

      final todayTotal = ep.todayExpenses;
      final r = DateTime.now().millisecond % 3;
      if (r == 0) {
        _successSubmessage =
            "Today's spending reached ${sp.currency}${NumberFormat('#,##,###').format(todayTotal)}.";
      } else if (r == 1) {
        _successSubmessage =
            "${cat.emoji} ${sp.catLabel(cat.id, cat.label)} selected.";
      } else {
        _successSubmessage = "Logged in under 3 seconds! ⚡";
      }
    });

    _autoDismiss();
  }

  // ── Save lend / borrow ───────────────────────────────────────────────────────

  Future<void> _saveLoan() async {
    final amount = double.tryParse(_amt);
    if (amount == null || amount <= 0) return;
    final person = _personCtrl.text.trim();
    if (person.isEmpty) {
      _showPersonError();
      return;
    }

    final lp = context.read<LoanProvider>();
    final sp = context.read<SettingsProvider>();

    await lp.add(
      amount: amount,
      type: _type,
      personName: person,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      date: _dateStr,
      dueDate: _dueDate != null
          ? DateFormat('yyyy-MM-dd').format(_dueDate!)
          : null,
    );

    final cur = sp.currency;
    final fmtAmt = '${cur}${NumberFormat('#,##,###').format(amount)}';
    final outstanding = _type == 'lend' ? lp.totalOwedToMe : lp.totalIOwe;

    setState(() {
      _amt = '';
      _personCtrl.clear();
      _noteCtrl.clear();
      _dueDate = null;

      if (_type == 'lend') {
        _successMessage = '💸 Lent $fmtAmt to $person.';
        _successSubmessage =
            'Outstanding owed to you: ${cur}${NumberFormat('#,##,###').format(outstanding)}';
      } else {
        _successMessage = '🤝 Borrowed $fmtAmt from $person.';
        _successSubmessage =
            'You owe: ${cur}${NumberFormat('#,##,###').format(outstanding)}';
      }
    });

    _autoDismiss();
  }

  void _showPersonError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter the person\'s name.'),
        backgroundColor: Color(0xFFEF4444),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _autoDismiss() {
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        setState(() {
          _successMessage = null;
          _successSubmessage = null;
        });
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ep  = context.watch<ExpenseProvider>();
    final lp  = context.watch<LoanProvider>();
    final sp  = context.watch<SettingsProvider>();
    final loc = context.watch<LocaleProvider>();

    final allCats = sp.getCategoryList(
        _type, _type == 'expense' ? expenseCategories : incomeCategories);
    final cs     = Theme.of(context).colorScheme;
    final cur    = sp.currency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Dashboard calculations ─────────────────────────────────────────────────
    final todaySpend  = ep.todayExpenses;
    final monthSpend  = ep.monthlyExpenses;

    final topCatEntry = ep.categoryTotals.entries.isNotEmpty
        ? (ep.categoryTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
        : null;
    final topCatLabel = topCatEntry != null
        ? sp.catLabel(
            topCatEntry.key,
            getCat(topCatEntry.key).label,
            localizedLabel: loc
                    .t('cat_${topCatEntry.key}')
                    .startsWith('cat_')
                ? null
                : loc.t('cat_${topCatEntry.key}'),
          )
        : 'None';
    final topCatAmount = topCatEntry?.value ?? 0.0;

    final trendPct = ep.monthlyTrendPercentage;
    final trendStr = trendPct == 0.0
        ? '0%'
        : '${trendPct > 0 ? "↑" : "↓"} ${trendPct.abs().toStringAsFixed(0)}%';

    // ── Smart predictions (only for expense / income) ──────────────────────────
    final suggestedIds  = _isLoanType ? <String>[] : ep.getSmartSuggestions(_type, allCats);
    final suggestedCats = allCats.where((c) => suggestedIds.contains(c.id)).toList();
    final remainingCats = allCats.where((c) => !suggestedIds.contains(c.id)).toList();

    // ── Spending health ────────────────────────────────────────────────────────
    String? healthStatusLabel;
    Color  healthColor  = Colors.transparent;
    String? healthDetail;

    if (sp.monthlyIncome != null && sp.monthlyIncome! > 0) {
      final recommended =
          ep.getRecommendedDailySpend(sp.monthlyIncome!, sp.savingsGoal ?? 0.0);
      final avg = ep.currentDailyAverage;
      if (avg <= recommended) {
        healthStatusLabel = 'On Track';
        healthColor  = const Color(0xFF22C55E);
        healthDetail = 'Daily average (${cur}${avg.toStringAsFixed(0)}) is under budget (${cur}${recommended.toStringAsFixed(0)}).';
      } else if (avg <= 1.2 * recommended) {
        healthStatusLabel = 'Watch Spending';
        healthColor  = const Color(0xFFF59E0B);
        healthDetail = 'Daily average (${cur}${avg.toStringAsFixed(0)}) is slightly over budget (${cur}${recommended.toStringAsFixed(0)}).';
      } else {
        healthStatusLabel = 'Overspending';
        healthColor  = const Color(0xFFEF4444);
        healthDetail = 'Daily average (${cur}${avg.toStringAsFixed(0)}) is well above budget (${cur}${recommended.toStringAsFixed(0)}).';
      }
    }

    // ── Dynamic insight ────────────────────────────────────────────────────────
    final singleInsight = ep.getSingleInsight(
      currency: cur,
      monthlyIncome: sp.monthlyIncome,
      savingsGoal: sp.savingsGoal,
    );

    final hasPendingLoans = lp.hasAnyPending;

    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: SizedBox(
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          loc.t('app_name'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: StreakBadge(
                            streak: ep.streak,
                            onTap: () => showStreakCalendar(
                              context,
                              activeDates: ep.streakDates,
                              streak: ep.streak,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Spending Health Banner ───────────────────────────
                        if (healthStatusLabel != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: healthColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: healthColor.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.circle,
                                    size: 12, color: healthColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        healthStatusLabel.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: healthColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        healthDetail!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.fgMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // ── Loans Overview Card ──────────────────────────────
                        if (hasPendingLoans) ...[
                          _LoansOverviewCard(
                            totalOwedToMe: lp.totalOwedToMe,
                            totalIOwe: lp.totalIOwe,
                            currency: cur,
                            isDark: isDark,
                            onTap: () {
                              final shell = context
                                  .findAncestorStateOfType<HomeShellState>();
                              if (shell != null && shell.mounted) {
                                shell.setIndex(3);
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                        ],

                        // ── 2×2 Dashboard ────────────────────────────────────
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cardW = (constraints.maxWidth - 8) / 2;
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MicroCard(
                                  width: cardW,
                                  title: loc.locale == 'hi'
                                      ? 'आज का खर्च'
                                      : 'Today',
                                  value:
                                      '$cur${NumberFormat('#,##,###').format(todaySpend)}',
                                ),
                                _MicroCard(
                                  width: cardW,
                                  title: loc.locale == 'hi'
                                      ? 'इस महीने'
                                      : 'This Month',
                                  value:
                                      '$cur${NumberFormat('#,##,###').format(monthSpend)}',
                                ),
                                _MicroCard(
                                  width: cardW,
                                  title: loc.locale == 'hi'
                                      ? 'शीर्ष श्रेणी'
                                      : 'Top Category',
                                  value: topCatEntry != null
                                      ? '$topCatLabel ($cur${NumberFormat('#,##,###').format(topCatAmount)})'
                                      : 'None',
                                ),
                                _MicroCard(
                                  width: cardW,
                                  title: loc.locale == 'hi'
                                      ? 'ट्रेंड'
                                      : 'Trend',
                                  value: trendStr,
                                  valueColor: trendPct > 0
                                      ? const Color(0xFFEF4444)
                                      : (trendPct < 0
                                          ? const Color(0xFF22C55E)
                                          : null),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // ── Money Insight Card ───────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.amber.withOpacity(0.06),
                                AppTheme.amber.withOpacity(0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.amber.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('💡',
                                  style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.locale == 'hi'
                                          ? 'साप्ताहिक इनसाइट'
                                          : 'MONEY INSIGHT',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.amber,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      singleInsight,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Quick Log Header ─────────────────────────────────
                        const Text(
                          'QUICK LOG',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.fgMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ── 4-way type toggle ────────────────────────────────
                        _TypeToggle(
                          selected: _type,
                          onSelect: (t) => setState(() {
                            _type = t;
                            _amt  = '';
                            _personCtrl.clear();
                            _noteCtrl.clear();
                            _dueDate = null;
                          }),
                          cs: cs,
                        ),
                        const SizedBox(height: 8),

                        // ── Date selector ────────────────────────────────────
                        GestureDetector(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setState(() => _date = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _dateLabel(loc),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Icon(Icons.calendar_today_outlined,
                                    size: 14, color: AppTheme.fgMuted),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ── Amount Display ───────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _amt.isEmpty ? '${cur}0' : '$cur$_amt',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: _amt.length > 7 ? 24 : 32,
                                    color: _amt.isEmpty
                                        ? AppTheme.fgMuted
                                        : null,
                                  ),
                                ),
                              ),
                              if (_amt.isNotEmpty)
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _amt = ''),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.card2,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 12,
                                        color: AppTheme.fgMuted),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ── Lend / Borrow extra fields ───────────────────────
                        if (_isLoanType) ...[
                          _LoanFields(
                            type: _type,
                            personCtrl: _personCtrl,
                            noteCtrl: _noteCtrl,
                            dueDate: _dueDate,
                            cs: cs,
                            onPickDueDate: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _dueDate ??
                                    DateTime.now()
                                        .add(const Duration(days: 7)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) setState(() => _dueDate = d);
                            },
                            onClearDueDate: () =>
                                setState(() => _dueDate = null),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _amt.isNotEmpty &&
                                      double.tryParse(_amt) != null &&
                                      double.parse(_amt) > 0
                                  ? _saveLoan
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _type == 'lend'
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppTheme.border,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: Text(
                                _type == 'lend'
                                    ? '💸  Record Lent Money'
                                    : '🤝  Record Borrowed Money',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // ── Smart Suggestions (expense/income only) ──────────
                        if (!_isLoanType && suggestedCats.isNotEmpty) ...[
                          Row(
                            children: [
                              const Text(
                                'SUGGESTED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.fgMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              if (_amt.isEmpty)
                                const Text(
                                  'Enter amount to log',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.fgMuted),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: suggestedCats.map((c) {
                              final catLabel = sp.catLabel(
                                c.id,
                                c.label,
                                localizedLabel: loc
                                        .t('cat_${c.id}')
                                        .startsWith('cat_')
                                    ? null
                                    : loc.t('cat_${c.id}'),
                              );
                              final isEnabled = _amt.isNotEmpty &&
                                  double.tryParse(_amt) != null &&
                                  double.parse(_amt) > 0;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  child: GestureDetector(
                                    onTap: isEnabled
                                        ? () => _pick(c)
                                        : null,
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                          milliseconds: 150),
                                      opacity: isEnabled ? 1 : 0.35,
                                      child: Container(
                                        padding: const EdgeInsets
                                            .symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: cs.surface,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                                AppTheme.amber.withOpacity(
                                                    isEnabled ? 0.4 : 0.1),
                                            width:
                                                isEnabled ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                sp.catEmoji(
                                                    c.id, c.emoji),
                                                style: const TextStyle(
                                                    fontSize: 18)),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                catLabel,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                ),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── Category Grid (expense/income only) ──────────────
                        if (!_isLoanType) ...[
                          CategoryGrid(
                            categories: remainingCats,
                            allCategories: allCats,
                            type: _type,
                            enabled: _amt.isNotEmpty &&
                                double.tryParse(_amt) != null &&
                                double.parse(_amt) > 0,
                            onPick: _pick,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── Numpad ───────────────────────────────────────────
                        Numpad(onKey: _onKey),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Success Banner Overlay ───────────────────────────────────────
            if (_successMessage != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  builder: (context, val, child) => Transform.scale(
                    scale: val,
                    child: Opacity(
                        opacity: val.clamp(0.0, 1.0), child: child),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141417),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF22C55E).withOpacity(0.3),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              size: 16, color: Colors.black),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _successMessage!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              if (_successSubmessage != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _successSubmessage!,
                                  style: const TextStyle(
                                      color: AppTheme.fgMuted,
                                      fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 4-way type toggle ─────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  final ColorScheme cs;

  const _TypeToggle({
    required this.selected,
    required this.onSelect,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    const types = [
      ('expense', '🟥', 'Expense',  Color(0xFFEF4444)),
      ('income',  '🟩', 'Income',   Color(0xFF22C55E)),
      ('lend',    '💸', 'Lend',     Color(0xFF3B82F6)),
      ('borrow',  '🤝', 'Borrow',   Color(0xFFF59E0B)),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: types.map((rec) {
          final (id, icon, label, color) = rec;
          final on = selected == id;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: on ? color.withOpacity(0.14) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: on
                      ? Border.all(color: color.withOpacity(0.35))
                      : Border.all(color: Colors.transparent),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: on ? color : AppTheme.fgMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Lend / Borrow extra fields ────────────────────────────────────────────────

class _LoanFields extends StatelessWidget {
  final String type;
  final TextEditingController personCtrl;
  final TextEditingController noteCtrl;
  final DateTime? dueDate;
  final ColorScheme cs;
  final VoidCallback onPickDueDate;
  final VoidCallback onClearDueDate;

  const _LoanFields({
    required this.type,
    required this.personCtrl,
    required this.noteCtrl,
    required this.dueDate,
    required this.cs,
    required this.onPickDueDate,
    required this.onClearDueDate,
  });

  @override
  Widget build(BuildContext context) {
    final isLend = type == 'lend';
    final accentColor =
        isLend ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Person name
        TextField(
          controller: personCtrl,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: isLend ? 'Lent to (name) *' : 'Borrowed from (name) *',
            prefixIcon: const Icon(Icons.person_outline, size: 18),
            filled: true,
            fillColor: cs.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Optional note
        TextField(
          controller: noteCtrl,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Note (optional)',
            prefixIcon: const Icon(Icons.notes_outlined, size: 18),
            filled: true,
            fillColor: cs.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Optional due date
        GestureDetector(
          onTap: onPickDueDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: dueDate != null
                    ? accentColor.withOpacity(0.5)
                    : AppTheme.border,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.event_outlined, size: 18, color: AppTheme.fgMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dueDate != null
                        ? 'Due: ${DateFormat('dd MMM yyyy').format(dueDate!)}'
                        : 'Due date (optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          dueDate != null ? null : AppTheme.fgMuted,
                    ),
                  ),
                ),
                if (dueDate != null)
                  GestureDetector(
                    onTap: onClearDueDate,
                    child: const Icon(Icons.close,
                        size: 16, color: AppTheme.fgMuted),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Loans Overview Card ───────────────────────────────────────────────────────

class _LoansOverviewCard extends StatelessWidget {
  final double totalOwedToMe;
  final double totalIOwe;
  final String currency;
  final bool isDark;
  final VoidCallback onTap;

  const _LoansOverviewCard({
    required this.totalOwedToMe,
    required this.totalIOwe,
    required this.currency,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('🤝', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                _LoansOverviewStat(
                  label: 'Owed to you',
                  amount:
                      '$currency${NumberFormat('#,##,###').format(totalOwedToMe)}',
                  color: const Color(0xFF22C55E),
                ),
                const SizedBox(width: 16),
                _LoansOverviewStat(
                  label: 'You owe',
                  amount:
                      '$currency${NumberFormat('#,##,###').format(totalIOwe)}',
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppTheme.fgMuted),
        ],
      ),
    );
  }
}

class _LoansOverviewStat extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _LoansOverviewStat({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppTheme.fgMuted)),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Micro Card ────────────────────────────────────────────────────────────────

class _MicroCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final Color? valueColor;

  const _MicroCard({
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

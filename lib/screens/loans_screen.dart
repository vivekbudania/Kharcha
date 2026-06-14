import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/loan_provider.dart';
import '../providers/settings_provider.dart';
import '../models/loan_record.dart';
import '../theme/app_theme.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});
  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LoanProvider>();
    final sp = context.watch<SettingsProvider>();
    final cur = sp.currency;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lentList   = lp.loans.where((l) => l.isLend).toList();
    final borrowList = lp.loans.where((l) => l.isBorrow).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Loans',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),

          // ── Summary Cards ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _SummaryCard(
                  emoji: '💸',
                  label: 'Owed to You',
                  amount: lp.totalOwedToMe,
                  currency: cur,
                  accentColor: const Color(0xFF22C55E),
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _SummaryCard(
                  emoji: '🤝',
                  label: 'You Owe',
                  amount: lp.totalIOwe,
                  currency: cur,
                  accentColor: const Color(0xFFEF4444),
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Tab Bar ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AppTheme.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppTheme.amber,
                unselectedLabelColor: AppTheme.fgMuted,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💸  Lent Out'),
                        if (lp.lentPending.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _Badge(lp.lentPending.length),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🤝  Borrowed'),
                        if (lp.borrowedPending.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _Badge(lp.borrowedPending.length),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Tab Content ──────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _LoanList(
                  loans: lentList,
                  currency: cur,
                  emptyTitle: 'No lent money',
                  emptySubtitle: 'When you lend money, it will appear here.',
                  emptyEmoji: '💸',
                ),
                _LoanList(
                  loans: borrowList,
                  currency: cur,
                  emptyTitle: 'No borrowed money',
                  emptySubtitle: 'When you borrow money, it will appear here.',
                  emptyEmoji: '🤝',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loan list ─────────────────────────────────────────────────────────────────

class _LoanList extends StatelessWidget {
  final List<LoanRecord> loans;
  final String currency;
  final String emptyTitle;
  final String emptySubtitle;
  final String emptyEmoji;

  const _LoanList({
    required this.loans,
    required this.currency,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyEmoji,
  });

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emptyEmoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(emptyTitle,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(emptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.fgMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: loans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _LoanTile(loan: loans[i], currency: currency),
    );
  }
}

// ── Single loan tile ──────────────────────────────────────────────────────────

class _LoanTile extends StatelessWidget {
  final LoanRecord loan;
  final String currency;

  const _LoanTile({required this.loan, required this.currency});

  @override
  Widget build(BuildContext context) {
    final lp = context.read<LoanProvider>();
    final isLend = loan.isLend;
    final isPending = loan.isPending;
    final accentColor =
        isLend ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return Slidable(
      key: ValueKey(loan.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          if (isPending)
            SlidableAction(
              onPressed: (_) => _confirmSettle(context, lp),
              icon: Icons.check_circle_outline,
              label: 'Settle',
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14)),
            ),
          SlidableAction(
            onPressed: (_) => lp.remove(loan.id),
            icon: Icons.delete_outline,
            label: 'Delete',
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.horizontal(
              left: isPending
                  ? Radius.zero
                  : const Radius.circular(14),
              right: const Radius.circular(14),
            ),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPending
                ? accentColor.withOpacity(0.25)
                : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  loan.personName.isNotEmpty
                      ? loan.personName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          loan.personName,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(isPending: isPending),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        _fmtDate(loan.date),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.fgMuted),
                      ),
                      if (loan.dueDate != null) ...[
                        const Text(' · ',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.fgMuted)),
                        Text(
                          'Due ${_fmtDate(loan.dueDate!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isDueOverdue(loan.dueDate!)
                                ? const Color(0xFFEF4444)
                                : AppTheme.fgMuted,
                            fontWeight: _isDueOverdue(loan.dueDate!)
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (loan.note != null && loan.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        loan.note!,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.fgMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Amount
            Text(
              '$currency${NumberFormat('#,##,###').format(loan.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSettle(BuildContext context, LoanProvider lp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettleSheet(
        loan: loan,
        currency: currency,
        onSettle: () => lp.settle(loan.id),
      ),
    );
  }

  String _fmtDate(String s) {
    try {
      return DateFormat('dd MMM yy')
          .format(DateTime.parse('${s}T12:00:00'));
    } catch (_) {
      return s;
    }
  }

  bool _isDueOverdue(String dueDate) {
    try {
      final d = DateTime.parse('${dueDate}T12:00:00');
      return d.isBefore(DateTime.now()) && loan.isPending;
    } catch (_) {
      return false;
    }
  }
}

// ── Settle confirmation sheet ─────────────────────────────────────────────────

class _SettleSheet extends StatelessWidget {
  final LoanRecord loan;
  final String currency;
  final VoidCallback onSettle;

  const _SettleSheet({
    required this.loan,
    required this.currency,
    required this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bg : const Color(0xFFF5F5F7);
    final isLend = loan.isLend;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.fgMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isLend ? '✅ Mark as Received' : '✅ Mark as Repaid',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            isLend
                ? 'Did ${loan.personName} return $currency${NumberFormat('#,##,###').format(loan.amount)} to you?'
                : 'Did you repay $currency${NumberFormat('#,##,###').format(loan.amount)} to ${loan.personName}?',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.fgMuted, fontSize: 14),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  child: const Text('Not Yet',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    onSettle();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Yes, Settled! 🎉',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String emoji;
  final String label;
  final double amount;
  final String currency;
  final Color accentColor;
  final bool isDark;

  const _SummaryCard({
    required this.emoji,
    required this.label,
    required this.amount,
    required this.currency,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$currency${NumberFormat('#,##,###').format(amount)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isPending;
  const _StatusBadge({required this.isPending});

  @override
  Widget build(BuildContext context) {
    final color =
        isPending ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);
    final label = isPending ? 'PENDING' : 'SETTLED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge(this.count);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: AppTheme.amber,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      );
}

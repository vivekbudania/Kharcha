import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/locale_provider.dart';

/// Shows a bottom-sheet calendar for the given month, highlighting
/// days that appear in [activeDates] (expense streak days).
void showStreakCalendar(
  BuildContext context, {
  required Set<String> activeDates,
  required int streak,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StreakCalendarSheet(
      activeDates: activeDates,
      streak: streak,
    ),
  );
}

class _StreakCalendarSheet extends StatefulWidget {
  final Set<String> activeDates;
  final int streak;
  const _StreakCalendarSheet(
      {required this.activeDates, required this.streak});

  @override
  State<_StreakCalendarSheet> createState() => _StreakCalendarSheetState();
}

class _StreakCalendarSheetState extends State<_StreakCalendarSheet> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prev() => setState(
      () => _month = DateTime(_month.year, _month.month - 1));
  void _next() {
    final next = DateTime(_month.year, _month.month + 1);
    if (next.isBefore(DateTime(DateTime.now().year, DateTime.now().month + 1))) {
      setState(() => _month = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.card : Colors.white;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.fgMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Header streak info
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.amber.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🔥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${widget.streak} ${widget.streak == 1 ? loc.t('day') : loc.t('days')}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.amber)),
                  Text(loc.t('current_streak'), style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.5))),
                ]),
              ]),
            ),
            const Spacer(),
            Text('${widget.activeDates.length} ${loc.t('active_days')}',
                style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.5))),
          ]),
          const SizedBox(height: 24),

          // Month nav
          Row(children: [
            IconButton(
              onPressed: _prev,
              icon: const Icon(Icons.chevron_left),
              color: onSurface,
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy').format(_month),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onSurface),
              ),
            ),
            IconButton(
              onPressed: _next,
              icon: const Icon(Icons.chevron_right),
              color: onSurface,
            ),
          ]),
          const SizedBox(height: 8),

          // Weekday labels
          Row(
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((d) =>
              Expanded(
                child: Text(d,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: onSurface.withValues(alpha: 0.35))),
              )
            ).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          _buildGrid(onSurface),
          const SizedBox(height: 8),

          // Legend
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: AppTheme.amber, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(loc.t('expense_logged'), style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.5))),
          ]),
        ],
      ),
    );
  }

  Widget _buildGrid(Color onSurface) {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    final cells = <Widget>[];

    // Empty cells before first day
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr = DateFormat('yyyy-MM-dd')
          .format(DateTime(_month.year, _month.month, day));
      final isActive = widget.activeDates.contains(dateStr);
      final isToday = dateStr == todayStr;
      final isFuture = DateTime(_month.year, _month.month, day).isAfter(today);

      cells.add(_DayCell(
        day: day,
        isActive: isActive,
        isToday: isToday,
        isFuture: isFuture,
        onSurface: onSurface,
      ));
    }

    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final rowCells = cells.sublist(i, i + 7 < cells.length ? i + 7 : cells.length);
      while (rowCells.length < 7) rowCells.add(const SizedBox());
      rows.add(Row(children: rowCells.map((c) => Expanded(child: c)).toList()));
      rows.add(const SizedBox(height: 4));
    }

    return Column(children: rows);
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isActive, isToday, isFuture;
  final Color onSurface;

  const _DayCell({
    required this.day,
    required this.isActive,
    required this.isToday,
    required this.isFuture,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      height: 36,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.amber.withValues(alpha: 0.15)
            : isToday
                ? onSurface.withValues(alpha: 0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: AppTheme.amber.withValues(alpha: 0.5))
            : isToday
                ? Border.all(color: onSurface.withValues(alpha: 0.2))
                : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isActive || isToday ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? AppTheme.amber
                    : isFuture
                        ? onSurface.withValues(alpha: 0.2)
                        : onSurface.withValues(alpha: isToday ? 1.0 : 0.7),
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 1),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.amber,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  final _uuid = const Uuid();

  List<Expense> get expenses => _expenses;

  ExpenseProvider() { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('kharcha_v1');
    if (s != null) _expenses = Expense.listFromJson(s);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('kharcha_v1', Expense.listToJson(_expenses));
  }

  Future<void> add({
    required double amount,
    required String category,
    required String date,
    required String type,
  }) async {
    await addAndGetId(amount: amount, category: category, date: date, type: type);
  }

  Future<String> addAndGetId({
    required double amount,
    required String category,
    required String date,
    required String type,
  }) async {
    final id = _uuid.v4();
    _expenses.insert(0, Expense(
      id: id, amount: amount,
      category: category, date: date,
      type: type, createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    notifyListeners();
    await _save();
    return id;
  }

  Future<void> remove(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> update(String id, {double? amount, String? category, String? date}) async {
    final i = _expenses.indexWhere((e) => e.id == id);
    if (i == -1) return;
    _expenses[i] = _expenses[i].copyWith(amount: amount, category: category, date: date);
    notifyListeners();
    await _save();
  }

  // ── Computed ──
  String get todayStr => DateTime.now().toIso8601String().substring(0, 10);
  String get thisMonth => DateTime.now().toIso8601String().substring(0, 7);

  double get totalBalance => _expenses.fold(
      0.0, (s, e) => s + (e.type == 'income' ? e.amount : -e.amount));

  double get todayExpenses => _expenses
      .where((e) => e.type == 'expense' && e.date == todayStr)
      .fold(0.0, (s, e) => s + e.amount);

  double get monthlyExpenses => _expenses
      .where((e) => e.type == 'expense' && e.date.startsWith(thisMonth))
      .fold(0, (s, e) => s + e.amount);

  double get monthlyIncomeTxn => _expenses
      .where((e) => e.type == 'income' && e.date.startsWith(thisMonth))
      .fold(0, (s, e) => s + e.amount);

  double get lastMonthExpenses {
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1);
    final prevMonthStr = prevMonth.toIso8601String().substring(0, 7);
    return _expenses
        .where((e) => e.type == 'expense' && e.date.startsWith(prevMonthStr))
        .fold(0.0, (s, e) => s + e.amount);
  }

  double get monthlyTrendPercentage {
    final cur = monthlyExpenses;
    final last = lastMonthExpenses;
    if (last == 0) return 0.0;
    return ((cur - last) / last) * 100;
  }

  double getRecommendedDailySpend(double monthlyIncome, double savingsGoal) {
    final limit = monthlyIncome - savingsGoal;
    if (limit <= 0) return 0.0;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return limit / daysInMonth;
  }

  double get currentDailyAverage {
    final now = DateTime.now();
    final daysElapsed = now.day;
    return monthlyExpenses / daysElapsed;
  }

  double getBurnRate(double monthlyIncome, double savingsGoal) {
    final limit = monthlyIncome - savingsGoal;
    if (limit <= 0) return 100.0;
    return (monthlyExpenses / limit) * 100;
  }

  int get streak {
    final dates = _expenses
        .where((e) => e.type == 'expense')
        .map((e) => e.date)
        .toSet()
        .toList()
      ..sort();
    if (dates.isEmpty) return 0;
    int streak = 0;
    var exp = todayStr;
    for (final d in dates.reversed) {
      if (d == exp) {
        streak++;
        exp = DateTime.parse('${exp}T12:00:00')
            .subtract(const Duration(days: 1))
            .toIso8601String()
            .substring(0, 10);
      } else if (d.compareTo(exp) < 0) break;
    }
    return streak;
  }

  Map<String, double> get categoryTotals {
    final m = <String, double>{};
    for (final e in _expenses.where((e) =>
        e.type == 'expense' && e.date.startsWith(thisMonth))) {
      m[e.category] = (m[e.category] ?? 0) + e.amount;
    }
    return m;
  }

  Map<String, List<Expense>> get groupedByDate {
    final m = <String, List<Expense>>{};
    for (final e in _expenses) {
      (m[e.date] ??= []).add(e);
    }
    return m;
  }

  Set<String> get streakDates => _expenses
      .where((e) => e.type == 'expense')
      .map((e) => e.date)
      .toSet();

  // ── Smart Category Prediction ──
  List<String> getSmartSuggestions(String type, List<Category> activeCats) {
    if (_expenses.isEmpty) {
      return activeCats.map((c) => c.id).take(3).toList();
    }
    final currentHour = DateTime.now().hour;
    final hourlyCounts = <String, int>{};
    final overallCounts = <String, int>{};
    
    for (final e in _expenses.where((e) => e.type == type)) {
      overallCounts[e.category] = (overallCounts[e.category] ?? 0) + 1;
      final txnTime = DateTime.fromMillisecondsSinceEpoch(e.createdAt);
      final hourDiff = (txnTime.hour - currentHour).abs();
      if (hourDiff <= 2 || hourDiff >= 22) {
        hourlyCounts[e.category] = (hourlyCounts[e.category] ?? 0) + 1;
      }
    }

    final sortedCats = activeCats.map((c) => c.id).toList();
    sortedCats.sort((a, b) {
      final aHourly = hourlyCounts[a] ?? 0;
      final bHourly = hourlyCounts[b] ?? 0;
      if (aHourly != bHourly) return bHourly.compareTo(aHourly);
      final aOverall = overallCounts[a] ?? 0;
      final bOverall = overallCounts[b] ?? 0;
      return bOverall.compareTo(aOverall);
    });
    return sortedCats.take(3).toList();
  }

  // ── Insights Generator ──
  List<String> generateAllInsights({
    required String currency,
    double? monthlyIncome,
    double? savingsGoal,
  }) {
    final insights = <String>[];
    final now = DateTime.now();

    // 1. Burn Rate warning (highest priority)
    if (monthlyIncome != null && monthlyIncome > 0) {
      final limit = monthlyIncome - (savingsGoal ?? 0);
      if (limit > 0) {
        final daysInM = DateTime(now.year, now.month + 1, 0).day;
        final elapsedRatio = now.day / daysInM;
        final currentBurn = monthlyExpenses / limit;
        if (currentBurn > elapsedRatio * 1.15) {
          final exceedPct = ((currentBurn - elapsedRatio) * 100).toStringAsFixed(0);
          insights.add('Warning: You are on track to exceed your spending budget by $exceedPct% this month. ⚠️');
        } else if (currentBurn < elapsedRatio * 0.85 && monthlyExpenses > 0) {
          insights.add('Great pace! You are spending well below your budget timeline this month. 🟢');
        }
      }
    }

    // 2. WoW Comparison
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final thisW = _expenses
        .where((e) =>
            e.type == 'expense' &&
            DateTime.parse('${e.date}T00:00:00')
                .isAfter(weekStart.subtract(const Duration(days: 1))))
        .fold(0.0, (s, e) => s + e.amount);
    final lastW = _expenses
        .where((e) =>
            e.type == 'expense' &&
            !DateTime.parse('${e.date}T00:00:00').isBefore(lastWeekStart) &&
            DateTime.parse('${e.date}T00:00:00').isBefore(weekStart))
        .fold(0.0, (s, e) => s + e.amount);
    if (thisW > 0 && lastW > 0) {
      final diff = thisW - lastW;
      final pct = ((diff / lastW) * 100).abs().toStringAsFixed(0);
      if (diff > 0.15 * lastW) {
        insights.add('You spent $pct% more this week compared to last week. Watch out! ⚠️');
      } else if (diff < -0.15 * lastW) {
        insights.add('You spent $pct% less this week compared to last week. Excellent job! 🌟');
      }
    }

    // 3. Top Category Dominance
    final totals = categoryTotals;
    final totalExpense = monthlyExpenses;
    if (totals.isNotEmpty && totalExpense > 0) {
      final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      final pct = (top.value / totalExpense * 100).toStringAsFixed(0);
      if (top.value > 0.35 * totalExpense) {
        final catName = top.key[0].toUpperCase() + top.key.substring(1);
        insights.add('$catName is your biggest expense this month ($pct% of total). Can you trim it? 🔍');
      }
    }

    // 4. Weekend vs Weekday Spend
    final weekends = _expenses.where((e) => e.type == 'expense' && e.date.startsWith(thisMonth)).where((e) {
      final d = DateTime.parse('${e.date}T12:00:00');
      return d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
    });
    final weekdays = _expenses.where((e) => e.type == 'expense' && e.date.startsWith(thisMonth)).where((e) {
      final d = DateTime.parse('${e.date}T12:00:00');
      return d.weekday != DateTime.saturday && d.weekday != DateTime.sunday;
    });
    final weekendTotal = weekends.fold(0.0, (s, e) => s + e.amount);
    final weekdayTotal = weekdays.fold(0.0, (s, e) => s + e.amount);
    if (weekendTotal > 0 && weekdayTotal > 0) {
      final totalDays = DateTime(now.year, now.month, now.day).day;
      int weekendDaysCount = 0;
      int weekdayDaysCount = 0;
      for (int i = 1; i <= totalDays; i++) {
        final d = DateTime(now.year, now.month, i);
        if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
          weekendDaysCount++;
        } else {
          weekdayDaysCount++;
        }
      }
      final wkAvg = weekendDaysCount > 0 ? weekendTotal / weekendDaysCount : 0.0;
      final wdAvg = weekdayDaysCount > 0 ? weekdayTotal / weekdayDaysCount : 0.0;
      if (wkAvg > 1.25 * wdAvg && wdAvg > 0) {
        final pct = (((wkAvg - wdAvg) / wdAvg) * 100).toStringAsFixed(0);
        insights.add('Your weekend daily average is $pct% higher than weekdays. Watch weekend splurges! 🛍️');
      }
    }

    // 5. Single Largest Transaction
    final thisMonthTxns = _expenses.where((e) => e.type == 'expense' && e.date.startsWith(thisMonth)).toList();
    if (thisMonthTxns.isNotEmpty && totalExpense > 0) {
      thisMonthTxns.sort((a, b) => b.amount.compareTo(a.amount));
      final largest = thisMonthTxns.first;
      if (largest.amount > 0.20 * totalExpense) {
        final pct = (largest.amount / totalExpense * 100).toStringAsFixed(0);
        final catName = largest.category[0].toUpperCase() + largest.category.substring(1);
        insights.add('A single expense of $currency${NumberFormat('#,##,###').format(largest.amount)} in $catName represents $pct% of this month\'s spend.');
      }
    }

    if (insights.isEmpty) {
      insights.add('Track your expenses daily to reveal money leaks and spending habits. 📈');
      insights.add('Great job staying aware of your spending! Keep logging consistently. 🧠');
    }
    return insights;
  }

  String getSingleInsight({
    required String currency,
    double? monthlyIncome,
    double? savingsGoal,
  }) {
    final list = generateAllInsights(
      currency: currency,
      monthlyIncome: monthlyIncome,
      savingsGoal: savingsGoal,
    );
    // Return the first one (which matches our priority hierarchy)
    return list.first;
  }
}

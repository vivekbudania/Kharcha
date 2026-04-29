import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
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

  double get monthlyExpenses => _expenses
      .where((e) => e.type == 'expense' && e.date.startsWith(thisMonth))
      .fold(0, (s, e) => s + e.amount);

  double get monthlyIncomeTxn => _expenses
      .where((e) => e.type == 'income' && e.date.startsWith(thisMonth))
      .fold(0, (s, e) => s + e.amount);

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

  /// All unique dates (yyyy-MM-dd) that have at least one expense entry.
  Set<String> get streakDates => _expenses
      .where((e) => e.type == 'expense')
      .map((e) => e.date)
      .toSet();
}

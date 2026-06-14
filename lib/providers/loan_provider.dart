import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/loan_record.dart';

class LoanProvider extends ChangeNotifier {
  List<LoanRecord> _loans = [];
  final _uuid = const Uuid();

  List<LoanRecord> get loans => _loans;

  LoanProvider() {
    _load();
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('kharcha_loans_v1');
    if (s != null) _loans = LoanRecord.listFromJson(s);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('kharcha_loans_v1', LoanRecord.listToJson(_loans));
  }

  // ── Mutations ────────────────────────────────────────────────────────────────

  Future<void> add({
    required double amount,
    required String type,
    required String personName,
    String? note,
    required String date,
    String? dueDate,
  }) async {
    final record = LoanRecord(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      personName: personName,
      note: note,
      date: date,
      dueDate: dueDate,
      status: 'pending',
      settledDate: null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    _loans.insert(0, record);
    notifyListeners();
    await _save();
  }

  Future<void> settle(String id) async {
    final i = _loans.indexWhere((l) => l.id == id);
    if (i == -1) return;
    _loans[i] = _loans[i].copyWith(
      status: 'settled',
      settledDate: DateTime.now().toIso8601String().substring(0, 10),
    );
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _loans.removeWhere((l) => l.id == id);
    notifyListeners();
    await _save();
  }

  // ── Computed ─────────────────────────────────────────────────────────────────

  /// All loans that haven't been settled yet.
  List<LoanRecord> get pendingLoans =>
      _loans.where((l) => l.isPending).toList();

  /// Pending loans the user gave to someone else (money owed TO user).
  List<LoanRecord> get lentPending =>
      _loans.where((l) => l.isPending && l.isLend).toList();

  /// Pending loans the user received from someone else (money user OWES).
  List<LoanRecord> get borrowedPending =>
      _loans.where((l) => l.isPending && l.isBorrow).toList();

  /// Sum of all pending lend amounts (others owe the user this much).
  double get totalOwedToMe =>
      lentPending.fold(0.0, (s, l) => s + l.amount);

  /// Sum of all pending borrow amounts (user owes this much to others).
  double get totalIOwe =>
      borrowedPending.fold(0.0, (s, l) => s + l.amount);

  bool get hasAnyPending => pendingLoans.isNotEmpty;
}

import 'dart:convert';

/// Represents a single lend or borrow record.
/// Kept entirely separate from [Expense] so analytics are never contaminated.
class LoanRecord {
  final String id;
  final double amount;

  /// 'lend' = user lent money to someone (money owed TO the user)
  /// 'borrow' = user borrowed money from someone (money user OWES)
  final String type;

  final String personName;
  final String? note;

  /// yyyy-MM-dd — when the loan was created
  final String date;

  /// yyyy-MM-dd — optional due date agreed with the person
  final String? dueDate;

  /// 'pending' | 'settled'
  final String status;

  /// yyyy-MM-dd — when it was settled (null if still pending)
  final String? settledDate;

  final int createdAt; // epoch ms

  const LoanRecord({
    required this.id,
    required this.amount,
    required this.type,
    required this.personName,
    this.note,
    required this.date,
    this.dueDate,
    required this.status,
    this.settledDate,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isLend => type == 'lend';
  bool get isBorrow => type == 'borrow';

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'type': type,
    'personName': personName,
    'note': note,
    'date': date,
    'dueDate': dueDate,
    'status': status,
    'settledDate': settledDate,
    'createdAt': createdAt,
  };

  factory LoanRecord.fromMap(Map<String, dynamic> m) => LoanRecord(
    id: m['id'] as String,
    amount: (m['amount'] as num).toDouble(),
    type: m['type'] as String,
    personName: m['personName'] as String,
    note: m['note'] as String?,
    date: m['date'] as String,
    dueDate: m['dueDate'] as String?,
    status: m['status'] as String,
    settledDate: m['settledDate'] as String?,
    createdAt: m['createdAt'] as int,
  );

  static List<LoanRecord> listFromJson(String s) =>
      (jsonDecode(s) as List).map((e) => LoanRecord.fromMap(e as Map<String, dynamic>)).toList();

  static String listToJson(List<LoanRecord> list) =>
      jsonEncode(list.map((e) => e.toMap()).toList());

  LoanRecord copyWith({String? status, String? settledDate}) => LoanRecord(
    id: id,
    amount: amount,
    type: type,
    personName: personName,
    note: note,
    date: date,
    dueDate: dueDate,
    status: status ?? this.status,
    settledDate: settledDate ?? this.settledDate,
    createdAt: createdAt,
  );
}

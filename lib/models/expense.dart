import 'dart:convert';

class Expense {
  final String id;
  final double amount;
  final String category;
  final String date;       // yyyy-MM-dd
  final String type;       // 'expense' | 'income'
  final int createdAt;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'amount': amount, 'category': category,
    'date': date, 'type': type, 'createdAt': createdAt,
  };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: m['id'], amount: m['amount'].toDouble(),
    category: m['category'], date: m['date'],
    type: m['type'], createdAt: m['createdAt'],
  );

  static List<Expense> listFromJson(String s) =>
      (jsonDecode(s) as List).map((e) => Expense.fromMap(e)).toList();

  static String listToJson(List<Expense> list) =>
      jsonEncode(list.map((e) => e.toMap()).toList());

  Expense copyWith({double? amount, String? category, String? date}) => Expense(
    id: id, createdAt: createdAt, type: type,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    date: date ?? this.date,
  );
}

// Category metadata
class Category {
  final String id, label, emoji;
  const Category(this.id, this.label, this.emoji);
}

const expenseCategories = [
  Category('food',      'Food',      '🍔'),
  Category('transport', 'Transport', '🚗'),
  Category('shopping',  'Shopping',  '🛍️'),
  Category('bills',     'Bills',     '📄'),
  Category('other',     'Other',     '➕'),
];

const incomeCategories = [
  Category('salary', 'Salary', '💰'),
  Category('refund', 'Refund', '🔄'),
  Category('gift',   'Gift',   '🎁'),
  Category('other',  'Other',  '➕'),
];

Category getCat(String id) {
  return [...expenseCategories, ...incomeCategories]
      .firstWhere((c) => c.id == id, orElse: () => expenseCategories.last);
}
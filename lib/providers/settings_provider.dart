import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDark = true;
  String _currency = '₹';
  // categoryId -> {label, emoji, hidden, type?}
  Map<String, Map<String, dynamic>> _catOverrides = {};

  bool get isDark => _isDark;
  String get currency => _currency;
  Map<String, Map<String, dynamic>> get catOverrides => _catOverrides;

  String catLabel(String id, String defaultLabel, {String? localizedLabel}) =>
      _catOverrides[id]?['label'] ?? localizedLabel ?? defaultLabel;
  String catEmoji(String id, String defaultEmoji) =>
      _catOverrides[id]?['emoji'] ?? defaultEmoji;
  bool catHidden(String id) =>
      _catOverrides[id]?['hidden'] == true;
  bool isCustomCat(String id) =>
      _catOverrides[id]?.containsKey('type') == true;

  List<Category> getCategoryList(String type, List<Category> defaultCats) {
    final list = [...defaultCats];
    for (final id in _catOverrides.keys) {
      final data = _catOverrides[id]!;
      if (data['type'] == type) {
        list.add(Category(id, data['label'] ?? 'New', data['emoji'] ?? '✨'));
      }
    }
    return list;
  }

  SettingsProvider() { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _isDark = p.getBool('isDark') ?? true;
    _currency = p.getString('currency') ?? '₹';
    final raw = p.getString('catOverrides');
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _catOverrides = decoded.map((k, v) =>
          MapEntry(k, Map<String, dynamic>.from(v as Map)));
    }
    notifyListeners();
  }

  Future<void> setTheme(bool dark) async {
    _isDark = dark;
    final p = await SharedPreferences.getInstance();
    await p.setBool('isDark', dark);
    notifyListeners();
  }

  Future<void> setCurrency(String c) async {
    _currency = c;
    final p = await SharedPreferences.getInstance();
    await p.setString('currency', c);
    notifyListeners();
  }


  Future<void> addCustomCategory(String type, {required String label, required String emoji}) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    _catOverrides[id] = {
      'type': type,
      'label': label,
      'emoji': emoji,
      'hidden': false,
    };
    final p = await SharedPreferences.getInstance();
    await p.setString('catOverrides', jsonEncode(_catOverrides));
    notifyListeners();
  }

  Future<void> setCatOverride(String id, {required String label, required String emoji, bool? hidden}) async {
    final existing = _catOverrides[id] ?? {};
    _catOverrides[id] = {
      ...existing,
      'label': label,
      'emoji': emoji,
      if (hidden != null) 'hidden': hidden,
      if (existing['hidden'] != null && hidden == null) 'hidden': existing['hidden'],
    };
    final p = await SharedPreferences.getInstance();
    await p.setString('catOverrides', jsonEncode(_catOverrides));
    notifyListeners();
  }

  Future<void> setCatHidden(String id, bool hidden) async {
    final existing = _catOverrides[id] ?? {};
    _catOverrides[id] = {
      ...existing,
      'hidden': hidden,
    };
    final p = await SharedPreferences.getInstance();
    await p.setString('catOverrides', jsonEncode(_catOverrides));
    notifyListeners();
  }

  Future<void> restoreHiddenCategories() async {
    bool changed = false;
    for (final id in _catOverrides.keys) {
      if (_catOverrides[id]?['hidden'] == true) {
        _catOverrides[id]?['hidden'] = false;
        changed = true;
      }
    }
    if (changed) {
      final p = await SharedPreferences.getInstance();
      await p.setString('catOverrides', jsonEncode(_catOverrides));
      notifyListeners();
    }
  }

  Future<void> deleteCustomCategory(String id) async {
    _catOverrides.remove(id);
    final p = await SharedPreferences.getInstance();
    await p.setString('catOverrides', jsonEncode(_catOverrides));
    notifyListeners();
  }

  Future<void> resetCatOverride(String id) async {
    if (isCustomCat(id)) return; // custom cats are deleted, not reset
    _catOverrides.remove(id);
    final p = await SharedPreferences.getInstance();
    await p.setString('catOverrides', jsonEncode(_catOverrides));
    notifyListeners();
  }
}

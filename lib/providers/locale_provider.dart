import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/translations.dart';

class LocaleProvider extends ChangeNotifier {
  String _locale = 'en';

  String get locale => _locale;

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('kharcha_locale');
    if (saved != null && appTranslations.containsKey(saved)) {
      _locale = saved;
      notifyListeners();
    }
  }

  Future<void> setLocale(String langCode) async {
    if (!appTranslations.containsKey(langCode)) return;
    _locale = langCode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kharcha_locale', langCode);
  }

  String t(String key) {
    return appTranslations[_locale]?[key] ?? appTranslations['en']?[key] ?? key;
  }
}

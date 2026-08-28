import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../utils/translations.dart';

class LanguageProvider extends ChangeNotifier {
  late final _box = DBService.box(DBService.settingsBox);

  // Default to English if not set
  String get currentLang => _box.get('app_language', defaultValue: 'en');

  void setLanguage(String langCode) {
    _box.put('app_language', langCode);
    notifyListeners();
  }

  String t(String key) {
    return Translations.get(key, currentLang);
  }
}

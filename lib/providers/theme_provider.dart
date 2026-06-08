import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  static const _boxName = 'app_settings';
  static const _key = 'dark_mode';
  bool _isDark = false;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final box = await Hive.openBox(_boxName);
    _isDark = box.get(_key, defaultValue: false) as bool;
    notifyListeners();
  }

  bool get isDark => _isDark;

  Future<void> toggle() async {
    _isDark = !_isDark;
    final box = await Hive.openBox(_boxName);
    await box.put(_key, _isDark);
    notifyListeners();
  }
}

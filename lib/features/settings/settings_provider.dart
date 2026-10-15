import 'package:flutter/material.dart';

import '../../core/services/storage_service.dart';

/// Tamaños de texto que ofrece la app (además del que tenga el sistema).
enum TextSizeOption {
  normal('Normal', 1.0),
  large('Grande', 1.2),
  extraLarge('Muy grande', 1.4);

  const TextSizeOption(this.label, this.factor);

  final String label;
  final double factor;
}

/// Preferencias visuales: tema claro/oscuro y tamaño de texto.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage) {
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == _storage.getString(_kTheme),
      orElse: () => ThemeMode.light,
    );
    _textSize = TextSizeOption.values.firstWhere(
      (t) => t.name == _storage.getString(_kTextSize),
      orElse: () => TextSizeOption.normal,
    );
    _soundEnabled = _storage.getBool(_kSound) ?? true;
  }

  static const _kTheme = 'settings.theme';
  static const _kTextSize = 'settings.textSize';
  static const _kSound = 'settings.sound';

  final StorageService _storage;

  late ThemeMode _themeMode;
  late TextSizeOption _textSize;
  late bool _soundEnabled;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  TextSizeOption get textSize => _textSize;
  bool get soundEnabled => _soundEnabled;

  void setDarkMode(bool dark) {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    _storage.setString(_kTheme, _themeMode.name);
    notifyListeners();
  }

  void setTextSize(TextSizeOption option) {
    _textSize = option;
    _storage.setString(_kTextSize, option.name);
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    _storage.setBool(_kSound, value);
    notifyListeners();
  }
}

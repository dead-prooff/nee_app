import 'package:shared_preferences/shared_preferences.dart';

/// Envoltorio fino sobre shared_preferences.
///
/// Se crea una sola vez en `main()` y se comparte con Provider, así las
/// pantallas no tienen que esperar a que cargue el almacenamiento.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> init() async =>
      StorageService(await SharedPreferences.getInstance());

  String? getString(String key) => _prefs.getString(key);
  int? getInt(String key) => _prefs.getInt(key);
  bool? getBool(String key) => _prefs.getBool(key);
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  /// Borra todo (útil para reiniciar la demo desde Configuración).
  Future<void> clear() => _prefs.clear();
}

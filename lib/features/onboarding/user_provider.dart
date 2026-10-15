import 'package:flutter/foundation.dart';

import '../../core/services/storage_service.dart';

/// Cuánto guaraní sabe el usuario al empezar.
enum StartLevel {
  none('Nunca hablé', 'Empiezo de cero', '🌱'),
  some('Entiendo algo', 'Conozco palabras y frases sueltas', '🌿'),
  jopara('Hablo jopara', 'Mezclo guaraní y castellano', '🧉');

  const StartLevel(this.label, this.description, this.emoji);

  final String label;
  final String description;
  final String emoji;
}

/// Cómo se registró el usuario.
enum AuthMethod { email, google }

/// Datos del usuario registrado y si ya completó el onboarding.
///
/// El registro es local (todavía no hay servidor). La contraseña se valida
/// en el formulario pero NO se guarda: shared_preferences no es un lugar
/// seguro para contraseñas.
class UserProvider extends ChangeNotifier {
  UserProvider(this._storage) {
    _onboardingDone = _storage.getBool(_kDone) ?? false;
    _name = _storage.getString(_kName);
    _username = _storage.getString(_kUsername);
    _email = _storage.getString(_kEmail);
    _authMethod = AuthMethod.values.firstWhere(
      (m) => m.name == _storage.getString(_kAuth),
      orElse: () => AuthMethod.email,
    );
    _level = StartLevel.values
        .where((l) => l.name == _storage.getString(_kLevel))
        .firstOrNull;
  }

  static const _kDone = 'user.onboardingDone';
  static const _kName = 'user.name';
  static const _kUsername = 'user.username';
  static const _kEmail = 'user.email';
  static const _kAuth = 'user.authMethod';
  static const _kLevel = 'user.level';

  final StorageService _storage;

  late bool _onboardingDone;
  String? _name;
  String? _username;
  String? _email;
  late AuthMethod _authMethod;
  StartLevel? _level;

  bool get onboardingDone => _onboardingDone;
  String? get name => _name;
  String? get username => _username;
  String? get email => _email;
  AuthMethod get authMethod => _authMethod;
  StartLevel? get level => _level;

  /// Guarda los datos del registro y marca el onboarding como hecho, así
  /// no vuelve a aparecer.
  Future<void> completeOnboarding({
    required String name,
    required String username,
    required String? email,
    required AuthMethod authMethod,
    required StartLevel level,
  }) async {
    _name = name;
    _username = username;
    _email = email;
    _authMethod = authMethod;
    _level = level;
    _onboardingDone = true;
    notifyListeners();

    await Future.wait([
      _storage.setString(_kName, name),
      _storage.setString(_kUsername, username),
      if (email != null) _storage.setString(_kEmail, email),
      _storage.setString(_kAuth, authMethod.name),
      _storage.setString(_kLevel, level.name),
      _storage.setBool(_kDone, true),
    ]);
  }
}

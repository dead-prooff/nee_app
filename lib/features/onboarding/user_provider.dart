import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/services/storage_service.dart';
import '../profile/avatars.dart';

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
  UserProvider(this._storage, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
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
    _avatarId = _storage.getString(_kAvatar) ?? defaultAvatarId;
    final photo = _storage.getString(_kPhoto);
    _photo = photo == null ? null : base64Decode(photo);
    final registered = _storage.getString(_kRegisteredAt);
    _registeredAt = registered == null ? null : DateTime.parse(registered);
    // Quien se registró antes de que existiera este dato: se toma hoy.
    if (_onboardingDone && _registeredAt == null) {
      _registeredAt = _clock();
      _storage.setString(_kRegisteredAt, _registeredAt!.toIso8601String());
    }
    _usedInviteCode = _storage.getString(_kUsedInvite);
    _invitedFriend = _storage.getBool(_kInvited) ?? false;
  }

  static const _kDone = 'user.onboardingDone';
  static const _kName = 'user.name';
  static const _kUsername = 'user.username';
  static const _kEmail = 'user.email';
  static const _kAuth = 'user.authMethod';
  static const _kLevel = 'user.level';
  static const _kAvatar = 'user.avatar';
  static const _kPhoto = 'user.photo';
  static const _kRegisteredAt = 'user.registeredAt';
  static const _kUsedInvite = 'user.usedInviteCode';
  static const _kInvited = 'user.invitedFriend';

  /// XP de bienvenida para los dos cuando alguien se registra con un código.
  static const inviteBonusXp = 50;

  final StorageService _storage;
  final DateTime Function() _clock;

  late bool _onboardingDone;
  String? _name;
  String? _username;
  String? _email;
  late AuthMethod _authMethod;
  StartLevel? _level;
  late String _avatarId;
  Uint8List? _photo;
  DateTime? _registeredAt;
  String? _usedInviteCode;
  late bool _invitedFriend;

  bool get onboardingDone => _onboardingDone;
  String? get name => _name;
  String? get username => _username;
  String? get email => _email;
  AuthMethod get authMethod => _authMethod;
  StartLevel? get level => _level;

  /// Avatar ilustrado elegido (se usa si no hay foto).
  String get avatarId => _avatarId;

  /// Foto propia (JPEG chico), o null si usa un avatar ilustrado.
  Uint8List? get photo => _photo;
  DateTime? get registeredAt => _registeredAt;

  /// Código de invitación con el que se registró, si usó uno.
  String? get usedInviteCode => _usedInviteCode;

  /// Si ya compartió su código con algún amigo.
  bool get invitedFriend => _invitedFriend;

  /// Código propio para invitar amigos: NEE- + usuario + 2 números
  /// (siempre el mismo para el mismo usuario). Ej.: NEE-WILLY23.
  String get inviteCode => inviteCodeFor(_username ?? 'amigo');

  static String inviteCodeFor(String username) {
    final letters = username.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final base = letters.isEmpty ? 'AMIGO' : letters;
    var hash = 7;
    for (final unit in username.codeUnits) {
      hash = (hash * 31 + unit) % 1000003;
    }
    final digits = (hash % 90 + 10).toString();
    return 'NEE-${base.length > 8 ? base.substring(0, 8) : base}$digits';
  }

  /// Formato válido de un código de invitación (NEE- y 3 a 12 letras o
  /// números). No se puede comprobar si existe: todavía no hay servidor.
  static bool isValidInviteCode(String code) =>
      RegExp(r'^NEE-[A-Z0-9]{3,12}$').hasMatch(code.trim().toUpperCase());

  /// Guarda los datos del registro y marca el onboarding como hecho, así
  /// no vuelve a aparecer.
  Future<void> completeOnboarding({
    required String name,
    required String username,
    required String? email,
    required AuthMethod authMethod,
    required StartLevel level,
    String? avatarId,
    Uint8List? photo,
    String? inviteCode,
  }) async {
    _name = name;
    _username = username;
    _email = email;
    _authMethod = authMethod;
    _level = level;
    _avatarId = avatarId ?? defaultAvatarId;
    _photo = photo;
    _registeredAt = _clock();
    _usedInviteCode = inviteCode != null && isValidInviteCode(inviteCode)
        ? inviteCode.trim().toUpperCase()
        : null;
    _onboardingDone = true;
    notifyListeners();

    await Future.wait([
      _storage.setString(_kName, name),
      _storage.setString(_kUsername, username),
      if (email != null) _storage.setString(_kEmail, email),
      _storage.setString(_kAuth, authMethod.name),
      _storage.setString(_kLevel, level.name),
      _storage.setString(_kAvatar, _avatarId),
      if (photo != null) _storage.setString(_kPhoto, base64Encode(photo)),
      _storage.setString(_kRegisteredAt, _registeredAt!.toIso8601String()),
      if (_usedInviteCode != null)
        _storage.setString(_kUsedInvite, _usedInviteCode!),
      _storage.setBool(_kDone, true),
    ]);
  }

  /// Elige un avatar ilustrado (y deja de usar la foto).
  Future<void> setAvatar(String id) async {
    _avatarId = id;
    _photo = null;
    notifyListeners();
    await Future.wait([
      _storage.setString(_kAvatar, id),
      _storage.remove(_kPhoto),
    ]);
  }

  /// Usa una foto propia como avatar (se guarda en el dispositivo).
  Future<void> setPhoto(Uint8List bytes) async {
    _photo = bytes;
    notifyListeners();
    await _storage.setString(_kPhoto, base64Encode(bytes));
  }

  /// Se llama al compartir o copiar el código de invitación.
  Future<void> markInvitedFriend() async {
    if (_invitedFriend) return;
    _invitedFriend = true;
    notifyListeners();
    await _storage.setBool(_kInvited, true);
  }
}

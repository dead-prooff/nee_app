/// Validaciones del formulario de registro.
///
/// Devuelven `null` si el valor es válido, o el mensaje de error a mostrar.
class Validators {
  Validators._();

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Escribí tu nombre';
    if (v.length < 2) return 'El nombre es muy corto';
    if (v.length > 40) return 'Máximo 40 caracteres';
    return null;
  }

  static final _usernameChars = RegExp(r'^[a-z0-9_]+$');

  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Elegí un nombre de usuario';
    if (v.length < 3) return 'Mínimo 3 caracteres';
    if (v.length > 20) return 'Máximo 20 caracteres';
    if (!_usernameChars.hasMatch(v)) {
      return 'Solo minúsculas, números y guion bajo (_)';
    }
    return null;
  }

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Escribí tu correo';
    if (!_email.hasMatch(v)) return 'Revisá el correo (ej.: nombre@gmail.com)';
    return null;
  }

  static const passwordMinLength = 8;

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Creá una contraseña';
    if (v.length < passwordMinLength) {
      return 'Mínimo $passwordMinLength caracteres';
    }
    if (!v.contains(RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]'))) {
      return 'Tiene que tener al menos una letra';
    }
    if (!v.contains(RegExp(r'[0-9]'))) {
      return 'Tiene que tener al menos un número';
    }
    return null;
  }
}

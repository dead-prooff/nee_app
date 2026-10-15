import 'dart:convert';

import 'package:flutter/services.dart';

import 'lesson_models.dart';

/// Carga el contenido de las lecciones desde los assets.
class LessonRepository {
  LessonRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const _path = 'assets/data/lecciones.json';

  final AssetBundle _bundle;
  Future<List<Unit>>? _units;

  /// Se lee una sola vez; las llamadas siguientes reutilizan el resultado.
  Future<List<Unit>> loadUnits() => _units ??= _load();

  Future<List<Unit>> _load() async {
    final json = jsonDecode(await _bundle.loadString(_path))
        as Map<String, dynamic>;
    return [
      for (final u in json['unidades'] as List)
        Unit.fromJson(u as Map<String, dynamic>),
    ];
  }
}

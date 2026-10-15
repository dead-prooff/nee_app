import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// AssetBundle que lee los assets del disco de forma síncrona.
///
/// Leer un asset con `rootBundle` en un widget test es I/O real, que no
/// avanza dentro del reloj falso de `pump`; un FutureBuilder que espera las
/// lecciones quedaría cargando para siempre.
class FileAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) =>
      SynchronousFuture(ByteData.sublistView(File(key).readAsBytesSync()));

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(File(key).readAsStringSync());
}

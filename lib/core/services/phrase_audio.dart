import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reproduce el audio de una frase desde `assets/audio/`.
///
/// Si la grabación todavía no existe, suena `placeholder.wav` en su lugar,
/// así los ejercicios de escucha funcionan antes de tener todos los audios.
class PhraseAudio {
  final AudioPlayer _player = AudioPlayer();

  static const _placeholder = 'audio/placeholder.wav';
  static Future<Set<String>>? _assets;

  /// Si existe la grabación real de [file].
  static Future<bool> hasRecording(String file) async {
    _assets ??= AssetManifest.loadFromAssetBundle(rootBundle)
        .then((m) => m.listAssets().toSet());
    return (await _assets!).contains('assets/audio/$file');
  }

  Future<void> play(String file) async {
    final source = await hasRecording(file) ? 'audio/$file' : _placeholder;
    try {
      await _player.stop();
      await _player.play(AssetSource(source));
    } catch (e) {
      // Sin audio (por ejemplo en tests) la app tiene que seguir funcionando.
      debugPrint('No se pudo reproducir $source: $e');
    }
  }

  Future<void> dispose() => _player.dispose();
}

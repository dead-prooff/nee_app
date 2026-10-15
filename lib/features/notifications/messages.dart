import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

/// Tipos de mensaje de `assets/data/mensajes.json` (la clave del JSON).
enum MessageKind {
  streakDanger('racha_peligro'),
  streakLost('racha_perdida'),
  streakActive('racha_activa'),
  streakKavaju('racha_kavaju'),
  goalReached('meta_cumplida'),
  duelReceived('duelo_recibido'),
  duelWon('duelo_ganado'),
  duelLost('duelo_perdido'),
  duelDraw('duelo_empate'),
  leagueUp('liga_subiste'),
  leagueDown('liga_bajaste'),
  leagueStay('liga_mantuviste'),
  welcomeLeague('bienvenida_liga'),
  welcomeStreak('bienvenida_racha');

  const MessageKind(this.key);

  final String key;
}

/// Un mensaje con variables sin reemplazar ("{nombre} te desafió").
class MessageTemplate {
  const MessageTemplate({required this.title, required this.body});

  final String title;
  final String body;
}

/// Textos de los avisos, editables en `assets/data/mensajes.json`.
class Messages {
  Messages(this._byKind);

  static const path = 'assets/data/mensajes.json';

  final Map<MessageKind, List<MessageTemplate>> _byKind;

  static Future<Messages> load(AssetBundle bundle) async =>
      Messages.fromJsonString(await bundle.loadString(path));

  factory Messages.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return Messages({
      for (final kind in MessageKind.values)
        kind: [
          for (final m in json[kind.key] as List? ?? const [])
            MessageTemplate(
              title: (m as Map<String, dynamic>)['titulo'] as String,
              body: m['texto'] as String? ?? '',
            ),
        ],
    });
  }

  List<MessageTemplate> of(MessageKind kind) => _byKind[kind] ?? const [];

  /// Elige un mensaje al azar evitando los índices de [recent] (los últimos
  /// usados), así no se repite el mismo seguido. Devuelve el índice elegido.
  int pick(MessageKind kind, Random random, {List<int> recent = const []}) {
    final count = of(kind).length;
    if (count == 0) return -1;
    final options = [
      for (var i = 0; i < count; i++)
        if (!recent.contains(i)) i,
    ];
    final pool = options.isEmpty ? List.generate(count, (i) => i) : options;
    return pool[random.nextInt(pool.length)];
  }

  /// Arma el título y el texto del mensaje [index] con las [vars]
  /// (`{nombre}`, `{dias}`, etc.).
  ({String title, String body}) render(
    MessageKind kind,
    int index,
    Map<String, Object> vars,
  ) {
    final list = of(kind);
    if (index < 0 || index >= list.length) return (title: '', body: '');
    String fill(String text) => text.replaceAllMapped(
      RegExp(r'\{(\w+)\}'),
      (m) => vars[m[1]]?.toString() ?? m[0]!,
    );
    return (title: fill(list[index].title), body: fill(list[index].body));
  }
}

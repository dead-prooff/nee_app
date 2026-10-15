import 'dart:convert';

import 'package:flutter/material.dart';

/// Quién escribió algo: el usuario ([me]) o el id de un amigo simulado.
const me = 'me';

enum ForumCategory {
  dudas('Dudas', Icons.help_outline),
  aportes('Aportes', Icons.lightbulb_outline),
  correcciones('Correcciones de guaraní', Icons.spellcheck),
  cultura('Cultura', Icons.festival_outlined),
  charla('Charla libre', Icons.chat_bubble_outline);

  const ForumCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Etiqueta de un comentario en una lección.
enum CommentTag {
  opinion('Opinión'),
  duda('Duda'),
  correccion('Corrección');

  const CommentTag(this.label);

  final String label;
}

/// Una respuesta (en un tema o en un comentario de lección).
class ForumReply {
  const ForumReply({
    required this.id,
    required this.authorId,
    required this.body,
    required this.createdAt,
    this.baseLikes = 0,
    this.seedUseful = false,
  });

  final String id;
  final String authorId;
  final String body;
  final DateTime createdAt;

  /// Likes que ya tenía (contenido de ejemplo); los del usuario se suman aparte.
  final int baseLikes;

  /// Marcada como útil en el contenido de ejemplo.
  final bool seedUseful;

  bool get isMine => authorId == me;

  Map<String, Object> toJson() => {
    'id': id,
    'autor': authorId,
    'texto': body,
    'fecha': createdAt.toIso8601String(),
  };

  factory ForumReply.fromJson(Map<String, dynamic> json) => ForumReply(
    id: json['id'] as String,
    authorId: json['autor'] as String,
    body: json['texto'] as String,
    createdAt: DateTime.parse(json['fecha'] as String),
  );
}

/// Un tema del foro o un comentario en una lección (si tiene [lessonId]).
class ForumPost {
  const ForumPost({
    required this.id,
    required this.authorId,
    required this.body,
    required this.createdAt,
    this.title,
    this.category,
    this.lessonId,
    this.tag,
    this.baseLikes = 0,
    this.replies = const [],
  });

  final String id;
  final String authorId;
  final String body;
  final DateTime createdAt;

  /// Solo en los temas del foro.
  final String? title;
  final ForumCategory? category;

  /// Solo en los comentarios de lección.
  final String? lessonId;
  final CommentTag? tag;

  final int baseLikes;
  final List<ForumReply> replies;

  bool get isMine => authorId == me;
  bool get isTopic => lessonId == null;

  /// Es una corrección de guaraní (tema o comentario).
  bool get isCorrection =>
      category == ForumCategory.correcciones || tag == CommentTag.correccion;

  /// Clave de las respuestas simuladas (`respuestas_simuladas` del JSON).
  String get kindKey => category?.name ?? tag?.name ?? 'charla';

  ForumPost withReplies(List<ForumReply> replies) => ForumPost(
    id: id,
    authorId: authorId,
    body: body,
    createdAt: createdAt,
    title: title,
    category: category,
    lessonId: lessonId,
    tag: tag,
    baseLikes: baseLikes,
    replies: replies,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'autor': authorId,
    'texto': body,
    'fecha': createdAt.toIso8601String(),
    'titulo': title,
    'categoria': category?.name,
    'leccion': lessonId,
    'etiqueta': tag?.name,
  };

  factory ForumPost.fromJson(Map<String, dynamic> json) => ForumPost(
    id: json['id'] as String,
    authorId: json['autor'] as String,
    body: json['texto'] as String,
    createdAt: DateTime.parse(json['fecha'] as String),
    title: json['titulo'] as String?,
    category: ForumCategory.values
        .where((c) => c.name == json['categoria'])
        .firstOrNull,
    lessonId: json['leccion'] as String?,
    tag: CommentTag.values.where((t) => t.name == json['etiqueta']).firstOrNull,
  );
}

/// Contenido de ejemplo de `assets/data/foro.json`. Las fechas son
/// relativas ("hace_min") y se calculan desde [baseline].
class ForumSeed {
  ForumSeed(this._json);

  static const path = 'assets/data/foro.json';

  final Map<String, dynamic> _json;

  factory ForumSeed.fromJsonString(String source) =>
      ForumSeed(jsonDecode(source) as Map<String, dynamic>);

  /// Respuestas que los amigos dejan en lo que publica el usuario.
  List<String> simulatedReplies(String kind) => [
    for (final r
        in (_json['respuestas_simuladas'] as Map<String, dynamic>)[kind]
                as List? ??
            const [])
      r as String,
  ];

  List<ForumReply> _replies(String postId, List? raw, DateTime baseline) => [
    for (final (i, r) in (raw ?? const []).indexed)
      ForumReply(
        id: '$postId-r$i',
        authorId: (r as Map<String, dynamic>)['autor'] as String,
        body: r['texto'] as String,
        createdAt: baseline.subtract(Duration(minutes: r['hace_min'] as int)),
        baseLikes: r['likes'] as int? ?? 0,
        seedUseful: r['util'] as bool? ?? false,
      ),
  ];

  List<ForumPost> topics(DateTime baseline) => [
    for (final t in _json['temas'] as List)
      ForumPost(
        id: (t as Map<String, dynamic>)['id'] as String,
        authorId: t['autor'] as String,
        title: t['titulo'] as String,
        body: t['texto'] as String,
        category: ForumCategory.values.byName(t['categoria'] as String),
        createdAt: baseline.subtract(Duration(minutes: t['hace_min'] as int)),
        baseLikes: t['likes'] as int? ?? 0,
        replies: _replies(
          t['id'] as String,
          t['respuestas'] as List?,
          baseline,
        ),
      ),
  ];

  List<ForumPost> lessonComments(String lessonId, DateTime baseline) {
    final raw =
        (_json['comentarios'] as Map<String, dynamic>)[lessonId] as List? ??
        const [];
    return [
      for (final (i, c) in raw.indexed)
        () {
          final id = 'c-$lessonId-$i';
          final map = c as Map<String, dynamic>;
          return ForumPost(
            id: id,
            authorId: map['autor'] as String,
            body: map['texto'] as String,
            lessonId: lessonId,
            tag: CommentTag.values.byName(map['etiqueta'] as String),
            createdAt: baseline.subtract(
              Duration(minutes: map['hace_min'] as int),
            ),
            baseLikes: map['likes'] as int? ?? 0,
            replies: _replies(id, map['respuestas'] as List?, baseline),
          );
        }(),
    ];
  }
}

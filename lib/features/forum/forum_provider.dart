import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/services/storage_service.dart';
import '../../core/utils/stable_hash.dart';
import 'forum_models.dart';

enum ForumSort { recent, popular }

/// Foro de la comunidad y comentarios por lección.
///
/// Mezcla el contenido de ejemplo (`assets/data/foro.json`) con lo que
/// publica el usuario, que se guarda en el dispositivo. Como todavía no hay
/// servidor, las reacciones de los amigos se simulan según el tiempo que
/// pasó desde cada publicación (siempre igual para la misma publicación):
/// - un amigo responde al minuto,
/// - llega un like cada 40 segundos (hasta 12 en las correcciones),
/// - a los 2 minutos, el autor del tema marca algunas de tus respuestas
///   como útiles.
class ForumProvider extends ChangeNotifier {
  ForumProvider(this._storage, {required this.seed, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    final seeded = _storage.getString(_kSeededAt);
    _baseline = seeded == null ? _clock() : DateTime.parse(seeded);
    if (seeded == null) {
      _storage.setString(_kSeededAt, _baseline.toIso8601String());
    }
    _seedTopics = seed.topics(_baseline);
    _myPosts = [
      for (final s in _storage.getStringList(_kPosts) ?? const <String>[])
        ForumPost.fromJson(jsonDecode(s) as Map<String, dynamic>),
    ];
    final replies = jsonDecode(
      _storage.getString(_kReplies) ?? '{}',
    ) as Map<String, dynamic>;
    _myReplies = {
      for (final e in replies.entries)
        e.key: [
          for (final r in e.value as List)
            ForumReply.fromJson(r as Map<String, dynamic>),
        ],
    };
    _liked = (_storage.getStringList(_kLiked) ?? const []).toSet();
    _useful = (_storage.getStringList(_kUseful) ?? const []).toSet();
    _reported = (_storage.getStringList(_kReported) ?? const []).toSet();
  }

  static const _kSeededAt = 'forum.seededAt';
  static const _kPosts = 'forum.myPosts';
  static const _kReplies = 'forum.myReplies';
  static const _kLiked = 'forum.liked';
  static const _kUseful = 'forum.useful';
  static const _kReported = 'forum.reported';
  static const _kRulesSeen = 'forum.rulesSeen';

  static const likeEvery = Duration(seconds: 40);
  static const friendReplyAfter = Duration(minutes: 1);
  static const usefulAfter = Duration(minutes: 2);

  /// Likes desde los que una corrección es "Revisión de la comunidad".
  static const reviewLikes = 10;
  static const correctionLikeTarget = 12;

  /// Quién responde según el tipo de publicación.
  static const _replier = {
    'correcciones': 'rosa',
    'correccion': 'rosa',
    'dudas': 'ramon',
    'duda': 'ramon',
    'aportes': 'sofi',
    'cultura': 'rosa',
    'charla': 'nico',
    'opinion': 'mati',
  };

  final StorageService _storage;
  final ForumSeed seed;
  final DateTime Function() _clock;

  late final DateTime _baseline;
  late final List<ForumPost> _seedTopics;
  final Map<String, List<ForumPost>> _seedComments = {};
  late List<ForumPost> _myPosts;
  late Map<String, List<ForumReply>> _myReplies;
  late Set<String> _liked;
  late Set<String> _useful;
  late Set<String> _reported;

  DateTime get now => _clock();
  bool get rulesSeen => _storage.getBool(_kRulesSeen) ?? false;

  // ---------------------------------------------------------------------
  // Lectura

  /// Temas visibles (sin los reportados), con todas sus respuestas.
  List<ForumPost> get topics => [
    for (final t in [..._seedTopics, ..._myPosts.where((p) => p.isTopic)])
      if (!_reported.contains(t.id)) _complete(t),
  ];

  List<ForumPost> filteredTopics({
    ForumCategory? category,
    String query = '',
    ForumSort sort = ForumSort.recent,
  }) {
    final q = _normalize(query.trim());
    final list = topics.where((t) {
      if (category != null && t.category != category) return false;
      if (q.isEmpty) return true;
      return _normalize('${t.title} ${t.body}').contains(q);
    }).toList();
    list.sort(
      (a, b) => sort == ForumSort.recent
          ? b.createdAt.compareTo(a.createdAt)
          : popularity(b).compareTo(popularity(a)),
    );
    return list;
  }

  int popularity(ForumPost p) => likesOf(p) + 2 * p.replies.length;

  ForumPost? topicById(String id) =>
      topics.where((t) => t.id == id).firstOrNull;

  /// Comentarios de una lección: primero los del usuario (el más nuevo
  /// arriba, así ve lo que acaba de publicar) y después los más votados.
  List<ForumPost> lessonComments(String lessonId) {
    final seeded = _seedComments.putIfAbsent(
      lessonId,
      () => seed.lessonComments(lessonId, _baseline),
    );
    final list = [
      for (final c in [
        ...seeded,
        ..._myPosts.where((p) => p.lessonId == lessonId),
      ])
        if (!_reported.contains(c.id)) _complete(c),
    ];
    list.sort((a, b) {
      if (a.isMine != b.isMine) return a.isMine ? -1 : 1;
      if (a.isMine) return b.createdAt.compareTo(a.createdAt);
      final byLikes = likesOf(b).compareTo(likesOf(a));
      return byLikes != 0 ? byLikes : b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  int lessonCommentCount(String lessonId) => lessonComments(lessonId).length;

  ForumPost? lessonCommentById(String lessonId, String id) =>
      lessonComments(lessonId).where((c) => c.id == id).firstOrNull;

  bool likedByMe(String id) => _liked.contains(id);

  int _since(DateTime from) => max(0, now.difference(from).inSeconds);

  int _simulatedLikes(String id, DateTime createdAt, int target) =>
      min(target, _since(createdAt) ~/ likeEvery.inSeconds);

  int likesOf(ForumPost p) =>
      (p.isMine
          ? _simulatedLikes(
              p.id,
              p.createdAt,
              p.isCorrection ? correctionLikeTarget : 3 + stableHash(p.id) % 6,
            )
          : p.baseLikes) +
      (likedByMe(p.id) ? 1 : 0);

  int replyLikesOf(ForumReply r) =>
      (r.isMine
          ? _simulatedLikes(r.id, r.createdAt, 1 + stableHash(r.id) % 5)
          : r.baseLikes) +
      (likedByMe(r.id) ? 1 : 0);

  /// Correcciones muy votadas: "Revisión de la comunidad".
  bool isCommunityReview(ForumPost p) =>
      p.isCorrection && likesOf(p) >= reviewLikes;

  /// Si [reply] está marcada como "Respuesta útil" en [post].
  bool isUseful(ForumPost post, ForumReply reply) {
    if (!post.isTopic) return false;
    if (post.isMine) return _useful.contains(reply.id);
    if (reply.isMine) {
      // El autor (simulado) marca algunas respuestas del usuario.
      return _since(reply.createdAt) >= usefulAfter.inSeconds &&
          stableHash(reply.id) % 10 < 7;
    }
    return reply.seedUseful;
  }

  /// Agrega las respuestas del usuario y la del amigo (si ya pasó el
  /// tiempo), sin las reportadas.
  ForumPost _complete(ForumPost p) {
    final replies =
        [
            ...p.replies,
            ...?_myReplies[p.id],
            ?_friendReply(p),
          ].where((r) => !_reported.contains(r.id)).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return p.withReplies(replies);
  }

  /// Respuesta simulada de un amigo a lo que publicó el usuario.
  ForumReply? _friendReply(ForumPost p) {
    if (!p.isMine) return null;
    final at = p.createdAt.add(friendReplyAfter);
    if (now.isBefore(at)) return null;
    final pool = seed.simulatedReplies(p.kindKey);
    if (pool.isEmpty) return null;
    return ForumReply(
      id: '${p.id}-amigo',
      authorId: _replier[p.kindKey] ?? 'lucia',
      body: pool[stableHash(p.id) % pool.length],
      createdAt: at,
    );
  }

  // ---------------------------------------------------------------------
  // Para avisos e insignias

  /// Todo lo que publicó el usuario (temas y comentarios), completo.
  List<ForumPost> get myPostsComplete => [
    for (final p in _myPosts)
      if (!_reported.contains(p.id)) _complete(p),
  ];

  /// Respuestas del usuario en temas de otros que el autor marcó útiles.
  int get myUsefulReplies => [
    for (final t in topics)
      for (final r in t.replies)
        if (r.isMine && isUseful(t, r)) r,
  ].length;

  /// Si alguna corrección del usuario llegó a 10 likes.
  bool get hasPopularCorrection =>
      myPostsComplete.any((p) => p.isCorrection && likesOf(p) >= reviewLikes);

  // ---------------------------------------------------------------------
  // Acciones

  String _newId() => 'me-${now.microsecondsSinceEpoch}';

  Future<ForumPost> createTopic({
    required String title,
    required ForumCategory category,
    required String body,
  }) async {
    final post = ForumPost(
      id: _newId(),
      authorId: me,
      title: title.trim(),
      category: category,
      body: body.trim(),
      createdAt: now,
    );
    _myPosts.add(post);
    await _savePosts();
    notifyListeners();
    return post;
  }

  Future<ForumPost> addLessonComment({
    required String lessonId,
    required CommentTag tag,
    required String body,
  }) async {
    final post = ForumPost(
      id: _newId(),
      authorId: me,
      lessonId: lessonId,
      tag: tag,
      body: body.trim(),
      createdAt: now,
    );
    _myPosts.add(post);
    await _savePosts();
    notifyListeners();
    return post;
  }

  Future<void> reply(String postId, String body) async {
    _myReplies
        .putIfAbsent(postId, () => [])
        .add(
          ForumReply(
            id: _newId(),
            authorId: me,
            body: body.trim(),
            createdAt: now,
          ),
        );
    await _storage.setString(
      _kReplies,
      jsonEncode({
        for (final e in _myReplies.entries)
          e.key: [for (final r in e.value) r.toJson()],
      }),
    );
    notifyListeners();
  }

  Future<void> toggleLike(String id) async {
    _liked.contains(id) ? _liked.remove(id) : _liked.add(id);
    notifyListeners();
    await _storage.setStringList(_kLiked, _liked.toList());
  }

  /// El autor del tema (el usuario) marca o desmarca una respuesta útil.
  Future<void> toggleUseful(String replyId) async {
    _useful.contains(replyId) ? _useful.remove(replyId) : _useful.add(replyId);
    notifyListeners();
    await _storage.setStringList(_kUseful, _useful.toList());
  }

  /// Reportar oculta la publicación para el usuario.
  Future<void> report(String id) async {
    _reported.add(id);
    notifyListeners();
    await _storage.setStringList(_kReported, _reported.toList());
  }

  Future<void> markRulesSeen() => _storage.setBool(_kRulesSeen, true);

  /// Avisa que pasó el tiempo (respuestas y likes simulados nuevos), para
  /// que avisos e insignias se actualicen.
  void refresh() => notifyListeners();

  Future<void> _savePosts() => _storage.setStringList(_kPosts, [
    for (final p in _myPosts) jsonEncode(p.toJson()),
  ]);

  static String _normalize(String s) {
    const from = 'áéíóúüñãẽĩõũỹ';
    const to = 'aeiouunaeiouy';
    final lower = s.toLowerCase();
    final buffer = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      buffer.write(i < 0 ? ch : to[i]);
    }
    return buffer.toString();
  }
}

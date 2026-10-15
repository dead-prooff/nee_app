import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'forum_models.dart';
import 'forum_provider.dart';
import 'widgets/forum_widgets.dart';

/// Hilo de comentarios de una lección: opiniones, dudas y correcciones de
/// guaraní. Las correcciones muy votadas se marcan como "Revisión de la
/// comunidad".
class LessonCommentsScreen extends StatefulWidget {
  const LessonCommentsScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  final String lessonId;
  final String lessonTitle;

  @override
  State<LessonCommentsScreen> createState() => _LessonCommentsScreenState();
}

class _LessonCommentsScreenState extends State<LessonCommentsScreen> {
  final _text = TextEditingController();
  CommentTag _tag = CommentTag.opinion;

  @override
  void initState() {
    super.initState();
    // Al entrar se revisan respuestas y likes simulados nuevos.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ForumProvider>().refresh(),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final text = _text.text.trim();
    if (text.length < 3) return;
    if (!await ensureRulesAccepted(context) || !mounted) return;
    await context.read<ForumProvider>().addLessonComment(
      lessonId: widget.lessonId,
      tag: _tag,
      body: text,
    );
    _text.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('¡Comentario publicado! 💬')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final forum = context.watch<ForumProvider>();
    final comments = forum.lessonComments(widget.lessonId);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Comentarios (${comments.length})')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(
            widget.lessonTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            semanticContainer: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final t in CommentTag.values)
                        ChoiceChip(
                          label: Text(t.label),
                          selected: _tag == t,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _tag = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _text,
                    minLines: 2,
                    maxLines: 6,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: switch (_tag) {
                        CommentTag.opinion => '¿Qué te pareció la lección?',
                        CommentTag.duda => '¿Qué duda tenés?',
                        CommentTag.correccion =>
                          '¿Qué corregirías del guaraní?',
                      },
                      alignLabelWithHint: true,
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _text,
                    builder: (context, value, _) => FilledButton.icon(
                      onPressed: value.text.trim().length >= 3
                          ? _publish
                          : null,
                      icon: const Icon(Icons.send),
                      label: const Text('Publicar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (comments.isEmpty)
            Text(
              'Todavía no hay comentarios. ¡Sé el primero!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final c in comments) ...[
              CommentCard(comment: c),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

/// Un comentario de lección con sus respuestas.
class CommentCard extends StatelessWidget {
  const CommentCard({super.key, required this.comment});

  final ForumPost comment;

  Future<void> _reply(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: ReplyComposer(
        hint: 'Respondé a ${authorName(context, comment.authorId)}',
        onSend: (text) async {
          await context.read<ForumProvider>().reply(comment.id, text);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final forum = context.watch<ForumProvider>();
    final theme = Theme.of(context);
    final review = forum.isCommunityReview(comment);

    return Card(
      semanticContainer: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              container: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthorAvatar(comment.authorId),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthorLine(
                          authorId: comment.authorId,
                          date: comment.createdAt,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ForumLabel(
                              text: comment.tag!.label,
                              tone: comment.isCorrection
                                  ? LabelTone.correction
                                  : LabelTone.neutral,
                            ),
                            if (review)
                              const ForumLabel(
                                text: 'Revisión de la comunidad',
                                icon: Icons.verified,
                                tone: LabelTone.success,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(comment.body, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                LikeButton(
                  count: forum.likesOf(comment),
                  liked: forum.likedByMe(comment.id),
                  onPressed: comment.isMine
                      ? null
                      : () => forum.toggleLike(comment.id),
                ),
                TextButton.icon(
                  onPressed: () => _reply(context),
                  icon: const Icon(Icons.reply),
                  label: const Text('Responder'),
                ),
                if (!comment.isMine) ReportButton(itemId: comment.id),
              ],
            ),
            if (comment.replies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 8),
                child: Column(
                  children: [
                    for (final r in comment.replies)
                      ReplyTile(post: comment, reply: r),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'forum_provider.dart';
import 'widgets/forum_widgets.dart';

/// Un tema del foro con sus respuestas, likes y "Respuesta útil".
class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key, required this.topicId});

  final String topicId;

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Después de responder, baja hasta la respuesta nueva.
  Future<void> _send(ForumProvider forum, String topicId, String text) async {
    await forum.reply(topicId, text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final topicId = widget.topicId;
    final forum = context.watch<ForumProvider>();
    final topic = forum.topicById(topicId);
    final theme = Theme.of(context);

    if (topic == null) {
      // Por ejemplo, si se acaba de reportar.
      return Scaffold(
        appBar: AppBar(title: const Text('Tema')),
        body: const Center(child: Text('Este tema ya no está disponible.')),
      );
    }

    final replies = topic.replies;
    return Scaffold(
      appBar: AppBar(title: Text(topic.category!.label)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        topic.title!,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        AuthorAvatar(topic.authorId),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AuthorLine(
                            authorId: topic.authorId,
                            date: topic.createdAt,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(topic.body, style: theme.textTheme.bodyLarge),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        LikeButton(
                          count: forum.likesOf(topic),
                          liked: forum.likedByMe(topic.id),
                          onPressed: topic.isMine
                              ? null
                              : () => forum.toggleLike(topic.id),
                        ),
                        if (!topic.isMine) ReportButton(itemId: topic.id),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    replies.isEmpty
                        ? 'Todavía no hay respuestas'
                        : replies.length == 1
                        ? '1 respuesta'
                        : '${replies.length} respuestas',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (topic.isMine && replies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Como es tu tema, podés marcar las respuestas que te '
                      'sirvieron.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (final r in replies) ReplyTile(post: topic, reply: r),
              ],
            ),
          ),
          const Divider(height: 1),
          ReplyComposer(onSend: (text) => _send(forum, topic.id, text)),
        ],
      ),
    );
  }
}

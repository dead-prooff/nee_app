import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'forum_models.dart';
import 'forum_provider.dart';
import 'topic_screen.dart';
import 'widgets/forum_widgets.dart';

/// Pestaña Foro: temas de la comunidad con buscador, orden y filtros por
/// categoría. El botón "Nuevo tema" está en la pantalla principal.
class ForumView extends StatefulWidget {
  const ForumView({super.key});

  @override
  State<ForumView> createState() => _ForumViewState();
}

class _ForumViewState extends State<ForumView> {
  final _search = TextEditingController();
  ForumCategory? _category;
  ForumSort _sort = ForumSort.recent;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forum = context.watch<ForumProvider>();
    final theme = Theme.of(context);
    final topics = forum.filteredTopics(
      category: _category,
      query: _search.text,
      sort: _sort,
    );

    return ListView(
      // Lugar abajo para que el botón "Nuevo tema" no tape el último tema.
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Buscar en el foro',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar búsqueda',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(_search.clear),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<ForumSort>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: ForumSort.recent,
              label: Text('Recientes'),
              icon: Icon(Icons.schedule),
            ),
            ButtonSegment(
              value: ForumSort.popular,
              label: Text('Populares'),
              icon: Icon(Icons.local_fire_department_outlined),
            ),
          ],
          selected: {_sort},
          onSelectionChanged: (s) => setState(() => _sort = s.first),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final c in [null, ...ForumCategory.values])
              ChoiceChip(
                label: Text(c?.label ?? 'Todos'),
                avatar: c == null ? null : Icon(c.icon, size: 18),
                selected: _category == c,
                showCheckmark: false,
                onSelected: (_) => setState(() => _category = c),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (topics.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const ExcludeSemantics(
                  child: Text('🔎', style: TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 8),
                Text(
                  _search.text.isEmpty
                      ? 'Todavía no hay temas acá. ¡Arrancá vos!'
                      : 'No encontramos temas con "${_search.text}".',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          for (final t in topics) ...[
            TopicCard(topic: t),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

/// Tarjeta de un tema en la lista.
class TopicCard extends StatelessWidget {
  const TopicCard({super.key, required this.topic});

  final ForumPost topic;

  @override
  Widget build(BuildContext context) {
    final forum = context.watch<ForumProvider>();
    final theme = Theme.of(context);
    final likes = forum.likesOf(topic);
    final replies = topic.replies.length;
    final author = authorName(context, topic.authorId);

    return Semantics(
      button: true,
      label:
          '${topic.title}. ${topic.category!.label}. De $author. '
          '$replies ${replies == 1 ? 'respuesta' : 'respuestas'}, '
          '$likes me gusta.',
      excludeSemantics: true,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TopicScreen(topicId: topic.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthorAvatar(topic.authorId),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ForumLabel(
                        text: topic.category!.label,
                        icon: topic.category!.icon,
                        tone: topic.isCorrection
                            ? LabelTone.correction
                            : LabelTone.neutral,
                      ),
                      const SizedBox(height: 6),
                      Text(topic.title!, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      AuthorLine(
                        authorId: topic.authorId,
                        date: topic.createdAt,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 16,
                        children: [
                          _Count(
                            icon: Icons.chat_bubble_outline,
                            text: '$replies',
                          ),
                          _Count(icon: Icons.favorite_border, text: '$likes'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
      ],
    );
  }
}

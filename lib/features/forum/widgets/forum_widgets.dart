import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../onboarding/user_provider.dart';
import '../../profile/widgets/avatar_image.dart';
import '../../social/friends.dart';
import '../forum_models.dart';
import '../forum_provider.dart';

/// Nombre de quien escribió (el usuario o un amigo).
String authorName(BuildContext context, String authorId) => authorId == me
    ? context.read<UserProvider>().name ?? 'Vos'
    : friendById(authorId).name;

class AuthorAvatar extends StatelessWidget {
  const AuthorAvatar(this.authorId, {super.key, this.size = 40});

  final String authorId;
  final double size;

  @override
  Widget build(BuildContext context) => authorId == me
      ? MyAvatar(size: size)
      : AvatarImage(avatarId: friendById(authorId).avatar, size: size);
}

/// "Lucía · hace 2 h" debajo del contenido.
class AuthorLine extends StatelessWidget {
  const AuthorLine({super.key, required this.authorId, required this.date});

  final String authorId;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = context.read<ForumProvider>().now;
    return Text(
      '${authorName(context, authorId)} · ${timeAgo(date, now)}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Botón de "me gusta" con el contador. [onPressed] null en lo propio.
class LikeButton extends StatelessWidget {
  const LikeButton({
    super.key,
    required this.count,
    required this.liked,
    required this.onPressed,
  });

  final int count;
  final bool liked;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FeedbackColors>()!;
    return Semantics(
      // Elemento propio: si no, se junta con el texto de la publicación.
      container: true,
      button: true,
      toggled: onPressed == null ? null : liked,
      label: count == 1 ? '1 me gusta' : '$count me gusta',
      excludeSemantics: true,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          liked ? Icons.favorite : Icons.favorite_border,
          color: liked ? colors.error : null,
        ),
        label: Text('$count'),
      ),
    );
  }
}

/// Botón "Reportar" (bandera) con los motivos.
class ReportButton extends StatelessWidget {
  const ReportButton({super.key, required this.itemId});

  final String itemId;

  static const reasons = [
    'Es ofensivo o falta el respeto',
    'Es spam o publicidad',
    'Tiene información incorrecta',
    'Otro motivo',
  ];

  Future<void> _report(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('¿Por qué la reportás?'),
        children: [
          for (final r in reasons)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, r),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Text(r),
            ),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;
    await context.read<ForumProvider>().report(itemId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Gracias por avisar 🙏 La vamos a revisar.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Reportar',
    icon: const Icon(Icons.outlined_flag),
    onPressed: () => _report(context),
  );
}

/// La primera vez que el usuario publica, muestra las normas de la
/// comunidad. Devuelve si aceptó.
Future<bool> ensureRulesAccepted(BuildContext context) async {
  final forum = context.read<ForumProvider>();
  if (forum.rulesSeen) return true;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      const rules = [
        ('💚', 'Respeto ante todo: nada de insultos ni burlas.'),
        ('🤝', 'Las correcciones, con cariño y explicando por qué.'),
        ('🧉', 'Ayudá como te gustaría que te ayuden.'),
        ('🔒', 'No compartas datos personales.'),
      ];
      return AlertDialog(
        // Con letra grande el contenido puede no entrar: se scrollea.
        scrollable: true,
        title: const Text('Normas de la comunidad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (emoji, text) in rules)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(text, style: theme.textTheme.bodyLarge),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Entendido'),
          ),
        ],
      );
    },
  );
  if (ok ?? false) {
    await forum.markRulesSeen();
    return true;
  }
  return false;
}

/// Etiqueta chica de color (categoría, "Corrección", "Respuesta útil"...).
class ForumLabel extends StatelessWidget {
  const ForumLabel({
    super.key,
    required this.text,
    this.icon,
    this.tone = LabelTone.neutral,
  });

  final String text;
  final IconData? icon;
  final LabelTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FeedbackColors>()!;
    final (bg, fg) = switch (tone) {
      LabelTone.neutral => (scheme.surfaceContainerHighest, scheme.onSurface),
      LabelTone.correction => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      LabelTone.success => (colors.successContainer, colors.onSuccessContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                color: fg,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum LabelTone { neutral, correction, success }

/// Una respuesta: avatar, texto, likes, "útil" y reportar.
class ReplyTile extends StatelessWidget {
  const ReplyTile({super.key, required this.post, required this.reply});

  final ForumPost post;
  final ForumReply reply;

  @override
  Widget build(BuildContext context) {
    final forum = context.watch<ForumProvider>();
    final theme = Theme.of(context);
    final useful = forum.isUseful(post, reply);
    // El autor del tema (el usuario) puede marcar respuestas de otros.
    final canMarkUseful = post.isTopic && post.isMine && !reply.isMine;

    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthorAvatar(reply.authorId, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthorLine(authorId: reply.authorId, date: reply.createdAt),
                  if (useful) ...[
                    const SizedBox(height: 4),
                    const ForumLabel(
                      text: 'Respuesta útil',
                      icon: Icons.check_circle,
                      tone: LabelTone.success,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(reply.body, style: theme.textTheme.bodyLarge),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      LikeButton(
                        count: forum.replyLikesOf(reply),
                        liked: forum.likedByMe(reply.id),
                        onPressed: reply.isMine
                            ? null
                            : () => forum.toggleLike(reply.id),
                      ),
                      if (canMarkUseful)
                        TextButton.icon(
                          onPressed: () => forum.toggleUseful(reply.id),
                          icon: Icon(
                            useful
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                          ),
                          label: Text(
                            useful ? 'Quitar "útil"' : 'Marcar como útil',
                          ),
                        ),
                      if (!reply.isMine) ReportButton(itemId: reply.id),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo para escribir una respuesta, con botón de enviar.
class ReplyComposer extends StatefulWidget {
  const ReplyComposer({
    super.key,
    required this.onSend,
    this.hint = 'Escribí una respuesta',
  });

  final Future<void> Function(String text) onSend;
  final String hint;

  @override
  State<ReplyComposer> createState() => _ReplyComposerState();
}

class _ReplyComposerState extends State<ReplyComposer> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.length < 2) return;
    if (!await ensureRulesAccepted(context)) return;
    await widget.onSend(text);
    _text.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                minLines: 1,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: widget.hint,
                  counterText: '',
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 4),
            ValueListenableBuilder(
              valueListenable: _text,
              builder: (context, value, _) => IconButton.filled(
                tooltip: 'Enviar',
                onPressed: value.text.trim().length >= 2 ? _send : null,
                icon: const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

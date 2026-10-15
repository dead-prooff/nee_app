import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/app_links.dart';
import '../../../core/theme/app_theme.dart';
import '../badges.dart';

/// Texto para compartir una insignia.
String badgeShareText(BadgeInfo b) =>
    '¡Gané la insignia "${b.name}" ${b.emoji} en Ñe\'ẽ! ${b.celebration} '
    'Aprendé guaraní conmigo: $appUrl';

Future<void> shareBadge(BuildContext context, BadgeInfo badge) async {
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      text: badgeShareText(badge),
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

/// Filtro que pasa a gris (para las insignias bloqueadas).
const _grayscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 0.5, 0,
]);

/// Medalla redonda con el emoji de la insignia (a color o en gris).
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({
    super.key,
    required this.badge,
    required this.unlocked,
    this.size = 64,
  });

  final BadgeInfo badge;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FeedbackColors>()!;

    final emoji = Text(badge.emoji, style: TextStyle(fontSize: size * 0.48));
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked
                    ? scheme.secondaryContainer
                    : scheme.surfaceContainerHighest,
                border: Border.all(
                  color: unlocked ? colors.gold : scheme.outline,
                  width: 3,
                ),
              ),
              child: unlocked
                  ? emoji
                  : ColorFiltered(colorFilter: _grayscale, child: emoji),
            ),
            if (!unlocked)
              Positioned(
                right: -2,
                bottom: -2,
                child: CircleAvatar(
                  radius: size * 0.17,
                  backgroundColor: scheme.onSurfaceVariant,
                  child: Icon(
                    Icons.lock,
                    size: size * 0.2,
                    color: scheme.surface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Grilla de insignias: desbloqueadas a color, bloqueadas en gris con
/// candado y cómo conseguirlas.
class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final badges = context.watch<BadgeProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        // Medalla + nombre (2 renglones) + cómo conseguirla (3 renglones),
        // según el tamaño de letra.
        mainAxisExtent:
            86 + MediaQuery.textScalerOf(context).scale(12) * 1.45 * 5,
      ),
      itemCount: badges.all.length,
      itemBuilder: (context, i) {
        final b = badges.all[i];
        final unlocked = badges.isUnlocked(b.id);
        return Semantics(
          button: true,
          label: unlocked
              ? 'Insignia ${b.name}, desbloqueada'
              : 'Insignia ${b.name}, bloqueada. ${b.howTo}',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => showBadgeDetails(context, b, unlocked: unlocked),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  BadgeMedal(badge: b, unlocked: unlocked),
                  const SizedBox(height: 6),
                  Text(
                    b.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      color: unlocked
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  if (!unlocked) ...[
                    const SizedBox(height: 2),
                    Text(
                      b.howTo,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Ficha de una insignia (al tocarla en la grilla).
Future<void> showBadgeDetails(
  BuildContext context,
  BadgeInfo badge, {
  required bool unlocked,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: BadgeMedal(badge: badge, unlocked: unlocked, size: 88),
              ),
              const SizedBox(height: 12),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                unlocked ? badge.celebration : badge.howTo,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              if (unlocked) ...[
                const SizedBox(height: 20),
                Builder(
                  builder: (buttonContext) => OutlinedButton.icon(
                    onPressed: () => shareBadge(buttonContext, badge),
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Festejo al ganar una insignia: la medalla aparece con un rebote.
class BadgeCelebrationDialog extends StatelessWidget {
  const BadgeCelebrationDialog({super.key, required this.badge});

  final BadgeInfo badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AlertDialog(
      // Con letra grande el contenido puede no entrar: se scrollea.
      scrollable: true,
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ExcludeSemantics(
            child: Text('🎉', style: TextStyle(fontSize: 32)),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.elasticOut,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: BadgeMedal(badge: badge, unlocked: true, size: 112),
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Column(
              children: [
                Text(
                  '¡Insignia nueva!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  badge.celebration,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Builder(
          builder: (buttonContext) => OutlinedButton.icon(
            onPressed: () => shareBadge(buttonContext, badge),
            icon: const Icon(Icons.share),
            label: const Text('Compartir'),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('¡Iporã!'),
        ),
      ],
    );
  }
}

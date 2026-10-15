import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../onboarding/user_provider.dart';
import '../profile/widgets/avatar_image.dart';
import 'league_models.dart';
import 'league_provider.dart';

/// Pestaña Ranking: liga semanal con 10 amigos, la posición del usuario
/// destacada y las zonas de ascenso y descenso.
class RankingView extends StatelessWidget {
  const RankingView({super.key});

  @override
  Widget build(BuildContext context) {
    final league = context.watch<LeagueProvider>();
    final myName =
        context.select<UserProvider, String?>((u) => u.name) ?? 'Vos';
    final table = league.standings(myName: myName);
    final current = league.league;

    final rows = <Widget>[];
    for (final entry in table) {
      // Separador al empezar la zona de descenso.
      if (entry.zone == Zone.demotion &&
          entry.rank == table.length - current.demoteCount + 1) {
        rows.add(
          _ZoneLabel(
            text: 'Zona de descenso a ${current.previous!.label}',
            icon: Icons.arrow_downward,
            promotion: false,
          ),
        );
      }
      rows.add(_EntryRow(entry: entry));
      // Separador al terminar la zona de ascenso.
      if (entry.zone == Zone.promotion && entry.rank == current.promoteCount) {
        rows.add(
          _ZoneLabel(
            text: 'Zona de ascenso a ${current.next!.label}',
            icon: Icons.arrow_upward,
            promotion: true,
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _LeagueHeader(league: current, daysLeft: league.daysLeft),
        const SizedBox(height: 16),
        Card(
          // Cada fila es un elemento aparte para el lector de pantalla (por
          // defecto Card junta todo en uno).
          semanticContainer: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: rows),
          ),
        ),
      ],
    );
  }
}

class _LeagueHeader extends StatelessWidget {
  const _LeagueHeader({required this.league, required this.daysLeft});

  final League league;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final closing = daysLeft == 1
        ? 'La liga cierra hoy a la medianoche.'
        : 'Faltan $daysLeft días para que cierre la liga.';
    final rules = [
      closing,
      if (league.next != null)
        'Los ${league.promoteCount} primeros suben a ${league.next!.label}.',
      if (league.previous != null)
        'Los ${league.demoteCount} últimos bajan a ${league.previous!.label}.',
      if (league.next == null) '¡Estás en la liga más alta!',
    ].join(' ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Escalera de ligas, con la actual resaltada.
            Semantics(
              label: 'Ligas: Bronce, Plata y Oro. Estás en ${league.label}',
              excludeSemantics: true,
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                children: [
                  for (final l in League.values) ...[
                    if (l != League.values.first)
                      Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                    _LeagueBadge(league: l, current: l == league),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                'Liga ${league.label}',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 6),
                  child: Icon(
                    Icons.schedule,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Flexible(
                  child: Text(
                    rules,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueBadge extends StatelessWidget {
  const _LeagueBadge({required this.league, required this.current});

  final League league;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Opacity(
      opacity: current ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: current ? scheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: current ? scheme.primary : scheme.outline,
            width: current ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(league.emoji, style: TextStyle(fontSize: current ? 32 : 24)),
            Text(
              league.label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                color: current ? scheme.onPrimaryContainer : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneLabel extends StatelessWidget {
  const _ZoneLabel({
    required this.text,
    required this.icon,
    required this.promotion,
  });

  final String text;
  final IconData icon;
  final bool promotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FeedbackColors>()!;
    final color = promotion ? colors.success : colors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Divider(color: color, thickness: 1.5)),
          const SizedBox(width: 8),
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            flex: 4,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color, thickness: 1.5)),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final LeagueEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FeedbackColors>()!;
    final isMe = entry.isMe;

    final rankColor = switch (entry.zone) {
      Zone.promotion => colors.success,
      Zone.demotion => colors.error,
      Zone.safe => scheme.onSurfaceVariant,
    };
    final zoneText = switch (entry.zone) {
      Zone.promotion => ', zona de ascenso',
      Zone.demotion => ', zona de descenso',
      Zone.safe => '',
    };
    final fg = isMe ? scheme.onPrimaryContainer : scheme.onSurface;

    return Semantics(
      label:
          'Puesto ${entry.rank}: ${isMe ? 'vos' : entry.name}, '
          '${entry.xp} XP$zoneText',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: isMe
            ? BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.primary, width: 2),
              )
            : null,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${entry.rank}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isMe ? fg : rankColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isMe)
              const MyAvatar(size: 40)
            else
              AvatarImage(avatarId: entry.avatar, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      entry.name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(color: fg),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'VOS',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (entry.zone != Zone.safe && !isMe)
              Icon(
                entry.zone == Zone.promotion
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 16,
                color: rankColor,
              ),
            const SizedBox(width: 4),
            Text(
              '${entry.xp} XP',
              style: theme.textTheme.titleSmall?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/dates.dart';
import 'data/duel_models.dart';
import 'duel_intro_screen.dart';
import 'duel_provider.dart';

/// Pestaña Duelos: récord, desafíos pendientes y amigos para desafiar.
class DuelsView extends StatelessWidget {
  const DuelsView({super.key});

  static void _open(
    BuildContext context,
    Friend friend, {
    PendingDuel? pending,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DuelIntroScreen(friend: friend, pending: pending),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duels = context.watch<DuelProvider>();
    final pending = duels.pending;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _RecordCard(duels: duels),
        const SizedBox(height: 24),
        _SectionTitle(
          'Duelos pendientes',
          trailing: pending.isEmpty ? null : '${pending.length}',
        ),
        if (pending.isEmpty)
          const _EmptyPending()
        else
          for (final duel in pending) ...[
            _PendingCard(
              duel: duel,
              onAccept: () => _open(context, duel.friend, pending: duel),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 24),
        const _SectionTitle('Desafiá a un amigo'),
        for (final friend in friends) ...[
          _FriendCard(
            friend: friend,
            onChallenge: () => _open(context, friend),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.duels});

  final DuelProvider duels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FeedbackColors>()!;

    Widget stat(String value, String label, Color color) => Expanded(
      child: Semantics(
        label: '$value $label',
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(color: color),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tu récord', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                stat('${duels.wins}', 'victorias', colors.success),
                stat('${duels.draws}', 'empates', scheme.onSurface),
                stat('${duels.losses}', 'derrotas', colors.error),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '5 preguntas · 10 segundos cada una · '
              '+${DuelOutcome.win.xp} XP si ganás',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Text(text, style: theme.textTheme.titleMedium),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trailing!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.friend);

  final Friend friend;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      child: Text(friend.emoji, style: const TextStyle(fontSize: 24)),
    ),
  );
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.duel, required this.onAccept});

  final PendingDuel duel;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final friend = duel.friend;

    return Card(
      color: scheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.secondary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _Avatar(friend),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${friend.name} te desafió',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    '${timeAgo(duel.receivedAt, DateTime.now())} · '
                    'ya jugó su parte',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onAccept,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.secondary,
                foregroundColor: scheme.onSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                'Jugar',
                semanticsLabel: 'Jugar el duelo de ${friend.name}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPending extends StatelessWidget {
  const _EmptyPending();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No tenés desafíos pendientes. ¡Desafiá a alguien!',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend, required this.onChallenge});

  final Friend friend;
  final VoidCallback onChallenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _Avatar(friend),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.name, style: theme.textTheme.titleMedium),
                  Text(
                    '@${friend.username} · ${friend.tagline}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onChallenge,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                'Desafiar',
                semanticsLabel: 'Desafiar a ${friend.name}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../duels/duel_provider.dart';
import '../league/league_provider.dart';
import '../onboarding/user_provider.dart';
import '../progress/progress_provider.dart';
import '../settings/settings_screen.dart';
import 'avatar_editor_screen.dart';
import 'badges.dart';
import 'invite_screen.dart';
import 'widgets/avatar_image.dart';
import 'widgets/badge_widgets.dart';

const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', //
  'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// "15 de octubre de 2026".
String longDate(DateTime d) =>
    '${d.day} de ${_months[d.month - 1]} de ${d.year}';

/// Pestaña Perfil: datos del usuario, estadísticas, insignias e
/// invitaciones.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badges = context.watch<BadgeProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _Header(onEditAvatar: () => _push(context, const AvatarEditorScreen())),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _push(context, const InviteScreen()),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Invitar amigos'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _push(context, const SettingsScreen()),
                icon: const Icon(Icons.settings),
                label: const Text('Configuración'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle('Estadísticas'),
        const _Stats(),
        const SizedBox(height: 24),
        _SectionTitle(
          'Insignias (${badges.unlockedCount} de ${badges.all.length})',
        ),
        const BadgeGrid(),
        const SizedBox(height: 8),
        Text(
          'Tocá una insignia para ver cómo conseguirla.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onEditAvatar});

  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final registered = user.registeredAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const MyAvatar(size: 88),
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: IconButton.filled(
                    tooltip: 'Cambiar avatar',
                    onPressed: onEditAvatar,
                    icon: const Icon(Icons.edit, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      user.name ?? 'Sin nombre',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  if (user.username != null)
                    Text(
                      '@${user.username}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  if (registered != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Se unió el ${longDate(registered)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final duels = context.watch<DuelProvider>();
    final league = context.watch<LeagueProvider>().league;
    final colors = Theme.of(context).extension<FeedbackColors>()!;
    final scheme = Theme.of(context).colorScheme;

    String days(int n) => n == 1 ? '1 día' : '$n días';

    final stats = [
      (
        Icons.local_fire_department,
        colors.fire,
        days(progress.streak),
        'Racha actual',
      ),
      (
        Icons.emoji_events,
        colors.gold,
        days(progress.longestStreak),
        'Racha más larga',
      ),
      (Icons.bolt, colors.gold, '${progress.totalXp}', 'XP total'),
      (
        Icons.menu_book,
        scheme.primary,
        '${progress.completedCount}',
        'Lecciones completadas',
      ),
      (
        Icons.sports_kabaddi,
        scheme.secondary,
        '${duels.wins}',
        'Duelos ganados',
      ),
      (
        Icons.shield,
        colors.gold,
        '${league.emoji} ${league.label}',
        'Liga actual',
      ),
    ];

    Widget card((IconData, Color, String, String) s) =>
        _StatCard(icon: s.$1, color: s.$2, value: s.$3, label: s.$4);

    // Filas de dos tarjetas que crecen con el texto (sin alto fijo, para
    // que no se corte con el tamaño de letra "Muy grande").
    return Column(
      children: [
        for (var i = 0; i < stats.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: card(stats[i])),
                  const SizedBox(width: 8),
                  Expanded(child: card(stats[i + 1])),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, style: theme.textTheme.titleLarge),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/dates.dart';
import 'notification_models.dart';
import 'notifications_provider.dart';

/// Pestaña Avisos: lista con filtros y marcado de leído.
///
/// Tocar un aviso lo marca como leído y lleva a la pestaña relacionada
/// (Duelos, Inicio o Ranking) mediante [onOpen].
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key, required this.onOpen});

  final ValueChanged<NotificationType> onOpen;

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  /// `null` = Todos.
  NotificationType? _filter;

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationsProvider>();
    final items = notifications.ofType(_filter);
    final unread = notifications.unreadOf(_filter);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filtros: Todos / Duelos / Racha / Liga.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              for (final type in [null, ...NotificationType.values]) ...[
                _FilterChip(
                  label: type?.label ?? 'Todos',
                  icon: type?.icon,
                  unread: notifications.unreadOf(type),
                  selected: _filter == type,
                  onSelected: () => setState(() => _filter = type),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  unread == 0
                      ? 'Todo leído'
                      : unread == 1
                      ? '1 sin leer'
                      : '$unread sin leer',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (unread > 0)
                TextButton.icon(
                  onPressed: () => notifications.markAllRead(type: _filter),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Marcar todo como leído'),
                ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _Empty(filter: _filter)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _NotificationTile(
                    notification: items[i],
                    onTap: () {
                      notifications.markRead(items[i].id);
                      widget.onOpen(items[i].type);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.unread,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData? icon;
  final int unread;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(unread > 0 ? '$label ($unread)' : label),
      avatar: icon == null ? null : Icon(icon, size: 18),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      tooltip: unread > 0 ? '$label, $unread sin leer' : label,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FeedbackColors>()!;
    final n = notification;
    final unread = !n.read;

    final iconColor = switch (n.type) {
      NotificationType.duel => scheme.secondary,
      NotificationType.streak => colors.fire,
      NotificationType.league => colors.gold,
    };

    return Semantics(
      button: true,
      label:
          '${unread ? 'No leído. ' : ''}${n.title}. ${n.body}. '
          '${clockLabel(n.createdAt, DateTime.now())}',
      excludeSemantics: true,
      child: Card(
        color: unread ? scheme.primaryContainer : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: unread ? scheme.primary : scheme.outline,
            width: unread ? 2 : 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.surface,
                  child: Icon(n.type.icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: unread
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: unread
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        n.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: unread
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        clockLabel(n.createdAt, DateTime.now()),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: unread
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 4, left: 8),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
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

class _Empty extends StatelessWidget {
  const _Empty({required this.filter});

  final NotificationType? filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(
              child: Text('🔔', style: TextStyle(fontSize: 56)),
            ),
            const SizedBox(height: 12),
            Text(
              filter == null
                  ? 'No tenés avisos todavía.'
                  : 'No tenés avisos de ${filter!.label.toLowerCase()}.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

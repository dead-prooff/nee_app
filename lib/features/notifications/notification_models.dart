import 'package:flutter/material.dart';

/// Tipo de aviso; también es el filtro de la pantalla de Avisos.
enum NotificationType {
  duel('Duelos', Icons.sports_kabaddi),
  streak('Racha', Icons.local_fire_department),
  league('Liga', Icons.emoji_events),
  forum('Foro', Icons.forum);

  const NotificationType(this.label, this.icon);

  final String label;
  final IconData icon;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  AppNotification markRead() => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    read: true,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: NotificationType.values.byName(json['type'] as String),
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        read: json['read'] as bool? ?? false,
      );
}

/// Utilidades de fechas compartidas (racha, liga semanal, avisos).
library;

/// Día local como texto: `2026-10-14`.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Lunes 00:00 de la semana de [d]. La liga semanal va de lunes a domingo.
DateTime weekStart(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// Identificador de la semana: el día del lunes (`2026-10-12`).
String weekKey(DateTime d) => dayKey(weekStart(d));

/// Semana anterior a la de [key].
String previousWeekKey(String key) {
  final monday = DateTime.parse(key);
  return dayKey(DateTime(monday.year, monday.month, monday.day - 7));
}

/// Cuánto pasó de la semana de [d], de 0 (lunes 00:00) a 1 (domingo 24:00).
double weekProgress(DateTime d) {
  final start = weekStart(d);
  final end = DateTime(start.year, start.month, start.day + 7);
  return d.difference(start).inMinutes / end.difference(start).inMinutes;
}

/// Días que faltan para que termine la semana (contando hoy).
int daysLeftInWeek(DateTime d) => 8 - d.weekday;

/// Hora de un aviso: "Hoy, 14:30", "Ayer, 09:05" o "12/10, 14:30".
String clockLabel(DateTime d, DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  final time = '${two(d.hour)}:${two(d.minute)}';
  final key = dayKey(d);
  if (key == dayKey(now)) return 'Hoy, $time';
  if (key == dayKey(DateTime(now.year, now.month, now.day - 1))) {
    return 'Ayer, $time';
  }
  return '${two(d.day)}/${two(d.month)}, $time';
}

/// "recién", "hace 5 min", "hace 2 h", "ayer", "hace 3 días".
String timeAgo(DateTime date, DateTime now) {
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'recién';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'ayer';
  return 'hace ${diff.inDays} días';
}

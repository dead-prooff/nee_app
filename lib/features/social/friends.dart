/// Amigo simulado (todavía no hay servidor ni amigos reales). Se usan en
/// los duelos y en la liga semanal.
class Friend {
  const Friend({
    required this.id,
    required this.name,
    required this.username,
    required this.emoji,
    required this.tagline,
    required this.skill,
  });

  final String id;
  final String name;
  final String username;
  final String emoji;
  final String tagline;

  /// Probabilidad de que responda bien (0 a 1). También lo hace más rápido.
  final double skill;
}

const friends = [
  Friend(
    id: 'lucia',
    name: 'Lucía',
    username: 'lu_asu',
    emoji: '🌸',
    tagline: 'Racha de 12 días',
    skill: 0.8,
  ),
  Friend(
    id: 'mati',
    name: 'Mati',
    username: 'mati10',
    emoji: '⚽',
    tagline: 'Aprendiendo para hablar con su abuela',
    skill: 0.6,
  ),
  Friend(
    id: 'rosa',
    name: 'Doña Rosa',
    username: 'dona_rosa',
    emoji: '🧉',
    tagline: 'Habla guaraní desde chiquita',
    skill: 0.95,
  ),
  Friend(
    id: 'nico',
    name: 'Nico',
    username: 'nico_cde',
    emoji: '🎸',
    tagline: 'Recién empieza',
    skill: 0.45,
  ),
  Friend(
    id: 'caro',
    name: 'Caro',
    username: 'caro_py',
    emoji: '📚',
    tagline: 'Liga Oro esta semana',
    skill: 0.7,
  ),
  Friend(
    id: 'fede',
    name: 'Fede',
    username: 'fede_luque',
    emoji: '🏄',
    tagline: 'Practica en el colectivo',
    skill: 0.55,
  ),
  Friend(
    id: 'sofi',
    name: 'Sofi',
    username: 'sofi_enc',
    emoji: '🎨',
    tagline: 'Fan del jopara',
    skill: 0.65,
  ),
  Friend(
    id: 'tomas',
    name: 'Tomás',
    username: 'tomas_py',
    emoji: '🐆',
    tagline: 'Racha de 30 días',
    skill: 0.85,
  ),
  Friend(
    id: 'vale',
    name: 'Vale',
    username: 'vale_mra',
    emoji: '🎧',
    tagline: 'Aprende con canciones',
    skill: 0.5,
  ),
  Friend(
    id: 'ramon',
    name: 'Don Ramón',
    username: 'don_ramon',
    emoji: '🌾',
    tagline: 'Profe de guaraní jubilado',
    skill: 0.9,
  ),
];

Friend friendById(String id) => friends.firstWhere((f) => f.id == id);

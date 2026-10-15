/// Modelos del contenido de `assets/data/lecciones.json`.
///
/// Las claves del JSON están en castellano porque las edita gente que no
/// programa; acá se traducen a nombres de código.
library;

class Unit {
  const Unit({
    required this.id,
    required this.title,
    required this.emoji,
    required this.lessons,
  });

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
    id: json['id'] as String,
    title: json['titulo'] as String,
    emoji: json['emoji'] as String? ?? '📘',
    lessons: [
      for (final l in json['lecciones'] as List)
        Lesson.fromJson(l as Map<String, dynamic>),
    ],
  );

  final String id;
  final String title;
  final String emoji;
  final List<Lesson> lessons;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.xp,
    required this.exercises,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
    id: json['id'] as String,
    title: json['titulo'] as String,
    xp: json['xp'] as int? ?? 10,
    exercises: [
      for (final e in json['ejercicios'] as List)
        Exercise.fromJson(e as Map<String, dynamic>),
    ],
  );

  final String id;
  final String title;

  /// XP base que da la lección al completarla.
  final int xp;
  final List<Exercise> exercises;
}

/// Hacia qué idioma se traduce en un ejercicio.
enum Direction {
  guaraniToSpanish,
  spanishToGuarani;

  static Direction parse(String? value) =>
      value == 'es-gn' ? spanishToGuarani : guaraniToSpanish;
}

sealed class Exercise {
  const Exercise({this.hint});

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final hint = json['pista'] as String?;
    return switch (json['tipo']) {
      'traduccion' => ChoiceExercise(
        direction: Direction.parse(json['direccion'] as String?),
        prompt: json['pregunta'] as String,
        options: List<String>.from(json['opciones'] as List),
        answer: json['respuesta'] as String,
        hint: hint,
      ),
      'armar' => BuildExercise(
        direction: Direction.parse(json['direccion'] as String?),
        prompt: json['pregunta'] as String,
        answer: json['respuesta'] as String,
        extras: List<String>.from(json['extras'] as List? ?? const []),
        hint: hint,
      ),
      'pares' => MatchExercise(
        pairs: [
          for (final p in json['pares'] as List)
            (guarani: p[0] as String, spanish: p[1] as String),
        ],
        hint: hint,
      ),
      'escuchar' => ListenExercise(
        audio: json['audio'] as String,
        options: List<String>.from(json['opciones'] as List),
        answer: json['respuesta'] as String,
        translation: json['traduccion'] as String?,
        hint: hint,
      ),
      final tipo => throw FormatException(
        'Tipo de ejercicio desconocido: $tipo',
      ),
    };
  }

  /// Ayuda opcional que se muestra debajo de la consigna.
  final String? hint;

  /// Texto que se muestra como "respuesta correcta" en el feedback.
  String get solution;
}

/// "Elegí la traducción correcta".
class ChoiceExercise extends Exercise {
  const ChoiceExercise({
    required this.direction,
    required this.prompt,
    required this.options,
    required this.answer,
    super.hint,
  });

  final Direction direction;
  final String prompt;
  final List<String> options;
  final String answer;

  @override
  String get solution => answer;
}

/// "Armá la frase" tocando palabras en orden.
class BuildExercise extends Exercise {
  const BuildExercise({
    required this.direction,
    required this.prompt,
    required this.answer,
    required this.extras,
    super.hint,
  });

  final Direction direction;
  final String prompt;
  final String answer;

  /// Palabras distractoras que no van en la respuesta.
  final List<String> extras;

  List<String> get answerWords => answer.split(' ');

  @override
  String get solution => answer;
}

typedef WordPair = ({String guarani, String spanish});

/// "Emparejá" cada palabra en guaraní con su traducción.
class MatchExercise extends Exercise {
  const MatchExercise({required this.pairs, super.hint});

  final List<WordPair> pairs;

  @override
  String get solution =>
      pairs.map((p) => '${p.guarani} = ${p.spanish}').join('\n');
}

/// "Escuchá y elegí" lo que se dijo.
class ListenExercise extends Exercise {
  const ListenExercise({
    required this.audio,
    required this.options,
    required this.answer,
    this.translation,
    super.hint,
  });

  /// Nombre del archivo dentro de `assets/audio/`.
  final String audio;
  final List<String> options;
  final String answer;
  final String? translation;

  @override
  String get solution =>
      translation == null ? answer : '$answer ($translation)';
}

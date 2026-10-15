import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../lessons/data/lesson_repository.dart';
import '../onboarding/user_provider.dart';
import '../profile/widgets/avatar_image.dart';
import '../progress/progress_provider.dart';
import 'data/duel_models.dart';
import 'data/duel_questions.dart';
import 'duel_provider.dart';
import 'duel_screen.dart';

/// Presentación del duelo ("Vos vs. Lucía") y reglas, mientras se preparan
/// las preguntas.
class DuelIntroScreen extends StatefulWidget {
  const DuelIntroScreen({super.key, required this.friend, this.pending});

  final Friend friend;

  /// Si se está respondiendo un desafío recibido.
  final PendingDuel? pending;

  @override
  State<DuelIntroScreen> createState() => _DuelIntroScreenState();
}

class _DuelIntroScreenState extends State<DuelIntroScreen> {
  late final Future<DuelSetup> _setup;

  @override
  void initState() {
    super.initState();
    _setup = _prepare();
  }

  Future<DuelSetup> _prepare() async {
    final progress = context.read<ProgressProvider>();
    final duels = context.read<DuelProvider>();
    final units = await context.read<LessonRepository>().loadUnits();

    return DuelSetup(
      friend: widget.friend,
      questions: DuelQuestionBuilder(units)
          .build(isCompleted: progress.isCompleted),
      rivalAnswers:
          widget.pending?.rivalAnswers ?? duels.simulateRival(widget.friend),
      pendingId: widget.pending?.id,
    );
  }

  void _start(DuelSetup setup) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DuelScreen(setup: setup)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final friend = widget.friend;
    final me = context.select<UserProvider, String?>((u) => u.name) ?? 'Vos';

    Widget player(Widget avatar, String name) => Expanded(
      child: Column(
        children: [
          avatar,
          const SizedBox(height: 8),
          Text(
            name,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cancelar',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Semantics(
                        header: true,
                        label: '$me contra ${friend.name}',
                        excludeSemantics: true,
                        child: Row(
                          children: [
                            player(const MyAvatar(size: 80), me),
                            Text(
                              'VS',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: scheme.secondary,
                              ),
                            ),
                            player(
                              AvatarImage(avatarId: friend.avatar, size: 80),
                              friend.name,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        widget.pending != null
                            ? '${friend.name} ya jugó su parte. '
                                  '¿Le podés ganar?'
                            : '${friend.name} va a responder las mismas '
                                  'preguntas que vos.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _Rule(
                        icon: Icons.quiz_outlined,
                        text:
                            '${DuelQuestionBuilder.questionCount} preguntas '
                            'rápidas',
                      ),
                      const _Rule(
                        icon: Icons.timer_outlined,
                        text: '10 segundos por pregunta',
                      ),
                      _Rule(
                        icon: Icons.bolt,
                        text:
                            'Ganás +${DuelOutcome.win.xp} XP, empatás '
                            '+${DuelOutcome.draw.xp} XP',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FutureBuilder<DuelSetup>(
                future: _setup,
                builder: (context, snapshot) {
                  final setup = snapshot.data;
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: setup == null ? null : () => _start(setup),
                      child: Text(
                        snapshot.hasError
                            ? 'No se pudieron cargar las preguntas'
                            : '¡Empezar!',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: theme.textTheme.titleSmall)),
        ],
      ),
    );
  }
}

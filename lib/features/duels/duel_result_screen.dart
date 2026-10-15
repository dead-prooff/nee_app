import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import 'data/duel_models.dart';
import 'duel_intro_screen.dart';

/// Resultado del duelo: ganó / perdió / empate, XP, detalle por pregunta y
/// botones para compartir y pedir revancha.
class DuelResultScreen extends StatelessWidget {
  const DuelResultScreen({
    super.key,
    required this.setup,
    required this.myAnswers,
    required this.outcome,
  });

  final DuelSetup setup;
  final List<String?> myAnswers;
  final DuelOutcome outcome;

  bool _iGotRight(int i) => myAnswers[i] == setup.questions[i].answer;

  int get myScore => [
    for (var i = 0; i < myAnswers.length; i++)
      if (_iGotRight(i)) 1,
  ].length;

  int get rivalScore => setup.rivalAnswers.where((a) => a.scored).length;

  String get shareText {
    final name = setup.friend.name;
    return switch (outcome) {
      DuelOutcome.win =>
        '¡Le gané $myScore a $rivalScore a $name en un duelo de guaraní '
            'en Ñe\'ẽ! ⚔️🧉 ¿Te animás a desafiarme?',
      DuelOutcome.draw =>
        'Empatamos $myScore a $rivalScore con $name en un duelo de guaraní '
            'en Ñe\'ẽ 🤝🧉',
      DuelOutcome.loss =>
        '$name me ganó $rivalScore a $myScore en un duelo de guaraní '
            'en Ñe\'ẽ. ¡Quiero la revancha! ⚔️🧉',
    };
  }

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: shareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FeedbackColors>()!;
    final friend = setup.friend;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ExcludeSemantics(
                    child: Text(
                      outcome.emoji,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 72),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    header: true,
                    child: Text(
                      outcome.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Vos $myScore, ${friend.name} $rivalScore',
                    excludeSemantics: true,
                    child: Text(
                      '$myScore – $rivalScore',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'contra ${friend.name} ${friend.emoji}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.gold, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, color: colors.gold),
                          const SizedBox(width: 4),
                          Text(
                            '+${outcome.xp} XP',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          _BreakdownRow.header(context, rival: friend.name),
                          for (var i = 0; i < setup.questions.length; i++)
                            _BreakdownRow(
                              prompt: setup.questions[i].prompt,
                              answer: setup.questions[i].answer,
                              mine: _iGotRight(i),
                              rival: setup.rivalAnswers[i].scored,
                              rivalName: friend.name,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (buttonContext) => OutlinedButton.icon(
                            onPressed: () => _share(buttonContext),
                            icon: const Icon(Icons.share),
                            label: const Text('Compartir'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context)
                              .pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DuelIntroScreen(friend: friend),
                                ),
                              ),
                          icon: const Icon(Icons.replay),
                          label: const Text('Revancha'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Volver a Duelos'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.prompt,
    required this.answer,
    required this.mine,
    required this.rival,
    required this.rivalName,
  });

  final String prompt;
  final String answer;
  final bool mine;
  final bool rival;
  final String rivalName;

  static Widget header(BuildContext context, {required String rival}) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 13,
    );
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(
          children: [
            Expanded(child: Text('Pregunta', style: style)),
            SizedBox(
              width: 56,
              child: Text('Vos', style: style, textAlign: TextAlign.center),
            ),
            SizedBox(
              width: 56,
              child: Text(
                rival,
                style: style,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FeedbackColors>()!;

    Widget mark(bool ok) => SizedBox(
      width: 56,
      child: Icon(
        ok ? Icons.check_circle : Icons.cancel,
        color: ok ? colors.success : colors.error,
      ),
    );

    return Semantics(
      label:
          '$prompt: $answer. Vos ${mine ? 'acertaste' : 'fallaste'}, '
          '$rivalName ${rival ? 'acertó' : 'falló'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prompt, style: theme.textTheme.titleSmall),
                  Text(
                    answer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            mark(mine),
            mark(rival),
          ],
        ),
      ),
    );
  }
}

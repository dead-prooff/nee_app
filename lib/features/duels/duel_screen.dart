import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../lessons/widgets/exercise_common.dart';
import '../onboarding/user_provider.dart';
import '../progress/progress_provider.dart';
import 'data/duel_models.dart';
import 'duel_provider.dart';
import 'duel_result_screen.dart';

/// Duelo en curso: 5 preguntas con 10 segundos cada una.
///
/// Las respuestas del rival vienen simuladas en [DuelSetup.rivalAnswers]
/// (cuándo responde y si acierta); se muestra "ya respondió" cuando llega
/// su momento y si acertó recién cuando respondés vos.
class DuelScreen extends StatefulWidget {
  const DuelScreen({super.key, required this.setup});

  final DuelSetup setup;

  static const questionTime = Duration(seconds: 10);

  /// Cuánto se muestra el resultado de cada pregunta antes de pasar a la
  /// siguiente.
  static const revealTime = Duration(milliseconds: 1800);

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  Timer? _nextTimer;

  int _index = 0;

  /// Lo que eligió el usuario en cada pregunta (null = se le pasó el tiempo).
  final List<String?> _myAnswers = [];

  /// Cuánto tardó el usuario en cada pregunta, en ms (10.000 si no respondió).
  final List<int> _myTimes = [];
  bool _revealed = false;
  bool _rivalAnswered = false;

  DuelSetup get _setup => widget.setup;
  int get _total => _setup.questions.length;
  DuelQuestion get _question => _setup.questions[_index];
  RivalAnswer get _rival => _setup.rivalAnswers[_index];

  int get _myScore => [
    for (final (i, a) in _myAnswers.indexed)
      if (a == _setup.questions[i].answer) 1,
  ].length;

  /// Puntos del rival en las preguntas ya reveladas.
  int get _rivalScore =>
      _setup.rivalAnswers.take(_myAnswers.length).where((a) => a.scored).length;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: DuelScreen.questionTime)
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_revealed) _answer(null);
      });
    _clock.forward();
  }

  @override
  void dispose() {
    _clock.dispose();
    _nextTimer?.cancel();
    super.dispose();
  }

  void _onTick() {
    final ms = _rival.ms;
    final elapsed = _clock.value * DuelScreen.questionTime.inMilliseconds;
    if (!_rivalAnswered && ms != null && elapsed >= ms) {
      setState(() => _rivalAnswered = true);
    }
  }

  void _answer(String? option) {
    if (_revealed) return;
    _clock.stop();
    final elapsed = (_clock.value * DuelScreen.questionTime.inMilliseconds)
        .round();
    if (option == _question.answer) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.mediumImpact();
    }
    setState(() {
      _myAnswers.add(option);
      _myTimes.add(
        option == null ? DuelScreen.questionTime.inMilliseconds : elapsed,
      );
      _revealed = true;
    });
    _nextTimer = Timer(DuelScreen.revealTime, _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (_index + 1 == _total) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _revealed = false;
      _rivalAnswered = false;
    });
    _clock.forward(from: 0);
  }

  void _finish() {
    final myMs = _myTimes.fold(0, (a, b) => a + b);
    final rivalMs = _setup.rivalAnswers.fold(0, (a, r) => a + r.timeMs);
    final outcome = DuelOutcome.compare(
      _myScore,
      _rivalScore,
      myMs: myMs,
      rivalMs: rivalMs,
    );
    context.read<DuelProvider>().recordResult(
      outcome,
      friend: _setup.friend,
      myScore: _myScore,
      rivalScore: _rivalScore,
      pendingId: _setup.pendingId,
    );
    context.read<ProgressProvider>().addXp(outcome.xp);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DuelResultScreen(
          setup: _setup,
          myAnswers: List.unmodifiable(_myAnswers),
          myMs: myMs,
          rivalMs: rivalMs,
          outcome: outcome,
        ),
      ),
    );
  }

  Future<void> _exit() async {
    _clock.stop();
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Abandonar el duelo?'),
        content: const Text('El resultado no se va a guardar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir jugando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (leave ?? false) {
      Navigator.of(context).pop();
    } else if (!_revealed) {
      _clock.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.select<UserProvider, String?>((u) => u.name) ?? 'Vos';
    final question = _question;
    final selected = _revealed ? _myAnswers.last : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Abandonar el duelo',
            icon: const Icon(Icons.close),
            onPressed: _exit,
          ),
          title: Text('Pregunta ${_index + 1} de $_total'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _Scoreboard(
              me: me,
              myScore: _myScore,
              friend: _setup.friend,
              rivalScore: _rivalScore,
              rivalStatus: _rivalStatus(),
            ),
            const SizedBox(height: 16),
            _TimerBar(clock: _clock, stopped: _revealed),
            const SizedBox(height: 20),
            ExerciseHeader(
              instruction: question.instruction,
              prompt: question.prompt,
            ),
            const SizedBox(height: 20),
            OptionList(
              options: question.options,
              answer: question.answer,
              selected: selected,
              locked: _revealed,
              onSelect: _answer,
            ),
            if (_revealed) _RevealMessage(option: selected, question: question),
          ],
        ),
      ),
    );
  }

  _RivalStatus _rivalStatus() {
    if (_revealed) {
      if (_rival.ms == null) return _RivalStatus.noAnswer;
      return _rival.correct ? _RivalStatus.correct : _RivalStatus.wrong;
    }
    return _rivalAnswered ? _RivalStatus.answered : _RivalStatus.thinking;
  }
}

enum _RivalStatus {
  thinking('Pensando…', Icons.more_horiz),
  answered('Ya respondió', Icons.check),
  correct('Acertó', Icons.check_circle),
  wrong('Se equivocó', Icons.cancel),
  noAnswer('No llegó a responder', Icons.timer_off);

  const _RivalStatus(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.me,
    required this.myScore,
    required this.friend,
    required this.rivalScore,
    required this.rivalStatus,
  });

  final String me;
  final int myScore;
  final Friend friend;
  final int rivalScore;
  final _RivalStatus rivalStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FeedbackColors>()!;
    final statusColor = switch (rivalStatus) {
      _RivalStatus.correct => colors.success,
      _RivalStatus.wrong || _RivalStatus.noAnswer => colors.error,
      _ => scheme.onSurfaceVariant,
    };

    Widget side({
      required String emoji,
      required String name,
      required int score,
      Widget? status,
    }) => Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 8),
              Text('$score', style: theme.textTheme.headlineMedium),
            ],
          ),
          Text(
            name,
            style: theme.textTheme.titleSmall,
            overflow: TextOverflow.ellipsis,
          ),
          ?status,
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Semantics(
          liveRegion: true,
          label:
              '$me $myScore, ${friend.name} $rivalScore. '
              '${friend.name}: ${rivalStatus.label}',
          excludeSemantics: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              side(emoji: '🙂', name: me, score: myScore),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'VS',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.secondary,
                  ),
                ),
              ),
              side(
                emoji: friend.emoji,
                name: friend.name,
                score: rivalScore,
                status: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(rivalStatus.icon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          rivalStatus.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra que se vacía en 10 segundos; se pone roja en los últimos 3.
class _TimerBar extends StatelessWidget {
  const _TimerBar({required this.clock, required this.stopped});

  final AnimationController clock;
  final bool stopped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FeedbackColors>()!;
    final total = DuelScreen.questionTime.inSeconds;

    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        final left = (total * (1 - clock.value)).ceil();
        final urgent = left <= 3 && !stopped;
        final color = urgent ? colors.error : scheme.primary;
        return Semantics(
          label: 'Quedan $left segundos',
          excludeSemantics: true,
          child: Row(
            children: [
              Icon(Icons.timer_outlined, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 1 - clock.value,
                    minHeight: 12,
                    color: color,
                    backgroundColor: scheme.outline,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                child: Text(
                  '$left s',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RevealMessage extends StatelessWidget {
  const _RevealMessage({required this.option, required this.question});

  final String? option;
  final DuelQuestion question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FeedbackColors>()!;
    final correct = option == question.answer;
    final text = option == null
        ? '¡Se acabó el tiempo!'
        : correct
        ? '¡Iporã! Correcto'
        : 'Incorrecto';

    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(
            correct ? Icons.check_circle : Icons.cancel,
            color: correct ? colors.success : colors.error,
          ),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

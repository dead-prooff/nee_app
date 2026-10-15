import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/lesson_models.dart';
import 'exercise_common.dart';

/// "Emparejá" cada palabra en guaraní con su traducción.
///
/// Se toca una palabra de cada columna; un par equivocado parpadea en rojo
/// y cuenta como error. El ejercicio está listo cuando se emparejaron todos,
/// y es correcto solo si no hubo errores.
class MatchExerciseView extends StatefulWidget {
  const MatchExerciseView({
    super.key,
    required this.exercise,
    required this.locked,
    required this.onChanged,
  });

  final MatchExercise exercise;
  final bool locked;
  final AnswerChanged onChanged;

  @override
  State<MatchExerciseView> createState() => _MatchExerciseViewState();
}

class _MatchExerciseViewState extends State<MatchExerciseView> {
  // Cada columna guarda índices de `exercise.pairs`, en distinto orden.
  late final List<int> _left = _shuffledIndexes();
  late final List<int> _right = _shuffledIndexes();

  int? _selectedLeft;
  int? _selectedRight;
  final Set<int> _matched = {};

  /// Par equivocado que se muestra en rojo por un momento.
  (int, int)? _wrong;
  Timer? _wrongTimer;
  int _mistakes = 0;

  List<int> _shuffledIndexes() =>
      List.generate(widget.exercise.pairs.length, (i) => i)..shuffle();

  @override
  void dispose() {
    _wrongTimer?.cancel();
    super.dispose();
  }

  void _tap({int? left, int? right}) {
    setState(() {
      _wrong = null;
      if (left != null) _selectedLeft = _selectedLeft == left ? null : left;
      if (right != null) {
        _selectedRight = _selectedRight == right ? null : right;
      }
    });

    final l = _selectedLeft;
    final r = _selectedRight;
    if (l == null || r == null) return;

    if (l == r) {
      setState(() {
        _matched.add(l);
        _selectedLeft = _selectedRight = null;
      });
      if (_matched.length == widget.exercise.pairs.length) {
        widget.onChanged(_mistakes == 0);
      }
    } else {
      HapticFeedback.lightImpact();
      setState(() {
        _mistakes++;
        _wrong = (l, r);
        _selectedLeft = _selectedRight = null;
      });
      _wrongTimer?.cancel();
      _wrongTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _wrong = null);
      });
    }
  }

  TileState _state(int pair, {required bool isLeft}) {
    if (_matched.contains(pair)) return TileState.matched;
    final wrong = _wrong;
    if (wrong != null && (isLeft ? wrong.$1 : wrong.$2) == pair) {
      return TileState.wrong;
    }
    final selected = isLeft ? _selectedLeft : _selectedRight;
    return selected == pair ? TileState.selected : TileState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final pairs = widget.exercise.pairs;

    Widget column(List<int> order, {required bool isLeft}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final i in order) ...[
          AnswerTile(
            label: isLeft ? pairs[i].guarani : pairs[i].spanish,
            state: _state(i, isLeft: isLeft),
            onTap: widget.locked || _matched.contains(i)
                ? null
                : () => isLeft ? _tap(left: i) : _tap(right: i),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExerciseHeader(
          instruction: 'Emparejá cada palabra con su traducción',
          hint: widget.exercise.hint,
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: column(_left, isLeft: true)),
            const SizedBox(width: 12),
            Expanded(child: column(_right, isLeft: false)),
          ],
        ),
      ],
    );
  }
}

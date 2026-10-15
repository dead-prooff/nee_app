import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile/avatars.dart';
import '../profile/widgets/avatar_picker.dart';
import '../progress/progress_provider.dart';
import 'choice_step.dart';
import 'intro_pages.dart';
import 'register_step.dart';
import 'user_provider.dart';

enum _Step { intro, register, level, goal, avatar }

/// Primera vez que se abre la app: bienvenida, registro, nivel, meta
/// diaria y avatar. Al terminar se guarda todo y la app pasa a la pantalla principal.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  _Step _step = _Step.intro;
  Registration? _registration;
  StartLevel? _level;
  DailyGoal? _goal;

  void _go(_Step step) => setState(() => _step = step);

  void _back() => _go(_Step.values[_step.index - 1]);

  AvatarSelection _avatar = const AvatarSelection(avatarId: defaultAvatarId);

  /// Termina el onboarding. [avatar] es null si se saltó ese paso.
  Future<void> _finish(AvatarSelection? avatar) async {
    final registration = _registration!;
    final progress = context.read<ProgressProvider>()..setDailyGoal(_goal!);
    final user = context.read<UserProvider>();
    // Con código de invitación: +50 XP de bienvenida (simulado).
    if (registration.inviteCode != null) {
      await progress.addBonusXp(UserProvider.inviteBonusXp);
    }
    await user.completeOnboarding(
      name: registration.name,
      username: registration.username,
      email: registration.email,
      authMethod: registration.method,
      level: _level!,
      avatarId: avatar?.avatarId,
      photo: avatar?.photo,
      inviteCode: registration.inviteCode,
    );
  }

  Widget _content() => switch (_step) {
    _Step.intro => IntroPages(onDone: () => _go(_Step.register)),
    _Step.register => RegisterStep(
      // Solo se recuperan los datos de un registro con correo.
      initial: _registration?.method == AuthMethod.email ? _registration : null,
      onRegistered: (r) {
        _registration = r;
        _go(_Step.level);
      },
    ),
    _Step.level => ChoiceStep<StartLevel>(
      title: '¿Cuánto guaraní sabés?',
      subtitle: 'Así arrancamos donde te queda cómodo.',
      initial: _level,
      buttonLabel: 'Continuar',
      options: [
        for (final level in StartLevel.values)
          ChoiceOption(
            value: level,
            emoji: level.emoji,
            title: level.label,
            subtitle: level.description,
          ),
      ],
      onConfirm: (level) {
        _level = level;
        _go(_Step.goal);
      },
    ),
    _Step.goal => ChoiceStep<DailyGoal>(
      title: 'Elegí tu meta diaria',
      subtitle: 'Podés cambiarla cuando quieras desde Configuración.',
      initial: _goal ?? DailyGoal.regular,
      buttonLabel: 'Continuar',
      options: [
        for (final goal in DailyGoal.values)
          ChoiceOption(
            value: goal,
            emoji: switch (goal) {
              DailyGoal.relaxed => '☕',
              DailyGoal.regular => '🧉',
              DailyGoal.intense => '🔥',
            },
            title: '${goal.minutes} min por día',
            subtitle: goal.label,
            badge: '${goal.xp} XP',
          ),
      ],
      onConfirm: (goal) {
        _goal = goal;
        _go(_Step.avatar);
      },
    ),
    _Step.avatar => _AvatarStep(
      initial: _avatar,
      onChanged: (a) => _avatar = a,
      onDone: () => _finish(_avatar),
      onSkip: () => _finish(null),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final showBar = _step != _Step.intro;
    // Pasos con barra: registro, nivel, meta y avatar (1 a 4).
    final stepNumber = _step.index;
    const steps = 4;

    return PopScope(
      canPop: _step == _Step.intro,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: showBar
            ? AppBar(
                leading: IconButton(
                  tooltip: 'Volver',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _back,
                ),
                titleSpacing: 0,
                title: Semantics(
                  label: 'Paso $stepNumber de $steps',
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: stepNumber / steps),
                        duration: const Duration(milliseconds: 300),
                        builder: (_, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 10,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .outline,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(key: ValueKey(_step), child: _content()),
        ),
      ),
    );
  }
}

/// Último paso: elegir avatar (se puede saltar).
class _AvatarStep extends StatelessWidget {
  const _AvatarStep({
    required this.initial,
    required this.onChanged,
    required this.onDone,
    required this.onSkip,
  });

  final AvatarSelection initial;
  final ValueChanged<AvatarSelection> onChanged;
  final VoidCallback onDone;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Elegí tu avatar',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Un mito guaraní, un amigo del campo o tu propia foto.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              AvatarPicker(initial: initial, onChanged: onChanged),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: onDone,
                  child: const Text('Empezar a aprender'),
                ),
                TextButton(
                  onPressed: onSkip,
                  child: const Text('Saltar por ahora'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

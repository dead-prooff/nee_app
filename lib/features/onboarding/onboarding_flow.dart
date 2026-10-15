import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../profile/avatars.dart';
import '../profile/widgets/avatar_picker.dart';
import '../progress/progress_provider.dart';
import 'account_steps.dart';
import 'choice_step.dart';
import 'intro_pages.dart';
import 'user_provider.dart';
import 'validators.dart';

/// Pasos del registro (con barra de progreso) y el de iniciar sesión.
enum _Step {
  intro,
  email,
  password,
  name,
  username,
  invite,
  level,
  goal,
  avatar,
  login,
}

/// Pasos que muestran la barra de progreso arriba, en orden.
const _progressSteps = [
  _Step.email,
  _Step.password,
  _Step.name,
  _Step.username,
  _Step.invite,
  _Step.level,
  _Step.goal,
  _Step.avatar,
];

/// Primera vez que se abre la app: bienvenida y, al estilo Spotify, un
/// registro con un dato por pantalla (correo, contraseña, nombre, usuario y
/// código de invitación), después nivel, meta diaria y avatar. También se
/// puede "Iniciar sesión" (simulado). Al terminar se guarda todo y la app
/// pasa a la pantalla principal.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  _Step _step = _Step.intro;

  /// Si se vuelve a la bienvenida desde el registro (arranca en la última
  /// página, la de los botones).
  bool _introAtEnd = false;

  // Los datos quedan acá, así no se pierden al volver atrás. La contraseña
  // se valida pero nunca se guarda.
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _invite = TextEditingController();
  AuthMethod _method = AuthMethod.email;
  StartLevel? _level;
  DailyGoal? _goal;
  AvatarSelection _avatar = const AvatarSelection(avatarId: defaultAvatarId);

  @override
  void dispose() {
    for (final c in [_email, _password, _name, _username, _invite]) {
      c.dispose();
    }
    super.dispose();
  }

  void _go(_Step step) => setState(() => _step = step);

  void _back() {
    if (_step == _Step.email || _step == _Step.login) _introAtEnd = true;
    _go(switch (_step) {
      _Step.intro || _Step.email || _Step.login => _Step.intro,
      _Step.password => _Step.email,
      // Con Google o Apple no hubo contraseña.
      _Step.name => _method == AuthMethod.email ? _Step.password : _Step.email,
      _Step.username => _Step.name,
      _Step.invite => _Step.username,
      _Step.level => _Step.invite,
      _Step.goal => _Step.level,
      _Step.avatar => _Step.goal,
    });
  }

  String? get _inviteCode {
    final code = _invite.text.trim().toUpperCase();
    return code.isNotEmpty && Validators.inviteCode(code) == null ? code : null;
  }

  /// Termina el registro. [avatar] es null si se saltó ese paso.
  Future<void> _finish(AvatarSelection? avatar) async {
    final progress = context.read<ProgressProvider>()..setDailyGoal(_goal!);
    final user = context.read<UserProvider>();
    final invite = _inviteCode;
    // Con código de invitación: +50 XP de bienvenida (simulado).
    if (invite != null) {
      await progress.addBonusXp(UserProvider.inviteBonusXp);
    }
    await user.completeOnboarding(
      name: _name.text.trim(),
      username: _username.text.trim(),
      email: _method == AuthMethod.email ? _email.text.trim() : null,
      authMethod: _method,
      level: _level!,
      avatarId: avatar?.avatarId,
      photo: avatar?.photo,
      inviteCode: invite,
    );
  }

  /// Iniciar sesión (simulado): todavía no hay servidor con cuentas, así
  /// que se entra con un usuario armado a partir del correo.
  Future<void> _logIn(String? email, AuthMethod method) async {
    final local = email?.split('@').first ?? '';
    final cleaned = local.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
    final fallback = switch (method) {
      AuthMethod.google => 'google_$suffix',
      AuthMethod.apple => 'apple_$suffix',
      AuthMethod.email => 'amigo_$suffix',
    };
    await context.read<UserProvider>().completeOnboarding(
      name: local.isEmpty
          ? 'Invitado'
          : '${local[0].toUpperCase()}${local.substring(1)}',
      username: cleaned.length >= 3 ? cleaned : fallback,
      email: email,
      authMethod: method,
      level: StartLevel.some,
    );
  }

  /// Google / Apple en el registro: se saltan el correo y la contraseña.
  void _socialRegister(AuthMethod method) {
    _method = method;
    _go(_Step.name);
  }

  Widget _content() => switch (_step) {
    _Step.intro => IntroPages(
      startAtEnd: _introAtEnd,
      onCreateAccount: () => _go(_Step.email),
      onLogin: () => _go(_Step.login),
    ),
    _Step.email => FieldStep(
      title: '¿Cuál es tu correo?',
      subtitle: 'Lo vas a usar para entrar a tu cuenta.',
      label: 'Correo',
      icon: Icons.mail_outline,
      controller: _email,
      validator: Validators.email,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      onContinue: () {
        _method = AuthMethod.email;
        _go(_Step.password);
      },
      below: [
        SocialButtons(
          dividerText: 'O registrate con',
          onSignedIn: _socialRegister,
        ),
        SwitchAccountLink(
          question: '¿Ya tenés cuenta?',
          action: 'Iniciá sesión',
          onPressed: () => _go(_Step.login),
        ),
      ],
    ),
    _Step.password => FieldStep(
      title: 'Creá una contraseña',
      label: 'Contraseña',
      icon: Icons.lock_outline,
      controller: _password,
      validator: Validators.password,
      isPassword: true,
      autofillHints: const [AutofillHints.newPassword],
      helper: (_) =>
          'Mínimo ${Validators.passwordMinLength} caracteres, con letras y '
          'números.',
      onContinue: () => _go(_Step.name),
    ),
    _Step.name => FieldStep(
      title: '¿Cómo te llamás?',
      subtitle: 'Así te vamos a saludar.',
      label: 'Nombre',
      icon: Icons.person_outline,
      controller: _name,
      validator: Validators.name,
      textCapitalization: TextCapitalization.words,
      autofillHints: const [AutofillHints.name],
      onContinue: () => _go(_Step.username),
    ),
    _Step.username => FieldStep(
      title: 'Elegí tu usuario',
      label: 'Usuario',
      icon: Icons.alternate_email,
      controller: _username,
      validator: Validators.username,
      autofillHints: const [AutofillHints.newUsername],
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
        LowerCaseFormatter(),
      ],
      helper: (_) => 'Así te van a encontrar tus amigos.',
      onContinue: () => _go(_Step.invite),
    ),
    _Step.invite => FieldStep(
      title: '¿Te invitó alguien?',
      label: 'Código de invitación (opcional)',
      icon: Icons.card_giftcard,
      controller: _invite,
      validator: Validators.inviteCode,
      optional: true,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
        UpperCaseFormatter(),
      ],
      helper: (_) => _inviteCode != null
          ? '¡Código válido! Vas a ganar +${UserProvider.inviteBonusXp} XP 🎁'
          : 'Si un amigo te pasó su código, los dos ganan '
                '+${UserProvider.inviteBonusXp} XP.',
      onContinue: () => _go(_Step.level),
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
    _Step.login => LoginStep(
      onLoggedIn: _logIn,
      onRegister: () => _go(_Step.email),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final progressIndex = _progressSteps.indexOf(_step);
    final steps = _progressSteps.length;

    return PopScope(
      canPop: _step == _Step.intro,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: _step == _Step.intro
            ? null
            : AppBar(
                leading: IconButton(
                  tooltip: 'Volver',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _back,
                ),
                titleSpacing: 0,
                // En el registro, la barra de progreso; en "Iniciar sesión",
                // nada.
                title: progressIndex < 0
                    ? null
                    : Semantics(
                        label: 'Paso ${progressIndex + 1} de $steps',
                        excludeSemantics: true,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(end: (progressIndex + 1) / steps),
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
              ),
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

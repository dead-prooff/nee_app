import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'user_provider.dart';
import 'validators.dart';

/// Demora de los inicios de sesión simulados con Google y Apple.
const socialSignInDelay = Duration(milliseconds: 900);

/// Pantalla de un solo dato (estilo Spotify): título, un campo con
/// validación en tiempo real y "Continuar", que se habilita cuando el dato
/// es válido.
class FieldStep extends StatefulWidget {
  const FieldStep({
    super.key,
    required this.title,
    required this.label,
    required this.controller,
    required this.validator,
    required this.onContinue,
    this.subtitle,
    this.helper,
    this.icon,
    this.keyboardType,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.isPassword = false,
    this.optional = false,
    this.below = const [],
  });

  final String title;
  final String? subtitle;
  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final VoidCallback onContinue;

  /// Texto de ayuda debajo del campo (puede cambiar según lo escrito).
  final String Function(String value)? helper;
  final IconData? icon;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool isPassword;

  /// Si se puede dejar vacío (el botón dice "Saltar" mientras está vacío).
  final bool optional;

  /// Lo que va debajo del botón (otras formas de registrarse, links).
  final List<Widget> below;

  @override
  State<FieldStep> createState() => _FieldStepState();
}

class _FieldStepState extends State<FieldStep> {
  bool _obscure = true;

  void _submit() {
    if (widget.validator(widget.controller.text) == null) widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Semantics(
          header: true,
          child: Text(widget.title, style: theme.textTheme.headlineSmall),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 24),
        ValueListenableBuilder(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            final text = value.text;
            final valid = widget.validator(text) == null;
            final empty = text.trim().isEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: widget.controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: widget.label,
                    prefixIcon: widget.icon == null ? null : Icon(widget.icon),
                    helperText: widget.helper?.call(text),
                    helperMaxLines: 3,
                    suffixIcon: widget.isPassword
                        ? IconButton(
                            tooltip: _obscure
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          )
                        : null,
                  ),
                  obscureText: widget.isPassword && _obscure,
                  enableSuggestions: !widget.isPassword,
                  autocorrect: false,
                  keyboardType: widget.keyboardType,
                  textCapitalization: widget.textCapitalization,
                  autofillHints: widget.autofillHints,
                  inputFormatters: widget.inputFormatters,
                  textInputAction: TextInputAction.done,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: widget.validator,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: valid ? widget.onContinue : null,
                  child: Text(
                    widget.optional && empty ? 'Saltar' : 'Continuar',
                  ),
                ),
              ],
            );
          },
        ),
        ...widget.below,
      ],
    );
  }
}

/// "Continuar con Google" y "Continuar con Apple" (simulados: después de
/// una pequeña espera siguen como si la cuenta se hubiera conectado).
class SocialButtons extends StatefulWidget {
  const SocialButtons({
    super.key,
    required this.dividerText,
    required this.onSignedIn,
  });

  /// "O registrate con" / "O iniciá sesión con".
  final String dividerText;
  final ValueChanged<AuthMethod> onSignedIn;

  @override
  State<SocialButtons> createState() => _SocialButtonsState();
}

class _SocialButtonsState extends State<SocialButtons> {
  AuthMethod? _loading;

  Future<void> _signIn(AuthMethod method) async {
    setState(() => _loading = method);
    await Future<void>.delayed(socialSignInDelay);
    if (!mounted) return;
    setState(() => _loading = null);
    widget.onSignedIn(method);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget button(AuthMethod method, String label, Widget mark) {
      final loading = _loading == method;
      return OutlinedButton.icon(
        onPressed: _loading == null ? () => _signIn(method) : null,
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : mark,
        label: Text(loading ? 'Conectando…' : label),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(child: Divider()),
            Flexible(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  widget.dividerText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        button(
          AuthMethod.google,
          'Continuar con Google',
          const _LetterMark('G'),
        ),
        const SizedBox(height: 12),
        button(
          AuthMethod.apple,
          'Continuar con Apple',
          const Icon(Icons.apple, size: 24),
        ),
      ],
    );
  }
}

/// Letra en un círculo (sin usar el logo de la marca).
class _LetterMark extends StatelessWidget {
  const _LetterMark(this.letter);

  final String letter;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
          color: color,
        ),
      ),
    );
  }
}

/// Link de texto centrado ("¿Ya tenés cuenta? Iniciá sesión").
class SwitchAccountLink extends StatelessWidget {
  const SwitchAccountLink({
    super.key,
    required this.question,
    required this.action,
    required this.onPressed,
  });

  final String question;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            question,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(onPressed: onPressed, child: Text(action)),
        ],
      ),
    );
  }
}

/// "Iniciar sesión" (simulado: todavía no hay servidor con cuentas).
class LoginStep extends StatefulWidget {
  const LoginStep({
    super.key,
    required this.onLoggedIn,
    required this.onRegister,
  });

  /// Con el correo (o null si entró con Google / Apple) y cómo entró.
  final void Function(String? email, AuthMethod method) onLoggedIn;
  final VoidCallback onRegister;

  @override
  State<LoginStep> createState() => _LoginStepState();
}

class _LoginStepState extends State<LoginStep> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    widget.onLoggedIn(_email.text.trim(), AuthMethod.email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Semantics(
              header: true,
              child: Text(
                'Iniciar sesión',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Qué bueno verte de nuevo 🧉',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscure
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) =>
                  (v ?? '').isEmpty ? 'Escribí tu contraseña' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text('Iniciar sesión'),
            ),
            SocialButtons(
              dividerText: 'O iniciá sesión con',
              onSignedIn: (method) => widget.onLoggedIn(null, method),
            ),
            SwitchAccountLink(
              question: '¿No tenés cuenta?',
              action: 'Registrate',
              onPressed: widget.onRegister,
            ),
            const SizedBox(height: 8),
            Text(
              'Por ahora es una simulación: todavía no hay servidor, así que '
              'tu progreso empieza de cero en este dispositivo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pasa el texto a minúsculas (usuario).
class LowerCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toLowerCase());
}

/// Pasa el texto a mayúsculas (código de invitación).
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

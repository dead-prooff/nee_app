import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'user_provider.dart';
import 'validators.dart';

/// Datos que junta el paso de registro.
class Registration {
  const Registration({
    required this.name,
    required this.username,
    required this.email,
    required this.method,
  });

  final String name;
  final String username;
  final String? email;
  final AuthMethod method;
}

/// Formulario de registro con validación en tiempo real (los errores
/// aparecen apenas se toca cada campo) y "Continuar con Google" simulado.
class RegisterStep extends StatefulWidget {
  const RegisterStep({super.key, required this.onRegistered, this.initial});

  final ValueChanged<Registration> onRegistered;

  /// Datos ya cargados, si se vuelve atrás a este paso (la contraseña
  /// nunca se guarda, así que hay que escribirla de nuevo).
  final Registration? initial;

  /// Demora del inicio de sesión simulado con Google.
  static const googleDelay = Duration(milliseconds: 900);

  @override
  State<RegisterStep> createState() => _RegisterStepState();
}

class _RegisterStepState extends State<RegisterStep> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _username = TextEditingController(text: widget.initial?.username);
  late final _email = TextEditingController(text: widget.initial?.email);
  final _password = TextEditingController();

  bool _obscurePassword = true;
  bool _googleLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    widget.onRegistered(
      Registration(
        name: _name.text.trim(),
        username: _username.text.trim(),
        email: _email.text.trim(),
        method: AuthMethod.email,
      ),
    );
  }

  /// Simulación: todavía no hay inicio de sesión real con Google, así que
  /// se crea una cuenta de invitado después de una pequeña espera.
  Future<void> _continueWithGoogle() async {
    setState(() => _googleLoading = true);
    await Future<void>.delayed(RegisterStep.googleDelay);
    if (!mounted) return;
    setState(() => _googleLoading = false);
    widget.onRegistered(
      Registration(
        name: 'Invitado',
        username: 'invitado_${Random().nextInt(9000) + 1000}',
        email: null,
        method: AuthMethod.google,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const gap = SizedBox(height: 16);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Creá tu cuenta',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Así guardamos tu progreso y podés desafiar a tus amigos.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: Validators.name,
              ),
              gap,
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.alternate_email),
                  helperText: 'Así te van a encontrar tus amigos',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  _LowerCaseFormatter(),
                ],
                autocorrect: false,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newUsername],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: Validators.username,
              ),
              gap,
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
              gap,
              TextFormField(
                controller: _password,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  helperText:
                      'Mínimo ${Validators.passwordMinLength} caracteres, '
                      'con letras y números',
                  helperMaxLines: 2,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                enableSuggestions: false,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: Validators.password,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _googleLoading ? null : _submit,
                child: const Text('Crear cuenta'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'o',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _googleLoading ? null : _continueWithGoogle,
                icon: _googleLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const _GoogleMark(),
                label: Text(
                  _googleLoading ? 'Conectando…' : 'Continuar con Google',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "G" genérica para el botón de Google (sin usar el logo de la marca).
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.onSurface, width: 2),
      ),
      child: Text(
        'G',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

class _LowerCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toLowerCase());
}

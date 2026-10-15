import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Panel inferior que aparece al comprobar: verde si acertó, rojo si no,
/// con ícono, texto y (si hace falta) la respuesta correcta.
class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    super.key,
    required this.correct,
    required this.onContinue,
    this.detailLabel,
    this.detail,
  });

  final bool correct;
  final VoidCallback onContinue;

  /// Por ejemplo "Respuesta correcta:" o "Significa:".
  final String? detailLabel;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FeedbackColors>()!;
    final fg = correct ? colors.onSuccessContainer : colors.onErrorContainer;
    final accent = correct ? colors.success : colors.error;
    final title = correct ? '¡Iporã! Correcto' : 'Incorrecto';

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        color: correct ? colors.successContainer : colors.errorContainer,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    correct ? Icons.check_circle : Icons.cancel,
                    color: accent,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(color: fg),
                    ),
                  ),
                ],
              ),
              if (detail != null) ...[
                const SizedBox(height: 12),
                if (detailLabel != null)
                  Text(
                    detailLabel!,
                    style: theme.textTheme.titleSmall?.copyWith(color: fg),
                  ),
                const SizedBox(height: 4),
                Text(
                  detail!,
                  style: theme.textTheme.bodyLarge?.copyWith(color: fg),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onContinue,
                autofocus: true,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor:
                      correct ? theme.colorScheme.onPrimary : theme.colorScheme.onError,
                ),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

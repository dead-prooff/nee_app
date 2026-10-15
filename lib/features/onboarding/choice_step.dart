import 'package:flutter/material.dart';

/// Una opción de [ChoiceStep].
class ChoiceOption<T> {
  const ChoiceOption({
    required this.value,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.badge,
  });

  final T value;
  final String emoji;
  final String title;
  final String subtitle;

  /// Texto chico a la derecha (por ejemplo "20 XP").
  final String? badge;
}

/// Paso de onboarding donde se elige una opción entre varias tarjetas
/// (nivel y meta diaria).
class ChoiceStep<T> extends StatefulWidget {
  const ChoiceStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.buttonLabel,
    required this.onConfirm,
    this.initial,
  });

  final String title;
  final String subtitle;
  final List<ChoiceOption<T>> options;
  final String buttonLabel;
  final ValueChanged<T> onConfirm;
  final T? initial;

  @override
  State<ChoiceStep<T>> createState() => _ChoiceStepState<T>();
}

class _ChoiceStepState<T> extends State<ChoiceStep<T>> {
  late T? _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              Semantics(
                header: true,
                child: Text(widget.title, style: theme.textTheme.headlineSmall),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              for (final option in widget.options) ...[
                _OptionCard(
                  option: option,
                  selected: option.value == selected,
                  onTap: () => setState(() => _selected = option.value),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton(
              onPressed: selected == null
                  ? null
                  : () => widget.onConfirm(selected),
              child: Text(widget.buttonLabel),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionCard<T> extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ChoiceOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final muted = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    const radius = BorderRadius.all(Radius.circular(16));

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: [
        option.title,
        option.subtitle,
        if (option.badge != null) option.badge!,
      ].join('. '),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? 2.5 : 2,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(option.emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: fg,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (option.badge != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      option.badge!,
                      style: theme.textTheme.titleSmall?.copyWith(color: fg),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

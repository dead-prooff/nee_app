import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_links.dart';
import '../../core/theme/app_theme.dart';
import '../onboarding/user_provider.dart';

/// "Invitar amigos": código propio, copiar y compartir.
class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key});

  static String shareText(String code) =>
      "Mba'éichapa, che ra'a! 🧉 Estoy aprendiendo guaraní y jopara con "
      "Ñe'ẽ y está de diez. Sumate con mi código $code y los dos ganamos "
      '+${UserProvider.inviteBonusXp} XP. Jaha! 👉 $appUrl';

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    context.read<UserProvider>().markInvitedFriend();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Código copiado 📋')));
  }

  Future<void> _share(BuildContext context, String code) async {
    final box = context.findRenderObject() as RenderBox?;
    context.read<UserProvider>().markInvitedFriend();
    await SharePlus.instance.share(
      ShareParams(
        text: shareText(code),
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
    final code = context.select<UserProvider, String>((u) => u.inviteCode);

    return Scaffold(
      appBar: AppBar(title: const Text('Invitar amigos')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ExcludeSemantics(
            child: Text(
              '🤝',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 72),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              'Aprender con amigos es más lindo',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: scheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: colors.gold, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cuando tu amigo se registra con tu código, los dos '
                      'ganan +${UserProvider.inviteBonusXp} XP.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tu código',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.primary, width: 2),
            ),
            child: SelectableText(
              code,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                letterSpacing: 2,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _copy(context, code),
            icon: const Icon(Icons.copy),
            label: const Text('Copiar código'),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (buttonContext) => FilledButton.icon(
              onPressed: () => _share(buttonContext, code),
              icon: const Icon(Icons.share),
              label: const Text('Compartir invitación'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tu amigo escribe el código al registrarse, en "¿Tenés un código '
            'de invitación?". Por ahora el premio es simulado: todavía no hay '
            'servidor que avise cuando alguien lo usa.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

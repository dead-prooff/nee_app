import 'package:flutter/material.dart';

class _IntroPage {
  const _IntroPage(this.emoji, this.title, this.body);

  final String emoji;
  final String title;
  final String body;
}

const _pages = [
  _IntroPage(
    '🧉',
    'Mba\'éichapa! Esto es Ñe\'ẽ',
    'Aprendé guaraní y jopara con frases de la vida real: las que se usan '
        'en la casa, en la calle y en la ronda de tereré.',
  ),
  _IntroPage(
    '🌿',
    'Cómo funciona',
    'Lecciones cortas de 5 minutos. Ganás XP, cumplís tu meta diaria y '
        'mantenés tu racha 🔥 practicando todos los días.',
  ),
  _IntroPage(
    '⚔️',
    'Duelos con amigos',
    'Desafiá a tus amigos a preguntas rápidas y competí en la liga '
        'semanal. ¡Aprender en grupo es más divertido!',
  ),
];

/// Las 3 pantallas de bienvenida, deslizables.
class IntroPages extends StatefulWidget {
  const IntroPages({
    super.key,
    required this.onCreateAccount,
    required this.onLogin,
    this.startAtEnd = false,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  /// Al volver desde el registro, arranca en la última página (la de los
  /// botones) en vez de repetir la bienvenida.
  final bool startAtEnd;

  @override
  State<IntroPages> createState() => _IntroPagesState();
}

class _IntroPagesState extends State<IntroPages> {
  late final _controller = PageController(
    initialPage: widget.startAtEnd ? _pages.length - 1 : 0,
  );
  late int _page = widget.startAtEnd ? _pages.length - 1 : 0;

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() => _controller.nextPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  /// "Saltar" lleva a la última página, donde se elige crear cuenta o
  /// iniciar sesión.
  void _skip() => _controller.animateToPage(
    _pages.length - 1,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Visibility(
                visible: !_isLast,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: TextButton(
                  onPressed: _skip,
                  child: const Text('Saltar'),
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final page = _pages[i];
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        ExcludeSemantics(
                          child: Text(
                            page.emoji,
                            style: const TextStyle(fontSize: 96),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Semantics(
                          header: true,
                          child: Text(
                            page.title,
                            style: theme.textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.body,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Semantics(
            label: 'Página ${_page + 1} de ${_pages.length}',
            excludeSemantics: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 24 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: i == _page ? scheme.primary : scheme.outline,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _isLast
                  ? [
                      FilledButton(
                        onPressed: widget.onCreateAccount,
                        child: const Text('Crear cuenta'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: widget.onLogin,
                        child: const Text('Ya tengo cuenta'),
                      ),
                    ]
                  : [
                      FilledButton(
                        onPressed: _next,
                        child: const Text('Siguiente'),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'forum_models.dart';
import 'forum_provider.dart';
import 'topic_screen.dart';
import 'widgets/forum_widgets.dart';

/// Formulario "Nuevo tema": título, categoría y texto, con validación.
class NewTopicScreen extends StatefulWidget {
  const NewTopicScreen({super.key});

  static const titleMin = 8;
  static const titleMax = 90;
  static const bodyMin = 20;
  static const bodyMax = 1000;

  static String? validateTitle(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Escribí un título';
    if (t.length < titleMin) return 'Mínimo $titleMin caracteres';
    return null;
  }

  static String? validateBody(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Contá un poco más';
    if (t.length < bodyMin) return 'Mínimo $bodyMin caracteres';
    return null;
  }

  @override
  State<NewTopicScreen> createState() => _NewTopicScreenState();
}

class _NewTopicScreenState extends State<NewTopicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  ForumCategory? _category;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await ensureRulesAccepted(context) || !mounted) return;
    final topic = await context.read<ForumProvider>().createTopic(
      title: _title.text,
      category: _category!,
      body: _body.text,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => TopicScreen(topicId: topic.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo tema')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            TextFormField(
              controller: _title,
              maxLength: NewTopicScreen.titleMax,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título',
                helperText: 'Por ejemplo: "¿Cómo se dice abuelo?"',
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: NewTopicScreen.validateTitle,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ForumCategory>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                for (final c in ForumCategory.values)
                  DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Icon(c.icon, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(c.label, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (c) => setState(() => _category = c),
              validator: (c) => c == null ? 'Elegí una categoría' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _body,
              minLines: 5,
              maxLines: 10,
              maxLength: NewTopicScreen.bodyMax,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Texto',
                alignLabelWithHint: true,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: NewTopicScreen.validateBody,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _publish,
              icon: const Icon(Icons.send),
              label: const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}

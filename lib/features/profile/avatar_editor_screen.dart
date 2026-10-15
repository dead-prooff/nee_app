import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../onboarding/user_provider.dart';
import 'widgets/avatar_picker.dart';

/// Cambiar el avatar desde el Perfil.
class AvatarEditorScreen extends StatefulWidget {
  const AvatarEditorScreen({super.key});

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> {
  late AvatarSelection _selection;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    _selection = AvatarSelection(avatarId: user.avatarId, photo: user.photo);
  }

  Future<void> _save() async {
    final user = context.read<UserProvider>();
    final photo = _selection.photo;
    if (photo != null) {
      await user.setPhoto(photo);
    } else {
      await user.setAvatar(_selection.avatarId);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu avatar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AvatarPicker(
            initial: _selection,
            onChanged: (s) => setState(() => _selection = s),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(onPressed: _save, child: const Text('Guardar')),
        ),
      ),
    );
  }
}

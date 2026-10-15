import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../avatars.dart';
import 'avatar_image.dart';

/// Lo que eligió el usuario: un personaje o una foto propia.
class AvatarSelection {
  const AvatarSelection({required this.avatarId, this.photo});

  final String avatarId;
  final Uint8List? photo;
}

/// Elige una foto (galería o cámara), achicada a 512 px para guardarla en
/// el dispositivo. Devuelve null si se canceló.
Future<Uint8List?> pickAvatarPhoto(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 80,
    preferredCameraDevice: CameraDevice.front,
  );
  return file?.readAsBytes();
}

/// Selector de avatar estilo Netflix: vista previa con la mini ficha del
/// elegido, botones para usar una foto propia y la grilla de personajes.
class AvatarPicker extends StatefulWidget {
  const AvatarPicker({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final AvatarSelection initial;
  final ValueChanged<AvatarSelection> onChanged;

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  late String _avatarId = widget.initial.avatarId;
  late Uint8List? _photo = widget.initial.photo;
  bool _loading = false;

  void _selectAvatar(String id) {
    setState(() {
      _avatarId = id;
      _photo = null;
    });
    widget.onChanged(AvatarSelection(avatarId: id));
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _loading = true);
    try {
      final bytes = await pickAvatarPhoto(source);
      if (bytes == null || !mounted) return;
      setState(() => _photo = bytes);
      widget.onChanged(AvatarSelection(avatarId: _avatarId, photo: bytes));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la foto. Probá de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final info = avatarById(_avatarId);
    final usingPhoto = _photo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Vista previa + mini ficha.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AvatarImage(avatarId: _avatarId, photo: _photo, size: 88),
                const SizedBox(width: 16),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usingPhoto ? 'Tu foto' : info.name,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          usingPhoto
                              ? 'Se guarda solo en este dispositivo.'
                              : info.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Cámara'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            'O elegí un personaje',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 112,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.78,
          ),
          itemCount: avatars.length,
          itemBuilder: (context, i) {
            final a = avatars[i];
            final selected = !usingPhoto && a.id == _avatarId;
            return _AvatarTile(
              info: a,
              selected: selected,
              onTap: () => _selectAvatar(a.id),
            );
          },
        ),
      ],
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.info,
    required this.selected,
    required this.onTap,
  });

  final AvatarInfo info;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: info.name,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Stack(
                children: [
                  AvatarImage(avatarId: info.id, size: 68),
                  if (selected)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: scheme.primary,
                        child: Icon(
                          Icons.check,
                          size: 15,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                color: selected ? scheme.primary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

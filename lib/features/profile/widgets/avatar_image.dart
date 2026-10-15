import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../onboarding/user_provider.dart';
import '../avatars.dart';

/// Avatar redondo: una foto propia (recortada en círculo) o uno de los
/// avatares ilustrados.
class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    required this.avatarId,
    this.photo,
    this.size = 48,
  });

  final String avatarId;
  final Uint8List? photo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    return ExcludeSemantics(
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: photo != null
              ? Image.memory(photo, fit: BoxFit.cover, gaplessPlayback: true)
              : SvgPicture.asset(avatarById(avatarId).asset),
        ),
      ),
    );
  }
}

/// El avatar del usuario (el que eligió o su foto).
class MyAvatar extends StatelessWidget {
  const MyAvatar({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    return AvatarImage(avatarId: user.avatarId, photo: user.photo, size: size);
  }
}

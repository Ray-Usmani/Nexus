import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Profile avatar that shows the user's photo or a default icon.
class ProfileAvatar extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const ProfileAvatar({super.key, this.size = 40, this.onTap});

  @override
  Widget build(BuildContext context) {
    final path = context.watch<AppState>().profileImagePath;
    final image = path != null && File(path).existsSync()
        ? FileImage(File(path))
        : null;

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.amberBright.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line.withValues(alpha: 0.3)),
        image: image != null ? DecorationImage(image: image, fit: BoxFit.cover) : null,
      ),
      child: image == null
          ? Icon(Icons.person, size: size * 0.5, color: AppColors.amber)
          : null,
    );

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}

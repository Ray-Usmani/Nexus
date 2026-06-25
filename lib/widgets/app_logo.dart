import 'package:flutter/material.dart';

/// Brand mark from [assets/logo.png].
class AppLogo extends StatelessWidget {
  final double size;
  final BorderRadius? borderRadius;

  const AppLogo({super.key, this.size = 40, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

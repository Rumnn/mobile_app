import 'package:flutter/material.dart';

class NebulaTheme {
  static const background = Color(0xFF0F0B3C);
  static const surface = Color(0xFF1C1949);
  static const surfaceHigh = Color(0xFF262454);
  static const primary = Color(0xFFD0BCFF);
  static const secondary = Color(0xFFFFB0CD);
  static const tertiary = Color(0xFF4CD7F6);
  static const text = Color(0xFFE3DFFF);
  static const textSubtle = Color(0xFFCBC3D7);

  static BoxDecoration glass({BorderRadius? radius}) {
    return BoxDecoration(
      color: surface.withValues(alpha: 0.72),
      borderRadius: radius ?? BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.14),
          blurRadius: 24,
          spreadRadius: -6,
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';

enum ThemeTemplateType { eggHatch, cozyCoop, fluffyCloud, sweetMint }

class NebulaThemePreset {
  final ThemeTemplateType type;
  final String name;
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color text;
  final Color textSubtle;

  const NebulaThemePreset({
    required this.type,
    required this.name,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.text,
    required this.textSubtle,
  });

  // Egg Hatch
  static const eggHatchDark = NebulaThemePreset(
    type: ThemeTemplateType.eggHatch,
    name: 'Egg Hatch',
    background: Color(0xFF1C1A24),
    surface: Color(0xFF2A2833),
    surfaceHigh: Color(0xFF383545),
    primary: Color(0xFFFFE082),
    secondary: Color(0xFFFAF7EE),
    tertiary: Color(0xFF90CAF9),
    text: Color(0xFFF5F5FA),
    textSubtle: Color(0xFF9E9EAF),
  );

  static const eggHatchLight = NebulaThemePreset(
    type: ThemeTemplateType.eggHatch,
    name: 'Egg Hatch',
    background: Color(0xFFFFFDF6),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFFFFDF0),
    primary: Color(0xFFFF8F00),
    secondary: Color(0xFFFFC107),
    tertiary: Color(0xFF00BCD4),
    text: Color(0xFF1C1A24),
    textSubtle: Color(0xFF5C5A66),
  );

  // Cozy Coop
  static const cozyCoopDark = NebulaThemePreset(
    type: ThemeTemplateType.cozyCoop,
    name: 'Cozy Coop',
    background: Color(0xFF261C1A),
    surface: Color(0xFF362B28),
    surfaceHigh: Color(0xFF483A36),
    primary: Color(0xFFFFAB91),
    secondary: Color(0xFFFFE082),
    tertiary: Color(0xFFA5D6A7),
    text: Color(0xFFFFF0F2),
    textSubtle: Color(0xFFBCAAA4),
  );

  static const cozyCoopLight = NebulaThemePreset(
    type: ThemeTemplateType.cozyCoop,
    name: 'Cozy Coop',
    background: Color(0xFFFAF0E6),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFFFF9F2),
    primary: Color(0xFFD87D6A),
    secondary: Color(0xFFC62828),
    tertiary: Color(0xFF689F38),
    text: Color(0xFF2E1C16),
    textSubtle: Color(0xFF795548),
  );

  // Fluffy Cloud
  static const fluffyCloudDark = NebulaThemePreset(
    type: ThemeTemplateType.fluffyCloud,
    name: 'Fluffy Cloud',
    background: Color(0xFF10152B),
    surface: Color(0xFF1F243D),
    surfaceHigh: Color(0xFF2E3354),
    primary: Color(0xFFF3B0C3),
    secondary: Color(0xFF9BD2EC),
    tertiary: Color(0xFFC5B0F3),
    text: Color(0xFFEAF1F8),
    textSubtle: Color(0xFFA4AFCE),
  );

  static const fluffyCloudLight = NebulaThemePreset(
    type: ThemeTemplateType.fluffyCloud,
    name: 'Fluffy Cloud',
    background: Color(0xFFE8F1F5),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF0F6F9),
    primary: Color(0xFFEC8F90),
    secondary: Color(0xFF9C9CFF),
    tertiary: Color(0xFF4DD0E1),
    text: Color(0xFF10152B),
    textSubtle: Color(0xFF616B82),
  );

  // Sweet Mint
  static const sweetMintDark = NebulaThemePreset(
    type: ThemeTemplateType.sweetMint,
    name: 'Sweet Mint',
    background: Color(0xFF15201A),
    surface: Color(0xFF233028),
    surfaceHigh: Color(0xFF314238),
    primary: Color(0xFFA5D6A7),
    secondary: Color(0xFFE6EE9C),
    tertiary: Color(0xFF80D8FF),
    text: Color(0xFFE0FFF3),
    textSubtle: Color(0xFFA3B8B2),
  );

  static const sweetMintLight = NebulaThemePreset(
    type: ThemeTemplateType.sweetMint,
    name: 'Sweet Mint',
    background: Color(0xFFEDF7F4),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE0ECE8),
    primary: Color(0xFF2D7F61),
    secondary: Color(0xFF88B04B),
    tertiary: Color(0xFF0288D1),
    text: Color(0xFF0A1D1A),
    textSubtle: Color(0xFF526E67),
  );

  static NebulaThemePreset resolvePreset(ThemeTemplateType template, bool isDarkMode) {
    switch (template) {
      case ThemeTemplateType.cozyCoop:
        return isDarkMode ? cozyCoopDark : cozyCoopLight;
      case ThemeTemplateType.fluffyCloud:
        return isDarkMode ? fluffyCloudDark : fluffyCloudLight;
      case ThemeTemplateType.sweetMint:
        return isDarkMode ? sweetMintDark : sweetMintLight;
      case ThemeTemplateType.eggHatch:
        return isDarkMode ? eggHatchDark : eggHatchLight;
    }
  }
}

class NebulaTheme {
  static NebulaThemePreset activePreset = NebulaThemePreset.eggHatchDark;

  static Color get background => activePreset.background;
  static Color get surface => activePreset.surface;
  static Color get surfaceHigh => activePreset.surfaceHigh;
  static Color get primary => activePreset.primary;
  static Color get secondary => activePreset.secondary;
  static Color get tertiary => activePreset.tertiary;
  static Color get text => activePreset.text;
  static Color get textSubtle => activePreset.textSubtle;

  static BoxDecoration glass({BorderRadius? radius}) {
    final isBrightBg = background.computeLuminance() > 0.5;
    return BoxDecoration(
      color: surface.withValues(alpha: isBrightBg ? 0.85 : 0.72),
      borderRadius: radius ?? BorderRadius.circular(22),
      border: Border.all(color: (isBrightBg ? Colors.black : Colors.white).withValues(alpha: 0.1)),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: isBrightBg ? 0.08 : 0.14),
          blurRadius: 24,
          spreadRadius: -6,
        ),
      ],
    );
  }
}

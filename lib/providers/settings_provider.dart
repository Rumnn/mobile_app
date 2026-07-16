import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/nebula_theme.dart';
import '../services/app_localization.dart';

class SettingsProvider with ChangeNotifier {
  String _themeTemplate = 'eggHatch';
  bool _isDarkMode = true;
  String _language = 'en';

  String get themeTemplate => _themeTemplate;
  bool get isDarkMode => _isDarkMode;
  String get language => _language;

  bool get isLightMode => !_isDarkMode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _themeTemplate = prefs.getString('setting_theme_template') ?? 'eggHatch';
    _isDarkMode = prefs.getBool('setting_is_dark_mode') ?? true;
    _language = prefs.getString('setting_language') ?? 'en';
    
    _applyThemeColors();
    notifyListeners();
  }

  void setSettings({
    required String template,
    required bool isDark,
    required String lang,
  }) {
    _themeTemplate = template;
    _isDarkMode = isDark;
    _language = lang;

    _applyThemeColors();
    notifyListeners();

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('setting_theme_template', template);
      prefs.setBool('setting_is_dark_mode', isDark);
      prefs.setString('setting_language', lang);
    });
  }

  void _applyThemeColors() {
    // 1. Resolve template type enum
    ThemeTemplateType templateType;
    switch (_themeTemplate) {
      case 'cozyCoop':
        templateType = ThemeTemplateType.cozyCoop;
        break;
      case 'fluffyCloud':
        templateType = ThemeTemplateType.fluffyCloud;
        break;
      case 'sweetMint':
        templateType = ThemeTemplateType.sweetMint;
        break;
      case 'eggHatch':
      default:
        templateType = ThemeTemplateType.eggHatch;
        break;
    }

    // 2. Resolve preset colors using resolvePreset helper
    NebulaTheme.activePreset = NebulaThemePreset.resolvePreset(templateType, _isDarkMode);
  }

  String getText(String key) {
    return AppLocalization.getString(_language, key);
  }
}

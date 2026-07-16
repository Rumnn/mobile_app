import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/nebula_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _tempTheme;
  late bool _tempIsDarkMode;
  late String _tempLang;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _tempTheme = settings.themeTemplate;
    _tempIsDarkMode = settings.isDarkMode;
    _tempLang = settings.language;
  }

  void _saveSettings() {
    context.read<SettingsProvider>().setSettings(
      template: _tempTheme,
      isDark: _tempIsDarkMode,
      lang: _tempLang,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<SettingsProvider>().getText('theme_saved'),
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  Map<String, Color> _getPreviewColors() {
    ThemeTemplateType templateType = ThemeTemplateType.eggHatch;
    if (_tempTheme == 'cozyCoop') templateType = ThemeTemplateType.cozyCoop;
    if (_tempTheme == 'fluffyCloud') templateType = ThemeTemplateType.fluffyCloud;
    if (_tempTheme == 'sweetMint') templateType = ThemeTemplateType.sweetMint;

    final preset = NebulaThemePreset.resolvePreset(templateType, _tempIsDarkMode);
    return {
      'bg': preset.background,
      'surf': preset.surface,
      'text': preset.text,
      'textSub': preset.textSubtle,
      'primary': preset.primary,
      'secondary': preset.secondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = _getPreviewColors();
    final isBright = colors['bg']!.computeLuminance() > 0.5;

    return Scaffold(
      backgroundColor: NebulaTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:       Icon(Icons.arrow_back_rounded, color: NebulaTheme.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          settings.getText('settings'),
          style:       TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // Dynamic Preview Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NebulaTheme.glass(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                          Icon(Icons.visibility, color: NebulaTheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      settings.getText('preview'),
                      style:       TextStyle(color: NebulaTheme.text, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors['bg'],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (isBright ? Colors.black : Colors.white).withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors['primary']!.withOpacity(0.15),
                            ),
                            child: Icon(Icons.sports_esports, color: colors['primary'], size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tempLang == 'en' ? 'CluckTogether Lobby' : 'Sảnh CluckTogether',
                                  style: TextStyle(color: colors['text'], fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _tempLang == 'en'
                                      ? '4 players in the coop ready'
                                      : 'Đang có 4 đồng đội trong chuồng',
                                  style: TextStyle(color: colors['textSub'], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: colors['primary'],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {},
                              child: Text(
                                _tempLang == 'en' ? 'PLAY NOW' : 'CHƠI NGAY',
                                style: TextStyle(
                                  color: isBright ? Colors.white : const Color(0xFF1C1A24),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colors['secondary']!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {},
                              child: Text(
                                _tempLang == 'en' ? 'INVITE' : 'MỜI BẠN',
                                style: TextStyle(
                                  color: colors['secondary'],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Language Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NebulaTheme.glass(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                          Icon(Icons.language, color: NebulaTheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      settings.getText('select_lang'),
                      style:       TextStyle(color: NebulaTheme.text, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tempLang = 'en'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _tempLang == 'en'
                                ? NebulaTheme.primary.withOpacity(0.15)
                                : NebulaTheme.surfaceHigh.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _tempLang == 'en'
                                  ? NebulaTheme.primary
                                  : Colors.white.withOpacity(0.08),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child:       Text(
                            'English (EN)',
                            style: TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tempLang = 'vi'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _tempLang == 'vi'
                                ? NebulaTheme.primary.withOpacity(0.15)
                                : NebulaTheme.surfaceHigh.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _tempLang == 'vi'
                                  ? NebulaTheme.primary
                                  : Colors.white.withOpacity(0.08),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child:       Text(
                            'Tiếng Việt (VI)',
                            style: TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Theme Templates Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NebulaTheme.glass(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                          Icon(Icons.palette, color: NebulaTheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      settings.getText('select_theme'),
                      style:       TextStyle(color: NebulaTheme.text, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  children: [
                    _PresetButton(
                      id: 'eggHatch',
                      name: settings.getText('eggHatch'),
                      primaryColor: const Color(0xFFFFE082),
                      secondaryColor: const Color(0xFFFAF7EE),
                      backgroundColor: const Color(0xFF1C1A24),
                      selected: _tempTheme == 'eggHatch',
                      onTap: () => setState(() => _tempTheme = 'eggHatch'),
                    ),
                    _PresetButton(
                      id: 'cozyCoop',
                      name: settings.getText('cozyCoop'),
                      primaryColor: const Color(0xFFFFAB91),
                      secondaryColor: const Color(0xFFFFE082),
                      backgroundColor: const Color(0xFF261C1A),
                      selected: _tempTheme == 'cozyCoop',
                      onTap: () => setState(() => _tempTheme = 'cozyCoop'),
                    ),
                    _PresetButton(
                      id: 'fluffyCloud',
                      name: settings.getText('fluffyCloud'),
                      primaryColor: const Color(0xFFF3B0C3),
                      secondaryColor: const Color(0xFF9BD2EC),
                      backgroundColor: const Color(0xFF10152B),
                      selected: _tempTheme == 'fluffyCloud',
                      onTap: () => setState(() => _tempTheme = 'fluffyCloud'),
                    ),
                    _PresetButton(
                      id: 'sweetMint',
                      name: settings.getText('sweetMint'),
                      primaryColor: const Color(0xFFA5D6A7),
                      secondaryColor: const Color(0xFFE6EE9C),
                      backgroundColor: const Color(0xFF15201A),
                      selected: _tempTheme == 'sweetMint',
                      onTap: () => setState(() => _tempTheme = 'sweetMint'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Theme Mode (Dark / Light Mode)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NebulaTheme.glass(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                          Icon(Icons.brightness_medium_rounded, color: NebulaTheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      settings.getText('theme_mode'),
                      style:       TextStyle(color: NebulaTheme.text, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tempIsDarkMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_tempIsDarkMode
                                ? NebulaTheme.primary.withOpacity(0.15)
                                : NebulaTheme.surfaceHigh.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !_tempIsDarkMode
                                  ? NebulaTheme.primary
                                  : Colors.white.withOpacity(0.08),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.light_mode, color: !_tempIsDarkMode ? NebulaTheme.primary : NebulaTheme.textSubtle, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                settings.getText('light_mode'),
                                style: TextStyle(
                                  color: !_tempIsDarkMode ? NebulaTheme.text : NebulaTheme.textSubtle,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tempIsDarkMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _tempIsDarkMode
                                ? NebulaTheme.primary.withOpacity(0.15)
                                : NebulaTheme.surfaceHigh.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _tempIsDarkMode
                                  ? NebulaTheme.primary
                                  : Colors.white.withOpacity(0.08),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.dark_mode, color: _tempIsDarkMode ? NebulaTheme.primary : NebulaTheme.textSubtle, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                settings.getText('dark_mode'),
                                style: TextStyle(
                                  color: _tempIsDarkMode ? NebulaTheme.text : NebulaTheme.textSubtle,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: NebulaTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _saveSettings,
              child: Text(
                settings.getText('save_settings'),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final bool selected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? NebulaTheme.primary.withOpacity(0.15)
              : NebulaTheme.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? NebulaTheme.primary : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style:       TextStyle(color: NebulaTheme.text, fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                    border: Border.all(color: Colors.white24),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: secondaryColor,
                    border: Border.all(color: Colors.white24),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: backgroundColor,
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

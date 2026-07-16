import 'package:flutter/material.dart';

import '../games/ludo/ludo_game_widget.dart';
import '../widgets/nebula_theme.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';

class LudoScreen extends StatelessWidget {
  const LudoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: NebulaTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: NebulaTheme.background.withValues(alpha: 0.92),
        leading: IconButton(
          icon:       Icon(Icons.arrow_back_rounded, color: NebulaTheme.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) =>       LinearGradient(
            colors: [NebulaTheme.primary, NebulaTheme.secondary],
          ).createShader(bounds),
          child: const Text(
            'Ludo',
            style: TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: const LudoGameWidget(),
            ),
          ),
        ),
      ),
    );
  }
}

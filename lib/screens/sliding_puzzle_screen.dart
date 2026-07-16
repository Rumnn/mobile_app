import 'package:flutter/material.dart';

import '../games/sliding_puzzle/sliding_puzzle_game.dart';
import '../widgets/nebula_theme.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// A full-screen wrapper that hosts the [SlidingPuzzleGame] widget
/// within the CluckTogether chrome (app bar, back nav, background).
class SlidingPuzzleScreen extends StatelessWidget {
  const SlidingPuzzleScreen({super.key});

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
            'Mini-Game',
            style: TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: SlidingPuzzleGame(),
        ),
      ),
    );
  }
}

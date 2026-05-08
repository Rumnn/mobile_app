import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../widgets/nebula_theme.dart';
import 'ludo_game.dart';
import 'network/mock_ludo_protocol.dart';

class LudoGameWidget extends StatefulWidget {
  const LudoGameWidget({super.key});

  @override
  State<LudoGameWidget> createState() => _LudoGameWidgetState();
}

class _LudoGameWidgetState extends State<LudoGameWidget> {
  late final LudoGame _game;

  @override
  void initState() {
    super.initState();
    _game = LudoGame(protocol: MockLudoProtocol());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: NebulaTheme.surface.withValues(alpha: 0.74),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 1,
          child: GameWidget(game: _game),
        ),
      ),
    );
  }
}

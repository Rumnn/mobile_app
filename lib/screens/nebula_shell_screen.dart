import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/nebula_theme.dart';
import 'admin_dashboard_screen.dart';
import 'nebula_games_screen.dart';
import 'nebula_profile_screen.dart';
import 'nebula_room_screen.dart';
import 'nebula_social_screen.dart';

class NebulaShellScreen extends StatefulWidget {
  const NebulaShellScreen({super.key});

  @override
  State<NebulaShellScreen> createState() => _NebulaShellScreenState();
}

class _NebulaShellScreenState extends State<NebulaShellScreen> {
  int _tab = 0;

  static const _titles = ['NebulaPlay', 'NebulaPlay', 'NebulaPlay', 'NebulaPlay'];
  static const _pages = [
    NebulaGamesScreen(),
    NebulaSocialScreen(),
    NebulaRoomScreen(),
    NebulaProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NebulaTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: NebulaTheme.background.withValues(alpha: 0.92),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(colors: [NebulaTheme.primary, NebulaTheme.secondary]).createShader(bounds),
          child: Text(_titles[_tab], style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: NebulaTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Row(
              children: [
                Icon(Icons.monetization_on, color: NebulaTheme.secondary, size: 16),
                SizedBox(width: 4),
                Text('500 Coins', style: TextStyle(color: NebulaTheme.secondary, fontSize: 12)),
              ],
            ),
          ),
          if (context.watch<AuthProvider>().isAdmin)
            IconButton(
              tooltip: 'Admin Dashboard',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
              icon: const Icon(Icons.admin_panel_settings, color: NebulaTheme.primary),
            ),
          IconButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout, color: NebulaTheme.textSubtle),
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (v) => setState(() => _tab = v),
        backgroundColor: NebulaTheme.surface.withValues(alpha: 0.95),
        selectedItemColor: NebulaTheme.secondary,
        unselectedItemColor: NebulaTheme.textSubtle,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'Games'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Social'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person_pin), label: 'Profile'),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              backgroundColor: NebulaTheme.primary.withValues(alpha: 0.9),
              onPressed: () {},
              child: const Icon(Icons.add, color: Colors.white),
            )
          : (_tab == 1
              ? FloatingActionButton(
                  backgroundColor: NebulaTheme.secondary.withValues(alpha: 0.9),
                  onPressed: () {},
                  child: const Icon(Icons.edit, color: Colors.white),
                )
              : null),
    );
  }
}


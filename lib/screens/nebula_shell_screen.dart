import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../providers/post_provider.dart';
import '../providers/settings_provider.dart';
import '../services/socket_service.dart';
import '../widgets/nebula_theme.dart';
import '../widgets/create_post_sheet.dart';
import 'admin_dashboard_screen.dart';
import 'nebula_games_screen.dart';
import 'nebula_message_screen.dart';
import 'nebula_profile_screen.dart';
import 'nebula_social_screen.dart';

class NebulaShellScreen extends StatefulWidget {
  const NebulaShellScreen({super.key});

  @override
  State<NebulaShellScreen> createState() => _NebulaShellScreenState();
}

class _NebulaShellScreenState extends State<NebulaShellScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Connect to Socket.io server, then register real-time listeners
      // IMPORTANT: listeners must be registered AFTER the socket is created,
      // otherwise socket.on() is called on a null socket and silently dropped.
      SocketService.instance.connect().then((_) {
        if (!mounted) return;
        context.read<PostProvider>().initSocketListeners();
        context.read<MessageProvider>().initSocketListeners();
      }).catchError((err) {
        // ignore: avoid_print
        print('Shell: Socket connection error: $err');
      });
    });
  }

  static const _titles = ['CluckTogether', 'CluckTogether', 'CluckTogether', 'CluckTogether'];
  List<Widget> get _pages => [
    NebulaGamesScreen(),
    NebulaSocialScreen(),
    NebulaMessageScreen(),
    NebulaProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: NebulaTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: NebulaTheme.background.withValues(alpha: 0.92),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFAF7EE),
                boxShadow: [
                  BoxShadow(
                    color: NebulaTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: NebulaTheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) =>       LinearGradient(colors: [NebulaTheme.primary, NebulaTheme.secondary]).createShader(bounds),
                child: Text(_titles[_tab], style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
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
            child: Row(
              children: [
                      Icon(Icons.monetization_on, color: NebulaTheme.secondary, size: 16),
                const SizedBox(width: 4),
                Text('500 ${settings.getText('coins')}', style:       TextStyle(color: NebulaTheme.secondary, fontSize: 12)),
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
              icon:       Icon(Icons.admin_panel_settings, color: NebulaTheme.primary),
            ),
          IconButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon:       Icon(Icons.logout, color: NebulaTheme.textSubtle),
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
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.sports_esports), label: settings.getText('games')),
          BottomNavigationBarItem(icon: const Icon(Icons.explore), label: settings.getText('social')),
          BottomNavigationBarItem(icon: const Icon(Icons.forum), label: settings.getText('message')),
          BottomNavigationBarItem(icon: const Icon(Icons.person_pin), label: settings.getText('profile')),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              backgroundColor: NebulaTheme.primary.withValues(alpha: 0.9),
              onPressed: () {},
              child: Icon(
                Icons.add,
                color: NebulaTheme.primary.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              ),
            )
          : (_tab == 1
              ? FloatingActionButton(
                  backgroundColor: NebulaTheme.secondary.withValues(alpha: 0.9),
                  onPressed: () => CreatePostSheet.show(context),
                  child: const Icon(Icons.edit, color: Colors.white),
                )
              : null),
    );
  }
}


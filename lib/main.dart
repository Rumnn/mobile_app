import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'providers/user_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/message_provider.dart';
import 'screens/login_screen.dart';
import 'screens/nebula_shell_screen.dart';
import 'widgets/nebula_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()..initSocketListeners()),
      ],
      child: const _AppBuilder(),
    );
  }
}

class _AppBuilder extends StatelessWidget {
  const _AppBuilder();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isLight = settings.isLightMode;

    return MaterialApp(
      title: 'CluckTogether',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: NebulaTheme.primary,
          brightness: isLight ? Brightness.light : Brightness.dark,
          surface: NebulaTheme.surface,
        ),
        scaffoldBackgroundColor: NebulaTheme.background,
        useMaterial3: true,
      ),
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) return const LoginScreen();
    return const NebulaShellScreen();
  }
}

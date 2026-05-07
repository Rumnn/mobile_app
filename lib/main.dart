import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
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
      ],
      child: MaterialApp(
        title: 'Social Board Game',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: NebulaTheme.primary,
            brightness: Brightness.dark,
            surface: NebulaTheme.surface,
          ),
          scaffoldBackgroundColor: NebulaTheme.background,
          useMaterial3: true,
        ),
        home: const _RootRouter(),
      ),
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

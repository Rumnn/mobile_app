import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/nebula_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    try {
      await auth.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.error ?? settings.getText('login_failed'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: NebulaTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: NebulaTheme.glass(),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFAF7EE),
                      boxShadow: [
                        BoxShadow(
                          color: NebulaTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: NebulaTheme.primary.withValues(alpha: 0.5),
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                        Text(
                    'CluckTogether',
                    style: TextStyle(
                      color: NebulaTheme.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    settings.getText('coop_desc'),
                    style:       TextStyle(
                      color: NebulaTheme.textSubtle,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailCtrl,
                    style:       TextStyle(color: NebulaTheme.text),
                    decoration: InputDecoration(
                      labelText: settings.getText('email'),
                      labelStyle:       TextStyle(
                        color: NebulaTheme.textSubtle,
                      ),
                      prefixIcon:       Icon(
                        Icons.email,
                        color: NebulaTheme.primary,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:       BorderSide(
                          color: NebulaTheme.textSubtle,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:       BorderSide(
                          color: NebulaTheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? settings.getText('email_required')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    style:       TextStyle(color: NebulaTheme.text),
                    decoration: InputDecoration(
                      labelText: settings.getText('password'),
                      labelStyle:       TextStyle(
                        color: NebulaTheme.textSubtle,
                      ),
                      prefixIcon:       Icon(
                        Icons.lock,
                        color: NebulaTheme.primary,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:       BorderSide(
                          color: NebulaTheme.textSubtle,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:       BorderSide(
                          color: NebulaTheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty)
                        ? settings.getText('password_required')
                        : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: NebulaTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: auth.isLoading ? null : _onLogin,
                      child: Text(
                        auth.isLoading
                            ? settings.getText('authenticating')
                            : settings.getText('login').toUpperCase(),
                        style:       TextStyle(
                          color: NebulaTheme.background,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: auth.isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                    child: Text(
                      settings.getText('create_account'),
                      style:       TextStyle(
                        color: NebulaTheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

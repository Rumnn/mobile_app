import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/nebula_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    try {
      await auth.register(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? settings.getText('register_failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: NebulaTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:       Icon(Icons.arrow_back, color: NebulaTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFAF7EE),
                      boxShadow: [
                        BoxShadow(
                          color: NebulaTheme.primary.withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                      border: Border.all(
                        color: NebulaTheme.primary.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    settings.getText('join_cluck'),
                    style:       TextStyle(
                      color: NebulaTheme.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    settings.getText('player_profile'),
                    style:       TextStyle(
                      color: NebulaTheme.textSubtle,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameCtrl,
                    style:       TextStyle(color: NebulaTheme.text),
                    decoration: InputDecoration(
                      labelText: settings.getText('username'),
                      labelStyle:       TextStyle(color: NebulaTheme.textSubtle),
                      prefixIcon:       Icon(Icons.person, color: NebulaTheme.primary),
                      enabledBorder: OutlineInputBorder(borderSide:       BorderSide(color: NebulaTheme.textSubtle), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide:       BorderSide(color: NebulaTheme.primary), borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? settings.getText('username_required') : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    style:       TextStyle(color: NebulaTheme.text),
                    decoration: InputDecoration(
                      labelText: settings.getText('email'),
                      labelStyle:       TextStyle(color: NebulaTheme.textSubtle),
                      prefixIcon:       Icon(Icons.email, color: NebulaTheme.primary),
                      enabledBorder: OutlineInputBorder(borderSide:       BorderSide(color: NebulaTheme.textSubtle), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide:       BorderSide(color: NebulaTheme.primary), borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.trim().isEmpty) ? settings.getText('email_required') : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    style:       TextStyle(color: NebulaTheme.text),
                    decoration: InputDecoration(
                      labelText: settings.getText('password'),
                      labelStyle:       TextStyle(color: NebulaTheme.textSubtle),
                      prefixIcon:       Icon(Icons.lock, color: NebulaTheme.primary),
                      enabledBorder: OutlineInputBorder(borderSide:       BorderSide(color: NebulaTheme.textSubtle), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide:       BorderSide(color: NebulaTheme.primary), borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty) ? settings.getText('password_required') : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: NebulaTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: auth.isLoading ? null : _onRegister,
                      child: Text(
                        auth.isLoading ? settings.getText('creating') : settings.getText('register').toUpperCase(),
                        style:       TextStyle(color: NebulaTheme.background, fontWeight: FontWeight.w800, letterSpacing: 1.5),
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


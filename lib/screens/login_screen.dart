import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
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
    try {
      await auth.login(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
                  const Text('NEBULAPLAY', style: TextStyle(color: NebulaTheme.primary, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  const Text('Enter the grid', style: TextStyle(color: NebulaTheme.textSubtle, fontSize: 16)),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailCtrl,
                    style: const TextStyle(color: NebulaTheme.text),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: const TextStyle(color: NebulaTheme.textSubtle),
                      prefixIcon: const Icon(Icons.email, color: NebulaTheme.primary),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: NebulaTheme.textSubtle), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: NebulaTheme.primary), borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    style: const TextStyle(color: NebulaTheme.text),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: NebulaTheme.textSubtle),
                      prefixIcon: const Icon(Icons.lock, color: NebulaTheme.primary),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: NebulaTheme.textSubtle), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: NebulaTheme.primary), borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
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
                      onPressed: auth.isLoading ? null : _onLogin,
                      child: Text(
                        auth.isLoading ? 'AUTHENTICATING...' : 'LOGIN',
                        style: const TextStyle(color: NebulaTheme.background, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: auth.isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                    child: const Text('CREATE NEW ACCOUNT', style: TextStyle(color: NebulaTheme.secondary, fontWeight: FontWeight.bold)),
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


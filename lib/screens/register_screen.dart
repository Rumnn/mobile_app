import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
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
        SnackBar(content: Text(auth.error ?? 'Register failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: NebulaTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NebulaTheme.primary),
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
                  const Text('JOIN NEBULAPLAY', style: TextStyle(color: NebulaTheme.primary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  const Text('Create your player profile', style: TextStyle(color: NebulaTheme.textSubtle, fontSize: 14)),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameCtrl,
                    style: const TextStyle(color: NebulaTheme.text),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: const TextStyle(color: NebulaTheme.textSubtle),
                      prefixIcon: const Icon(Icons.person, color: NebulaTheme.primary),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: NebulaTheme.textSubtle), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: NebulaTheme.primary), borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null,
                  ),
                  const SizedBox(height: 16),
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
                      onPressed: auth.isLoading ? null : _onRegister,
                      child: Text(
                        auth.isLoading ? 'CREATING...' : 'REGISTER',
                        style: const TextStyle(color: NebulaTheme.background, fontWeight: FontWeight.w800, letterSpacing: 1.5),
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


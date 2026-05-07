import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _usernameCtrl.text = user?.username ?? '';
    _avatarCtrl.text = user?.avatarURL ?? '';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null || user.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing user id. Please login again.')),
      );
      return;
    }

    try {
      final updated = await context.read<UserProvider>().updateUser(user.id, {
        'username': _usernameCtrl.text.trim(),
        'avatarURL': _avatarCtrl.text.trim(),
      });
      await auth.setCurrentUser(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: user == null
            ? const Center(child: Text('Not logged in'))
            : ListView(
                children: [
                  Text('Role: ${user.role}'),
                  Text('Level: ${user.level}'),
                  Text('Win rate: ${user.winRate}%'),
                  Text('Total games: ${user.totalGames}'),
                  const SizedBox(height: 16),
                  const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameCtrl,
                          decoration: const InputDecoration(labelText: 'Username'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _avatarCtrl,
                          decoration: const InputDecoration(labelText: 'Avatar URL'),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _save,
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}


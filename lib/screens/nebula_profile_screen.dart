import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/nebula_theme.dart';

class NebulaProfileScreen extends StatefulWidget {
  const NebulaProfileScreen({super.key});

  @override
  State<NebulaProfileScreen> createState() => _NebulaProfileScreenState();
}

class _NebulaProfileScreenState extends State<NebulaProfileScreen> {
  Future<void> _openEditProfileDialog() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final formKey = GlobalKey<FormState>();
    final usernameCtrl = TextEditingController(text: user.username);
    final avatarCtrl = TextEditingController(text: user.avatarURL);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NebulaTheme.surfaceHigh,
        title: const Text('Edit Profile', style: TextStyle(color: NebulaTheme.text)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: usernameCtrl,
                style: const TextStyle(color: NebulaTheme.text),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: NebulaTheme.textSubtle),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: NebulaTheme.textSubtle)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: avatarCtrl,
                style: const TextStyle(color: NebulaTheme.text),
                decoration: const InputDecoration(
                  labelText: 'Avatar URL',
                  labelStyle: TextStyle(color: NebulaTheme.textSubtle),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: NebulaTheme.textSubtle)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: NebulaTheme.textSubtle)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NebulaTheme.primary),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(context, {
                  'username': usernameCtrl.text.trim(),
                  'avatarURL': avatarCtrl.text.trim(),
                });
              }
            },
            child: const Text('Save', style: TextStyle(color: NebulaTheme.background)),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    try {
      final updated = await context.read<UserProvider>().updateUser(user.id, result);
      await auth.setCurrentUser(updated);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in', style: TextStyle(color: NebulaTheme.text)));
    }

    final avatarUrl = user.avatarURL.isNotEmpty
        ? user.avatarURL
        : 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?q=80&w=500&auto=format&fit=crop';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: NebulaTheme.glass(),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: NebulaTheme.secondary, width: 3)),
                child: CircleAvatar(
                  radius: 42,
                  backgroundImage: NetworkImage(avatarUrl),
                  onBackgroundImageError: (_, __) {},
                ),
              ),
              const SizedBox(height: 10),
              Text(user.username, style: const TextStyle(color: NebulaTheme.text, fontSize: 32, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('LEVEL ${user.level} ${user.role.toUpperCase()}', style: const TextStyle(color: NebulaTheme.primary, fontWeight: FontWeight.w600, fontSize: 11)),
              const SizedBox(height: 8),
              Text(user.email, style: const TextStyle(color: NebulaTheme.textSubtle)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Stat(title: '${user.winRate}%', subtitle: 'WIN RATE'),
                  _Stat(title: '${user.totalGames}', subtitle: 'GAMES'),
                  const _Stat(title: '0', subtitle: 'FRIENDS'),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _openEditProfileDialog,
                style: FilledButton.styleFrom(backgroundColor: NebulaTheme.primary.withOpacity(0.24), minimumSize: const Size.fromHeight(46)),
                child: const Text('Edit Profile', style: TextStyle(color: NebulaTheme.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: NebulaTheme.glass(),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Achievements', style: TextStyle(color: NebulaTheme.text, fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(text: 'First Blood'),
                _Badge(text: 'Puzzle Master'),
                _Badge(text: 'Social Butterfly'),
              ],
            )
          ]),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Stat({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(title, style: const TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.w700)),
      Text(subtitle, style: const TextStyle(color: NebulaTheme.textSubtle, fontSize: 11)),
    ]);
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: NebulaTheme.surfaceHigh, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: NebulaTheme.text)),
    );
  }
}


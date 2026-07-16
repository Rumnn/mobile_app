import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/nebula_theme.dart';
import 'settings_screen.dart';

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
        title:       Text('Edit Profile', style: TextStyle(color: NebulaTheme.text)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: usernameCtrl,
                style:       TextStyle(color: NebulaTheme.text),
                decoration:       InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: NebulaTheme.textSubtle),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: NebulaTheme.textSubtle)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: avatarCtrl,
                style:       TextStyle(color: NebulaTheme.text),
                decoration:       InputDecoration(
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
            child:       Text('Cancel', style: TextStyle(color: NebulaTheme.textSubtle)),
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
            child:       Text('Save', style: TextStyle(color: NebulaTheme.background)),
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
    final settings = context.watch<SettingsProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return Center(child: Text(settings.getText('not_logged_in'), style:       TextStyle(color: NebulaTheme.text)));
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
              Text(user.username, style:       TextStyle(color: NebulaTheme.text, fontSize: 32, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('LEVEL ${user.level} ${user.role.toUpperCase()}', style:       TextStyle(color: NebulaTheme.primary, fontWeight: FontWeight.w600, fontSize: 11)),
              const SizedBox(height: 8),
              Text(user.email, style:       TextStyle(color: NebulaTheme.textSubtle)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Stat(title: '${user.winRate}%', subtitle: settings.getText('win_rate')),
                  _Stat(title: '${user.totalGames}', subtitle: settings.getText('games_played')),
                  _Stat(title: '0', subtitle: settings.getText('friends')),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _openEditProfileDialog,
                style: FilledButton.styleFrom(backgroundColor: NebulaTheme.primary.withOpacity(0.24), minimumSize: const Size.fromHeight(46)),
                child: Text(settings.getText('edit_profile'), style:       TextStyle(color: NebulaTheme.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: NebulaTheme.glass(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(settings.getText('achievements'), style:       TextStyle(color: NebulaTheme.text, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            const Wrap(
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
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: NebulaTheme.glass(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settings.getText('settings'),
                style:       TextStyle(color: NebulaTheme.text, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:       Icon(Icons.settings, color: NebulaTheme.primary),
                title: Text(
                  settings.getText('customize_ui'),
                  style:       TextStyle(color: NebulaTheme.text, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  settings.getText('customize_ui_desc'),
                  style:       TextStyle(color: NebulaTheme.textSubtle, fontSize: 13),
                ),
                trailing:       Icon(Icons.arrow_forward_ios, color: NebulaTheme.textSubtle, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
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
      Text(title, style:       TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.w700)),
      Text(subtitle, style:       TextStyle(color: NebulaTheme.textSubtle, fontSize: 11)),
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
      child: Text(text, style:       TextStyle(color: NebulaTheme.text)),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../services/user_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  Future<void> _confirmDelete(UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm delete'),
        content: Text('Delete ${user.username}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    try {
      await context.read<UserProvider>().deleteUser(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _openEditDialog({UserModel? user}) async {
    final isEdit = user != null;
    final usernameCtrl = TextEditingController(text: user?.username ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passwordCtrl = TextEditingController();
    final avatarCtrl = TextEditingController(text: user?.avatarURL ?? '');
    final levelCtrl = TextEditingController(text: (user?.level ?? 1).toString());
    final winRateCtrl = TextEditingController(text: (user?.winRate ?? 0).toString());
    final totalGamesCtrl = TextEditingController(text: (user?.totalGames ?? 0).toString());
    String role = user?.role ?? 'user';

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit user' : 'Add user'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    if (!isEdit)
                      TextFormField(
                        controller: passwordCtrl,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    if (!isEdit) const SizedBox(height: 10),
                    TextFormField(
                      controller: avatarCtrl,
                      decoration: const InputDecoration(labelText: 'Avatar URL'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: levelCtrl,
                            decoration: const InputDecoration(labelText: 'Level'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: winRateCtrl,
                            decoration: const InputDecoration(labelText: 'Win Rate'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: totalGamesCtrl,
                      decoration: const InputDecoration(labelText: 'Total Games'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('user')),
                        DropdownMenuItem(value: 'admin', child: Text('admin')),
                      ],
                      onChanged: (v) => role = v ?? 'user',
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(context, {
                  'username': usernameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  if (!isEdit) 'password': passwordCtrl.text,
                  'avatarURL': avatarCtrl.text.trim(),
                  'level': int.tryParse(levelCtrl.text.trim()) ?? 1,
                  'winRate': double.tryParse(winRateCtrl.text.trim()) ?? 0,
                  'totalGames': int.tryParse(totalGamesCtrl.text.trim()) ?? 0,
                  'role': role,
                });
              },
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        );
      },
    );

    usernameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    avatarCtrl.dispose();
    levelCtrl.dispose();
    winRateCtrl.dispose();
    totalGamesCtrl.dispose();

    if (result == null) return;
    if (!mounted) return;

    try {
      if (isEdit) {
        await context.read<UserProvider>().updateUser(user.id, result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated')));
      } else {
        // Create user is admin-only: call service directly, then refresh list.
        await UserService().createUser(result);
        if (!mounted) return;
        await context.read<UserProvider>().fetchUsers();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Operation failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: const Center(child: Text('Forbidden: admin only')),
      );
    }

    final usersProvider = context.watch<UserProvider>();
    final users = usersProvider.users;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: usersProvider.isLoading ? null : () => context.read<UserProvider>().fetchUsers(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: usersProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: users.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final u = users[i];
                return ListTile(
                  title: Text(u.username),
                  subtitle: Text('${u.email} • ${u.role}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _openEditDialog(user: u),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(u),
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}


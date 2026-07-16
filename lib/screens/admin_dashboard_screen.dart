import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/user_service.dart';
import '../widgets/role_guard.dart';
import '../widgets/nebula_theme.dart';
import '../providers/settings_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

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
    context.watch<SettingsProvider>();
    final usersProvider = context.watch<UserProvider>();
    final allUsers = usersProvider.users;

    // Filter users based on search query
    final filteredUsers = allUsers.where((u) {
      final query = _searchQuery.toLowerCase();
      return u.username.toLowerCase().contains(query) || u.email.toLowerCase().contains(query);
    }).toList();

    // Pagination logic
    final totalPages = (filteredUsers.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < filteredUsers.length)
        ? startIndex + _itemsPerPage
        : filteredUsers.length;
    final paginatedUsers = filteredUsers.sublist(startIndex, endIndex);

    final totalUsers = allUsers.length;
    final adminCount = allUsers.where((u) => u.role == 'admin').length;
    final totalGamesCount = allUsers.fold<int>(0, (sum, u) => sum + u.totalGames);

    return RoleGuard(
      allowedRoles: const ['admin'],
      child: Scaffold(
        backgroundColor: NebulaTheme.background,
        appBar: AppBar(
          backgroundColor: NebulaTheme.background.withValues(alpha: 0.92),
          elevation: 0,
          title: Text('Command Center', style: TextStyle(fontWeight: FontWeight.bold, color: NebulaTheme.text)),
          actions: [
            IconButton(
              tooltip: 'Sync Data',
              onPressed: usersProvider.isLoading ? null : () => context.read<UserProvider>().fetchUsers(),
              icon: Icon(Icons.refresh, color: NebulaTheme.textSubtle),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditDialog(),
          backgroundColor: Theme.of(context).colorScheme.primary,
          icon: const Icon(Icons.person_add, color: Colors.black),
          label: const Text('Add User', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        body: usersProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Dashboard Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monitoring real-time performance across the CluckTogether ecosystem.',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          // Metrics Grid
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  title: 'Total Users',
                                  value: totalUsers.toString(),
                                  icon: Icons.groups,
                                  color: Colors.purpleAccent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _MetricCard(
                                  title: 'Admins',
                                  value: adminCount.toString(),
                                  icon: Icons.admin_panel_settings,
                                  color: Colors.pinkAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _MetricCard(
                            title: 'Total Games Played',
                            value: totalGamesCount.toString(),
                            icon: Icons.sports_esports,
                            color: Colors.cyanAccent,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // User Management Section Title & Search
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(color: NebulaTheme.text.withValues(alpha: 0.1), height: 40),
                          Text('User Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: NebulaTheme.text)),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search by username or email...',
                              prefixIcon: Icon(Icons.search, color: NebulaTheme.textSubtle.withValues(alpha: 0.6)),
                              filled: true,
                              fillColor: NebulaTheme.text.withValues(alpha: 0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: NebulaTheme.textSubtle.withValues(alpha: 0.6)),
                                      onPressed: () => setState(() {
                                        _searchQuery = '';
                                        _currentPage = 0;
                                      }),
                                    )
                                  : null,
                            ),
                            style: TextStyle(color: NebulaTheme.text),
                            onChanged: (value) => setState(() {
                              _searchQuery = value;
                              _currentPage = 0;
                            }),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // User List
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final u = paginatedUsers[i];
                           return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: NebulaTheme.text.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: NebulaTheme.text.withValues(alpha: 0.1)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: u.role == 'admin' ? Colors.pinkAccent.withOpacity(0.2) : Colors.purpleAccent.withOpacity(0.2),
                                child: Icon(
                                  u.role == 'admin' ? Icons.shield : Icons.person,
                                  color: u.role == 'admin' ? Colors.pinkAccent : Colors.purpleAccent,
                                ),
                              ),
                              title: Text(u.username, style: TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.bold)),
                              subtitle: Text('${u.email} • Level ${u.level}', style: TextStyle(color: NebulaTheme.textSubtle)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () => _openEditDialog(user: u),
                                    icon: Icon(Icons.edit, color: NebulaTheme.textSubtle),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    onPressed: () => _confirmDelete(u),
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: paginatedUsers.length,
                      ),
                    ),
                  ),

                  // Pagination
                  if (totalPages > 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left, color: NebulaTheme.text),
                              onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: NebulaTheme.text.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Page ${_currentPage + 1} of $totalPages', style: TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right, color: NebulaTheme.text),
                              onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                  // Bottom padding for FAB
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: NebulaTheme.textSubtle, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: NebulaTheme.text, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


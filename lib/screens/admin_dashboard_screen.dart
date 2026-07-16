import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/post_provider.dart';
import '../providers/user_provider.dart';
import '../services/user_service.dart';
import '../widgets/role_guard.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  // Post management state
  String _postSearchQuery = '';
  int _postCurrentPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
      context.read<PostProvider>().fetchPosts(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── User management ───────────────────────────────────────

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

  // ─── Post management ───────────────────────────────────────

  Future<void> _confirmDeletePost(PostModel post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete post?'),
        content: Text('Delete post by ${post.authorName}?\n\n"${post.content.length > 80 ? '${post.content.substring(0, 80)}...' : post.content}"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<PostProvider>().deletePost(post.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: const ['admin'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Command Center', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          actions: [
            IconButton(
              tooltip: 'Sync Data',
              onPressed: () {
                context.read<UserProvider>().fetchUsers();
                context.read<PostProvider>().fetchPosts(refresh: true);
              },
              icon: const Icon(Icons.refresh, color: Colors.white70),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.purpleAccent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.article), text: 'Posts'),
            ],
          ),
        ),
        floatingActionButton: ListenableBuilder(
          listenable: _tabController,
          builder: (context, _) {
            if (_tabController.index == 0) {
              return FloatingActionButton.extended(
                onPressed: () => _openEditDialog(),
                backgroundColor: Theme.of(context).colorScheme.primary,
                icon: const Icon(Icons.person_add, color: Colors.black),
                label: const Text('Add User', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildUsersTab(),
            _buildPostsTab(),
          ],
        ),
      ),
    );
  }

  // ─── Users Tab ─────────────────────────────────────────────

  Widget _buildUsersTab() {
    final usersProvider = context.watch<UserProvider>();
    final allUsers = usersProvider.users;

    final filteredUsers = allUsers.where((u) {
      final query = _searchQuery.toLowerCase();
      return u.username.toLowerCase().contains(query) || u.email.toLowerCase().contains(query);
    }).toList();

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

    if (usersProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        // Dashboard Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monitoring real-time performance across the NebulaPlay ecosystem.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
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

        // Search
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.white10, height: 40),
                const Text('User Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by username or email...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () => setState(() {
                              _searchQuery = '';
                              _currentPage = 0;
                            }),
                          )
                        : null,
                  ),
                  style: const TextStyle(color: Colors.white),
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
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: u.role == 'admin' ? Colors.pinkAccent.withValues(alpha: 0.2) : Colors.purpleAccent.withValues(alpha: 0.2),
                      child: Icon(
                        u.role == 'admin' ? Icons.shield : Icons.person,
                        color: u.role == 'admin' ? Colors.pinkAccent : Colors.purpleAccent,
                      ),
                    ),
                    title: Text(u.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('${u.email} • Level ${u.level}', style: const TextStyle(color: Colors.white54)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => _openEditDialog(user: u),
                          icon: const Icon(Icons.edit, color: Colors.white70),
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
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Page ${_currentPage + 1} of $totalPages', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                  ),
                ],
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // ─── Posts Tab ─────────────────────────────────────────────

  Widget _buildPostsTab() {
    final postProvider = context.watch<PostProvider>();
    final allPosts = postProvider.posts;

    final filteredPosts = allPosts.where((p) {
      final query = _postSearchQuery.toLowerCase();
      return p.authorName.toLowerCase().contains(query) || p.content.toLowerCase().contains(query);
    }).toList();

    final totalPages = (filteredPosts.length / _itemsPerPage).ceil();
    if (_postCurrentPage >= totalPages && totalPages > 0) {
      _postCurrentPage = totalPages - 1;
    }

    final startIndex = _postCurrentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < filteredPosts.length)
        ? startIndex + _itemsPerPage
        : filteredPosts.length;
    final paginatedPosts = filteredPosts.sublist(startIndex, endIndex);

    if (postProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Total Posts',
                        value: allPosts.length.toString(),
                        icon: Icons.article,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MetricCard(
                        title: 'Total Likes',
                        value: allPosts.fold<int>(0, (s, p) => s + p.likesCount).toString(),
                        icon: Icons.favorite,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                const Text('Post Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by author or content...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    suffixIcon: _postSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () => setState(() {
                              _postSearchQuery = '';
                              _postCurrentPage = 0;
                            }),
                          )
                        : null,
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => setState(() {
                    _postSearchQuery = value;
                    _postCurrentPage = 0;
                  }),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Post List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final p = paginatedPosts[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        p.authorAvatar.isNotEmpty ? p.authorAvatar : 'https://i.pravatar.cc/150?img=12',
                      ),
                      onBackgroundImageError: (_, _a) {},
                    ),
                    title: Text(p.authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          p.content.length > 100 ? '${p.content.substring(0, 100)}...' : p.content,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.redAccent.withValues(alpha: 0.7), size: 14),
                            const SizedBox(width: 4),
                            Text('${p.likesCount}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(width: 12),
                            Icon(Icons.chat_bubble, color: Colors.blueAccent.withValues(alpha: 0.7), size: 14),
                            const SizedBox(width: 4),
                            Text('${p.commentsCount}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _confirmDeletePost(p),
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                    ),
                  ),
                );
              },
              childCount: paginatedPosts.length,
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
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _postCurrentPage > 0 ? () => setState(() => _postCurrentPage--) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Page ${_postCurrentPage + 1} of $totalPages', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _postCurrentPage < totalPages - 1 ? () => setState(() => _postCurrentPage++) : null,
                  ),
                ],
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ─── Metric Card ─────────────────────────────────────────────

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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

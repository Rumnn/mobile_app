import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// A wrapper widget that acts as a role-based navigation guard.
/// It verifies if the current user has the required roles.
/// If they don't, it displays the [fallback] widget instead of the [child].
class RoleGuard extends StatelessWidget {
  final List<String> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;

    if (currentUser == null || !allowedRoles.contains(currentUser.role)) {
      return fallback ??
          Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: const Center(
              child: Text(
                'Forbidden: Insufficient permissions.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          );
    }

    return child;
  }
}

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService;

  UserProvider({UserService? userService}) : _userService = userService ?? UserService();

  List<UserModel> _users = const [];
  List<UserModel> _friends = const [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get users => _users;
  List<UserModel> get friends => _friends;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUsers() async {
    _setLoading(true);
    try {
      _error = null;
      _users = await _userService.getUsers();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchFriends() async {
    _setLoading(true);
    try {
      _error = null;
      _friends = await _userService.getFriends();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserModel> updateUser(String id, Map<String, dynamic> payload) async {
    _setLoading(true);
    try {
      _error = null;
      final updated = await _userService.updateUser(id, payload);
      _users = _users.map((u) => u.id == updated.id ? updated : u).toList();
      return updated;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteUser(String id) async {
    _setLoading(true);
    try {
      _error = null;
      await _userService.deleteUser(id);
      _users = _users.where((u) => u.id != id).toList();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}


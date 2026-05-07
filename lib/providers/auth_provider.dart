import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService}) : _authService = authService ?? AuthService();

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => (_token != null && _token!.isNotEmpty);
  bool get isAdmin => _currentUser?.role == 'admin';

  Future<void> init() async {
    _token = await _authService.getSavedToken();
    _currentUser = await _authService.getSavedUser();
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      _error = null;
      final result = await _authService.login(email: email, password: password);
      _token = result.token;
      _currentUser = result.user;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({required String username, required String email, required String password}) async {
    _setLoading(true);
    try {
      _error = null;
      final result = await _authService.register(username: username, email: email, password: password);
      _token = result.token;
      _currentUser = result.user;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> setCurrentUser(UserModel user) async {
    _currentUser = user;
    await _authService.saveUser(user);
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}


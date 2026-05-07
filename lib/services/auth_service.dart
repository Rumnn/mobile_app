import '../models/user_model.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthResult {
  final String token;
  final UserModel user;

  const AuthResult({required this.token, required this.user});
}

class AuthService {
  final ApiClient _api;
  final TokenStorage _tokenStorage;

  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage(),
        _api = apiClient ?? ApiClient(tokenStorage: tokenStorage);

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final envelope = await _api.post(
      '/auth/register',
      authorized: false,
      body: {
        'username': username,
        'email': email,
        'password': password,
      },
    );

    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final token = (data['token'] ?? '') as String;
    final userJson = (data['user'] as Map<String, dynamic>?) ?? {};
    final user = UserModel.fromJson(userJson);

    await _tokenStorage.saveToken(token);
    await _tokenStorage.saveRole(user.role);
    await _tokenStorage.saveUser(user);

    return AuthResult(token: token, user: user);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final envelope = await _api.post(
      '/auth/login',
      authorized: false,
      body: {
        'email': email,
        'password': password,
      },
    );

    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final token = (data['token'] ?? '') as String;
    final userJson = (data['user'] as Map<String, dynamic>?) ?? {};
    final user = UserModel.fromJson(userJson);

    await _tokenStorage.saveToken(token);
    await _tokenStorage.saveRole(user.role);
    await _tokenStorage.saveUser(user);

    return AuthResult(token: token, user: user);
  }

  Future<void> logout() async {
    await _tokenStorage.clearToken();
    await _tokenStorage.clearRole();
    await _tokenStorage.clearUser();
  }

  Future<String?> getSavedToken() => _tokenStorage.getToken();
  Future<String?> getSavedRole() => _tokenStorage.getRole();
  Future<UserModel?> getSavedUser() => _tokenStorage.getUser();

  Future<void> saveUser(UserModel user) => _tokenStorage.saveUser(user);
}


import '../models/user_model.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _api;

  UserService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<UserModel> createUser(Map<String, dynamic> payload) async {
    final envelope = await _api.post('/users', body: payload);
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final userJson = (data['user'] as Map<String, dynamic>?) ?? {};
    return UserModel.fromJson(userJson);
  }

  Future<List<UserModel>> getUsers() async {
    final envelope = await _api.get('/users');
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final usersJson = (data['users'] as List<dynamic>?) ?? const [];
    return usersJson.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UserModel>> getFriends() async {
    final envelope = await _api.get('/users/friends');
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final friendsJson = (data['friends'] as List<dynamic>?) ?? const [];
    return friendsJson.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserModel> getUserById(String id) async {
    final envelope = await _api.get('/users/$id');
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final userJson = (data['user'] as Map<String, dynamic>?) ?? {};
    return UserModel.fromJson(userJson);
  }

  Future<UserModel> updateUser(String id, Map<String, dynamic> payload) async {
    final envelope = await _api.put('/users/$id', body: payload);
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final userJson = (data['user'] as Map<String, dynamic>?) ?? {};
    return UserModel.fromJson(userJson);
  }

  Future<void> deleteUser(String id) async {
    await _api.delete('/users/$id');
  }
}


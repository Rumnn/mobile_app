import 'api_client.dart';

class FollowService {
  final ApiClient _api;

  FollowService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> follow(String userId) async {
    final envelope = await _api.post('/users/$userId/follow');
    return (envelope['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> unfollow(String userId) async {
    final envelope = await _api.delete('/users/$userId/follow');
    return (envelope['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<bool> checkFollowing(String userId) async {
    final envelope = await _api.get('/users/$userId/follow/check');
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    return (data['isFollowing'] ?? false) as bool;
  }

  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    final envelope = await _api.get('/users/$userId/followers');
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final list = (data['followers'] as List<dynamic>?) ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    final envelope = await _api.get('/users/$userId/following');
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final list = (data['following'] as List<dynamic>?) ?? [];
    return list.cast<Map<String, dynamic>>();
  }
}

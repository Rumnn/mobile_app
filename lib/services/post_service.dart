import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'api_client.dart';

class PostService {
  final ApiClient _api;

  PostService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<PostModel>> getPosts({int page = 1, int limit = 20}) async {
    final envelope = await _api.get('/posts?page=$page&limit=$limit');
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final postsJson = (data['posts'] as List<dynamic>?) ?? const [];
    return postsJson
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PostModel> createPost(String content, {String? imageURL, String? videoURL}) async {
    final envelope = await _api.post('/posts', body: {
      'content': content,
      if (imageURL != null && imageURL.isNotEmpty) 'imageURL': imageURL,
      if (videoURL != null && videoURL.isNotEmpty) 'videoURL': videoURL,
    });
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final postJson = (data['post'] as Map<String, dynamic>?) ?? {};
    return PostModel.fromJson(postJson);
  }

  Future<PostModel> updatePost(String id, {String? content, String? imageURL, String? videoURL}) async {
    final body = <String, dynamic>{};
    if (content != null) body['content'] = content;
    if (imageURL != null) body['imageURL'] = imageURL;
    if (videoURL != null) body['videoURL'] = videoURL;

    final envelope = await _api.put('/posts/$id', body: body);
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final postJson = (data['post'] as Map<String, dynamic>?) ?? {};
    return PostModel.fromJson(postJson);
  }

  Future<void> deletePost(String id) async {
    await _api.delete('/posts/$id');
  }

  Future<Map<String, dynamic>> toggleLike(String postId) async {
    final envelope = await _api.post('/posts/$postId/like');
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    return {
      'isLiked': data['isLiked'] ?? false,
      'likesCount': data['likesCount'] ?? 0,
    };
  }

  Future<List<CommentModel>> getComments(String postId, {int page = 1}) async {
    final envelope = await _api.get('/posts/$postId/comments?page=$page');
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final commentsJson = (data['comments'] as List<dynamic>?) ?? const [];
    return commentsJson
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommentModel> addComment(String postId, String content) async {
    final envelope = await _api.post('/posts/$postId/comments', body: {
      'content': content,
    });
    final data = (envelope['data'] as Map<String, dynamic>?) ?? {};
    final commentJson = (data['comment'] as Map<String, dynamic>?) ?? {};
    return CommentModel.fromJson(commentJson);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _api.delete('/posts/$postId/comments/$commentId');
  }
}

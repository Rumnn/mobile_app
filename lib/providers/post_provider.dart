import 'package:flutter/foundation.dart';

import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/post_service.dart';

class PostProvider extends ChangeNotifier {
  final PostService _postService;

  PostProvider({PostService? postService})
      : _postService = postService ?? PostService();

  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }
    if (_currentPage == 1) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    notifyListeners();

    try {
      _error = null;
      final newPosts = await _postService.getPosts(page: _currentPage);
      if (refresh || _currentPage == 1) {
        _posts = newPosts;
      } else {
        _posts = [..._posts, ...newPosts];
      }
      _hasMore = newPosts.length >= 20;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    await fetchPosts();
  }

  Future<PostModel?> createPost(String content, {String? imageURL}) async {
    try {
      _error = null;
      final post = await _postService.createPost(content, imageURL: imageURL);
      _posts.insert(0, post);
      notifyListeners();
      return post;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updatePost(String id, {String? content, String? imageURL}) async {
    try {
      _error = null;
      final updated = await _postService.updatePost(id, content: content, imageURL: imageURL);
      final index = _posts.indexWhere((p) => p.id == id);
      if (index != -1) {
        _posts[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePost(String id) async {
    try {
      _error = null;
      await _postService.deletePost(id);
      _posts.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleLike(String postId) async {
    // Optimistic update
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final wasLiked = post.isLiked;
    post.isLiked = !wasLiked;
    post.likesCount += wasLiked ? -1 : 1;
    notifyListeners();

    try {
      final result = await _postService.toggleLike(postId);
      post.isLiked = result['isLiked'] as bool;
      post.likesCount = result['likesCount'] as int;
      notifyListeners();
    } catch (e) {
      // Rollback
      post.isLiked = wasLiked;
      post.likesCount += wasLiked ? 1 : -1;
      notifyListeners();
    }
  }

  // ─── Comments ───────────────────────────────────────────

  Future<List<CommentModel>> getComments(String postId, {int page = 1}) async {
    try {
      return await _postService.getComments(postId, page: page);
    } catch (e) {
      return [];
    }
  }

  Future<CommentModel?> addComment(String postId, String content) async {
    try {
      final comment = await _postService.addComment(postId, content);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index].commentsCount += 1;
        notifyListeners();
      }
      return comment;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      await _postService.deleteComment(postId, commentId);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index].commentsCount =
            (_posts[index].commentsCount - 1).clamp(0, 999999);
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

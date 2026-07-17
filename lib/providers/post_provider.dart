import 'package:flutter/foundation.dart';

import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/post_service.dart';
import '../services/socket_service.dart';

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

  // Named handlers so we can remove exactly our own listeners, not others'
  void Function(dynamic)? _hdlPostCreated;
  void Function(dynamic)? _hdlPostUpdated;
  void Function(dynamic)? _hdlPostDeleted;
  void Function(dynamic)? _hdlLikesUpdated;
  void Function(dynamic)? _hdlCommentAdded;
  void Function(dynamic)? _hdlCommentDeleted;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;

  void initSocketListeners() {
    final socket = SocketService.instance;

    // Remove only our own previous handlers (not handlers from _PostCardState)
    if (_hdlPostCreated != null) socket.off('post_created', _hdlPostCreated);
    if (_hdlPostUpdated != null) socket.off('post_updated', _hdlPostUpdated);
    if (_hdlPostDeleted != null) socket.off('post_deleted', _hdlPostDeleted);
    if (_hdlLikesUpdated != null) socket.off('post_likes_updated', _hdlLikesUpdated);
    if (_hdlCommentAdded != null) socket.off('comment_added', _hdlCommentAdded);
    if (_hdlCommentDeleted != null) socket.off('comment_deleted', _hdlCommentDeleted);

    _hdlPostCreated = (data) {
      if (data == null || data['post'] == null) return;
      try {
        final newPost = PostModel.fromJson(Map<String, dynamic>.from(data['post'] as Map));
        if (!_posts.any((p) => p.id == newPost.id)) {
          _posts.insert(0, newPost);
          notifyListeners();
        }
      } catch (_) {}
    };

    _hdlPostUpdated = (data) {
      if (data == null || data['post'] == null) return;
      try {
        final updatedPost = PostModel.fromJson(Map<String, dynamic>.from(data['post'] as Map));
        final idx = _posts.indexWhere((p) => p.id == updatedPost.id);
        if (idx != -1) {
          _posts[idx] = updatedPost;
          notifyListeners();
        }
      } catch (_) {}
    };

    _hdlPostDeleted = (data) {
      if (data == null || data['postId'] == null) return;
      final postId = data['postId'].toString();
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
    };

    _hdlLikesUpdated = (data) {
      if (data == null || data['postId'] == null) return;
      final postId = data['postId'].toString();
      final likesCount = (data['likesCount'] ?? 0) as int;
      final idx = _posts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        _posts[idx].likesCount = likesCount;
        notifyListeners();
      }
    };

    _hdlCommentAdded = (data) {
      if (data == null || data['postId'] == null) return;
      final postId = data['postId'].toString();
      final commentsCount = (data['commentsCount'] ?? 0) as int;
      final idx = _posts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        _posts[idx].commentsCount = commentsCount;
        notifyListeners();
      }
    };

    _hdlCommentDeleted = (data) {
      if (data == null || data['postId'] == null) return;
      final postId = data['postId'].toString();
      final commentsCount = (data['commentsCount'] ?? 0) as int;
      final idx = _posts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        _posts[idx].commentsCount = commentsCount;
        notifyListeners();
      }
    };

    socket.on('post_created', _hdlPostCreated!);
    socket.on('post_updated', _hdlPostUpdated!);
    socket.on('post_deleted', _hdlPostDeleted!);
    socket.on('post_likes_updated', _hdlLikesUpdated!);
    socket.on('comment_added', _hdlCommentAdded!);
    socket.on('comment_deleted', _hdlCommentDeleted!);
  }

  void disposeSocketListeners() {
    final socket = SocketService.instance;
    if (_hdlPostCreated != null) socket.off('post_created', _hdlPostCreated);
    if (_hdlPostUpdated != null) socket.off('post_updated', _hdlPostUpdated);
    if (_hdlPostDeleted != null) socket.off('post_deleted', _hdlPostDeleted);
    if (_hdlLikesUpdated != null) socket.off('post_likes_updated', _hdlLikesUpdated);
    if (_hdlCommentAdded != null) socket.off('comment_added', _hdlCommentAdded);
    if (_hdlCommentDeleted != null) socket.off('comment_deleted', _hdlCommentDeleted);
  }

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

  Future<PostModel?> createPost(String content, {String? imageURL, String? videoURL}) async {
    try {
      _error = null;
      final post = await _postService.createPost(content, imageURL: imageURL, videoURL: videoURL);
      _posts.insert(0, post);
      notifyListeners();
      return post;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updatePost(String id, {String? content, String? imageURL, String? videoURL}) async {
    try {
      _error = null;
      final updated = await _postService.updatePost(id, content: content, imageURL: imageURL, videoURL: videoURL);
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

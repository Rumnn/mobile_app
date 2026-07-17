import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../services/follow_service.dart';
import '../services/socket_service.dart';
import '../services/upload_service.dart';
import '../widgets/nebula_theme.dart';

class NebulaSocialScreen extends StatefulWidget {
  const NebulaSocialScreen({super.key});

  @override
  State<NebulaSocialScreen> createState() => _NebulaSocialScreenState();
}

class _NebulaSocialScreenState extends State<NebulaSocialScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPosts(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<PostProvider>().loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<PostProvider>().fetchPosts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();

    if (postProvider.isLoading && postProvider.posts.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: NebulaTheme.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: NebulaTheme.primary,
      backgroundColor: NebulaTheme.surface,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: postProvider.posts.length + 2, // +1 composer, +1 loading
        separatorBuilder: (_, _a) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Composer(
              onPost: (content, imageURL, videoURL) async {
                await context.read<PostProvider>().createPost(
                      content,
                      imageURL: imageURL,
                      videoURL: videoURL,
                    );
              },
            );
          }
          if (index == postProvider.posts.length + 1) {
            if (postProvider.isLoadingMore) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: NebulaTheme.primary),
                ),
              );
            }
            return const SizedBox.shrink();
          }
          final post = postProvider.posts[index - 1];
          return _PostCard(key: ValueKey(post.id), post: post);
        },
      ),
    );
  }
}

// ─── Composer ─────────────────────────────────────────────────

class _Composer extends StatefulWidget {
  final Future<void> Function(String content, String? imageURL, String? videoURL) onPost;
  const _Composer({required this.onPost});

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();
  final _uploadService = UploadService();

  // Picked file data (bytes + name) — works on Web & Mobile
  Uint8List? _imageBytes;
  String? _imageName;
  Uint8List? _videoBytes;
  String? _videoName;

  bool _isUploading = false;
  bool _isPosting = false;
  String? _uploadError;

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // always load bytes (needed for web)
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      setState(() {
        _imageBytes = file.bytes;
        _imageName = file.name;
        _videoBytes = null;
        _videoName = null;
        _uploadError = null;
      });
    } catch (e) {
      setState(() => _uploadError = 'Không chọn được ảnh: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      setState(() {
        _videoBytes = file.bytes;
        _videoName = file.name;
        _imageBytes = null;
        _imageName = null;
        _uploadError = null;
      });
    } catch (e) {
      setState(() => _uploadError = 'Không chọn được video: $e');
    }
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty || _isPosting) return;
    setState(() { _isPosting = true; _uploadError = null; });

    String? imageURL;
    String? videoURL;

    try {
      if (_imageBytes != null && _imageName != null) {
        setState(() => _isUploading = true);
        imageURL = await _uploadService.uploadImage(_imageBytes!, _imageName!);
        setState(() => _isUploading = false);
      } else if (_videoBytes != null && _videoName != null) {
        setState(() => _isUploading = true);
        videoURL = await _uploadService.uploadVideo(_videoBytes!, _videoName!);
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() {
        _isPosting = false;
        _isUploading = false;
        _uploadError = 'Upload thất bại: ${e.toString()}';
      });
      return;
    }

    await widget.onPost(_controller.text, imageURL, videoURL);
    _controller.clear();
    setState(() {
      _isPosting = false;
      _imageBytes = null; _imageName = null;
      _videoBytes = null; _videoName = null;
    });
    if (mounted) FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final avatarUrl = user?.avatarURL ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: NebulaTheme.glass(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(
                  avatarUrl.isNotEmpty
                      ? avatarUrl
                      : 'https://i.pravatar.cc/150?img=12',
                ),
                onBackgroundImageError: (_, _a) {},
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: NebulaTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: NebulaTheme.text),
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText:
                          'Bạn đang nghĩ gì, ${user?.username ?? 'Gamer'}?',
                      hintStyle: TextStyle(color: NebulaTheme.textSubtle),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_imageBytes != null) ...[
            const SizedBox(height: 10),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    _imageBytes!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() { _imageBytes = null; _imageName = null; }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_videoBytes != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: NebulaTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NebulaTheme.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.video_file_rounded, color: NebulaTheme.primary, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _videoName ?? 'video',
                          style: TextStyle(color: NebulaTheme.text, fontSize: 13,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('Video đã chọn • ${(_videoBytes!.length / (1024 * 1024)).toStringAsFixed(1)} MB',
                            style: TextStyle(color: NebulaTheme.textSubtle, fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() { _videoBytes = null; _videoName = null; }),
                    child: Icon(Icons.close, color: NebulaTheme.textSubtle, size: 20),
                  ),
                ],
              ),
            ),
          ],
          if (_uploadError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_uploadError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _ToolbarBtn(
                    icon: Icons.image_outlined,
                    label: 'Ảnh',
                    active: _imageBytes != null,
                    onTap: _pickImage,
                  ),
                  const SizedBox(width: 6),
                  _ToolbarBtn(
                    icon: Icons.video_library_outlined,
                    label: 'Video',
                    active: _videoBytes != null,
                    onTap: _pickVideo,
                  ),
                ],
              ),
              InkWell(
                onTap: (_isPosting || _isUploading) ? null : _submit,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                        colors: [NebulaTheme.primary, NebulaTheme.secondary]),
                    boxShadow: [
                      BoxShadow(
                        color: NebulaTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 10, spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: (_isPosting || _isUploading)
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isUploading ? 'Uploading...' : 'Đang đăng...',
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ],
                        )
                      : const Text('Đăng',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToolbarBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? NebulaTheme.primary : NebulaTheme.secondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Post Card ────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final PostModel post;
  const _PostCard({super.key, required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _showCommentBox = false;
  bool _showComments = false;
  List<CommentModel> _comments = [];
  bool _loadingComments = false;
  final _commentCtrl = TextEditingController();
  final FollowService _followService = FollowService();
  bool? _isFollowing;

  @override
  void initState() {
    super.initState();
    // Listen for real-time comment addition and deletion
    SocketService.instance.on('comment_added', _onCommentAdded);
    SocketService.instance.on('comment_deleted', _onCommentDeleted);
  }

  @override
  void dispose() {
    SocketService.instance.off('comment_added', _onCommentAdded);
    SocketService.instance.off('comment_deleted', _onCommentDeleted);
    _commentCtrl.dispose();
    super.dispose();
  }

  void _onCommentAdded(dynamic data) {
    if (data == null || data['postId'] != widget.post.id) return;
    try {
      final newComment = CommentModel.fromJson(Map<String, dynamic>.from(data['comment'] as Map));
      if (mounted) {
        setState(() {
          if (!_comments.any((c) => c.id == newComment.id)) {
            _comments.insert(0, newComment);
          }
        });
      }
    } catch (_) {}
  }

  void _onCommentDeleted(dynamic data) {
    if (data == null || data['postId'] != widget.post.id) return;
    final commentId = data['commentId']?.toString();
    if (mounted) {
      setState(() {
        _comments.removeWhere((c) => c.id == commentId);
      });
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _toggleFollow() async {
    final post = widget.post;
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null || post.authorId == currentUser.id) return;

    try {
      if (_isFollowing == true) {
        await _followService.unfollow(post.authorId);
        if (mounted) setState(() => _isFollowing = false);
      } else {
        await _followService.follow(post.authorId);
        if (mounted) setState(() => _isFollowing = true);
      }
    } catch (_) {}
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    final comments =
        await context.read<PostProvider>().getComments(widget.post.id);
    if (mounted) {
      setState(() {
        _comments = comments;
        _loadingComments = false;
      });
    }
  }

  Future<void> _submitComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    final text = _commentCtrl.text.trim();
    _commentCtrl.clear();
    FocusScope.of(context).unfocus();
    // Only call API — the socket 'comment_added' event will add the comment to
    // the list (with dedup) so we never insert it twice.
    await context.read<PostProvider>().addComment(widget.post.id, text);
  }

  void _showPostMenu() {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;
    final isOwner = widget.post.authorId == currentUser.id;
    final isAdmin = currentUser.role == 'admin';
    if (!isOwner && !isAdmin) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: NebulaTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isOwner)
              ListTile(
                leading:
                    Icon(Icons.edit, color: NebulaTheme.primary),
                title: Text('Chỉnh sửa bài viết',
                    style: TextStyle(color: NebulaTheme.text)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog();
                },
              ),
            ListTile(
              leading:
                  Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Xóa bài viết',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog() async {
    final editCtrl = TextEditingController(text: widget.post.content);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NebulaTheme.surface,
        title: Text('Chỉnh sửa bài viết',
            style: TextStyle(color: NebulaTheme.text)),
        content: TextField(
          controller: editCtrl,
          maxLines: 5,
          style: TextStyle(color: NebulaTheme.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: NebulaTheme.surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, editCtrl.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    editCtrl.dispose();
    if (result != null && result.isNotEmpty && mounted) {
      await context
          .read<PostProvider>()
          .updatePost(widget.post.id, content: result);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NebulaTheme.surface,
        title: Text('Xóa bài viết?',
            style: TextStyle(color: NebulaTheme.text)),
        content: Text(
          'Bạn có chắc muốn xóa bài viết này? Hành động này không thể hoàn tác.',
          style: TextStyle(color: NebulaTheme.textSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final deleted =
          await context.read<PostProvider>().deletePost(widget.post.id);
      if (deleted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài viết')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final currentUser = context.watch<AuthProvider>().currentUser;
    final isOwner = currentUser != null && post.authorId == currentUser.id;
    final isAdmin = currentUser?.role == 'admin';
    final canManage = isOwner || isAdmin;

    return Container(
      decoration: NebulaTheme.glass(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(
                  post.authorAvatar.isNotEmpty
                      ? post.authorAvatar
                      : 'https://i.pravatar.cc/150?img=12',
                ),
                onBackgroundImageError: (_, _a) {},
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName,
                        style: TextStyle(
                            color: NebulaTheme.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Text(_timeAgo(post.createdAt),
                        style: TextStyle(
                            color: NebulaTheme.textSubtle, fontSize: 12)),
                  ],
                ),
              ),
              if (!isOwner)
                OutlinedButton(
                  onPressed: _toggleFollow,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: _isFollowing == true
                            ? NebulaTheme.textSubtle
                            : NebulaTheme.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isFollowing == true ? 'Đang theo dõi' : 'Theo dõi',
                    style: TextStyle(
                        color: _isFollowing == true
                            ? NebulaTheme.textSubtle
                            : NebulaTheme.primary,
                        fontSize: 12),
                  ),
                ),
              if (canManage)
                IconButton(
                  onPressed: _showPostMenu,
                  icon: Icon(Icons.more_vert,
                      color: NebulaTheme.textSubtle, size: 20),
                ),
            ],
          ),

          // ── Content
          const SizedBox(height: 12),
          Text(post.content,
              style:
                  TextStyle(color: NebulaTheme.text, fontSize: 14)),

          // ── Image
          if (post.imageURL.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                post.imageURL,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _a, _b) => const SizedBox.shrink(),
              ),
            ),
          ],

          // ── Video
          if (post.videoURL.isNotEmpty) ...[
            const SizedBox(height: 12),
            _VideoPreview(url: post.videoURL),
          ],

          // ── Actions
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: () =>
                    context.read<PostProvider>().toggleLike(post.id),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                          post.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: post.isLiked
                              ? Colors.redAccent
                              : NebulaTheme.textSubtle,
                          size: 22),
                      const SizedBox(width: 6),
                      Text('${post.likesCount}',
                          style: TextStyle(
                              color: post.isLiked
                                  ? Colors.redAccent
                                  : NebulaTheme.textSubtle,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {
                  setState(() {
                    _showCommentBox = !_showCommentBox;
                    if (_showCommentBox && !_showComments) {
                      _showComments = true;
                      _loadComments();
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          color: NebulaTheme.textSubtle, size: 22),
                      const SizedBox(width: 6),
                      Text('${post.commentsCount}',
                          style: TextStyle(
                              color: NebulaTheme.textSubtle,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.share_outlined,
                    color: NebulaTheme.textSubtle, size: 22),
              ),
            ],
          ),

          // ── Comments section
          if (_showCommentBox) ...[
            const Divider(color: Colors.white10, height: 24),

            // Comment list
            if (_loadingComments)
              Padding(
                padding: EdgeInsets.all(8),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: NebulaTheme.primary),
                  ),
                ),
              )
            else if (_comments.isNotEmpty)
              ..._comments.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(
                            c.authorAvatar.isNotEmpty
                                ? c.authorAvatar
                                : 'https://i.pravatar.cc/150?img=12',
                          ),
                          onBackgroundImageError: (_, __) {},
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: NebulaTheme.surfaceHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(c.authorName,
                                        style: TextStyle(
                                            color: NebulaTheme.text,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Text(_timeAgo(c.createdAt),
                                        style: TextStyle(
                                            color: NebulaTheme.textSubtle,
                                            fontSize: 10)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(c.content,
                                    style: TextStyle(
                                        color: NebulaTheme.text,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        if (currentUser != null &&
                            (c.authorId == currentUser.id ||
                                currentUser.role == 'admin'))
                          IconButton(
                            iconSize: 16,
                            onPressed: () async {
                              final deleted = await context
                                  .read<PostProvider>()
                                  .deleteComment(post.id, c.id);
                              if (deleted && mounted) {
                                setState(() {
                                  _comments.removeWhere(
                                      (cm) => cm.id == c.id);
                                });
                              }
                            },
                            icon: Icon(Icons.close,
                                color: NebulaTheme.textSubtle, size: 14),
                          ),
                      ],
                    ),
                  )),

            // Comment input
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: NebulaTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(20)),
                    child: TextField(
                      controller: _commentCtrl,
                      style: TextStyle(
                          color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Viết bình luận...',
                        hintStyle:
                            TextStyle(color: NebulaTheme.textSubtle),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submitComment,
                  icon:
                      Icon(Icons.send, color: NebulaTheme.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Video Preview ─────────────────────────────────────────────

class _VideoPreview extends StatelessWidget {
  final String url;
  const _VideoPreview({required this.url});

  bool _isYoutube(String u) =>
      u.contains('youtube.com') || u.contains('youtu.be');

  String? _ytThumbnail(String u) {
    final regExp = RegExp(
        r'(?:youtu\.be/|youtube\.com/(?:watch\?v=|embed/|v/|shorts/))([\w-]+)');
    final match = regExp.firstMatch(u);
    if (match != null) {
      return 'https://img.youtube.com/vi/${match.group(1)}/hqdefault.jpg';
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở link video')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = _isYoutube(url) ? _ytThumbnail(url) : null;

    return GestureDetector(
      onTap: () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (thumbnail != null)
              Image.network(
                thumbnail,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _a, _b) => _VideoPlaceholder(url: url),
              )
            else
              _VideoPlaceholder(url: url),

            // Gradient overlay
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),

            // Play button
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(color: Colors.white60, width: 2),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),

            // URL label at bottom-left
            Positioned(
              bottom: 10,
              left: 12,
              right: 12,
              child: Text(
                url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  final String url;
  const _VideoPlaceholder({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [NebulaTheme.surfaceHigh, NebulaTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_rounded,
              color: NebulaTheme.primary, size: 48),
          const SizedBox(height: 8),
          Text('Nhấn để xem video',
              style: TextStyle(
                  color: NebulaTheme.textSubtle,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../services/follow_service.dart';
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
              onPost: (content, imageURL) async {
                await context.read<PostProvider>().createPost(
                      content,
                      imageURL: imageURL,
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
  final Future<void> Function(String content, String? imageURL) onPost;
  const _Composer({required this.onPost});

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();
  final _imageController = TextEditingController();
  bool _showImageField = false;
  bool _isPosting = false;

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty || _isPosting) return;
    setState(() => _isPosting = true);
    await widget.onPost(
      _controller.text,
      _imageController.text.isNotEmpty ? _imageController.text : null,
    );
    _controller.clear();
    _imageController.clear();
    setState(() {
      _isPosting = false;
      _showImageField = false;
    });
    if (mounted) FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _imageController.dispose();
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
                      hintStyle:
                          TextStyle(color: NebulaTheme.textSubtle),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showImageField) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: NebulaTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _imageController,
                style: TextStyle(color: NebulaTheme.text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Dán URL hình ảnh...',
                  hintStyle: TextStyle(color: NebulaTheme.textSubtle),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () =>
                        setState(() => _showImageField = !_showImageField),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.image_outlined,
                              color: _showImageField
                                  ? NebulaTheme.primary
                                  : NebulaTheme.secondary,
                              size: 20),
                          const SizedBox(width: 4),
                          Text('Ảnh',
                              style: TextStyle(
                                  color: _showImageField
                                      ? NebulaTheme.primary
                                      : NebulaTheme.secondary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _isPosting ? null : _submit,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                        colors: [Color(0xFFA078FF), Color(0xFFAA0266)]),
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Đăng',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
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
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
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
    final comment = await context
        .read<PostProvider>()
        .addComment(widget.post.id, _commentCtrl.text.trim());
    if (comment != null && mounted) {
      setState(() {
        _comments.insert(0, comment);
      });
      _commentCtrl.clear();
      FocusScope.of(context).unfocus();
    }
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

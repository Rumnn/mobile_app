import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import 'nebula_theme.dart';

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostSheet(),
    );
  }

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _contentController = TextEditingController();
  final _imageController = TextEditingController();
  bool _showImageField = false;
  bool _isPosting = false;

  @override
  void dispose() {
    _contentController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPosting = true);

    final imageUrl = _imageController.text.trim();
    final postProvider = context.read<PostProvider>();
    final success = await postProvider.createPost(
      content,
      imageURL: imageUrl.isNotEmpty ? imageUrl : null,
    );

    if (mounted) {
      setState(() => _isPosting = false);
      if (success != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng bài viết thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(postProvider.error ?? 'Đăng bài viết thất bại!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final avatarUrl = user?.avatarURL ?? '';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: 20 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: NebulaTheme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: NebulaTheme.primary.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: NebulaTheme.textSubtle.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [NebulaTheme.primary, NebulaTheme.secondary],
                  ).createShader(bounds),
                  child: const Text(
                    'Tạo bài viết mới',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: NebulaTheme.textSubtle),
                ),
              ],
            ),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),

            // User Profile Row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    avatarUrl.isNotEmpty
                        ? avatarUrl
                        : 'https://i.pravatar.cc/150?img=12',
                  ),
                  onBackgroundImageError: (_, stackTrace) {},
                ),
                const SizedBox(width: 12),
                Text(
                  user?.username ?? 'Gamer',
                  style: TextStyle(
                    color: NebulaTheme.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content Text Field
            Container(
              decoration: BoxDecoration(
                color: NebulaTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                minLines: 3,
                style: TextStyle(color: NebulaTheme.text, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Bạn đang nghĩ gì, ${user?.username ?? 'Gamer'}?',
                  hintStyle: TextStyle(color: NebulaTheme.textSubtle, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Toggle Image Field button
            if (!_showImageField)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showImageField = true),
                  icon: Icon(Icons.image_outlined, color: NebulaTheme.secondary, size: 20),
                  label: Text(
                    'Thêm ảnh (URL)',
                    style: TextStyle(color: NebulaTheme.secondary),
                  ),
                ),
              ),

            // Image URL Field
            if (_showImageField) ...[
              Container(
                decoration: BoxDecoration(
                  color: NebulaTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _imageController,
                        style: TextStyle(color: NebulaTheme.text, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Nhập URL hình ảnh...',
                          hintStyle: TextStyle(color: NebulaTheme.textSubtle, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: NebulaTheme.textSubtle, size: 18),
                      onPressed: () {
                        _imageController.clear();
                        setState(() => _showImageField = false);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 10),

            // Post Button
            Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [NebulaTheme.primary, NebulaTheme.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: NebulaTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isPosting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isPosting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Đăng bài',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

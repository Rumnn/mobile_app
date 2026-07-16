import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/nebula_theme.dart';

class NebulaSocialScreen extends StatefulWidget {
  const NebulaSocialScreen({super.key});

  @override
  State<NebulaSocialScreen> createState() => _NebulaSocialScreenState();
}

class _NebulaSocialScreenState extends State<NebulaSocialScreen> {
  final List<Map<String, dynamic>> _posts = [
    {
      'id': '1',
      'user': 'NeoVibe',
      'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=400&auto=format&fit=crop',
      'time': 'Đã đăng 2 giờ trước',
      'content': 'Vừa đạt Pentakill trong trận đấu tối nay! Cảm giác thật bùng nổ 🚀 Ai muốn party tối mai không?',
      'image': 'https://images.unsplash.com/photo-1560419015-7c427e8ae5ba?q=80&w=1400&auto=format&fit=crop',
      'likes': 1200,
      'comments': 45,
      'isLiked': false,
    },
    {
      'id': '2',
      'user': 'VoidRunner',
      'avatar': 'https://i.pravatar.cc/150?img=11',
      'time': 'Vừa cập nhật',
      'content': 'Đang tìm đồng đội leo rank Bạch Kim tối nay. Cần 1 Support và 1 Tanker. Anh em nào rảnh hú mình nha!',
      'image': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=1400&auto=format&fit=crop',
      'likes': 850,
      'comments': 12,
      'isLiked': true,
    },
  ];

  void _addNewPost(String content) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || content.trim().isEmpty) return;

    setState(() {
      _posts.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'user': user.username,
        'avatar': user.avatarURL.isNotEmpty ? user.avatarURL : 'https://i.pravatar.cc/150?img=12',
        'time': 'Vừa xong',
        'content': content.trim(),
        'image': null,
        'likes': 0,
        'comments': 0,
        'isLiked': false,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: _posts.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _Composer(onPost: _addNewPost);
        }
        final post = _posts[index - 1];
        return _PostCard(
          key: ValueKey(post['id']),
          postData: post,
        );
      },
    );
  }
}

class _Composer extends StatefulWidget {
  final Function(String) onPost;
  const _Composer({required this.onPost});

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();

  void _submit() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onPost(_controller.text);
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final avatarUrl = user?.avatarURL ?? '';
    context.watch<SettingsProvider>();

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
                backgroundImage: NetworkImage(avatarUrl.isNotEmpty ? avatarUrl : 'https://i.pravatar.cc/150?img=12'),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(color: NebulaTheme.surfaceHigh, borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    controller: _controller,
                    style:       TextStyle(color: NebulaTheme.text),
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Bạn đang nghĩ gì, ${user?.username ?? 'Gamer'}?',
                      hintStyle:       TextStyle(color: NebulaTheme.textSubtle),
                      border: InputBorder.none,
                      contentPadding:       EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
                SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children:       [
                  Icon(Icons.image_outlined, color: NebulaTheme.primary, size: 20),
                  const SizedBox(width: 4),
                  Text('Ảnh', style: TextStyle(color: NebulaTheme.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                  Icon(Icons.videocam_outlined, color: NebulaTheme.secondary, size: 20),
                  const SizedBox(width: 4),
                  Text('Video', style: TextStyle(color: NebulaTheme.secondary, fontWeight: FontWeight.w600)),
                ],
              ),
              InkWell(
                onTap: _submit,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [NebulaTheme.primary, NebulaTheme.secondary],
                    ),
                  ),
                  child: Text(
                    'Đăng',
                    style: TextStyle(
                      color: NebulaTheme.primary.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final Map<String, dynamic> postData;
  const _PostCard({super.key, required this.postData});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late int likes;
  late bool isLiked;
  bool showCommentBox = false;
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    likes = widget.postData['likes'];
    isLiked = widget.postData['isLiked'];
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likes += isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.postData;
    return Container(
      decoration: NebulaTheme.glass(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(post['avatar']),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post['user'], style:       TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(post['time'], style:       TextStyle(color: NebulaTheme.textSubtle, fontSize: 12)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side:       BorderSide(color: NebulaTheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child:       Text('Theo dõi', style: TextStyle(color: NebulaTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post['content'], style:       TextStyle(color: NebulaTheme.text, fontSize: 14)),
          if (post['image'] != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(post['image'], height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: _toggleLike,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : NebulaTheme.textSubtle, size: 22),
                      const SizedBox(width: 6),
                      Text('$likes', style: TextStyle(color: isLiked ? Colors.redAccent : NebulaTheme.textSubtle, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {
                  setState(() {
                    showCommentBox = !showCommentBox;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                            Icon(Icons.chat_bubble_outline, color: NebulaTheme.textSubtle, size: 22),
                      const SizedBox(width: 6),
                      Text('${post['comments']}', style:       TextStyle(color: NebulaTheme.textSubtle, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon:       Icon(Icons.share_outlined, color: NebulaTheme.textSubtle, size: 22),
              ),
            ],
          ),
          if (showCommentBox) ...[
            Divider(color: NebulaTheme.text.withValues(alpha: 0.08), height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: NebulaTheme.surfaceHigh, borderRadius: BorderRadius.circular(20)),
                    child: TextField(
                      controller: _commentCtrl,
                      style: TextStyle(color: NebulaTheme.text, fontSize: 13),
                      decoration:       InputDecoration(
                        hintText: 'Viết bình luận...',
                        hintStyle: TextStyle(color: NebulaTheme.textSubtle),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (_commentCtrl.text.isNotEmpty) {
                      setState(() {
                        post['comments'] = post['comments'] + 1;
                        showCommentBox = false;
                      });
                      _commentCtrl.clear();
                      FocusScope.of(context).unfocus();
                    }
                  },
                  icon:       Icon(Icons.send, color: NebulaTheme.primary),
                )
              ],
            )
          ]
        ],
      ),
    );
  }
}


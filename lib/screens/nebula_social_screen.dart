import 'package:flutter/material.dart';

import '../widgets/nebula_theme.dart';

class NebulaSocialScreen extends StatelessWidget {
  const NebulaSocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: const [
        _Composer(),
        SizedBox(height: 14),
        _PostCard(
          user: 'NeoVibe',
          time: 'Đã đăng 2 giờ trước',
          content: 'Vừa đạt Pentakill trong trận đấu tối nay! Cảm giác thật bùng nổ 🚀 Ai muốn party tối mai không?',
          image: 'https://images.unsplash.com/photo-1560419015-7c427e8ae5ba?q=80&w=1400&auto=format&fit=crop',
        ),
        SizedBox(height: 14),
        _PostCard(
          user: 'VoidRunner',
          time: 'Vừa cập nhật',
          content: 'Đang tìm đồng đội leo rank Bạch Kim tối nay. Cần 1 Support và 1 Tanker. Anh em nào rảnh hú mình nha!',
          image: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=1400&auto=format&fit=crop',
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: NebulaTheme.glass(),
      child: Column(children: [
        Row(children: [
          const CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=400&auto=format&fit=crop'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(color: NebulaTheme.surfaceHigh, borderRadius: BorderRadius.circular(14)),
              child: const Text('Bạn đang nghĩ gì, Mage?', style: TextStyle(color: NebulaTheme.textSubtle)),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: const [
            Icon(Icons.image_outlined, color: NebulaTheme.secondary, size: 18),
            SizedBox(width: 4),
            Text('Ảnh', style: TextStyle(color: NebulaTheme.secondary)),
            SizedBox(width: 14),
            Icon(Icons.videocam_outlined, color: NebulaTheme.tertiary, size: 18),
            SizedBox(width: 4),
            Text('Video', style: TextStyle(color: NebulaTheme.tertiary)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(colors: [Color(0xFFA078FF), Color(0xFFAA0266)]),
            ),
            child: const Text('Đăng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String user;
  final String time;
  final String content;
  final String image;
  const _PostCard({required this.user, required this.time, required this.content, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: NebulaTheme.glass(),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=400&auto=format&fit=crop')),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user, style: const TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.w700)),
              Text(time, style: const TextStyle(color: NebulaTheme.textSubtle, fontSize: 12)),
            ]),
          ),
          OutlinedButton(onPressed: () {}, child: const Text('Theo dõi')),
        ]),
        const SizedBox(height: 10),
        Text(content, style: const TextStyle(color: NebulaTheme.textSubtle)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(image, height: 170, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.favorite_border, color: NebulaTheme.secondary),
            SizedBox(width: 4),
            Text('1.2k', style: TextStyle(color: NebulaTheme.textSubtle)),
            SizedBox(width: 18),
            Icon(Icons.chat_bubble_outline, color: NebulaTheme.textSubtle),
            SizedBox(width: 4),
            Text('45', style: TextStyle(color: NebulaTheme.textSubtle)),
            SizedBox(width: 18),
            Icon(Icons.share_outlined, color: NebulaTheme.textSubtle),
          ],
        )
      ]),
    );
  }
}


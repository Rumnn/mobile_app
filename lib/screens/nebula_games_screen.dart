import 'package:flutter/material.dart';

import '../widgets/nebula_theme.dart';
import 'sliding_puzzle_screen.dart';

class NebulaGamesScreen extends StatelessWidget {
  const NebulaGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        Container(
          height: 190,
          decoration: NebulaTheme.glass(radius: BorderRadius.circular(26)).copyWith(
            image: const DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1511512578047-dfb367046420?q=80&w=1500&auto=format&fit=crop',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _Chip(text: 'SỰ KIỆN MỚI'),
                SizedBox(height: 8),
                Text('Đại Chiến Ma Sói: Đêm Trăng Máu', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Tham gia ngay nhận x2 phần thưởng xu!', style: TextStyle(color: NebulaTheme.textSubtle)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        _sectionTitle('Trò Chơi Nổi Bật', 'Xem tất cả'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
            _GameCard(
              title: 'Sliding Puzzle',
              image: 'https://images.unsplash.com/photo-1611996515756-1d31fc370c25?q=80&w=900&auto=format&fit=crop',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SlidingPuzzleScreen())),
            ),
            const _GameCard(title: 'Ma Sói', image: 'https://images.unsplash.com/photo-1520637836862-4d197d17c50a?q=80&w=900&auto=format&fit=crop'),
            const _GameCard(title: 'Vẽ và Đoán', image: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?q=80&w=900&auto=format&fit=crop'),
            const _GameCard(title: 'Đấu Nhạc', image: 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?q=80&w=900&auto=format&fit=crop'),
            const _GameCard(title: 'Uno Online', image: 'https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?q=80&w=900&auto=format&fit=crop'),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle('Phòng Trò Chuyện', '1.2k Đang Online', accent: true),
        const SizedBox(height: 12),
        const _RoomTile(
          title: 'Hội Những Người Độc Thân',
          subtitle: '+42 đang hát',
          image: 'https://images.unsplash.com/photo-1607746882042-944635dfe10e?q=80&w=600&auto=format&fit=crop',
        ),
        const SizedBox(height: 10),
        const _RoomTile(
          title: 'Tìm Đồng Đội Ma Sói',
          subtitle: 'Sắp bắt đầu • 10/12',
          image: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=600&auto=format&fit=crop',
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, String trailing, {bool accent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: NebulaTheme.text, fontSize: 28, fontWeight: FontWeight.w700)),
        Text(trailing, style: TextStyle(color: accent ? NebulaTheme.tertiary : NebulaTheme.secondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String image;
  final VoidCallback? onTap;
  const _GameCard({required this.title, required this.image, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: NebulaTheme.glass(radius: BorderRadius.circular(24)).copyWith(
          image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
        ),
        child: Container(
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
            ),
          ),
          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  const _RoomTile({required this.title, required this.subtitle, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: NebulaTheme.glass(),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: NetworkImage(image)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.w700)),
              Text(subtitle, style: const TextStyle(color: NebulaTheme.textSubtle, fontSize: 12)),
            ]),
          ),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(backgroundColor: NebulaTheme.primary.withValues(alpha: 0.22)),
            child: const Text('Vào phòng', style: TextStyle(color: NebulaTheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: NebulaTheme.secondary.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(color: Color(0xFF3E0022), fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}


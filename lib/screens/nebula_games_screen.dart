import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../widgets/nebula_theme.dart';
import 'ludo_screen.dart';
import 'multiplayer_lobby_screen.dart';

class NebulaGamesScreen extends StatelessWidget {
  const NebulaGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Container(
            height: 190,
            decoration: NebulaTheme.glass(radius: BorderRadius.circular(26)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1511512578047-dfb367046420?q=80&w=1500&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          NebulaTheme.tertiary.withValues(alpha: 0.4),
                          NebulaTheme.primary.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _Chip(text: 'SỰ KIỆN MỚI'),
                      const SizedBox(height: 8),
                      const Text('Đại Chiến Ma Sói: Đêm Trăng Máu', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Tham gia ngay nhận x2 phần thưởng xu!', style: TextStyle(color: NebulaTheme.textSubtle)),
                    ],
                  ),
                ),
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
              badge: '⚔️ VS',
              image: 'assets/images/sliding_puzzle.png',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MultiplayerLobbyScreen())),
            ),
            _GameCard(
              title: 'Ludo Online',
              image: 'https://images.unsplash.com/photo-1606167668584-78701c57f13d?q=80&w=900&auto=format&fit=crop',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LudoScreen())),
            ),
            const _GameCard(title: 'Ma Sói', image: 'assets/images/ma_soi.png'),
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
        Text(title, style:       TextStyle(color: NebulaTheme.text, fontSize: 28, fontWeight: FontWeight.w700)),
        Text(trailing, style: TextStyle(color: accent ? NebulaTheme.tertiary : NebulaTheme.secondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String image;
  final String? badge;
  final VoidCallback? onTap;
  const _GameCard({required this.title, required this.image, this.badge, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: NebulaTheme.glass(radius: BorderRadius.circular(24)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: NebulaTheme.primary.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final imageWidget = image.startsWith('http')
        ? Image.network(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallback(),
          )
        : Image.asset(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallback(),
          );
    return imageWidget;
  }

  Widget _buildFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NebulaTheme.primary.withValues(alpha: 0.3),
            NebulaTheme.surfaceHigh.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.15,
          child: Icon(
            Icons.sports_esports,
            size: 64,
            color: NebulaTheme.text,
          ),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: NebulaTheme.primary.withValues(alpha: 0.15),
                  alignment: Alignment.center,
                  child: Text(
                    title.isNotEmpty ? title.substring(0, 1).toUpperCase() : 'R',
                    style: TextStyle(color: NebulaTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.w700)),
              Text(subtitle, style: TextStyle(color: NebulaTheme.textSubtle, fontSize: 12)),
            ]),
          ),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(backgroundColor: NebulaTheme.primary.withValues(alpha: 0.22)),
            child: Text('Vào phòng', style: TextStyle(color: NebulaTheme.primary)),
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


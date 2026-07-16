import 'package:flutter/material.dart';

import '../widgets/nebula_theme.dart';

class NebulaRoomScreen extends StatelessWidget {
  const NebulaRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: NebulaTheme.glass(),
                child:       Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('ĐANG DIỄN RA', style: TextStyle(color: NebulaTheme.tertiary, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Ma Sói: Đêm Huyền Bí', style: TextStyle(color: NebulaTheme.text, fontSize: 20, fontWeight: FontWeight.w700)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('THỜI GIAN CÒN LẠI', style: TextStyle(color: NebulaTheme.textSubtle, fontSize: 11)),
                      Text('00:42', style: TextStyle(color: NebulaTheme.secondary, fontSize: 24, fontWeight: FontWeight.w700)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _PlayersRing(),
              const SizedBox(height: 16),
                    Text('ShadowNinja: Tôi nghĩ Gamer777 là sói đó.', style: TextStyle(color: NebulaTheme.textSubtle)),
              const SizedBox(height: 6),
                    Text('CyberX: Đồng ý, tối qua thấy di chuyển lạ lắm.', style: TextStyle(color: NebulaTheme.textSubtle)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NebulaTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border:       Border(left: BorderSide(color: NebulaTheme.primary, width: 3)),
                ),
                child:       Text(
                  'Hệ thống: Đến giờ thảo luận, hãy chọn người bị tình nghi.',
                  style: TextStyle(color: NebulaTheme.primary, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 96),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: NebulaTheme.glass(radius: BorderRadius.circular(999)),
                child:       TextField(
                  style: TextStyle(color: NebulaTheme.text),
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(color: NebulaTheme.textSubtle),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _iconBubble(Icons.card_giftcard, NebulaTheme.secondary),
            const SizedBox(width: 8),
            _iconBubble(Icons.mic, NebulaTheme.primary),
          ]),
        ),
      ],
    );
  }

  Widget _iconBubble(IconData icon, Color color) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _PlayersRing extends StatelessWidget {
  const _PlayersRing();

  @override
  Widget build(BuildContext context) {
    final players = const [
      _Player(name: 'Gamer777', top: 6, left: 126, active: true),
      _Player(name: 'ZenMaster', top: 92, left: 20),
      _Player(name: 'ShadowNinja', top: 92, left: 230),
      _Player(name: 'MoonLight', top: 220, left: 28),
      _Player(name: 'CyberX', top: 220, left: 230, cyan: true),
      _Player(name: 'Bạn', top: 276, left: 126, me: true),
    ];

    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          Align(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NebulaTheme.surface.withValues(alpha: 0.6),
                border: Border.all(color: NebulaTheme.primary.withValues(alpha: 0.25)),
              ),
              child:       Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.nightlight_round, color: NebulaTheme.primary, size: 42),
                  Text('GIAI ĐOẠN', style: TextStyle(color: NebulaTheme.primary, fontWeight: FontWeight.w600)),
                  Text('Ban Đêm', style: TextStyle(color: NebulaTheme.text, fontSize: 28, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          ...players.map((p) => Positioned(top: p.top, left: p.left, child: p)),
        ],
      ),
    );
  }
}

class _Player extends StatelessWidget {
  final String name;
  final double top;
  final double left;
  final bool active;
  final bool cyan;
  final bool me;
  const _Player({
    required this.name,
    required this.top,
    required this.left,
    this.active = false,
    this.cyan = false,
    this.me = false,
  });

  @override
  Widget build(BuildContext context) {
    Color border = NebulaTheme.textSubtle;
    if (active) border = NebulaTheme.secondary;
    if (cyan) border = NebulaTheme.tertiary;
    if (me) border = NebulaTheme.primary;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: border, width: 2)),
          child: const CircleAvatar(
            radius: 23,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1527980965255-d3b416303d12?q=80&w=400&auto=format&fit=crop'),
          ),
        ),
        const SizedBox(height: 5),
        Text(name, style: TextStyle(color: me ? NebulaTheme.primary : NebulaTheme.textSubtle, fontSize: 11)),
      ],
    );
  }
}


import 'package:flutter/material.dart';

import '../widgets/nebula_theme.dart';

class NebulaProfileScreen extends StatelessWidget {
  const NebulaProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: NebulaTheme.glass(),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: NebulaTheme.secondary, width: 3)),
                child: const CircleAvatar(
                  radius: 42,
                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1521572267360-ee0c2909d518?q=80&w=500&auto=format&fit=crop'),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Gamer777', style: TextStyle(color: NebulaTheme.text, fontSize: 32, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('LEVEL 42 MAGE', style: TextStyle(color: NebulaTheme.primary, fontWeight: FontWeight.w600, fontSize: 11)),
              const SizedBox(height: 8),
              const Text('Chasing high scores and digital dreams.', style: TextStyle(color: NebulaTheme.textSubtle)),
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Stat(title: '1.2k', subtitle: 'FOLLOWING'),
                  _Stat(title: '8.4k', subtitle: 'FOLLOWERS'),
                  _Stat(title: '450', subtitle: 'WINS'),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(backgroundColor: NebulaTheme.primary.withValues(alpha: 0.24), minimumSize: const Size.fromHeight(46)),
                child: const Text('Chỉnh sửa hồ sơ', style: TextStyle(color: NebulaTheme.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: NebulaTheme.glass(),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Thành tích', style: TextStyle(color: NebulaTheme.text, fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(text: 'Top 10 Thách Đấu'),
                _Badge(text: 'Thợ Săn Quà'),
                _Badge(text: 'Siêu Tốc Độ'),
              ],
            )
          ]),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Stat({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(title, style: const TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.w700)),
      Text(subtitle, style: const TextStyle(color: NebulaTheme.textSubtle, fontSize: 11)),
    ]);
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: NebulaTheme.surfaceHigh, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: NebulaTheme.text)),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/nebula_theme.dart';

class NebulaMessageScreen extends StatelessWidget {
  const NebulaMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    return Column(
      children: [
        // Search & Top Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: NebulaTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: NebulaTheme.text.withValues(alpha: 0.08)),
                  ),
                  child: TextField(
                    style: TextStyle(color: NebulaTheme.text),
                    decoration: InputDecoration(
                      hintText: 'Search friends or groups...',
                      hintStyle: TextStyle(color: NebulaTheme.textSubtle.withValues(alpha: 0.5)),
                      prefixIcon:       Icon(Icons.search, color: NebulaTheme.primary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: NebulaTheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon:       Icon(Icons.group_add, color: NebulaTheme.primary),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),

        // Online Friends (Horizontal Scroll)
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 8,
            itemBuilder: (context, index) {
              final isOnline = index % 3 != 0;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isOnline ? NebulaTheme.tertiary : Colors.transparent, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=${index + 10}'),
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: NebulaTheme.background, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'User ${index + 1}',
                      style:       TextStyle(color: NebulaTheme.text, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        Divider(color: NebulaTheme.text.withValues(alpha: 0.08), height: 1),

        // Recent Chats List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: _mockChats.length,
            itemBuilder: (context, index) {
              final chat = _mockChats[index];
              final isGroup = chat['isGroup'] == true;
              final hasUnread = (chat['unread'] as int) > 0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onTap: () {},
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isGroup ? NebulaTheme.secondary.withOpacity(0.2) : Colors.transparent,
                      backgroundImage: isGroup ? null : NetworkImage(chat['avatar']),
                      child: isGroup ?       Icon(Icons.groups, color: NebulaTheme.secondary) : null,
                    ),
                    if (isGroup && chat['members'] != null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: NebulaTheme.background,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundImage: NetworkImage((chat['members'] as List)[0]),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  chat['name'],
                  style: TextStyle(
                    color: NebulaTheme.text,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                subtitle: Row(
                  children: [
                    if (chat['isTyping'] == true)
                            Text('Typing...', style: TextStyle(color: NebulaTheme.tertiary, fontStyle: FontStyle.italic))
                    else
                      Expanded(
                        child: Text(
                          chat['lastMessage'],
                          style: TextStyle(color: hasUnread ? NebulaTheme.text : NebulaTheme.textSubtle),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chat['time'],
                      style: TextStyle(
                        color: hasUnread ? NebulaTheme.primary : NebulaTheme.textSubtle,
                        fontSize: 12,
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration:       BoxDecoration(
                          color: NebulaTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${chat['unread']}',
                          style: TextStyle(
                            color: NebulaTheme.primary.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Mock data for the social messaging UI
final List<Map<String, dynamic>> _mockChats = [
  {
    'name': 'Gamer Guild (SG)',
    'avatar': '',
    'isGroup': true,
    'members': ['https://i.pravatar.cc/150?img=11'],
    'lastMessage': 'ShadowNinja: Anyone up for a raid tonight?',
    'time': '10:42 AM',
    'unread': 3,
    'isTyping': false,
  },
  {
    'name': 'ZenMaster',
    'avatar': 'https://i.pravatar.cc/150?img=12',
    'isGroup': false,
    'lastMessage': 'GG wp!',
    'time': '09:15 AM',
    'unread': 1,
    'isTyping': false,
  },
  {
    'name': 'CyberX',
    'avatar': 'https://i.pravatar.cc/150?img=13',
    'isGroup': false,
    'lastMessage': 'Are you going to the tournament?',
    'time': 'Yesterday',
    'unread': 0,
    'isTyping': true,
  },
  {
    'name': 'League of Legends VN',
    'avatar': '',
    'isGroup': true,
    'members': ['https://i.pravatar.cc/150?img=14'],
    'lastMessage': 'Admin: Patch notes v14.2 are out.',
    'time': 'Yesterday',
    'unread': 0,
    'isTyping': false,
  },
  {
    'name': 'MoonLight',
    'avatar': 'https://i.pravatar.cc/150?img=15',
    'isGroup': false,
    'lastMessage': 'Thanks for the gift! 🎁',
    'time': 'Mon',
    'unread': 0,
    'isTyping': false,
  },
  {
    'name': 'DarkVader99',
    'avatar': 'https://i.pravatar.cc/150?img=16',
    'isGroup': false,
    'lastMessage': 'Let\'s play duo tomorrow',
    'time': 'Sun',
    'unread': 0,
    'isTyping': false,
  },
];

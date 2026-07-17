import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/nebula_theme.dart';
import 'chat_detail_screen.dart';

class NebulaMessageScreen extends StatefulWidget {
  const NebulaMessageScreen({super.key});

  @override
  State<NebulaMessageScreen> createState() => _NebulaMessageScreenState();
}

class _NebulaMessageScreenState extends State<NebulaMessageScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().fetchConversations();
      context.read<UserProvider>().fetchFriends();
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      switch (time.weekday) {
        case DateTime.monday:
          return 'Thứ 2';
        case DateTime.tuesday:
          return 'Thứ 3';
        case DateTime.wednesday:
          return 'Thứ 4';
        case DateTime.thursday:
          return 'Thứ 5';
        case DateTime.friday:
          return 'Thứ 6';
        case DateTime.saturday:
          return 'Thứ 7';
        default:
          return 'Chủ Nhật';
      }
    }
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsProvider>();
    final myUser = context.watch<AuthProvider>().currentUser;
    final userProvider = context.watch<UserProvider>();
    final messageProvider = context.watch<MessageProvider>();

    // 1. Filter online users / user list to chat with (excluding self)
    final filteredUsers = userProvider.friends.where((user) {
      final isSelf = user.id == myUser?.id;
      final matchesSearch = user.username.toLowerCase().contains(_searchQuery.toLowerCase());
      return !isSelf && matchesSearch;
    }).toList();

    // 2. Filter existing conversations
    final filteredConversations = messageProvider.conversations.where((conv) {
      return conv.user.username.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search bar
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
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(color: NebulaTheme.text),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm bạn bè...',
                      hintStyle: TextStyle(color: NebulaTheme.textSubtle.withValues(alpha: 0.5)),
                      prefixIcon: Icon(Icons.search, color: NebulaTheme.primary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // User list (Horizontal Scroll)
        SizedBox(
          height: 105,
          child: userProvider.isLoading && userProvider.friends.isEmpty
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: NebulaTheme.primary),
                  ),
                )
              : filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        'Không tìm thấy bạn bè',
                        style: TextStyle(color: NebulaTheme.textSubtle, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(partner: user),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundImage: NetworkImage(
                                    user.avatarURL.isNotEmpty
                                        ? user.avatarURL
                                        : 'https://i.pravatar.cc/150?img=${index + 10}',
                                  ),
                                  onBackgroundImageError: (_, __) {},
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    user.username,
                                    style: TextStyle(color: NebulaTheme.text, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),

        Divider(color: NebulaTheme.text.withValues(alpha: 0.08), height: 1),

        // Recent Chats List
        Expanded(
          child: messageProvider.isLoadingConversations && messageProvider.conversations.isEmpty
              ? Center(
                  child: CircularProgressIndicator(color: NebulaTheme.primary),
                )
              : filteredConversations.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: NebulaTheme.textSubtle.withValues(alpha: 0.4),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có cuộc trò chuyện nào',
                          style: TextStyle(
                            color: NebulaTheme.textSubtle,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hãy chọn một người bạn ở trên để bắt đầu nhắn tin',
                          style: TextStyle(
                            color: NebulaTheme.textSubtle.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: () => messageProvider.fetchConversations(),
                      color: NebulaTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        itemCount: filteredConversations.length,
                        itemBuilder: (context, index) {
                          final conv = filteredConversations[index];
                          final hasUnread = conv.unread > 0;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(partner: conv.user),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(
                                conv.user.avatarURL.isNotEmpty
                                    ? conv.user.avatarURL
                                    : 'https://i.pravatar.cc/150?img=12',
                              ),
                              onBackgroundImageError: (_, __) {},
                            ),
                            title: Text(
                              conv.user.username,
                              style: TextStyle(
                                color: NebulaTheme.text,
                                fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                conv.lastMessage,
                                style: TextStyle(
                                  color: hasUnread ? NebulaTheme.text : NebulaTheme.textSubtle,
                                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTime(conv.time),
                                  style: TextStyle(
                                    color: hasUnread ? NebulaTheme.primary : NebulaTheme.textSubtle,
                                    fontSize: 11,
                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (hasUnread)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: NebulaTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${conv.unread}',
                                      style: TextStyle(
                                        color: NebulaTheme.primary.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../widgets/nebula_theme.dart';

class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({super.key});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    final messageProvider = context.read<MessageProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messageProvider.joinCommunityChat();
    });
  }

  @override
  void dispose() {
    // Leave community socket room
    final messageProvider = context.read<MessageProvider>();
    messageProvider.leaveCommunityChat();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();
    context.read<MessageProvider>().sendCommunityMessage(text);

    Timer(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();
    final myId = context.watch<AuthProvider>().currentUser?.id ?? '';

    // Scroll to bottom when history is loaded or new message comes in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messageProvider.communityMessages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: NebulaTheme.background,
      appBar: AppBar(
        backgroundColor: NebulaTheme.background.withValues(alpha: 0.95),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: NebulaTheme.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NebulaTheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.groups_rounded, color: NebulaTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Chat Cộng Đồng',
                    style: TextStyle(
                      color: NebulaTheme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Mọi người đang online',
                    style: TextStyle(
                      color: NebulaTheme.textSubtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messageProvider.communityMessages.length,
              itemBuilder: (context, index) {
                final msg = messageProvider.communityMessages[index];
                final isMe = msg.sender.id == myId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(
                            msg.sender.avatarURL.isNotEmpty
                                ? msg.sender.avatarURL
                                : 'https://i.pravatar.cc/150?img=12',
                          ),
                          onBackgroundImageError: (_, __) {},
                        ),
                        const SizedBox(width: 8),
                      ],
                      Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 4),
                              child: Text(
                                msg.sender.username,
                                style: TextStyle(
                                  color: NebulaTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.72,
                            ),
                            decoration: BoxDecoration(
                              gradient: isMe
                                  ? LinearGradient(
                                      colors: [NebulaTheme.primary, NebulaTheme.secondary],
                                    )
                                  : null,
                              color: isMe ? null : NebulaTheme.surfaceHigh,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                            ),
                            child: Text(
                              msg.content,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Message input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: NebulaTheme.surface,
                border: Border(
                  top: BorderSide(color: NebulaTheme.text.withValues(alpha: 0.08)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: NebulaTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: TextField(
                        controller: _textCtrl,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(color: NebulaTheme.text, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn vào cộng đồng...',
                          hintStyle: TextStyle(color: NebulaTheme.textSubtle.withValues(alpha: 0.6)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [NebulaTheme.primary, NebulaTheme.secondary],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

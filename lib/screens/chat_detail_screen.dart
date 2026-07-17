import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../services/socket_service.dart';
import '../widgets/nebula_theme.dart';

class ChatDetailScreen extends StatefulWidget {
  final UserModel partner;

  const ChatDetailScreen({super.key, required this.partner});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _typingDebounce;
  bool _isTyping = false;
  int _prevMessageCount = 0;

  @override
  void initState() {
    super.initState();
    final messageProvider = context.read<MessageProvider>();

    // Listen to provider changes — scroll to bottom when new messages arrive
    messageProvider.addListener(_onMessagesChanged);
    
    // Set active chat user and fetch message history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messageProvider.setActiveChatUser(widget.partner.id);
      messageProvider.fetchMessagesWithUser(widget.partner.id).then((_) {
        _prevMessageCount = messageProvider.messages.length;
        _scrollToBottom();
      });
    });

    _textCtrl.addListener(_onTextChanged);
    SocketService.instance.on('error_message', _onErrorMessage);
  }

  void _onMessagesChanged() {
    final messageProvider = context.read<MessageProvider>();
    final newCount = messageProvider.messages.length;
    if (newCount > _prevMessageCount) {
      _prevMessageCount = newCount;
      // Give the list time to render the new item, then scroll
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _onErrorMessage(dynamic msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.toString()),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    context.read<MessageProvider>().removeListener(_onMessagesChanged);
    _textCtrl.removeListener(_onTextChanged);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _typingDebounce?.cancel();
    SocketService.instance.off('error_message');

    // Reset active chat user when leaving screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().setActiveChatUser(null);
    });
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

  void _onTextChanged() {
    final hasText = _textCtrl.text.trim().isNotEmpty;
    if (hasText && !_isTyping) {
      _isTyping = true;
      context.read<MessageProvider>().setTyping(widget.partner.id, true);
    }

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (mounted && _isTyping) {
        _isTyping = false;
        context.read<MessageProvider>().setTyping(widget.partner.id, false);
      }
    });
  }

  void _sendMessage() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();
    context.read<MessageProvider>().sendDirectMessage(widget.partner.id, text);

    // Cancel typing status immediately on send
    _isTyping = false;
    _typingDebounce?.cancel();
    context.read<MessageProvider>().setTyping(widget.partner.id, false);

    // Schedule scroll to bottom shortly after UI rebuilds
    Timer(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();
    final myId = context.watch<AuthProvider>().currentUser?.id ?? '';
    final opponentTyping = messageProvider.isOpponentTyping;

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
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                widget.partner.avatarURL.isNotEmpty
                    ? widget.partner.avatarURL
                    : 'https://i.pravatar.cc/150?img=12',
              ),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.partner.username,
                    style: TextStyle(
                      color: NebulaTheme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: opponentTyping ? 16 : 0,
                    child: opponentTyping
                        ? Text(
                            'đang nhập...',
                            style: TextStyle(
                              color: NebulaTheme.tertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : const SizedBox.shrink(),
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
            child: messageProvider.isLoadingMessages
                ? Center(
                    child: CircularProgressIndicator(color: NebulaTheme.primary),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: messageProvider.messages.length,
                    itemBuilder: (context, index) {
                      final msg = messageProvider.messages[index];
                      final isMe = msg.sender.id == myId;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.72,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            gradient: isMe
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      NebulaTheme.primary.withValues(alpha: 0.8),
                                      NebulaTheme.secondary.withValues(alpha: 0.7),
                                    ],
                                  )
                                : null,
                            color: isMe ? null : NebulaTheme.surfaceHigh.withValues(alpha: 0.75),
                            border: isMe
                                ? Border.all(color: NebulaTheme.primary.withValues(alpha: 0.25))
                                : Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Text(
                            msg.content,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Message input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: NebulaTheme.surface.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: NebulaTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: TextField(
                        controller: _textCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        style: TextStyle(color: NebulaTheme.text, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          hintStyle: TextStyle(
                            color: NebulaTheme.textSubtle.withValues(alpha: 0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [NebulaTheme.primary, NebulaTheme.secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NebulaTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
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

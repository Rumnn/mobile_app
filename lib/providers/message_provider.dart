import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/message_model.dart';
import '../services/api_client.dart';
import '../services/socket_service.dart';

class MessageProvider extends ChangeNotifier {
  final ApiClient _api;

  MessageProvider({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  String? _error;

  // Active chat details
  String? _activeChatUserId;
  bool _isOpponentTyping = false;

  // Getters
  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get error => _error;
  String? get activeChatUserId => _activeChatUserId;
  bool get isOpponentTyping => _isOpponentTyping;

  // Initialize socket listeners for real-time message stream
  void initSocketListeners() {
    final socket = SocketService.instance;

    socket.off('new_direct_message');
    socket.off('typing_status');

    socket.on('new_direct_message', (data) {
      final message = MessageModel.fromJson(Map<String, dynamic>.from(data as Map));
      _handleIncomingMessage(message);
    });

    socket.on('typing_status', (data) {
      final senderId = data['senderId']?.toString();
      final isTyping = data['isTyping'] == true;

      if (senderId == _activeChatUserId) {
        _isOpponentTyping = isTyping;
        notifyListeners();
      }
    });
  }

  void disposeSocketListeners() {
    SocketService.instance.off('new_direct_message');
    SocketService.instance.off('typing_status');
  }

  // Set the active user we are currently chatting with
  void setActiveChatUser(String? userId) {
    _activeChatUserId = userId;
    _isOpponentTyping = false;
    if (userId != null) {
      markAsRead(userId);
    }
  }

  // Handle a new message received via socket
  void _handleIncomingMessage(MessageModel message) {
    final myId = message.sender.id;

    // 1. If this message is part of our active conversation, append it
    if (_activeChatUserId != null &&
        (message.sender.id == _activeChatUserId || message.receiver.id == _activeChatUserId)) {
      _messages.add(message);
      // Automatically mark as read if it is incoming
      if (message.sender.id == _activeChatUserId) {
        markAsRead(_activeChatUserId!);
      }
    }

    // 2. Update conversation list
    final partner = message.sender.id == _activeChatUserId
        ? message.sender
        : (message.receiver.id == _activeChatUserId ? message.receiver : (message.sender.id == myId ? message.receiver : message.sender));

    final existingIdx = _conversations.indexWhere((c) => c.user.id == partner.id);
    final incrementUnread = _activeChatUserId != partner.id && message.sender.id == partner.id;

    if (existingIdx != -1) {
      final oldConv = _conversations[existingIdx];
      _conversations[existingIdx] = oldConv.copyWith(
        lastMessage: message.content,
        time: message.createdAt,
        unread: oldConv.unread + (incrementUnread ? 1 : 0),
      );
    } else {
      _conversations.add(ConversationModel(
        user: partner,
        lastMessage: message.content,
        time: message.createdAt,
        unread: incrementUnread ? 1 : 0,
      ));
    }

    // Sort conversations: most recent first
    _conversations.sort((a, b) => b.time.compareTo(a.time));
    notifyListeners();
  }

  // HTTP GET: Fetch conversation list
  Future<void> fetchConversations() async {
    _isLoadingConversations = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/messages/conversations');
      final list = (response['data'] as List? ?? []);
      _conversations = list
          .map((item) => ConversationModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  // HTTP GET: Fetch messages with a specific user
  Future<void> fetchMessagesWithUser(String userId) async {
    _isLoadingMessages = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/messages/$userId');
      final list = (response['data'] as List? ?? []);
      _messages = list
          .map((item) => MessageModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // Emit direct message to server via Socket
  void sendDirectMessage(String receiverId, String content) {
    if (content.trim().isEmpty) return;
    SocketService.instance.emit('send_direct_message', {
      'receiverId': receiverId,
      'content': content.trim(),
    });
  }

  // Emit typing indicator to opponent
  void setTyping(String receiverId, bool isTyping) {
    SocketService.instance.emit('typing', {
      'receiverId': receiverId,
      'isTyping': isTyping,
    });
  }

  // HTTP PUT: Mark messages from this user as read
  Future<void> markAsRead(String senderId) async {
    try {
      await _api.put('/messages/$senderId/read');
      // Update local unread counter in conversations
      final idx = _conversations.indexWhere((c) => c.user.id == senderId);
      if (idx != -1) {
        _conversations[idx] = _conversations[idx].copyWith(unread: 0);
        notifyListeners();
      }
    } catch (e) {
      // ignore silently
    }
  }
}

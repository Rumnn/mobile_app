import 'user_model.dart';

class MessageModel {
  final String id;
  final UserModel sender;
  final UserModel receiver;
  final String content;
  final bool read;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.content,
    required this.read,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      sender: UserModel.fromJson(json['sender'] is Map ? json['sender'] as Map<String, dynamic> : {}),
      receiver: UserModel.fromJson(json['receiver'] is Map ? json['receiver'] as Map<String, dynamic> : {}),
      content: (json['content'] ?? '') as String,
      read: (json['read'] ?? false) as bool,
      createdAt: DateTime.parse((json['createdAt'] ?? DateTime.now().toIso8601String()).toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'sender': sender.toJson(),
        'receiver': receiver.toJson(),
        'content': content,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
      };
}

class ConversationModel {
  final UserModel user;
  final String lastMessage;
  final DateTime time;
  final int unread;

  const ConversationModel({
    required this.user,
    required this.lastMessage,
    required this.time,
    required this.unread,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      user: UserModel.fromJson((json['user'] as Map<String, dynamic>?) ?? {}),
      lastMessage: (json['lastMessage'] ?? '') as String,
      time: DateTime.parse((json['time'] ?? DateTime.now().toIso8601String()).toString()),
      unread: (json['unread'] ?? 0) as int,
    );
  }

  ConversationModel copyWith({
    UserModel? user,
    String? lastMessage,
    DateTime? time,
    int? unread,
  }) {
    return ConversationModel(
      user: user ?? this.user,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      unread: unread ?? this.unread,
    );
  }
}

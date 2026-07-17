import 'user_model.dart';

class CommunityMessageModel {
  final String id;
  final UserModel sender;
  final String content;
  final DateTime createdAt;

  const CommunityMessageModel({
    required this.id,
    required this.sender,
    required this.content,
    required this.createdAt,
  });

  factory CommunityMessageModel.fromJson(Map<String, dynamic> json) {
    return CommunityMessageModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      sender: UserModel.fromJson(
        json['sender'] is Map ? Map<String, dynamic>.from(json['sender'] as Map) : {},
      ),
      content: (json['content'] ?? '') as String,
      createdAt: DateTime.parse(
        (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'sender': sender.toJson(),
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };
}

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    String authorId = '';
    String authorName = '';
    String authorAvatar = '';

    if (author is Map<String, dynamic>) {
      authorId = (author['_id'] ?? author['id'] ?? '').toString();
      authorName = (author['username'] ?? '') as String;
      authorAvatar = (author['avatarURL'] ?? '') as String;
    } else if (author is String) {
      authorId = author;
    }

    return CommentModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      postId: (json['post'] ?? '').toString(),
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      content: (json['content'] ?? '') as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

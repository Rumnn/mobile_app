class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final String imageURL;
  int likesCount;
  int commentsCount;
  bool isLiked;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    this.imageURL = '',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
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

    return PostModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      content: (json['content'] ?? '') as String,
      imageURL: (json['imageURL'] ?? '') as String,
      likesCount: (json['likesCount'] ?? 0) as int,
      commentsCount: (json['commentsCount'] ?? 0) as int,
      isLiked: (json['isLiked'] ?? false) as bool,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'content': content,
        'imageURL': imageURL,
      };

  PostModel copyWith({
    String? content,
    String? imageURL,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
  }) {
    return PostModel(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      content: content ?? this.content,
      imageURL: imageURL ?? this.imageURL,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
    );
  }
}

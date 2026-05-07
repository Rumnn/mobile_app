class UserModel {
  final String id;
  final String username;
  final String email;
  final String avatarURL;
  final int level;
  final double winRate;
  final int totalGames;
  final String role;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarURL,
    required this.level,
    required this.winRate,
    required this.totalGames,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      avatarURL: (json['avatarURL'] ?? '') as String,
      level: (json['level'] ?? 1) as int,
      winRate: (json['winRate'] ?? 0).toDouble(),
      totalGames: (json['totalGames'] ?? 0) as int,
      role: (json['role'] ?? 'user') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'username': username,
        'email': email,
        'avatarURL': avatarURL,
        'level': level,
        'winRate': winRate,
        'totalGames': totalGames,
        'role': role,
      };

  UserModel copyWith({
    String? username,
    String? email,
    String? avatarURL,
    int? level,
    double? winRate,
    int? totalGames,
    String? role,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarURL: avatarURL ?? this.avatarURL,
      level: level ?? this.level,
      winRate: winRate ?? this.winRate,
      totalGames: totalGames ?? this.totalGames,
      role: role ?? this.role,
    );
  }
}


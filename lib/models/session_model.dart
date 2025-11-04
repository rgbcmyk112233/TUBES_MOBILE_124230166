class Session {
  int? id;
  String userId;
  String userName;
  String userEmail;
  String userPhoto;
  bool isLoggedIn;
  DateTime lastLogin;
  DateTime? expiresAt;

  Session({
    this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhoto,
    required this.isLoggedIn,
    required this.lastLogin,
    this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'user_photo': userPhoto,
      'is_logged_in': isLoggedIn ? 1 : 0,
      'last_login': lastLogin.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      userId: map['user_id'],
      userName: map['user_name'],
      userEmail: map['user_email'],
      userPhoto: map['user_photo'],
      isLoggedIn: map['is_logged_in'] == 1,
      lastLogin: DateTime.parse(map['last_login']),
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'])
          : null,
    );
  }

  bool get isValid {
    if (expiresAt != null) {
      return DateTime.now().isBefore(expiresAt!);
    }
    return true;
  }
}

import 'package:myfilms_app/models/session_model.dart';

class User {
  final String userId;
  final String userName;
  final String userMail;
  final String userDesc;
  final String? userPhoto;

  User({
    required this.userId,
    required this.userName,
    required this.userMail,
    required this.userDesc,
    this.userPhoto,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['UserId'] ?? '',
      userName: json['UserName'] ?? '',
      userMail: json['UserMail'] ?? '',
      userDesc: json['UserDesc'] ?? '',
      userPhoto: json['UserPhoto'],
    );
  }

  // Tambahkan method dari Session
  factory User.fromSession(Session session) {
    return User(
      userId: session.userId,
      userName: session.userName,
      userMail: session.userEmail,
      userDesc: 'Profile user', // Default description
      userPhoto: session.userPhoto.isNotEmpty ? session.userPhoto : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'UserName': userName,
      'UserMail': userMail,
      'UserDesc': userDesc,
      'UserPhoto': userPhoto,
    };
  }

  // Convert to Session
  Session toSession() {
    return Session(
      userId: userId,
      userName: userName,
      userEmail: userMail,
      userPhoto: userPhoto ?? '',
      isLoggedIn: true,
      lastLogin: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)), // 30 days expiry
    );
  }
}

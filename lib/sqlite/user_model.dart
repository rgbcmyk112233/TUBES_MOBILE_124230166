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

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'UserName': userName,
      'UserMail': userMail,
      'UserDesc': userDesc,
      'UserPhoto': userPhoto,
    };
  }
}

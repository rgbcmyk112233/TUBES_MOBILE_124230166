class LoginLog {
  final int? id;
  final String username;
  final String loginTime; // Kita simpan sebagai String ISO8601

  LoginLog({this.id, required this.username, required this.loginTime});

  // Konversi dari Map (Database) ke Object
  factory LoginLog.fromMap(Map<String, dynamic> json) => LoginLog(
    id: json['id'],
    username: json['username'],
    loginTime: json['login_time'],
  );

  // Konversi dari Object ke Map (Database)
  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'login_time': loginTime,
  };
}

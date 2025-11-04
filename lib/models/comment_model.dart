class Comment {
  final String id;
  final String imdbId;
  final String userId;
  final String userName;
  final String userComment;
  final DateTime posted;
  final String? userPhoto;

  Comment({
    required this.id,
    required this.imdbId,
    required this.userId,
    required this.userName,
    required this.userComment,
    required this.posted,
    this.userPhoto,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      imdbId: json['imdb_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userComment: json['user_comment'] ?? '',
      posted: DateTime.parse(json['posted']),
      userPhoto: json['user_photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imdb_id': imdbId,
      'user_id': userId,
      'user_name': userName,
      'user_comment': userComment,
      'posted': posted.toIso8601String(),
      'user_photo': userPhoto,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(posted);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    }
  }
}

class Movie {
  final String title;
  final String year;
  final String imdbId;
  final String rank;
  final String actors;
  final String imdbUrl;
  final String imagePoster;
  final int photoWidth;
  final int photoHeight;

  Movie({
    required this.title,
    required this.year,
    required this.imdbId,
    required this.rank,
    required this.actors,
    required this.imdbUrl,
    required this.imagePoster,
    required this.photoWidth,
    required this.photoHeight,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    // Handle berbagai kemungkinan tipe data dari API
    String parseString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Movie(
      title: parseString(json['#TITLE']),
      year: parseString(json['#YEAR']),
      imdbId: parseString(json['#IMDB_ID']),
      rank: parseString(json['#RANK']),
      actors: parseString(json['#ACTORS']),
      imdbUrl: parseString(json['#IMDB_URL']),
      imagePoster: parseString(json['#IMG_POSTER']),
      photoWidth: parseInt(json['photo_width']),
      photoHeight: parseInt(json['photo_height']),
    );
  }

  double get rating {
    try {
      // Convert rank to rating (lower rank = higher rating)
      int rankValue = int.tryParse(rank) ?? 10000;
      // Normalize rating to 0-10 scale
      double normalizedRating = (10000 - rankValue) / 1000.0;
      return normalizedRating.clamp(0.0, 10.0);
    } catch (e) {
      return 0.0;
    }
  }

  String get formattedRating {
    return rating.toStringAsFixed(1);
  }
}

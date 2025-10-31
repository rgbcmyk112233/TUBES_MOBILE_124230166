class OmdbMovie {
  final String title;
  final String year;
  final String rated;
  final String released;
  final String runtime;
  final String genre;
  final String director;
  final String writer;
  final String actors;
  final String plot;
  final String language;
  final String country;
  final String awards;
  final String poster;
  final List<Rating> ratings;
  final String metascore;
  final String imdbRating;
  final String imdbVotes;
  final String imdbId;
  final String type;
  final String dvd;
  final String boxOffice;
  final String production;
  final String website;
  final String response;

  OmdbMovie({
    required this.title,
    required this.year,
    required this.rated,
    required this.released,
    required this.runtime,
    required this.genre,
    required this.director,
    required this.writer,
    required this.actors,
    required this.plot,
    required this.language,
    required this.country,
    required this.awards,
    required this.poster,
    required this.ratings,
    required this.metascore,
    required this.imdbRating,
    required this.imdbVotes,
    required this.imdbId,
    required this.type,
    required this.dvd,
    required this.boxOffice,
    required this.production,
    required this.website,
    required this.response,
  });

  factory OmdbMovie.fromJson(Map<String, dynamic> json) {
    String parseString(dynamic value) {
      if (value == null) return 'N/A';
      if (value is String) return value;
      return value.toString();
    }

    List<Rating> parseRatings(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((rating) => Rating.fromJson(rating)).toList();
      }
      return [];
    }

    return OmdbMovie(
      title: parseString(json['Title']),
      year: parseString(json['Year']),
      rated: parseString(json['Rated']),
      released: parseString(json['Released']),
      runtime: parseString(json['Runtime']),
      genre: parseString(json['Genre']),
      director: parseString(json['Director']),
      writer: parseString(json['Writer']),
      actors: parseString(json['Actors']),
      plot: parseString(json['Plot']),
      language: parseString(json['Language']),
      country: parseString(json['Country']),
      awards: parseString(json['Awards']),
      poster: parseString(json['Poster']),
      ratings: parseRatings(json['Ratings']),
      metascore: parseString(json['Metascore']),
      imdbRating: parseString(json['imdbRating']),
      imdbVotes: parseString(json['imdbVotes']),
      imdbId: parseString(json['imdbID']),
      type: parseString(json['Type']),
      dvd: parseString(json['DVD']),
      boxOffice: parseString(json['BoxOffice']),
      production: parseString(json['Production']),
      website: parseString(json['Website']),
      response: parseString(json['Response']),
    );
  }

  bool get isValid => response == 'True';
}

class Rating {
  final String source;
  final String value;

  Rating({required this.source, required this.value});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      source: json['Source']?.toString() ?? 'Unknown',
      value: json['Value']?.toString() ?? 'N/A',
    );
  }
}

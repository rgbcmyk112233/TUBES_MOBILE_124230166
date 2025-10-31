import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';

class MovieService {
  static const String baseUrl = 'https://imdb.iamidiotareyoutoo.com/search';

  Future<List<Movie>> searchMovies(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse('$baseUrl?q=$encodedQuery&tt=&lsn=1&v=1');

      print('Fetching movies from: $url');

      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        print('API response ok: ${data['ok']}');

        if (data['ok'] == true) {
          final List<dynamic> moviesJson = data['description'] ?? [];
          print('Found ${moviesJson.length} movies');

          final movies = moviesJson
              .map((json) {
                try {
                  return Movie.fromJson(json);
                } catch (e) {
                  print('Error parsing movie: $e');
                  print('Problematic JSON: $json');
                  return null;
                }
              })
              .where((movie) => movie != null)
              .cast<Movie>()
              .toList();

          return movies;
        } else {
          throw Exception('API returned error: ${data['error_code']}');
        }
      } else {
        throw Exception(
          'Failed to load movies. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in searchMovies: $e');
      throw Exception('Error searching movies: $e');
    }
  }

  Future<List<Movie>> getSpidermanMovies() async {
    return await searchMovies('spiderman');
  }
}

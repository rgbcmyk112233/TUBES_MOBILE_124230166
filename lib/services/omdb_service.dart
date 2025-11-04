import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/omdb_movie_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OmdbService {
  static const String baseUrl = 'http://www.omdbapi.com/';
  static final String apiKey = 'a167ee30';

  Future<OmdbMovie> getMovieDetails(String imdbId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?i=$imdbId&apikey=$apiKey'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['Response'] == 'True') {
          return OmdbMovie.fromJson(data);
        } else {
          throw Exception('Movie not found: ${data['Error']}');
        }
      } else {
        throw Exception('Failed to load movie details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching movie details: $e');
    }
  }
}

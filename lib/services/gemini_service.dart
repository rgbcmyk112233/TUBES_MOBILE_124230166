import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  final String apiKey;

  GeminiService({required this.apiKey});

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': message},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final candidates = data['candidates'];
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          if (content != null) {
            final parts = content['parts'];
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'] ?? 'No response from AI';
            }
          }
        }
        throw Exception('Invalid response format from Gemini API');
      } else {
        throw Exception(
          'Failed to get response: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error communicating with Gemini: $e');
    }
  }

  Future<String> getMovieExplanation(String movieTitle) async {
    final prompt =
        '''
Jelaskan saya tentang film "$movieTitle" dan harus diingat, dilarang membahas selain hal tersebut, jika ada pertanyaan diluar topik tersebut
maka jawablah dengan "maaf pertanyaan diluar konteks, ayo diskusi tentang film ini" TIDAK BOLEH MEMBAHAS HAL LAIN !.

Berikan penjelasan yang komprehensif tentang Sinopsis dan alur cerita secara umum

Jawablah dalam bahasa Indonesia yang santai dan hindari kata kata dicetak tebal.
''';

    return await sendMessage(prompt);
  }
}

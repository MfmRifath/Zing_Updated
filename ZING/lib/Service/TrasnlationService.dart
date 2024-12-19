import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  final String apiKey = "AIzaSyD-Y7nIBM2QYYBVa7pTvT7GPCvFqEWtfN4";  // Replace with your API key

  Future<String?> translateText(String text, String targetLang) async {
    try {
      final url = Uri.parse(
          'https://translation.googleapis.com/language/translate/v2?key=$apiKey');

      final response = await http.post(
        url,
        body: json.encode({
          'q': text,
          'target': targetLang,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText = data['data']['translations'][0]['translatedText'];
        return translatedText;
      } else {
        // Log the error and response body
        print('Failed to translate text. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      // Catch any other errors like network issues
      print('Error during translation: $e');
      return null;
    }
  }
}

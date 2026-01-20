import 'dart:convert';
import 'package:http/http.dart' as http;

class AIChatService {
  // 🔑 ඔයා Groq එකෙන් ගත්ත අලුත් API Key එක මෙතනට දාන්න
  final String _apiKey =
      "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";

  // Groq API Endpoint එක (මේක ලංකාවට වැඩ කරනවා)
  final String _baseUrl = "https://api.groq.com/openai/v1/chat/completions";

  Future<String> getResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model":
              "llama-3.3-70b-versatile", // ලෝකයේ තියෙන හොඳම open model එකක්
          "messages": [
            {
              "role": "system",
              "content":
                  "You are a professional support assistant for the Socially mobile app.",
            },
            {"role": "user", "content": prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print("Groq Error: ${response.body}");
        return "I'm having trouble connecting right now. Please try again.";
      }
    } catch (e) {
      print("Network Error: $e");
      return "Please check your internet connection.";
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIChatService {
  final String _apiKey =
      "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";
  final String _baseUrl = "https://api.groq.com/openai/v1/chat/completions";

  Future<String> getResponse(String prompt) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              "model": "llama-3.1-8b-instant",
              "messages": [
                {
                  "role": "system",
                  "content":
                      "You are Socially AI, the official smart assistant for the Socially social media app. "
                      "Your style is modern, energetic, and extremely helpful. "
                      "Guide users on how to share posts, watch Reels, and use the Admin Dashboard analytics. "
                      "If a user asks how to do something, explain the steps clearly. "
                      "Crucially, if they ask about 'how to post' or 'tutorials', always mention that a video tutorial is available in this chat.",
                },
                {"role": "user", "content": prompt},
              ],
              "temperature": 0.7,
              "max_tokens": 500,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else if (response.statusCode == 401) {
        return "System error: Authentication failed. Please check the API configuration.";
      } else if (response.statusCode == 429) {
        return "I'm processing too many requests right now. 🚀 Please give me a second!";
      } else {
        debugPrint("Groq API Error: ${response.statusCode} - ${response.body}");
        return "I'm having trouble connecting to Socially servers. Please try again.";
      }
    } on SocketException {
      return "It looks like you're offline. Please check your internet connection and try again! 🌐";
    } on http.ClientException {
      return "Network connection problem. Please try again later.";
    } catch (e) {
      debugPrint("Unexpected Error: $e");
      return "Something went wrong. Let's try that again! 🚀";
    }
  }
}

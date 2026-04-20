import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_constant.dart';
import 'chat_message_model.dart';

class GeminiService {
  static String _getGenerateContentUrl(String model) {
    return 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
  }

  static Stream<String> getChatResponseStream({
    required String pageContext,
    required List<ChatMessage> history,
    required String systemPrompt,
  }) async* {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/${AppConstant.GEMINI_TEXT_MODEL}:streamGenerateContent?key=${AppConstant.GEMINI_API_KEY}&alt=sse');
    
    final fullSystemPrompt = "$systemPrompt\n\nHere is the relevant context you must use:\n\n$pageContext";

    final List<Map<String, dynamic>> apiHistory = history.map((message) {
      return {
        'role': message.role == ChatRole.user ? 'user' : 'model',
        'parts': [
          {'text': message.text}
        ]
      };
    }).toList();

    final body = jsonEncode({
      'contents': apiHistory,
      'generationConfig': {
        'temperature': 0.7,
        'topK': 1,
        'topP': 1,
      },
      'systemInstruction': {
        'parts': [
          {'text': fullSystemPrompt}
        ]
      },
    });

    final client = http.Client();
    try {
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.body = body;
      
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final responseBody = await response.stream.bytesToString();
        try {
            final errorJson = jsonDecode(responseBody);
            final message = errorJson['error']['message'] ?? responseBody;
            throw Exception('API Error: $message');
        } catch (_) {
            throw Exception('API Error: ${response.statusCode} - $responseBody');
        }
      }

      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr == '[DONE]') break;
          if (jsonStr.isEmpty) continue;
          
          try {
            final data = jsonDecode(jsonStr);
            final candidates = data['candidates'] as List<dynamic>?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates.first['content'];
              if (content != null && content['parts'] is List && content['parts'].isNotEmpty) {
                final text = content['parts'][0]['text'] as String?;
                if (text != null) {
                  yield text;
                }
              }
            }
          } catch (e) {
            // Continue parsing other lines
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to connect to AI service: $e');
    } finally {
      client.close();
    }
  }

  static Future<String> generateSocialContent({
    required String platform,
    String? profileContext,
    required String inputType,
    String? userContext,
    required String selectedTone,
    required String language,
    int? wordCount,
    String? pageContent,
  }) async {
    final url = Uri.parse(
        '${_getGenerateContentUrl(AppConstant.GEMINI_TEXT_MODEL)}?key=${AppConstant.GEMINI_API_KEY}');

    String platformStyle;
    switch (platform) {
      case 'X':
      case 'Twitter':
        platformStyle = "casual, concise, and engaging, suitable for X (formerly Twitter). Use hashtags where appropriate inpost not in reply or comment .";
        break;
      case 'LinkedIn':
        platformStyle = "professional, insightful, and well-structured, suitable for LinkedIn.";
        break;
      case 'Reddit':
        platformStyle = "community-focused, authentic, and possibly humorous or niche, depending on the context, suitable for Reddit.";
        break;
      case 'Instagram':
        platformStyle = "visually descriptive, friendly, and emoji-heavy, suitable for an Instagram caption.";
        break;
      default:
        platformStyle = "neutral and broadly engaging.";
    }

    String profileInstruction = "You are writing from a general perspective.";
    if (profileContext != null && profileContext.isNotEmpty) {
      profileInstruction = "Adopt the persona described in this context: '$profileContext'.";
    }

    String contextInstruction = "";
    if (pageContent != null && pageContent.isNotEmpty) {
      contextInstruction += "The general context is from a webpage with the following content (first 500 chars): '${pageContent.substring(0, pageContent.length > 500 ? 500 : pageContent.length)}...'.";
    }
    if (wordCount != null) {
      contextInstruction += " The response should be approximately $wordCount words.";
    }
    if (userContext != null && userContext.isNotEmpty) {
      contextInstruction += " The user has provided this specific instruction: '$userContext'.";
    }
    if (inputType == 'Reply') {
      contextInstruction += " The goal is to reply to existing content, so be conversational and reference the context. don't add # in reply ";
    }

    final prompt = """
    You are an expert social media content generator. Your task is to create a '$inputType' for the '$platform' platform.

    **Instructions:**
    1.  **Platform Style:** Adhere to a $platformStyle style.
    2.  **Profile Persona:** $profileInstruction
    3.  **Desired Tone:** The specific tone for this piece of content should be '$selectedTone'.
    4.  **Language:** Generate the response in '$language'. If 'Default', use the primary language of the provided context.
    5.  **Content Context:** $contextInstruction

    Generate the content now.
    """;

    final body = jsonEncode({
      'contents': [{'role': 'user', 'parts': [{'text': prompt}]}],
      'generationConfig': {'temperature': 0.8, 'maxOutputTokens': 1024},
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        try {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = data['candidates'] as List<dynamic>?;
            if (candidates != null && candidates.isNotEmpty) {
                final content = candidates.first['content'];
                if (content != null && content['parts'] is List && content['parts'].isNotEmpty) {
                    final text = content['parts'][0]['text'] as String?;
                    if (text != null) {
                        return text.trim();
                    }
                }
            }
            throw Exception('Could not parse AI response.');
        } catch (e) {
            throw Exception('Error parsing AI response: ${e.toString()}');
        }
      } else {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        final message = errorBody['error']['message'] ?? 'Unknown API Error';
        throw Exception('API Error: $message');
      }
    } catch (e) {
      throw Exception('Failed to generate content: $e');
    }
  }
}

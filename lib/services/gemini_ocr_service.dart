import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wordstory/data/word_entry.dart';

class GeminiOcrService {
  final String apiKey;
  final BuildContext context;

  GeminiOcrService({
    this.apiKey = "AIzaSyCi0nEKnCBqTUd_i39pJBy2qm_EaaLdO7A",
    required this.context,
  });

  void _showLoading([String message = "Processing image"]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Flexible(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  void _hideLoading() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Returns a list of WordEntry models for each word/phrase found in the image.
  Future<List<WordEntry>> extractWordsFromImage(File imageFile) async {
    _showLoading("Processing image...");
    try {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final payload = {
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Extract all English words (or phrases) found in this image. For each, reply as a JSON list with these fields: word, meaning (in simple English), example (a clear sentence). Example format: [{\"word\": \"Apple\", \"meaning\": \"A round fruit...\", \"example\": \"She ate an apple.\"}]"
              },
              {
                "inlineData": {"mimeType": "image/jpeg", "data": base64Image}
              }
            ]
          }
        ]
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': apiKey,
        },
        body: jsonEncode(payload),
      );
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates[0]['content']['parts'][0]['text'];
          // Extract JSON array from text
          final jsonStart = text.indexOf('[');
          final jsonEnd = text.lastIndexOf(']');
          if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
            final jsonString = text.substring(jsonStart, jsonEnd + 1);
            final List<dynamic> decoded = jsonDecode(jsonString);
            return decoded.map((item) => WordEntry.fromJson(item as Map<String, dynamic>)).toList();
          }
        }
      }
      return [];
    } catch (e) {
      print('Error in Gemini OCR: $e');
      return [];
    } finally {
      _hideLoading();
    }
  }
}

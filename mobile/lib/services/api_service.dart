import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Android emulator reaches the host at 10.0.2.2; browser/desktop use localhost.
  // Physical phone -> flutter run --dart-define=API_URL=http://<PC-LAN-IP>:8000
  static const _overrideUrl = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_overrideUrl.isNotEmpty) return _overrideUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }
  static const maxUploadBytes = 30 * 1024 * 1024; // keep in sync with backend

  static Map<String, String> _headers({String? accessToken}) => {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

  static Future<({String answer, List<String> images})> sendMessage(
    String message,
    String sessionId, {
    String? accessToken,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: _headers(accessToken: accessToken),
      body: jsonEncode({'message': message, 'session_id': sessionId}),
    );
    if (res.statusCode != 200) throw Exception(_detail(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (
      answer: body['answer'] as String,
      images: (body['images'] as List? ?? const []).cast<String>(),
    );
  }

  /// Index a PDF or image on the backend so the agent can search it.
  /// Returns the file name it was stored under.
  static Future<String> uploadFile(
    Uint8List bytes,
    String filename, {
    String? accessToken,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'))
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
    if (accessToken != null && accessToken.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $accessToken';
    }
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200) throw Exception(_detail(res));
    return jsonDecode(utf8.decode(res.bodyBytes))['indexed'] as String;
  }

  static String _detail(http.Response res) {
    try {
      final detail = jsonDecode(utf8.decode(res.bodyBytes))['detail'];
      if (detail is String) return detail;
    } catch (_) {}
    return 'Server error ${res.statusCode}';
  }
}

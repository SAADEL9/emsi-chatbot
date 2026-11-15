import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ApiService {
  // Android emulator -> host machine is 10.0.2.2
  // Real phone -> use your PC's LAN IP, e.g. http://192.168.1.20:8000
  static const baseUrl = 'http://192.168.11.107:8000';
  static const maxUploadBytes = 20 * 1024 * 1024; // keep in sync with backend

  static Future<String> sendMessage(String message, String sessionId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message, 'session_id': sessionId}),
    );
    if (res.statusCode != 200) throw Exception(_detail(res));
    return jsonDecode(utf8.decode(res.bodyBytes))['answer'];
  }

  /// Index a PDF or image on the backend so the agent can search it.
  /// Returns the file name it was stored under.
  static Future<String> uploadFile(Uint8List bytes, String filename) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'))
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
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

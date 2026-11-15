import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Android emulator -> host machine is 10.0.2.2
  // Real phone -> use your PC's LAN IP, e.g. http://192.168.1.20:8000
  static const baseUrl = 'http://192.168.11.107:8000';

  static Future<String> sendMessage(String message, String sessionId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message, 'session_id': sessionId}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes))['answer'];
    }
    throw Exception('Server error ${res.statusCode}');
  }
}
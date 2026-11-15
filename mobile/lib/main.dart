import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() => runApp(const EmsiChatBotApp());

class EmsiChatBotApp extends StatelessWidget {
  const EmsiChatBotApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Emsi_chatBot',
        theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
        home: const ChatScreen(),
      );
}
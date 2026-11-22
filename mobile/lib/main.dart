import 'package:flutter/material.dart';

import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthController();
  await auth.init();
  runApp(EmsiChatBotApp(auth: auth));
}

class EmsiChatBotApp extends StatelessWidget {
  const EmsiChatBotApp({super.key, required this.auth});
  final AuthController auth;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'EMSI Chatbot',
        debugShowCheckedModeBanner: false,
        theme: emsiTheme(),
        home: AuthGate(auth: auth),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth});
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) => auth.isSignedIn
          ? ChatScreen(auth: auth)
          : LoginScreen(auth: auth),
    );
  }
}

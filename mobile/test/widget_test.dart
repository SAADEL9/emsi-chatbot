import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/services/auth_service.dart';

void main() {
  testWidgets('shows login when signed out', (WidgetTester tester) async {
    await tester.pumpWidget(EmsiChatBotApp(auth: AuthController()));

    expect(find.text('EMSI Chatbot'), findsOneWidget);
    expect(find.text('Bonjour ! 👋'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
  });

  testWidgets('shows the welcome chat when signed in', (WidgetTester tester) async {
    await tester.pumpWidget(
      EmsiChatBotApp(auth: AuthController.signedInForTest()),
    );

    expect(find.text('EMSI Chatbot'), findsOneWidget);
    expect(find.text('Bonjour ! 👋'), findsOneWidget);
    expect(find.text('Posez votre question...'), findsOneWidget);
    expect(find.text('En ligne'), findsOneWidget);
  });
}

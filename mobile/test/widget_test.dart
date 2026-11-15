import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('shows the empty chat state', (WidgetTester tester) async {
    await tester.pumpWidget(const EmsiChatBotApp());

    expect(find.text('Emsi chatBot'), findsOneWidget);
    expect(find.text('Ask about your course'), findsOneWidget);
  });
}

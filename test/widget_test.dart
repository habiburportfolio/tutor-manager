import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('App launches to Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const TutorManagerApp());
    await tester.pumpAndSettle();
    expect(find.text('Tutor Manager'), findsWidgets);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_os/app.dart';

void main() {
  testWidgets('Personal Life OS app shell renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const PersonalLifeOSApp());

    // Verify core navigation tabs render
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });
}

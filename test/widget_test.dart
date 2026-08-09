import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frethq/main.dart';

void main() {
  testWidgets('FretHQApp renders HomeScreen dashboard correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FretHQApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('FRET HQ'), findsOneWidget);
    expect(find.text('Identify Note'), findsOneWidget);
    expect(find.textContaining('START'), findsWidgets);
  });
}

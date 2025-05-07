import 'package:flutter_test/flutter_test.dart';

import 'package:kite_mobile/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KiteApp());
    expect(find.text('Kite'), findsOneWidget);
  });
}

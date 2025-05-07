import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:kite_mobile/api.dart';
import 'package:http/testing.dart';


import 'package:kite_mobile/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final api = KiteApi(client: MockClient((request) async => Response('', 400)));
    await tester.pumpWidget(KiteApp(api: api));
    expect(find.text('Kite'), findsOneWidget);
  });
}

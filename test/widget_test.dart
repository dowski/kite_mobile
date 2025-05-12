import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:kite_mobile/api.dart';
import 'package:http/testing.dart';

import 'package:kite_mobile/main.dart';
import 'package:kite_mobile/testing/models.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';

void main() {
  late KiteApp app;
  late FakeImagePreloader imagePreloader;
  setUp(() {
    imagePreloader = FakeImagePreloader();

    app = KiteApp(
      api: KiteApi(client: limitedClient),
      imagePreloader: imagePreloader,
    );
  });

  tearDown(() {
    imageCache.clear();
    imageCache.clearLiveImages();
    HttpOverrides.global = null;
  });

  group('Valid API responses', () {
    testWidgets('app launches', (WidgetTester tester) async {
      await tester.pumpWidget(app);
      expect(find.text('Kite'), findsOneWidget);
    });

    testWidgets('does not show error', (WidgetTester tester) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(find.byType(KiteLoadFailed), findsNothing);
      expect(find.text('Error loading'), findsNothing);
    });

    testWidgets('renders categories', (WidgetTester tester) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('World'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Foo'), findsNothing);
      expect(find.text('Today in History'), findsOneWidget);
    });

    testWidgets('renders headlines', (WidgetTester tester) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(
        find.text('India-Pakistan military tensions escalate after strikes'),
        findsOneWidget,
      );
      expect(find.text('Conflict'), findsOneWidget);
    });

    testWidgets('shows loading spinner when opening article', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(mockNetworkImages(() => app));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('India-Pakistan military tensions escalate after strikes'),
      );
      // Pump twice - once for navigation and once for image preload trigger.
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.text(
          'India launched missile strikes on what it described as "terrorist infrastructure" in Pakistan and Pakistan-administered Kashmir early on May 7, 2025, in response to a deadly attack on tourists in Kashmir last month. Pakistan condemned the strikes as "an act of war," claimed 26 civilians were killed, and said it had shot down five Indian fighter jets in retaliation. The confrontation marks the most serious military escalation between the nuclear-armed neighbors in over two decades.',
        ),
        findsNothing,
      );
      await tester.pumpAndSettle();
    });
  });

  testWidgets('can open articles', (WidgetTester tester) async {
    await tester.pumpWidget(mockNetworkImages(() => app));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('India-Pakistan military tensions escalate after strikes'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(KiteArticle), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(Image), findsNWidgets(2));
    // No placeholders, which are shown when image loading fails.
    expect(find.byType(Placeholder), findsNothing);
    expect(
      find.text(
        'India launched missile strikes on what it described as "terrorist infrastructure" in Pakistan and Pakistan-administered Kashmir early on May 7, 2025, in response to a deadly attack on tourists in Kashmir last month. Pakistan condemned the strikes as "an act of war," claimed 26 civilians were killed, and said it had shot down five Indian fighter jets in retaliation. The confrontation marks the most serious military escalation between the nuclear-armed neighbors in over two decades.',
      ),
      findsOneWidget,
    );
  });

  group('Image load failure', () {
    //TODO: this test fails when run with others due to mockNetworkImages not resetting state
    testWidgets('can open articles', (WidgetTester tester) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('India-Pakistan military tensions escalate after strikes'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(KiteArticle), findsOneWidget);
      // A placeholder is used when an image fails to load.
      expect(find.byType(Placeholder), findsOneWidget);
      expect(
        find.text(
          'India launched missile strikes on what it described as "terrorist infrastructure" in Pakistan and Pakistan-administered Kashmir early on May 7, 2025, in response to a deadly attack on tourists in Kashmir last month. Pakistan condemned the strikes as "an act of war," claimed 26 civilians were killed, and said it had shot down five Indian fighter jets in retaliation. The confrontation marks the most serious military escalation between the nuclear-armed neighbors in over two decades.',
        ),
        findsOneWidget,
      );
    });
  });

  group('Failed category list load request', () {
    var requestCount = 0;
    late MockClient initiallyFailingClient;

    setUp(() {
      requestCount = 0;
      // A client that fails on the first request.
      initiallyFailingClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return Response('', 404);
        }
        return limitedClientHandler(request);
      });
    });

    testWidgets('shows error screen', (WidgetTester tester) async {
      final api = KiteApi(client: initiallyFailingClient);
      await tester.pumpWidget(KiteApp(api: api));
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsNothing);
      expect(find.text('Error loading'), findsOneWidget);
    });

    testWidgets('can reload', (WidgetTester tester) async {
      final api = KiteApi(client: initiallyFailingClient);
      await tester.pumpWidget(KiteApp(api: api));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(find.text('Error loading'), findsNothing);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('World'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Foo'), findsNothing);
      expect(find.text('Today in History'), findsOneWidget);
    });
  });

  group('Failed article list load request', () {
    var requestCount = 0;
    late MockClient initiallyFailingClient;

    setUp(() {
      requestCount = 0;
      // A client that fails on the first article list request.
      initiallyFailingClient = MockClient((request) async {
        if (request.url.path == '/world.json') {
          requestCount++;
          if (requestCount == 1) {
            return Response('', 404);
          }
        }
        return limitedClientHandler(request);
      });
    });

    testWidgets('shows error screen', (WidgetTester tester) async {
      final api = KiteApi(client: initiallyFailingClient);
      await tester.pumpWidget(KiteApp(api: api));
      await tester.pumpAndSettle();
      // TabBar should show but no article list.
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('World'), findsOneWidget);
      expect(find.text('Error loading'), findsOneWidget);
      expect(
        find.text('India-Pakistan military tensions escalate after strikes'),
        findsNothing,
      );
    });

    testWidgets('can reload', (WidgetTester tester) async {
      final api = KiteApi(client: initiallyFailingClient);
      await tester.pumpWidget(KiteApp(api: api));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      // Upon reload, headlines load.
      expect(
        find.text('India-Pakistan military tensions escalate after strikes'),
        findsOneWidget,
      );
    });
  });
}

Future<Response> limitedClientHandler(Request request) async {
  switch (request.url) {
    case Uri(host: 'kite.kagi.com', path: '/kite.json'):
      return Response.bytes(
        utf8.encode(limitedJsonPayload),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    case Uri(host: 'kite.kagi.com', path: '/world.json'):
      return Response.bytes(
        utf8.encode(
          categoryPayload('World', clusterJsonList: '[$worldPayload]'),
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    case Uri(host: 'kite.kagi.com', path: '/business.json'):
      return Response.bytes(
        utf8.encode(categoryPayload('Business')),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    case Uri(host: 'kite.kagi.com', path: '/onthisday.json'):
      return Response.bytes(
        utf8.encode(categoryPayload('OnThisDay')),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    default:
      return Response('', 404);
  }
}

final limitedClient = MockClient(limitedClientHandler);

const limitedJsonPayload = r'''
{
  "timestamp": 1746628202,
  "categories": [
    {
      "name": "World",
      "file": "world.json"
    },
    {
      "name": "Business",
      "file": "business.json"
    },
    {
      "name": "Foo",
      "file": "foo.json"
    },
    {
      "name": "OnThisDay",
      "file": "onthisday.json"
    }
  ]
}
''';

String categoryPayload(String category, {String clusterJsonList = '[]'}) {
  return '''
{
  "category": "$category",
  "timestamp": 1746621686,
  "read": 674,
  "clusters": $clusterJsonList
}
''';
}

const worldPayload = r'''
{
  "cluster_number": 1,
  "category": "Conflict",
  "title": "India-Pakistan military tensions escalate after strikes",
  "short_summary": "India launched missile strikes on what it described as \"terrorist infrastructure\" in Pakistan and Pakistan-administered Kashmir early on May 7, 2025, in response to a deadly attack on tourists in Kashmir last month. Pakistan condemned the strikes as \"an act of war,\" claimed 26 civilians were killed, and said it had shot down five Indian fighter jets in retaliation. The confrontation marks the most serious military escalation between the nuclear-armed neighbors in over two decades.",
  "location": "India-Pakistan border region",
  "talking_points": [
    "Operation Sindoor: India targeted nine sites in Pakistan and Pakistan-administered Kashmir, claiming they were terrorist camps linked to the April 22 attack that killed 26 tourists in Pahalgam.",
    "Civilian casualties: Pakistan reported that 26 civilians were killed in the Indian strikes, while India reported 12 deaths from Pakistani shelling along the Line of Control.",
    "International reaction: Global powers including the US, China, Turkey, and Germany have called for restraint and de-escalation between the nuclear-armed neighbors.",
    "Military response: Pakistan claims to have shot down five Indian aircraft, while India acknowledged some of its jets had crashed on its territory.",
    "Diplomatic fallout: The crisis has led to expulsion of diplomats, suspension of trade, and closure of airspace between the two nations."
  ],
  "articles":[
  {
          "title": "Global community reacts to Indian strikes in Pakistan",
          "link": "https://www.dawn.com/news/1909055/global-community-reacts-to-indian-strikes-in-pakistan",
          "domain": "dawn.com",
          "date": "2025-05-07T09:38:14+00:00",
          "image": "https://kagiproxy.com/img/VSkdKFQWXf8VVFl89r1tmFx37nf33N4zx0WDJQpftoQl8HaRw5JOIuAFoI1mDPtfe3sRHxbHT2zOVeLE22COIzkDLCvyVVfLvwIoq0o389aYxSURTSpNqFY",
          "image_caption": "A vendor sells a morning Urdu newspaper with the headline ’Indian Strikes in Pakistan, in Lahore on May 7. — AFP."
        },
        {
          "title": "Pakistan downs 5 Indian jets as retaliation for late-night strikes at 6 sites: officials",
          "link": "https://www.dawn.com/news/1908824/pakistan-downs-5-indian-jets-as-retaliation-for-late-night-strikes-at-6-sites-officials",
          "domain": "dawn.com",
          "date": "2025-05-07T06:26:33+00:00",
          "image": "https://kagiproxy.com/img/noxHK1fEgFxKxeC9pMx8ENQAU2OIznqAqxPamgR62-5zcFmH6tcXdi8RbXkJo6HoTWpFOJ12BFZQhIGD_Fiwv39Fd7eAZ6VXV6z3LPffuD4TESnJmu6imIA",
          "image_caption": "The wreckage of a mosque is seen after Indian strikes in Muzaffarabad, AJK on May 7, 2025. — AFP"
        }
  ]
}
''';

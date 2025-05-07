import 'package:flutter/material.dart';
import 'package:kite_mobile/categories.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const KiteApp());
}

class KiteApp extends StatelessWidget {
  const KiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureProvider<Result<List<Category>, Exception>>(
      initialData: const Success([]),
      create: (BuildContext context) {
        final categories = HttpCategories(
          kiteUrl: 'https://kite.kagi.com/kite.json',
        );
        return categories.load();
      },
      child: Builder(
        builder: (context) {
          final categories = context.watch<Result<List<Category>, Exception>>();
          return KiteDispatcher(categories: categories);
        },
      ),
    );
  }
}

class KiteDispatcher extends StatelessWidget {
  final Result<List<Category>, Exception> categories;

  const KiteDispatcher({super.key, required this.categories});
  @override
  Widget build(BuildContext context) {
    return switch (categories) {
      Success(success: final categoryList) => DefaultTabController(
        length: categoryList.length,
        child: KiteMaterialApp(home: KiteHost(categories: categoryList)),
      ),
      Error(error: final error) => KiteMaterialApp(home: KiteLoadFailed()),
    };
  }
}

class KiteMaterialApp extends StatelessWidget {
  final Widget home;

  const KiteMaterialApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kite Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
      ),
      home: home,
    );
  }
}

class KiteScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? tabBar;

  const KiteScaffold({super.key, required this.body, this.tabBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Kite'),
        bottom: tabBar,
      ),
      body: body,
    );
  }
}

class KiteHost extends StatelessWidget {
  final List<Category> categories;

  const KiteHost({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return KiteScaffold(
      tabBar: TabBar(
        tabs: categories.map((category) => Tab(text: category.name)).toList(),
        isScrollable: true,
        labelPadding: EdgeInsets.only(left: 8, right: 8),
      ),
      body: TabBarView(
        children: [
          for (final category in categories) Center(child: Text(category.name)),
        ],
      ),
    );
  }
}

class KiteLoadFailed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //TODO(dowski): support reloading on error
    return KiteScaffold(body: Center(child: Text('Error loading')));
  }
}

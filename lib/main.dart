import 'package:flutter/material.dart';
import 'package:kite_mobile/api.dart';
import 'package:kite_mobile/articles.dart';
import 'package:kite_mobile/categories.dart';
import 'package:kite_mobile/models.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:provider/provider.dart';

void main() {
  final api = KiteApi();
  runApp(KiteApp(api: api));
}

class KiteApp extends StatelessWidget {
  final KiteApi api;
  
  const KiteApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ActiveCategoryModel()),
        FutureProvider<Result<List<Category>, Exception>>(
          initialData: const Success([]),
          create: (BuildContext context) async {
            final activeCategoryModel = context.read<ActiveCategoryModel>();
            final result = await api.loadCategories();
            result.whenSuccess((categories) {
              if (categories.isNotEmpty) {
                activeCategoryModel.setActiveCategory(categories.first);
              }
            });
            return result;
          },
        ),
        ProxyProvider<
          ActiveCategoryModel,
          Future<Result<List<Article>, Exception>>
        >(
          update: (context, model, _) async {
            final category = model.category;
            if (category == null || category is! ArticleCategory) {
              return const Success([]);
            }
            return api.loadArticles(category);
          },
        ),
      ],
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
        onTap:
            (value) => context.read<ActiveCategoryModel>().setActiveCategory(
              categories[value],
            ),
      ),
      body: TabBarView(
        children: [
          for (final category in categories) ArticleList(category: category),
        ],
      ),
    );
  }
}

class ArticleList extends StatelessWidget {
  final Category category;

  const ArticleList({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final future = context.watch<Future<Result<List<Article>, Exception>>>();
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final result = snapshot.data!;
        return switch (result) {
          Success(success: final articles) => Column(
            children: [
              Text(category.name),
              for (final article in articles) Text(article.title),
            ],
          ),
          Error(error: final error) => Center(child: Text(error.toString())),
        };
      },
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

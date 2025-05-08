import 'package:flutter/material.dart';
import 'package:kite_mobile/api.dart';
import 'package:kite_mobile/categories.dart';
import 'package:kite_mobile/colors.dart';
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
        ChangeNotifierProvider(
          create: (context) => CategoryListModel(api: api),
        ),
        ChangeNotifierProvider(create: (context) => ArticleListModel(api: api)),
      ],
      child: KiteDispatcher(),
    );
  }
}

class KiteDispatcher extends StatefulWidget {
  const KiteDispatcher({super.key});

  @override
  State<KiteDispatcher> createState() => _KiteDispatcherState();
}

class _KiteDispatcherState extends State<KiteDispatcher> {
  @override
  void initState() {
    super.initState();
    final model = context.read<CategoryListModel>();
    model.fetch();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryListModel>();
    return switch (categories.list) {
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
      routes: {
        '/article':
            (context) => Scaffold(body: Center(child: Text('Coming soon.'))),
      },
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
            (value) => context.read<CategoryListModel>().setActiveCategory(
              categories[value],
            ),
      ),
      body: TabBarView(
        children: [
          for (final category in categories)
            switch (category) {
              ArticleCategory() => ArticleList(category: category),
              OnThisDayCategory() => Center(child: Text('Coming soon.')),
            },
        ],
      ),
    );
  }
}

class ArticleList extends StatefulWidget {
  final ArticleCategory category;

  const ArticleList({super.key, required this.category});

  @override
  State<ArticleList> createState() => _ArticleListState();
}

class _ArticleListState extends State<ArticleList> {
  @override
  void initState() {
    super.initState();
    final model = context.read<ArticleListModel>();
    model.fetch(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ArticleListModel>();
    final articles = model.summaries(widget.category);
    if (articles == null) {
      return Center(child: CircularProgressIndicator());
    } else if (articles.isNotEmpty) {
      return ListView.builder(
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          final navigator = Navigator.of(context);
          return ListTile(
            title: Text(article.title),
            contentPadding: EdgeInsets.all(4),
            horizontalTitleGap: 0,
            leading: Container(width: 8, color: colorFromText(article.category), padding: EdgeInsets.zero,),
            subtitle: Text(
              article.category,
              style: TextStyle(color: colorFromText(article.category)),
            ),
            onTap: () => navigator.pushNamed('/article'),
          );
        },
      );
    } else {
      return Center(child: Text('No articles.'));
    }
  }
}

class KiteLoadFailed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //TODO(dowski): support reloading on error
    return KiteScaffold(body: Center(child: Text('Error loading')));
  }
}

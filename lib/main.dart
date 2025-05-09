import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kite_mobile/api.dart';
import 'package:kite_mobile/articles.dart';
import 'package:kite_mobile/categories.dart';
import 'package:kite_mobile/colors.dart';
import 'package:kite_mobile/models.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
        ChangeNotifierProvider(create: (context) => ArticlesModel(api: api)),
        ProxyProvider2<CategoryListModel, ArticlesModel, AllModels>(
          update:
              (context, categoryListModel, articlesModel, _) => AllModels(
                categoryListModel: categoryListModel,
                articlesModel: articlesModel,
              ),
        ),
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
      routes: {'/article': (context) => KiteArticleHost()},
    );
  }
}

class KiteScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? tabBar;
  final String title;

  const KiteScaffold({
    super.key,
    required this.body,
    this.tabBar,
    this.title = 'Kite',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
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
    final model = context.read<ArticlesModel>();
    model.fetch(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ArticlesModel>();
    final articles = model.headlines(widget.category);
    if (articles == null) {
      return Center(child: CircularProgressIndicator());
    } else if (articles.isNotEmpty) {
      return ListView.builder(
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final headline = articles[index];
          final navigator = Navigator.of(context);
          return ListTile(
            title: Text(headline.title),
            contentPadding: EdgeInsets.all(4),
            horizontalTitleGap: 0,
            leading: Container(
              width: 8,
              color: colorFromText(headline.category),
              padding: EdgeInsets.zero,
            ),
            subtitle: Text(
              headline.category,
              style: TextStyle(color: colorFromText(headline.category)),
            ),
            onTap: () {
              model.selectArticle(headline);
              navigator.pushNamed('/article');
            },
          );
        },
      );
    } else {
      return Center(child: Text('No articles.'));
    }
  }
}

class KiteArticleHost extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = context.watch<ArticlesModel>();
    final article = model.selectedArticle!;
    return KiteArticle(article: article);
  }
}

class KiteArticle extends StatefulWidget {
  final Article article;

  const KiteArticle({super.key, required this.article});

  @override
  State<KiteArticle> createState() => _KiteArticleState();
}

class _KiteArticleState extends State<KiteArticle> {
  bool _isImage1Loading = true;
  final _externalArticleKey = PageStorageKey('externalArticles');

  @override
  void initState() {
    super.initState();
    if (widget.article.image1 != null) {
      final image = NetworkImage(widget.article.image1!.url.toString());
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadImage1(image));
    } else {
      _isImage1Loading = false;
    }
  }

  Future<void> _loadImage1(ImageProvider image) async {
    await precacheImage(
      image,
      context,
      onError: (exception, stackTrace) {
        // Purposely empty - we don't do anything with preload errors.
      },
    );

    setState(() {
      _isImage1Loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KiteScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedOpacity(
              opacity: _isImage1Loading ? 0.0 : 1.0,
              duration: Durations.medium1,
              child:
                  _isImage1Loading
                      ? Container()
                      : ListView(
                        padding: EdgeInsets.all(16),
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  color: colorFromText(
                                    widget.article.headline.category,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.article.headline.title,
                                        style: TextStyle(fontSize: 24),
                                      ),
                                      Text(
                                        widget.article.headline.category,
                                        style: TextStyle(
                                          color: colorFromText(
                                            widget.article.headline.category,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            widget.article.summary,
                            style: TextStyle(fontSize: 16),
                          ),
                          if (widget.article.image1 != null) ...[
                            SizedBox(height: 16),
                            Image.network(
                              widget.article.image1!.url.toString(),
                              errorBuilder:
                                  (context, error, stackTrace) => Placeholder(),
                            ),
                            Text(widget.article.image1!.caption ?? ''),
                          ],
                          if (widget.article.talkingPoints.isNotEmpty) ...[
                            SizedBox(height: 16),
                            TalkingPointsWidget(
                              talkingPoints: widget.article.talkingPoints,
                            ),
                          ],
                          if (widget.article.image2 != null) ...[
                            SizedBox(height: 16),
                            Image.network(
                              widget.article.image2!.url.toString(),
                              errorBuilder:
                                  (context, error, stackTrace) => Placeholder(),
                            ),
                            Text(widget.article.image2!.caption ?? ''),
                          ],
                          if (widget.article.externalArticles.isNotEmpty) ...[
                            SizedBox(height: 16),
                            ExternalArticlesWidget(
                              key: _externalArticleKey,
                              articles: widget.article.externalArticles,
                            ),
                          ],
                        ],
                      ),
            ),
            if (_isImage1Loading) Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class TalkingPointsWidget extends StatelessWidget {
  final List<TalkingPoint> talkingPoints;

  TalkingPointsWidget({required this.talkingPoints});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Highlights', style: TextStyle(fontSize: 24)),
        for (final talkingPoint in talkingPoints) ...[
          SizedBox(height: 16),
          Text(
            talkingPoint.heading,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(talkingPoint.body, style: TextStyle(fontSize: 16)),
        ],
      ],
    );
  }
}

class ExternalArticlesWidget extends StatelessWidget {
  final List<ExternalArticle> articles;

  ExternalArticlesWidget({super.key, required this.articles});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('Sources', style: TextStyle(fontSize: 24)),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final article in articles) ...[
          ListTile(
            title: Text(article.title),
            subtitle: Text(article.domain),
            onTap: () => launchUrl(article.link),
          ),
        ],
      ],
    );
  }
}

class KiteLoadFailed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return KiteScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading'),
            IconButton.filled(
              onPressed: () {
                context.read<AllModels>().reload();
              },
              icon: Icon(Icons.refresh),
            ),
            Text('Check your internet connection and try again'),
          ],
        ),
      ),
    );
  }
}

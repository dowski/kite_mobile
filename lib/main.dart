import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:kite_mobile/api.dart';
import 'package:kite_mobile/articles.dart';
import 'package:kite_mobile/categories.dart';
import 'package:kite_mobile/colors.dart';
import 'package:kite_mobile/models.dart';
import 'package:kite_mobile/thisday.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  final api = KiteApi();
  runApp(KiteApp(api: api));
}

/// This is the launcher widget for the app.
///
/// It wires up the dependencies using [Provider] and prepares the corr app.
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
        ChangeNotifierProvider(create: (context) => OnThisDayModel(api: api)),
      ],
      child: KiteHost(),
    );
  }
}

/// The host widget for the app.
///
/// It kicks off data loading and then dispatches to either the [KiteCore]
/// that handles all other use of the app or shows an error page in the
/// case that data load failed.
class KiteHost extends StatefulWidget {
  const KiteHost({super.key});

  @override
  State<KiteHost> createState() => _KiteHostState();
}

class _KiteHostState extends State<KiteHost> {
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
        child: KiteMaterialApp(home: KiteCore(categories: categoryList)),
      ),
      Error(error: final error) => KiteMaterialApp(home: KiteLoadFailed(error)),
    };
  }
}

/// A convenient wrapper around [MaterialApp] for Kite.
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

/// A convenient wrapper around [Scaffold] for Kite.
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
        title: Row(
          children: [
            Image.asset('assets/icon/kite.png', width: 32, height: 32),
            Text(title),
          ],
        ),
        bottom: tabBar,
      ),
      body: body,
    );
  }
}

/// The core Kite widget.
///
/// Renders the main app UI including the [TabBar] and the views associated
/// with each tab.
class KiteCore extends StatelessWidget {
  final List<Category> categories;

  const KiteCore({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return KiteScaffold(
      tabBar: TabBar(
        tabs:
            categories
                .map((category) => Tab(text: category.displayName))
                .toList(),
        isScrollable: true,
        labelPadding: EdgeInsets.only(left: 8, right: 8),
        onTap:
            (value) =>
                context.read<CategoryListModel>().active = categories[value],
      ),
      body: TabBarView(
        children: [
          for (final category in categories)
            switch (category) {
              ArticleCategory() => ArticleList(category: category),
              OnThisDayCategory() => OnThisDay(category),
            },
        ],
      ),
    );
  }
}

/// A list of articles loaded from the [KiteApi].
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
    final result = model.headlines(widget.category);
    if (result == null) {
      return Center(child: CircularProgressIndicator());
    }
    switch (result) {
      case Success(success: final articles):
        if (articles.isNotEmpty) {
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
      case Error(error: final error):
        return RefreshOnError(error);
    }
  }
}

/// A host widget for [KiteArticle].
///
/// Rebuilds when a selected article changes.
class KiteArticleHost extends StatelessWidget {
  const KiteArticleHost({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ArticlesModel>();
    final article = model.selectedArticle!;
    return KiteArticle(article: article);
  }
}

/// A widget that renders a full article for Kite.
///
/// Handles a loading state while the first image is fetched. That prevents
/// the content "jumping" if the widget rendered the rest of its contents first.
//NOTE: if the Kite API returned image dimensions, the initial spinner could be avoided.
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

/// A supporting widget for [KiteArticle] that renders highlights.
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

/// A supporting widget for [KiteArticle] that renders external article links.
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

/// A widget that shows a list of historical events.
class OnThisDay extends StatefulWidget {
  final OnThisDayCategory category;

  const OnThisDay(this.category);

  @override
  State<OnThisDay> createState() => _OnThisDayState();
}

class _OnThisDayState extends State<OnThisDay> {
  @override
  void initState() {
    super.initState();
    final model = context.read<OnThisDayModel>();
    model.fetch(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<OnThisDayModel>();
    final result = model.history;
    return switch (result) {
      Success(success: final history) => ListView.builder(
        itemCount: history.length,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final note = history[index];
          return OnThisDayEvent(historicalNote: note);
        },
      ),
      Error(error: final error) => RefreshOnError(error),
      null => Center(child: CircularProgressIndicator()),
    };
  }
}

class OnThisDayEvent extends StatelessWidget {
  final HistoricalNote historicalNote;

  const OnThisDayEvent({super.key, required this.historicalNote});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Stack(
              children: [
                Positioned(
                  top: 6,
                  right: 0,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      historicalNote.year,
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(90),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  width: 4,
                  left: 6,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Html(
              data: historicalNote.content,
              onAnchorTap: (url, attributes, element) {
                if (url != null) launchUrl(Uri.parse(url));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class KiteLoadFailed extends StatelessWidget {
  final ExceptionWithRetry error;

  const KiteLoadFailed(this.error);

  @override
  Widget build(BuildContext context) {
    return KiteScaffold(body: RefreshOnError(error));
  }
}

/// A widget that shows a reload button for retrying after an error.
class RefreshOnError extends StatelessWidget {
  final ExceptionWithRetry error;

  const RefreshOnError(this.error);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error loading'),
          IconButton.filled(onPressed: error.retry, icon: Icon(Icons.refresh)),
          Text('Check your internet connection and try again'),
        ],
      ),
    );
  }
}

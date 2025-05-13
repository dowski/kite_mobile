import 'package:flutter_test/flutter_test.dart';
import 'package:kite_mobile/api.dart';
import 'package:kite_mobile/articles.dart';
import 'package:kite_mobile/categories.dart';
import 'package:kite_mobile/models.dart';
import 'package:kite_mobile/thisday.dart';
import 'package:multiple_result/src/result.dart';

void main() {
  group(CategoryListModel, () {
    test('notifies listener on successful load', () async {
      final api = _FakeKiteApi();
      final model = CategoryListModel(api: api);
      var notified = false;
      model.addListener(() => notified = true);
      await model.fetch();
      expect(notified, true);
    });

    test('categories available after successful load', () async {
      final api = _FakeKiteApi(
        categoryListResults: [Success(fakeCategoryList)],
      );
      final model = CategoryListModel(api: api);
      await model.fetch();
      expect(model.list.tryGetSuccess(), equals(fakeCategoryList));
    });

    test('subsequent fetch after success ignored', () async {
      // Setup the API so it will return an empty list after the initial result.
      final api = _FakeKiteApi(
        categoryListResults: [Success(fakeCategoryList), Success([])],
      );
      final model = CategoryListModel(api: api);
      Result<List<Category>, ExceptionWithRetry>? result;
      model.addListener(() => result = model.list);
      // Fetch and verify that the initial result was received.
      await model.fetch();
      expect(result?.tryGetSuccess(), equals(fakeCategoryList));
      // Fetch and verify that the initial result is still present.
      await model.fetch();
      expect(result?.tryGetSuccess(), equals(fakeCategoryList));
    });

    test('notifies listener on failed load', () async {
      final api = _FakeKiteApi(categoryListResults: [Error(Exception())]);
      final model = CategoryListModel(api: api);
      var notified = false;
      model.addListener(() => notified = true);
      await model.fetch();
      expect(notified, true);
    });

    test('can trigger reload on failure', () async {
      // Setup the API so it will initially fail and then return a category list.
      final api = _FakeKiteApi(
        categoryListResults: [Error(Exception()), Success(fakeCategoryList)],
      );
      final model = CategoryListModel(api: api);
      Result<List<Category>, ExceptionWithRetry>? result;
      model.addListener(() => result = model.list);
      // Trigger the first fetch which should be a failure.
      await model.fetch();
      expect(result?.isError(), true);
      // Use the exception object to trigger another request and verify it works.
      await result?.tryGetError()?.retry();
      expect(result?.tryGetSuccess(), equals(fakeCategoryList));
    });
  });

  group(ArticlesModel, () {
    test('listener can read headlines on successful load', () async {
      final api = _FakeKiteApi(articleListResults: [Success(fakeArticleList)]);
      final model = ArticlesModel(api: api);
      Result<List<ArticleHeadline>, ExceptionWithRetry>? result;
      model.addListener(() => result = model.headlines(fakeCategoryList.first));
      await model.fetch(fakeCategoryList.first);
      final headline = result?.tryGetSuccess()?.first;
      expect(headline?.title, equals(fakeArticleList.first.headline.title));
      expect(
        headline?.category,
        equals(fakeArticleList.first.headline.category),
      );
    });

    test('subsequent fetch after success ignored', () async {
      final api = _FakeKiteApi(
        articleListResults: [Success(fakeArticleList), Success([])],
      );
      final model = ArticlesModel(api: api);
      Result<List<ArticleHeadline>, ExceptionWithRetry>? result;
      model.addListener(() => result = model.headlines(fakeCategoryList.first));
      // Fetch and verify that the initial result was received.
      await model.fetch(fakeCategoryList.first);
      expect(result?.tryGetSuccess(), hasLength(1));
      // Fetch and verify that the initial result is still present.
      await model.fetch(fakeCategoryList.first);
      expect(result?.tryGetSuccess(), hasLength(1));
    });

    test('can trigger reload on failure', () async {
      // Setup the API so it will initially fail and then return an article list.
      final api = _FakeKiteApi(
        articleListResults: [Error(Exception()), Success(fakeArticleList)],
      );
      final model = ArticlesModel(api: api);
      Result<List<ArticleHeadline>, ExceptionWithRetry>? result;
      model.addListener(() => result = model.headlines(fakeCategoryList.first));
      // Trigger the first fetch which should be a failure.
      await model.fetch(fakeCategoryList.first);
      expect(result?.isError(), true);
      // Use the exception object to trigger another request and verify it works.
      await result?.tryGetError()?.retry();
      expect(result?.tryGetSuccess(), hasLength(1));
    });
  });
}

const fakeCategoryList = [ArticleCategory(name: "Foo", file: "foo.json")];
final fakeArticleList = [
  Article(
    headline: ArticleHeadline(category: 'Foo', title: 'A foo article'),
    summary: 'This is all about foo. So much foo. Unbelievable.',
    location: 'Somewhere, Foo',
    externalArticles: [
      ExternalArticle(
        title: 'You won\'t believe this foo',
        domain: 'example.com',
        link: Uri.parse('https://example.com/foo'),
        date: '2025/01/01',
        image: Uri.parse('https://example.com/foo.jpg'),
        imageCaption: 'Foo foo foo!',
      ),
    ],
    talkingPoints: [
      TalkingPoint(heading: 'A thing', body: 'Stuff about a thing'),
      TalkingPoint(heading: 'Another thing', body: 'Things about things'),
    ],
  ),
];

// TODO: move to dedicated fake lib if needed elsewhere
final class _FakeKiteApi implements KiteApi {
  final List<Result<List<Article>, Exception>> articleListResults;
  var articleListCalls = 0;
  final List<Result<List<Category>, Exception>> categoryListResults;
  var categoryListCalls = 0;
  final List<Result<List<HistoricalNote>, Exception>> historicalNoteListResults;
  var historicalNoteListCalls = 0;

  _FakeKiteApi({
    this.articleListResults = const [Success([])],
    this.categoryListResults = const [Success([])],
    this.historicalNoteListResults = const [Success([])],
  });

  @override
  Future<Result<List<Article>, Exception>> loadArticles(
    ArticleCategory category,
  ) {
    return Future.value(
      articleListResults.elementAtOrNull(articleListCalls++) ??
          articleListResults.last,
    );
  }

  @override
  Future<Result<List<Category>, Exception>> loadCategories() {
    return Future.value(
      categoryListResults.elementAtOrNull(categoryListCalls++) ??
          categoryListResults.last,
    );
  }

  @override
  Future<Result<List<HistoricalNote>, Exception>> loadOnThisDay(
    OnThisDayCategory category,
  ) {
    return Future.value(
      historicalNoteListResults.elementAtOrNull(historicalNoteListCalls++) ??
          historicalNoteListResults.last,
    );
  }
}

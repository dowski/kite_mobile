import 'package:flutter/material.dart';
import 'package:kite_mobile/api.dart';
import 'package:kite_mobile/articles.dart';
import 'package:kite_mobile/categories.dart';
import 'package:kite_mobile/thisday.dart';
import 'package:multiple_result/multiple_result.dart';

/// An observable model that can be used to load and consume [Category] data.
/// 
/// Uses the [KiteApi] and notifies observers when data is changed.
final class CategoryListModel extends ChangeNotifier {
  final KiteApi _api;
  Result<List<Category>, ExceptionWithRetry>? _categories;
  Category? _activeCategory;

  CategoryListModel({required KiteApi api}) : _api = api;

  /// The currently selected category.
  /// 
  /// Listeners will be notified when it changes.
  Category? get active => _activeCategory;
  set active(Category? value) {
    _activeCategory = value;
    notifyListeners();
  }

  /// The list of available categories.
  /// 
  /// If there was an error loading the categories, it will contain
  /// an [ExceptionWithRetry] instead which allows retrying the load.
  Result<List<Category>, ExceptionWithRetry> get list =>
      _categories ?? const Success([]);

  /// Triggers a load of categories.
  /// 
  /// If they've already been loaded, calling is a no-op.
  /// 
  /// Notifies listeners when the load completes.
  Future<void> fetch() async {
    if (_categories != null) return;
    final result = await _api.loadCategories();
    _categories = result.mapError(
      (error) => ExceptionWithRetry(error, () async {
        _reset();
        await fetch();
      }),
    );
    notifyListeners();
  }

  void _reset() {
    _categories = null;
    notifyListeners();
  }
}

/// An observable model that can be used to load and consume [Article] data.
/// 
/// Uses the [KiteApi] and notifies observers when data is changed.
final class ArticlesModel extends ChangeNotifier {
  final KiteApi _api;
  final Map<ArticleCategory, Result<List<ArticleHeadline>, ExceptionWithRetry>> _headlines = {};
  final Map<ArticleHeadline, Article> _articles = {};
  Article? selectedArticle;

  ArticlesModel({required KiteApi api}) : _api = api;

  /// Triggers a load of articles for a category.
  /// 
  /// If they've already been loaded successfully, calling is a no-op.
  /// 
  /// Notifies listeners when the load completes.
  Future<void> fetch(ArticleCategory category) async {
    if (_headlines[category] is Success) {
      return;
    }
    final result = await _api.loadArticles(category);
    _headlines[category] = result.map(
      successMapper: (articles) {
        // Transform data into headlines and articles.
        articles.map((article) => article.headline).toList();
        _articles.addEntries(
          articles.map((article) => MapEntry(article.headline, article)),
        );
        return articles.map((article) => article.headline).toList();
      },
      errorMapper: (error) {
        return ExceptionWithRetry(error, () async {
          _reset();
          await fetch(category);
        });
      },
    );
    notifyListeners();
  }

  /// Available headlines, or an error that allows retrying the load.
  Result<List<ArticleHeadline>, ExceptionWithRetry>? headlines(
    ArticleCategory category,
  ) => _headlines[category];

  /// Sets the selected article on the model and notifies listeners.
  void selectArticle(ArticleHeadline headline) {
    selectedArticle = _articles[headline];
    notifyListeners();
  }

  void _reset() {
    selectedArticle = null;
    _headlines.clear();
    _articles.clear();
    notifyListeners();
  }
}

/// An observable model that can be used to load and consume [HistoricalNote] data.
/// 
/// Uses the [KiteApi] and notifies observers when data is changed.
final class OnThisDayModel extends ChangeNotifier {
  final KiteApi _api;
  Result<List<HistoricalNote>, ExceptionWithRetry>? _history;

  OnThisDayModel({required KiteApi api}) : _api = api;

  /// The list of historical events fetched from the API.
  /// 
  /// If there was an [Error], the load can be retried.
  Result<List<HistoricalNote>, ExceptionWithRetry>? get history => _history;

  /// Loads historical note data from the backend.
  /// 
  /// Notifies listeners when the load completes.
  Future<void> fetch(OnThisDayCategory category) async {
    if (_history != null) return;
    final result = await _api.loadOnThisDay(category);
    _history = result.mapError((error) => ExceptionWithRetry(error, () async {
          _reset();
          await fetch(category);
        }));
    notifyListeners();
  }

  void _reset() {
    _history = null;
    notifyListeners();
  }
}

/// A bundle of an original [Exception] and a callback to [retry].
/// 
/// Useful for resolving transient load errors (e.g. flaky network).
class ExceptionWithRetry implements Exception {
  final Future<void> Function() retry;
  final Exception exception;

  ExceptionWithRetry(this.exception, this.retry);
}

abstract interface class ImagePreloader {
  Future<void> precacheImage(BuildContext context, ImageProvider image);
}

final class FlutterImagePreloader implements ImagePreloader {
  const FlutterImagePreloader();

  @override
  Future<void> precacheImage(BuildContext context, ImageProvider image) async {
    await precacheImage(context, image);
  }
}
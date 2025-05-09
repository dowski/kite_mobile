import 'package:flutter/material.dart';
import 'package:kite_mobile/api.dart';
import 'package:kite_mobile/articles.dart';
import 'package:kite_mobile/categories.dart';
import 'package:multiple_result/multiple_result.dart';

final class CategoryListModel extends ChangeNotifier {
  final KiteApi _api;
  Result<List<Category>, ExceptionWithRetry>? _categories;
  Category? _activeCategory;

  CategoryListModel({required KiteApi api}) : _api = api;

  Category? get active => _activeCategory;
  Result<List<Category>, ExceptionWithRetry> get list =>
      _categories ?? const Success([]);

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

  void setActiveCategory(Category category) {
    _activeCategory = category;
    notifyListeners();
  }
}

final class ArticlesModel extends ChangeNotifier {
  final KiteApi _api;
  final Map<ArticleCategory, Result<List<ArticleHeadline>, ExceptionWithRetry>> _headlines = {};
  final Map<ArticleHeadline, Article> _articles = {};
  Article? selectedArticle;

  ArticlesModel({required KiteApi api}) : _api = api;

  Future<void> fetch(ArticleCategory category) async {
    if (_headlines[category] is Success) {
      debugPrint('already fetched ${category.name}');
      return;
    }
    final result = await _api.loadArticles(category);
    debugPrint('fetched');
    _headlines[category] = result.map(
      successMapper: (articles) {
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
    debugPrint('notifying');
    notifyListeners();
  }

  Result<List<ArticleHeadline>, ExceptionWithRetry>? headlines(
    ArticleCategory category,
  ) => _headlines[category];

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

class ExceptionWithRetry implements Exception {
  final Future<void> Function() retry;
  final Exception exception;

  ExceptionWithRetry(this.exception, this.retry);
}

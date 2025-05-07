import 'package:flutter/material.dart';
import 'package:kite_mobile/api.dart';
import 'package:kite_mobile/articles.dart';
import 'package:kite_mobile/categories.dart';
import 'package:multiple_result/multiple_result.dart';

final class CategoryListModel extends ChangeNotifier {
  final KiteApi _api;
  Result<List<Category>, Exception>? _categories;
  Category? _activeCategory;

  CategoryListModel({required KiteApi api}): _api = api;

  Category? get active => _activeCategory;
  Result<List<Category>, Exception> get list => _categories ?? const Success([]);

  Future<void> fetch() async {
    if (_categories != null) return;
    _categories = await _api.loadCategories();
    notifyListeners();
  }

  void setActiveCategory(Category category) {
    _activeCategory = category;
    notifyListeners();
  }
}

final class ArticleListModel extends ChangeNotifier {
  final KiteApi _api;
  final Map<ArticleCategory, List<ArticleSummary>> _articles = {};

  ArticleListModel({required KiteApi api}): _api = api;

  Future<void> fetch(ArticleCategory category) async {
    if (_articles.containsKey(category)) {
      return;
    }
    final result = await _api.loadArticles(category);
    result.mapSuccess((articles) {
      _articles[category] = articles;
      notifyListeners();
    });
  }

  List<ArticleSummary>? summaries(ArticleCategory category) => _articles[category];
}

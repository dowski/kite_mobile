import 'package:flutter/material.dart';
import 'package:kite_mobile/categories.dart';

final class ActiveCategoryModel extends ChangeNotifier {
  Category? _activeCategory;

  Category? get category => _activeCategory;

  void setActiveCategory(Category category) {
    _activeCategory = category;
    notifyListeners();
  }
}
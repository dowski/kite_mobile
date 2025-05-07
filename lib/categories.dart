import 'package:multiple_result/multiple_result.dart';

const defaultCategoryNames = [
  "World",
  "Business",
  "Technology",
  "Science",
  "Sports",
  "OnThisDay",
];

abstract interface class Categories {
  Future<Result<List<Category>, Exception>> load();
}

sealed class Category {
  final String name;
  final String file;

  const Category({required this.name, required this.file});

  factory Category.fromJson(Map<String, dynamic> json) {
    if (json['name'] == 'OnThisDay') {
      return OnThisDayCategory(name: json['name'], file: json['file']);
    } else {
      return ArticleCategory(name: json['name'], file: json['file']);
    }
  }
}

final class ArticleCategory extends Category {
  const ArticleCategory({required super.name, required super.file});
}

final class OnThisDayCategory extends Category {
  const OnThisDayCategory({required super.name, required super.file});
}

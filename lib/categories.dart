import 'package:multiple_result/multiple_result.dart';

// TODO: consider custom categories.
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

/// Data for categories returned from the Kite API.
///
/// Two broad types are supported: articles and "on this day". The data
/// received when fetching each type is different, and codifying that here
/// makes it easier for consuming code to deal with [Category] data.
sealed class Category {
  final String name;
  final String file;

  String get displayName;

  const Category({required this.name, required this.file});

  factory Category.fromJson(Map<String, dynamic> json) {
    if (json['name'] == 'OnThisDay') {
      return OnThisDayCategory(name: json['name'], file: json['file']);
    } else {
      return ArticleCategory(name: json['name'], file: json['file']);
    }
  }

  @override
  bool operator ==(Object other) {
    return other is Category && other.name == name && other.file == file;
  }

  @override
  int get hashCode {
    return Object.hash(name, file);
  }
}

final class ArticleCategory extends Category {
  const ArticleCategory({required super.name, required super.file});

  @override
  String get displayName => name;
}

final class OnThisDayCategory extends Category {
  const OnThisDayCategory({required super.name, required super.file});

  @override
  String get displayName => 'Today in History';
}

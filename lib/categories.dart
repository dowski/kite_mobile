import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multiple_result/multiple_result.dart';

const _defaultCategoryNames = [
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

final class HttpCategories implements Categories {
  final Uri _url;

  HttpCategories({required String kiteUrl}) : _url = Uri.parse(kiteUrl);

  @override
  Future<Result<List<Category>, Exception>> load() async {
    final response = await http.get(_url);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final categories = json['categories'] as List<dynamic>;
      return Success(
        categories
            .map((dynamic item) => item as Map<String, dynamic>)
            .where((json) => _defaultCategoryNames.contains(json['name']))
            .map((json) => Category(name: json['name'], file: json['file']))
            .toList(),
      );
    }
    return Error(Exception(response.body));
  }
}

final class Category {
  final String name;
  final String file;

  const Category({required this.name, required this.file});
}

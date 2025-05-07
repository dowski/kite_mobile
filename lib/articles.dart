import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multiple_result/multiple_result.dart';

abstract interface class Articles {
  Future<Result<List<Article>, Exception>> load();
}

//TODO(dowski): refactor into a KagiApi class
final class HttpArticles implements Articles {
  final Uri _categoryUrl;

  HttpArticles({required String categoryUrl}) : _categoryUrl = Uri.parse(categoryUrl);

  @override
  Future<Result<List<Article>, Exception>> load() async {
    final response = await http.get(_categoryUrl);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final clusters = json['clusters'] as List<dynamic>;
      return Success(
        clusters
            .map((dynamic item) => item as Map<String, dynamic>)
            .map((json) => Article(title: json['title'], category: json['category']))
            .toList(),
      );
    }
    return Error(Exception(response.body));
  }
}
final class Article {
  final String title;
  final String category;

  const Article({required this.title, required this.category});
}
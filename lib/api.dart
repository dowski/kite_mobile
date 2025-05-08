import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kite_mobile/articles.dart';
import 'package:kite_mobile/categories.dart';
import 'package:kite_mobile/thisday.dart';
import 'package:multiple_result/multiple_result.dart';

class KiteApi {
  static const _host = 'kite.kagi.com';
  static final _categoryUrl = Uri.https(_host, 'kite.json');

  final http.Client _client;

  KiteApi({http.Client? client}) : _client = client ?? http.Client();

  Future<Result<Map<String, dynamic>, Exception>> _rawFetch(Uri url) async {
    try {
      final response = await _client.get(url);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Success(json);
      }
      return Error(Exception(response.body));
    } on Exception catch (e) {
      return Error(e);
    }
  }

  Future<Result<List<Category>, Exception>> loadCategories() async {
    final result = await _rawFetch(_categoryUrl);
    return result.mapSuccess(
      (categoryJson) =>
          (categoryJson['categories'] as List<dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .where((json) => defaultCategoryNames.contains(json['name']))
              .map((json) {
                if (json['name'] == 'OnThisDay') {
                  return OnThisDayCategory(
                    name: json['name'],
                    file: json['file'],
                  );
                } else {
                  return ArticleCategory(
                    name: json['name'],
                    file: json['file'],
                  );
                }
              })
              .toList(),
    );
  }

  Future<Result<List<Article>, Exception>> loadArticles(
    ArticleCategory category,
  ) async {
    final result = await _rawFetch(Uri.https(_host, category.file));
    return result.mapSuccess(
      (articlesJson) =>
          (articlesJson['clusters'] as List<dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .map(Article.fromJson)
              .nonNulls
              .toList(),
    );
  }

  Future<Result<List<HistoricalNote>, Exception>> loadOnThisDay(
    OnThisDayCategory category,
  ) async {
    final result = await _rawFetch(Uri.https(_host, category.file));
    return result.mapSuccess(
      (historyJson) =>
          (historyJson['events'] as List<dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .map(HistoricalNote.fromJson)
              .nonNulls
              .toList(),
    );
  }
}

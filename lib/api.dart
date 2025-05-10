import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kite_mobile/articles.dart';
import 'package:kite_mobile/categories.dart';
import 'package:kite_mobile/thisday.dart';
import 'package:multiple_result/multiple_result.dart';

/// An implementation of the Kite API.
/// 
/// Call [loadCategories] to find out what data is available.
/// 
/// Then call [loadArticles] and pass a category to retrieve available
/// articles.
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

  /// Returns categories from the Kite backend.
  /// 
  /// Most categories are [ArticleCategory]. There is also support for
  /// [OnThisDayCategory], which powers the 'Today in History' feature.
  /// 
  /// The [Result] will be [Success] or [Error]. Calling code can react
  /// to that and do the right thing in either case (show content, show
  /// error message).
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

  /// Returns a list of articles for an [ArticleCategory].
  /// 
  /// The [Result] will be [Success] or [Error]. Calling code can react
  /// to that and do the right thing in either case (show content, show
  /// error message).
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

  /// Returns historical events for this day.
  /// 
  /// The [Result] will be [Success] or [Error]. Calling code can react
  /// to that and do the right thing in either case (show content, show
  /// error message).
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

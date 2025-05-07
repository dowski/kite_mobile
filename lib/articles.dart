final class ArticleSummary {
  final String title;
  final String category;

  const ArticleSummary({required this.title, required this.category});

  static ArticleSummary? fromJson(Map<String, dynamic> json) {
    try {
      return ArticleSummary(title: json['title'], category: json['category']);
    } catch (e) {
      return null;
    }
  }
}

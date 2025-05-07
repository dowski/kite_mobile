final class Article {
  final String title;
  final String category;

  const Article({required this.title, required this.category});

  static Article? fromJson(Map<String, dynamic> json) {
    try {
      return Article(title: json['title'], category: json['category']);
    } catch (e) {
      return null;
    }
  }
}

/// A headline for an article shown in Kite.
/// 
/// Data typically comes from the Kite JSON backend.
final class ArticleHeadline {
  final String title;
  final String category;

  const ArticleHeadline({required this.title, required this.category});

  static ArticleHeadline? fromJson(Map<String, dynamic> json) {
    try {
      return ArticleHeadline(title: json['title'], category: json['category']);
    } catch (e) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is ArticleHeadline &&
        other.title == title &&
        other.category == category;
  }

  @override
  int get hashCode {
    return Object.hash(title, category);
  }
}

/// A full article for Kite.
/// 
/// Data typically comes from the Kite JSON backend.
// TODO: add more content to enrich the article viewing experience 
final class Article {
  final ArticleHeadline headline;
  final String summary;
  final String location;
  final List<ExternalArticle> externalArticles;
  final List<TalkingPoint> talkingPoints;

  const Article({
    required this.headline,
    required this.summary,
    required this.location,
    required this.externalArticles,
    required this.talkingPoints,
  });

  static Article? fromJson(Map<String, dynamic> json) {
    final headline = ArticleHeadline.fromJson(json);
    if (headline == null) {
      return null;
    }
    return Article(
      headline: headline,
      summary: json['short_summary'],
      location: json['location'],
      externalArticles:
          (json['articles'] as List<dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .map(ExternalArticle.fromJson)
              .nonNulls
              .toList(),
      talkingPoints:
          (json['talking_points'] as List<dynamic>)
              .map((item) => item as String)
              .map(TalkingPoint.fromString)
              .nonNulls
              .toList(),
    );
  }

  /// The first image to show for an article.
  ArticleImage? get image1 => ArticleImage.fromExternalOrNull(
    externalArticles
        .where((article) => article.image != null)
        .elementAtOrNull(0),
  );
  
  /// The second image to show for an article.
  ArticleImage? get image2 => ArticleImage.fromExternalOrNull(
    externalArticles
        .where((article) => article.image != null)
        .elementAtOrNull(1),
  );
}

final class ExternalArticle {
  final String title;
  final String domain;
  final Uri link;
  final String date;
  final Uri? image;
  final String? imageCaption;

  ExternalArticle({
    required this.title,
    required this.domain,
    required this.link,
    required this.date,
    required this.image,
    required this.imageCaption,
  });

  static ExternalArticle? fromJson(Map<String, dynamic> json) {
    return ExternalArticle(
      title: json['title'],
      domain: json['domain'],
      link: Uri.parse((json['link'] as String).trim()),
      date: json['date'],
      image:
          json['image'] == null || json['image'].isEmpty
              ? null
              : Uri.parse((json['image'] as String).trim()),
      imageCaption: json['image_caption'],
    );
  }
}

final class ArticleImage {
  final Uri url;
  final String? caption;

  ArticleImage({required this.url, this.caption});

  static ArticleImage? fromExternalOrNull(ExternalArticle? article) {
    if (article == null || article.image == null) {
      return null;
    }
    return ArticleImage(url: article.image!, caption: article.imageCaption);
  }
}

final class TalkingPoint {
  final String heading;
  final String body;

  const TalkingPoint({required this.heading, required this.body});

  static TalkingPoint? fromString(String rawTalkingPoint) {
    final index = rawTalkingPoint.indexOf(':');
    final (heading, body) =
        index >= 0
            ? (
              rawTalkingPoint.substring(0, index),
              rawTalkingPoint.substring(index + 1),
            )
            : (null, null);
    if (heading == null || body == null) {
      return null;
    }
    return TalkingPoint(heading: heading, body: body.trim());
  }
}

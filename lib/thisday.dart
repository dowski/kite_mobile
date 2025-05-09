sealed class HistoricalNote {
  final String year;
  final String content;
  final double sortYear;

  const HistoricalNote({
    required this.year,
    required this.content,
    required this.sortYear,
  });

  static HistoricalNote? fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'people') {
      return HistoricPerson(
        year: json['year'],
        content: json['content'],
        sortYear: (json['sort_year'] as num).toDouble(),
      );
    } else if (json['type'] == 'event') {
      return HistoricEvent(
        year: json['year'],
        content: json['content'],
        sortYear: (json['sort_year'] as num).toDouble(),
      );
    }
    return null;
  }
}

final class HistoricPerson extends HistoricalNote {
  HistoricPerson({
    required super.year,
    required super.content,
    required super.sortYear,
  });
}

final class HistoricEvent extends HistoricalNote {
  HistoricEvent({
    required super.year,
    required super.content,
    required super.sortYear,
  });
}

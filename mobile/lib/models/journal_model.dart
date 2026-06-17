class JournalModel {
  const JournalModel({
    required this.id,
    required this.displayName,
    required this.worksCount,
    this.citedByCount = 0,
  });

  final String id;
  final String displayName;
  final int worksCount;
  final int citedByCount;

  factory JournalModel.fromMap(Map<String, dynamic> map) {
    return JournalModel(
      id: _asString(map['id'] ?? map['key']),
      displayName: _asString(
        map['display_name'] ?? map['key_display_name'],
        fallback: 'Unknown Journal',
      ),
      worksCount: _asInt(map['works_count'] ?? map['count']),
      citedByCount: _asInt(map['cited_by_count']),
    );
  }

  static String _asString(Object? value, {String fallback = ''}) {
    if (value is! String) {
      return fallback;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

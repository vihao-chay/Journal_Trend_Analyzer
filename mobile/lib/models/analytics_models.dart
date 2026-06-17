enum SortMode { relevance, citations, publicationCount }

class ResearchFilters {
  const ResearchFilters({
    this.fromYear,
    this.toYear,
    this.field = '',
    this.subfield = '',
    this.topic = '',
    this.country = '',
    this.journal = '',
    this.openAccessOnly = false,
    this.sortMode = SortMode.relevance,
  });

  final int? fromYear;
  final int? toYear;
  final String field;
  final String subfield;
  final String topic;
  final String country;
  final String journal;
  final bool openAccessOnly;
  final SortMode sortMode;

  static const empty = ResearchFilters();

  ResearchFilters copyWith({
    int? fromYear,
    bool clearFromYear = false,
    int? toYear,
    bool clearToYear = false,
    String? field,
    String? subfield,
    String? topic,
    String? country,
    String? journal,
    bool? openAccessOnly,
    SortMode? sortMode,
  }) {
    return ResearchFilters(
      fromYear: clearFromYear ? null : (fromYear ?? this.fromYear),
      toYear: clearToYear ? null : (toYear ?? this.toYear),
      field: field ?? this.field,
      subfield: subfield ?? this.subfield,
      topic: topic ?? this.topic,
      country: country ?? this.country,
      journal: journal ?? this.journal,
      openAccessOnly: openAccessOnly ?? this.openAccessOnly,
      sortMode: sortMode ?? this.sortMode,
    );
  }

  bool get isEmpty => activeCount == 0;

  int get activeCount {
    var count = 0;
    if (fromYear != null || toYear != null) count++;
    if (field.trim().isNotEmpty) count++;
    if (subfield.trim().isNotEmpty) count++;
    if (topic.trim().isNotEmpty) count++;
    if (country.trim().isNotEmpty) count++;
    if (journal.trim().isNotEmpty) count++;
    if (openAccessOnly) count++;
    if (sortMode != SortMode.relevance) count++;
    return count;
  }

  String get sortLabel {
    return switch (sortMode) {
      SortMode.relevance => 'Liên quan nhất',
      SortMode.citations => 'Trích dẫn cao',
      SortMode.publicationCount => 'Số công bố',
    };
  }
}

class InstitutionModel {
  const InstitutionModel({
    required this.id,
    required this.displayName,
    required this.worksCount,
    required this.countryCode,
    this.countryName,
    this.citedByCount = 0,
  });

  final String id;
  final String displayName;
  final int worksCount;
  final String countryCode;
  final String? countryName;
  final int citedByCount;

  factory InstitutionModel.fromMap(Map<String, dynamic> map) {
    final geo = _asMap(map['geo']);
    return InstitutionModel(
      id: _asString(map['id']),
      displayName: _asString(
        map['display_name'] ?? map['key_display_name'],
        fallback: 'Unknown Institution',
      ),
      worksCount: _asInt(map['works_count'] ?? map['count']),
      countryCode: _asString(map['country_code'] ?? geo?['country_code']),
      countryName: _nullableString(geo?['country']),
      citedByCount: _asInt(map['cited_by_count']),
    );
  }
}

class CountryOutput {
  const CountryOutput({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.worksCount,
  });

  final String id;
  final String name;
  final String countryCode;
  final int worksCount;

  factory CountryOutput.fromGroup(Map<String, dynamic> group) {
    final rawKey = _asString(group['key']);
    return CountryOutput(
      id: rawKey,
      name: _asString(group['key_display_name'], fallback: 'Unknown Country'),
      countryCode: _countryCodeFromKey(rawKey),
      worksCount: _asInt(group['count']),
    );
  }
}

class KeywordMetric {
  const KeywordMetric({
    required this.id,
    required this.displayName,
    required this.worksCount,
    this.citedByCount = 0,
    this.field,
    this.subfield,
  });

  final String id;
  final String displayName;
  final int worksCount;
  final int citedByCount;
  final String? field;
  final String? subfield;

  factory KeywordMetric.fromMap(Map<String, dynamic> map) {
    final field = _asMap(map['field']);
    final subfield = _asMap(map['subfield']);
    return KeywordMetric(
      id: _asString(map['id'] ?? map['key']),
      displayName: _asString(
        map['display_name'] ?? map['key_display_name'],
        fallback: 'Unknown Keyword',
      ),
      worksCount: _asInt(map['works_count'] ?? map['count']),
      citedByCount: _asInt(map['cited_by_count']),
      field: _nullableString(field?['display_name']),
      subfield: _nullableString(subfield?['display_name']),
    );
  }
}

class ChartBarData {
  const ChartBarData({required this.label, required this.value, this.subtitle});

  final String label;
  final int value;
  final String? subtitle;
}

class ScatterPointData {
  const ScatterPointData({
    required this.label,
    required this.x,
    required this.y,
    this.size = 1,
  });

  final String label;
  final double x;
  final double y;
  final double size;
}

class BubblePointData {
  const BubblePointData({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final int value;
  final String? subtitle;
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _asString(Object? value, {String fallback = ''}) {
  if (value is! String) {
    return fallback;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String? _nullableString(Object? value) {
  final result = _asString(value);
  return result.isEmpty ? null : result;
}

int _asInt(Object? value) {
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

String _countryCodeFromKey(String key) {
  final uri = Uri.tryParse(key);
  if (uri != null && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.last.toUpperCase();
  }
  final trimmed = key.trim();
  return trimmed.length <= 3 ? trimmed.toUpperCase() : '';
}

class PublicationModel {
  const PublicationModel({
    required this.id,
    required this.title,
    required this.publicationYear,
    required this.citedByCount,
    required this.doi,
    required this.journalName,
    required this.authors,
  });

  final String id;
  final String title;
  final int publicationYear;
  final int citedByCount;
  final String? doi;
  final String journalName;
  final List<String> authors;

  factory PublicationModel.fromJson(Map<String, dynamic> json) {
    return PublicationModel(
      id: _asNonEmptyString(json['id']) ?? '',
      title:
          _asNonEmptyString(json['title']) ??
          _asNonEmptyString(json['display_name']) ??
          'Untitled Publication',
      publicationYear: _asInt(json['publication_year']),
      citedByCount: _asInt(json['cited_by_count']),
      doi: _asNonEmptyString(json['doi']),
      journalName: _extractJournalName(json),
      authors: _extractAuthors(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'publication_year': publicationYear,
      'cited_by_count': citedByCount,
      'doi': doi,
      'journal_name': journalName,
      'authors': List<String>.from(authors),
    };
  }

  static String _extractJournalName(Map<String, dynamic> json) {
    final primaryLocation = _asMap(json['primary_location']);
    final source = _asMap(primaryLocation?['source']);

    return _asNonEmptyString(source?['display_name']) ?? 'Unknown Journal';
  }

  static List<String> _extractAuthors(Map<String, dynamic> json) {
    final authorships = json['authorships'];
    if (authorships is! List) {
      return const <String>[];
    }

    final authors = <String>[];
    for (final authorship in authorships) {
      final authorshipMap = _asMap(authorship);
      final author = _asMap(authorshipMap?['author']);
      final displayName = _asNonEmptyString(author?['display_name']);

      if (displayName != null) {
        authors.add(displayName);
      }
    }

    return List<String>.unmodifiable(authors);
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String? _asNonEmptyString(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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

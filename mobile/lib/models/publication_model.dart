class PublicationModel {
  const PublicationModel({
    required this.id,
    required this.title,
    required this.publicationYear,
    required this.citedByCount,
    required this.doi,
    required this.journalName,
    required this.authors,
    this.abstractText,
  });

  final String id;
  final String title;
  final int publicationYear;
  final int citedByCount;
  final String? doi;
  final String journalName;
  final List<String> authors;
  final String? abstractText;

  /// Human-readable year label; invalid or missing years show [unknownYearLabel].
  String get displayYear =>
      isPlausiblePublicationYear(publicationYear)
          ? publicationYear.toString()
          : unknownYearLabel;

  static const unknownYearLabel = 'Chưa rõ';

  static bool isPlausiblePublicationYear(int year) {
    final currentYear = DateTime.now().year;
    return year >= 1800 && year <= currentYear;
  }

  factory PublicationModel.fromJson(Map<String, dynamic> json) {
    return PublicationModel(
      id: _asNonEmptyString(json['id']) ?? '',
      title:
          _asNonEmptyString(json['title']) ??
          _asNonEmptyString(json['display_name']) ??
          'Untitled Publication',
      publicationYear: _resolvePublicationYear(json),
      citedByCount: _asInt(json['cited_by_count']),
      doi: _asNonEmptyString(json['doi']),
      journalName: _extractJournalName(json),
      authors: _extractAuthors(json),
      abstractText: decodeAbstractInvertedIndex(json['abstract_inverted_index']),
    );
  }

  /// Reconstructs OpenAlex `abstract_inverted_index` into readable text.
  static String? decodeAbstractInvertedIndex(Object? value) {
    if (value is! Map) {
      return null;
    }

    final invertedIndex = value.map(
      (key, positions) => MapEntry(key.toString(), positions),
    );
    if (invertedIndex.isEmpty) {
      return null;
    }

    var maxIndex = -1;
    for (final positions in invertedIndex.values) {
      if (positions is! List) {
        continue;
      }
      for (final position in positions) {
        final index = _positionToInt(position);
        if (index != null && index > maxIndex) {
          maxIndex = index;
        }
      }
    }

    if (maxIndex < 0) {
      return null;
    }

    final words = List<String>.filled(maxIndex + 1, '');
    invertedIndex.forEach((word, positions) {
      if (positions is! List) {
        return;
      }
      for (final position in positions) {
        final index = _positionToInt(position);
        if (index != null && index >= 0 && index < words.length) {
          words[index] = word;
        }
      }
    });

    final abstractText = words.join(' ').trim();
    return abstractText.isEmpty ? null : abstractText;
  }

  static int? _positionToInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
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
      'abstract': abstractText,
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

  static int _resolvePublicationYear(Map<String, dynamic> json) {
    final rawYear = _asNullableInt(json['publication_year']);
    if (rawYear != null && isPlausiblePublicationYear(rawYear)) {
      return rawYear;
    }

    final publicationDate = _asNonEmptyString(json['publication_date']);
    if (publicationDate != null && publicationDate.length >= 4) {
      final parsedYear = int.tryParse(publicationDate.substring(0, 4));
      if (parsedYear != null && isPlausiblePublicationYear(parsedYear)) {
        return parsedYear;
      }
    }

    return 0;
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
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

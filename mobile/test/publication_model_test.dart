import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/models/publication_model.dart';

void main() {
  group('PublicationModel publication year', () {
    test('rejects implausible future years from OpenAlex metadata', () {
      final model = PublicationModel.fromJson({
        'id': 'https://openalex.org/W1',
        'display_name': 'Future dated work',
        'publication_year': 2050,
        'publication_date': '2050-01-01',
        'cited_by_count': 0,
      });

      expect(model.publicationYear, 0);
      expect(model.displayYear, PublicationModel.unknownYearLabel);
    });

    test('falls back to publication_date when publication_year is missing', () {
      final model = PublicationModel.fromJson({
        'id': 'https://openalex.org/W2',
        'display_name': 'Dated work',
        'publication_date': '2023-08-12',
        'cited_by_count': 3,
      });

      expect(model.publicationYear, 2023);
      expect(model.displayYear, '2023');
    });
    test('rejects next-year publications', () {
      final nextYear = DateTime.now().year + 1;
      final model = PublicationModel.fromJson({
        'id': 'https://openalex.org/W3',
        'display_name': 'Next year work',
        'publication_year': nextYear,
        'cited_by_count': 0,
      });

      expect(model.publicationYear, 0);
      expect(model.displayYear, PublicationModel.unknownYearLabel);
    });
  });

  group('PublicationModel.decodeAbstractInvertedIndex', () {
    test('reconstructs abstract text from inverted index', () {
      const invertedIndex = {
        'This': [0],
        'is': [1],
        'a': [2],
        'test': [3],
        'abstract': [4],
      };

      final result = PublicationModel.decodeAbstractInvertedIndex(invertedIndex);

      expect(result, 'This is a test abstract');
    });

    test('returns null for empty or invalid input', () {
      expect(PublicationModel.decodeAbstractInvertedIndex(null), isNull);
      expect(PublicationModel.decodeAbstractInvertedIndex({}), isNull);
      expect(PublicationModel.decodeAbstractInvertedIndex('text'), isNull);
    });
  });
}

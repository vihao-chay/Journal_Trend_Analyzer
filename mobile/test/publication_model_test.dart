import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/models/publication_model.dart';

void main() {
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

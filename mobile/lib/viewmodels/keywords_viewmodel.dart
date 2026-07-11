import 'package:flutter/foundation.dart';
import '../models/author_model.dart';
import '../models/publication_model.dart';

class KeywordData {
  final String keyword;
  final int count;
  final int totalCitations;
  final List<PublicationModel> relatedPublications;

  KeywordData({
    required this.keyword,
    required this.count,
    required this.totalCitations,
    required this.relatedPublications,
  });
}

class KeywordsViewModel extends ChangeNotifier {
  List<KeywordData> _topKeywords = [];
  bool _isLoading = false;
  String? _error;

  List<KeywordData> get topKeywords => _topKeywords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Basic English stop words
  static const _stopWords = {
    'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from', 'has', 'he',
    'in', 'is', 'it', 'its', 'of', 'on', 'that', 'the', 'to', 'was', 'were', 'will', 'with',
    'this', 'these', 'those', 'their', 'there', 'they', 'which', 'what', 'who', 'how', 'why',
    'when', 'where', 'can', 'could', 'should', 'would', 'may', 'might', 'must', 'do', 'does',
    'did', 'have', 'had', 'not', 'no', 'yes', 'but', 'or', 'so', 'if', 'then', 'than', 'about',
    'over', 'under', 'between', 'into', 'through', 'after', 'before', 'most', 'more', 'some',
    'such', 'only', 'own', 'same', 'very', 'too', 'also', 'any', 'all', 'other', 'another',
    'each', 'every', 'both', 'much', 'many', 'few', 'less', 'least', 'well', 'good', 'bad'
  };

  void processPublications(List<PublicationModel> publications) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, List<PublicationModel>> keywordPubs = {};

      for (var pub in publications) {
        final words = pub.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').split(RegExp(r'\s+')).toSet();
        for (var word in words) {
          if (word.length > 3 && !_stopWords.contains(word)) {
            keywordPubs.putIfAbsent(word, () => []).add(pub);
          }
        }
      }

      final List<KeywordData> keywords = keywordPubs.entries.map((e) {
        final pubs = e.value;
        final citations = pubs.fold(0, (sum, pub) => sum + pub.citedByCount);
        return KeywordData(
          keyword: e.key,
          count: pubs.length,
          totalCitations: citations,
          relatedPublications: pubs,
        );
      }).toList();

      keywords.sort((a, b) => b.count.compareTo(a.count));
      _topKeywords = keywords;
    } catch (e) {
      _error = 'Failed to process keywords: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<AuthorModel> getTopAuthorsForKeyword(String keyword) {
    final keywordData = _topKeywords.firstWhere(
      (k) => k.keyword == keyword, 
      orElse: () => KeywordData(keyword: keyword, count: 0, totalCitations: 0, relatedPublications: [])
    );
    
    final Map<String, int> authorCounts = {};
    final Map<String, int> authorCitations = {};

    for (var pub in keywordData.relatedPublications) {
      for (var author in pub.authors) {
        authorCounts[author] = (authorCounts[author] ?? 0) + 1;
        authorCitations[author] = (authorCitations[author] ?? 0) + pub.citedByCount;
      }
    }

    final List<AuthorModel> authors = authorCounts.entries.map((e) {
      return AuthorModel(
        id: e.key,
        displayName: e.key,
        worksCount: e.value,
        citedByCount: authorCitations[e.key] ?? 0,
      );
    }).toList();

    authors.sort((a, b) => b.worksCount.compareTo(a.worksCount));
    return authors;
  }
}

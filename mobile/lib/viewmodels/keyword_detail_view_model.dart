import 'package:flutter/foundation.dart';

import '../models/analytics_models.dart';
import '../models/author_model.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../services/api_service.dart';

class KeywordDetailViewModel extends ChangeNotifier {
  KeywordDetailViewModel({required this.keyword, ApiService? apiService})
    : _apiService = apiService ?? ApiService(),
      _ownsApiService = apiService == null;

  final KeywordMetric keyword;
  final ApiService _apiService;
  final bool _ownsApiService;

  bool isLoading = false;
  String? errorMessage;
  Map<String, int> publicationTrend = const {};
  List<JournalModel> relatedJournals = const [];
  List<PublicationModel> relatedPublications = const [];
  List<AuthorModel> topAuthors = const [];

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final query = keyword.displayName;
      final results = await Future.wait<dynamic>([
        _apiService.fetchPublicationTrend(query),
        _apiService.fetchTopJournals(query: query),
        _apiService.searchPublications(query),
        _apiService.fetchTopAuthors(query: query),
      ]);

      publicationTrend = results[0] as Map<String, int>;
      relatedJournals = results[1] as List<JournalModel>;
      relatedPublications = results[2] as List<PublicationModel>;
      topAuthors = List<AuthorModel>.from(results[3] as List<AuthorModel>)
        ..sort((a, b) => b.worksCount.compareTo(a.worksCount));
    } on ApiException catch (exception) {
      _clear();
      errorMessage = exception.message;
    } catch (_) {
      _clear();
      errorMessage = 'Không thể tải phân tích chi tiết cho từ khóa này.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _clear() {
    publicationTrend = const {};
    relatedJournals = const [];
    relatedPublications = const [];
    topAuthors = const [];
  }

  @override
  void dispose() {
    if (_ownsApiService) {
      _apiService.dispose();
    }
    super.dispose();
  }
}

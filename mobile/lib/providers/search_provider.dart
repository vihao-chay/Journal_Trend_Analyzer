import 'package:flutter/foundation.dart';

import '../models/author_model.dart';
import '../models/global_overview.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../services/api_service.dart';
import '../services/publication_analytics.dart';

class SearchProvider extends ChangeNotifier {
  SearchProvider({
    ApiService? apiService,
    bool autoLoadGlobalOverview = true,
  }) : _apiService = apiService ?? ApiService() {
    if (autoLoadGlobalOverview) {
      loadGlobalOverview();
    }
  }

  final ApiService _apiService;

  GlobalOverview? globalOverview;
  bool isGlobalLoading = false;
  String? globalError;

  String? keyword;
  List<PublicationModel> publications = const [];
  Map<String, int> publicationTrend = const {};
  List<JournalModel> topJournals = const [];
  List<AuthorModel> topAuthors = const [];

  bool isSearchLoading = false;
  String? searchError;
  bool hasSearched = false;

  DashboardStats get searchDashboardStats =>
      DashboardStats.fromPublications(publications);

  Future<void> loadGlobalOverview() async {
    isGlobalLoading = true;
    globalError = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _apiService.fetchEntityCount('/works'),
        _apiService.fetchEntityCount('/authors'),
        _apiService.fetchEntityCount('/sources'),
        _apiService.fetchGlobalPublicationTrend(),
        _apiService.fetchGlobalTopElements('journals'),
        _apiService.fetchGlobalTopElements('authors'),
        _apiService.fetchMostCitedWork(),
      ]);

      globalOverview = GlobalOverview.fromApiResults(
        totalWorks: results[0] as int,
        totalAuthors: results[1] as int,
        totalSources: results[2] as int,
        publicationTrend: results[3] as Map<String, int>,
        topJournals: (results[4] as List<Map<String, dynamic>>)
            .map(JournalModel.fromMap)
            .toList(growable: false),
        topAuthors: (results[5] as List<Map<String, dynamic>>)
            .map(AuthorModel.fromMap)
            .toList(growable: false),
        mostCitedWork: results[6] as PublicationModel?,
      );
      globalError = null;
    } on ApiException catch (exception) {
      globalOverview = null;
      globalError = exception.message;
    } catch (_) {
      globalOverview = null;
      globalError = 'Unable to load OpenAlex overview. Please try again.';
    } finally {
      isGlobalLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }

    keyword = trimmed;
    isSearchLoading = true;
    searchError = null;
    hasSearched = true;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _apiService.searchPublications(trimmed),
        _apiService.fetchPublicationTrend(trimmed),
        _apiService.fetchTopElements(trimmed, 'journals'),
        _apiService.fetchTopElements(trimmed, 'authors'),
      ]);

      publications = results[0] as List<PublicationModel>;
      publicationTrend = results[1] as Map<String, int>;
      topJournals = (results[2] as List<Map<String, dynamic>>)
          .map(JournalModel.fromMap)
          .toList(growable: false);
      topAuthors = (results[3] as List<Map<String, dynamic>>)
          .map(AuthorModel.fromMap)
          .toList(growable: false);
      searchError = null;
    } on ApiException catch (exception) {
      _resetSearchResults();
      searchError = exception.message;
    } catch (_) {
      _resetSearchResults();
      searchError = 'Unable to load publications. Please try again.';
    } finally {
      isSearchLoading = false;
      notifyListeners();
    }
  }

  void _resetSearchResults() {
    publications = const [];
    publicationTrend = const {};
    topJournals = const [];
    topAuthors = const [];
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/analytics_models.dart';
import '../models/author_model.dart';
import '../models/global_overview.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../services/api_service.dart';
import '../services/publication_analytics.dart';

class SearchProvider extends ChangeNotifier {
  SearchProvider({ApiService? apiService, bool autoLoadGlobalOverview = true})
    : _apiService = apiService ?? ApiService() {
    if (autoLoadGlobalOverview) {
      loadRecentSearches();
      loadGlobalOverview();
    }
  }

  final ApiService _apiService;

  static const _recentSearchesKey = 'recent_searches_v1';

  ResearchFilters filters = ResearchFilters.empty;

  GlobalOverview? globalOverview;
  bool isGlobalLoading = false;
  String? globalError;

  String? keyword;
  List<PublicationModel> publications = const [];
  Map<String, int> publicationTrend = const {};
  Map<String, int> citationVelocity = const {};
  List<JournalModel> topJournals = const [];
  List<AuthorModel> topAuthors = const [];
  List<InstitutionModel> topInstitutions = const [];
  List<CountryOutput> countryOutputs = const [];
  List<KeywordMetric> keywordFrontiers = const [];

  bool isSearchLoading = false;
  String? searchError;
  bool hasSearched = false;

  List<String> recentSearches = const [];

  DashboardStats get searchDashboardStats =>
      DashboardStats.fromPublications(publications);

  Future<void> loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_recentSearchesKey) ?? const <String>[];
      recentSearches = list;
      notifyListeners();
    } catch (_) {
      recentSearches = const [];
    }
  }

  Future<void> clearRecentSearches() async {
    recentSearches = const [];
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
    } catch (_) {}
  }

  Future<void> updateFilters(
    ResearchFilters next, {
    bool rerunSearch = false,
  }) async {
    filters = next;
    notifyListeners();

    if (rerunSearch && keyword != null && keyword!.trim().isNotEmpty) {
      await search(keyword!);
    }
  }

  Future<void> resetFilters({bool rerunSearch = false}) {
    return updateFilters(ResearchFilters.empty, rerunSearch: rerunSearch);
  }

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
        _apiService.fetchCitationVelocity(''),
        _apiService.fetchTopJournals(),
        _apiService.fetchTopAuthors(),
        _apiService.fetchMostCitedWork(),
        _apiService.fetchTopInstitutions(),
        _apiService.fetchCountryOutputs(),
        _apiService.fetchTrendingKeywords(),
        _apiService.fetchFeaturedPublications(),
      ]);

      globalOverview = GlobalOverview.fromApiResults(
        totalWorks: results[0] as int,
        totalAuthors: results[1] as int,
        totalSources: results[2] as int,
        publicationTrend: results[3] as Map<String, int>,
        citationVelocity: results[4] as Map<String, int>,
        topJournals: results[5] as List<JournalModel>,
        topAuthors: results[6] as List<AuthorModel>,
        mostCitedWork: results[7] as PublicationModel?,
        topInstitutions: results[8] as List<InstitutionModel>,
        countryOutputs: results[9] as List<CountryOutput>,
        trendingKeywords: results[10] as List<KeywordMetric>,
        featuredPublications: results[11] as List<PublicationModel>,
      );
      globalError = null;
    } on ApiException catch (exception) {
      globalOverview = null;
      globalError = exception.message;
    } catch (_) {
      globalOverview = null;
      globalError = 'Không thể tải tổng quan OpenAlex. Vui lòng thử lại.';
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
        _apiService.searchPublications(trimmed, filters: filters),
        _apiService.fetchPublicationTrend(trimmed, filters: filters),
        _apiService.fetchCitationVelocity(trimmed, filters: filters),
        _apiService.fetchTopJournals(query: trimmed, filters: filters),
        _apiService.fetchTopAuthors(query: trimmed, filters: filters),
        _apiService.fetchTopInstitutions(query: trimmed, filters: filters),
        _apiService.fetchCountryOutputs(query: trimmed, filters: filters),
        _apiService.fetchResearchFrontiers(trimmed, filters: filters),
      ]);

      publications = results[0] as List<PublicationModel>;
      publicationTrend = results[1] as Map<String, int>;
      citationVelocity = results[2] as Map<String, int>;
      topJournals = results[3] as List<JournalModel>;
      topAuthors = results[4] as List<AuthorModel>;
      topInstitutions = results[5] as List<InstitutionModel>;
      countryOutputs = results[6] as List<CountryOutput>;
      keywordFrontiers = results[7] as List<KeywordMetric>;
      searchError = null;

      await _recordRecentSearch(trimmed);
    } on ApiException catch (exception) {
      _resetSearchResults();
      searchError = exception.message;
    } catch (_) {
      _resetSearchResults();
      searchError = 'Không thể tải dữ liệu nghiên cứu. Vui lòng thử lại.';
    } finally {
      isSearchLoading = false;
      notifyListeners();
    }
  }

  Future<void> _recordRecentSearch(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final updated = <String>[
      normalized,
      ...recentSearches.where(
        (item) => item.toLowerCase() != normalized.toLowerCase(),
      ),
    ];
    if (updated.length > 10) {
      updated.removeRange(10, updated.length);
    }

    recentSearches = List<String>.unmodifiable(updated);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, updated);
    } catch (_) {}
  }

  void _resetSearchResults() {
    publications = const [];
    publicationTrend = const {};
    citationVelocity = const {};
    topJournals = const [];
    topAuthors = const [];
    topInstitutions = const [];
    countryOutputs = const [];
    keywordFrontiers = const [];
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}

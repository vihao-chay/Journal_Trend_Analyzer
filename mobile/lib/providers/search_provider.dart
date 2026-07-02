import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/analytics_models.dart';
import '../models/author_model.dart';
import '../models/global_overview.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../models/publication_page_result.dart';
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
  int _searchGeneration = 0;
  int _journalLoadGeneration = 0;

  ResearchFilters filters = ResearchFilters.empty;

  GlobalOverview? globalOverview;
  bool isGlobalLoading = false;
  String? globalError;

  String? keyword;
  List<PublicationModel> publications = const [];
  int publicationTotalCount = 0;
  List<PublicationModel> journalPagePublications = const [];
  int journalPublicationPage = 1;
  bool isJournalPublicationsLoading = false;
  String? journalPublicationsError;
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

  int searchCitationTotal = 0;
  double searchAverageCitations = 0;

  DashboardStats get searchDashboardStats =>
      DashboardStats.fromPublications(publications);

  int get journalPublicationTotalPages {
    if (publicationTotalCount <= 0) {
      return 0;
    }
    return (publicationTotalCount +
            ApiService.defaultPublicationPageSize -
            1) ~/
        ApiService.defaultPublicationPageSize;
  }

  Future<void> loadJournalPublications({required int page}) async {
    final targetPage = page.clamp(1, 9999);
    final generation = ++_journalLoadGeneration;
    isJournalPublicationsLoading = true;
    journalPublicationsError = null;
    notifyListeners();

    try {
      final result = await _apiService.fetchPublicationsPage(
        query: hasSearched ? keyword : null,
        filters: hasSearched ? filters : ResearchFilters.empty,
        page: targetPage,
      );

      if (generation != _journalLoadGeneration) {
        return;
      }

      journalPublicationPage = targetPage;
      publicationTotalCount = result.totalCount;
      journalPagePublications = sortPublicationsByYearDesc(result.publications);
      if (targetPage == 1 && hasSearched) {
        publications = result.publications;
      }
      journalPublicationsError = null;
    } on ApiException catch (exception) {
      if (generation != _journalLoadGeneration) {
        return;
      }
      journalPagePublications = const [];
      journalPublicationsError = exception.message;
    } catch (_) {
      if (generation != _journalLoadGeneration) {
        return;
      }
      journalPagePublications = const [];
      journalPublicationsError =
          'Không thể tải danh sách bài báo. Vui lòng thử lại.';
    } finally {
      if (generation == _journalLoadGeneration) {
        isJournalPublicationsLoading = false;
        notifyListeners();
      }
    }
  }

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
    if (isGlobalLoading) {
      return;
    }

    isGlobalLoading = true;
    globalError = null;
    notifyListeners();

    try {
      final batch1 = await Future.wait<dynamic>([
        _safe(_apiService.fetchEntityCount('/works'), 0),
        _safe(_apiService.fetchEntityCount('/authors'), 0),
        _safe(_apiService.fetchEntityCount('/sources'), 0),
      ]);
      final batch2 = await Future.wait<dynamic>([
        _safe(_apiService.fetchGlobalPublicationTrend(), const <String, int>{}),
        _safe(
          _apiService.fetchCitationVelocity(''),
          const CitationVelocityResult(
            velocity: <String, int>{},
            sampleTotalCitations: 0,
            sampleSize: 0,
          ),
        ),
        _safe(_apiService.fetchTopJournals(), const <JournalModel>[]),
      ]);
      final batch3 = await Future.wait<dynamic>([
        _safe(_apiService.fetchTopAuthors(), const <AuthorModel>[]),
        _safe<PublicationModel?>(_apiService.fetchMostCitedWork(), null),
        _safe(_apiService.fetchTopInstitutions(), const <InstitutionModel>[]),
      ]);
      final batch4 = await Future.wait<dynamic>([
        _safe(_apiService.fetchCountryOutputs(), const <CountryOutput>[]),
        _safe(_apiService.fetchTrendingKeywords(), const <KeywordMetric>[]),
        _safe(_apiService.fetchFeaturedPublications(), const <PublicationModel>[]),
      ]);

      final results = [...batch1, ...batch2, ...batch3, ...batch4];

      globalOverview = GlobalOverview.fromApiResults(
        totalWorks: results[0] as int,
        totalAuthors: results[1] as int,
        totalSources: results[2] as int,
        publicationTrend: results[3] as Map<String, int>,
        citationVelocity: (results[4] as CitationVelocityResult).velocity,
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
      globalError = exception.message;
    } catch (_) {
      globalError = 'Không thể tải tổng quan OpenAlex. Vui lòng thử lại.';
    } finally {
      isGlobalLoading = false;
      notifyListeners();
    }
  }

  Future<T> _safe<T>(Future<T> future, T fallback) async {
    try {
      return await future;
    } catch (e) {
      debugPrint('API Call failed, using fallback. Error: $e');
      return fallback;
    }
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final generation = ++_searchGeneration;
    keyword = trimmed;
    isSearchLoading = true;
    searchError = null;
    hasSearched = true;
    journalPublicationPage = 1;
    journalPagePublications = const [];
    publicationTotalCount = 0;
    searchCitationTotal = 0;
    searchAverageCitations = 0;
    notifyListeners();

    try {
      final batch1 = await Future.wait<dynamic>([
        _safe(
          _apiService.fetchPublicationsPage(
            query: trimmed,
            filters: filters,
            page: 1,
          ),
          const PublicationPageResult(
            totalCount: 0,
            publications: <PublicationModel>[],
            page: 1,
            perPage: 10,
          ),
        ),
        _safe(
          _apiService.fetchPublicationTrend(trimmed, filters: filters),
          const <String, int>{},
        ),
      ]);
      final batch2 = await Future.wait<dynamic>([
        _safe(
          _apiService.fetchCitationVelocity(trimmed, filters: filters),
          const CitationVelocityResult(
            velocity: <String, int>{},
            sampleTotalCitations: 0,
            sampleSize: 0,
          ),
        ),
        _safe(
          _apiService.fetchTopJournals(query: trimmed, filters: filters),
          const <JournalModel>[],
        ),
      ]);
      final batch3 = await Future.wait<dynamic>([
        _safe(
          _apiService.fetchTopAuthors(query: trimmed, filters: filters),
          const <AuthorModel>[],
        ),
        _safe(
          _apiService.fetchTopInstitutions(query: trimmed, filters: filters),
          const <InstitutionModel>[],
        ),
      ]);
      final batch4 = await Future.wait<dynamic>([
        _safe(
          _apiService.fetchCountryOutputs(query: trimmed, filters: filters),
          const <CountryOutput>[],
        ),
        _safe(
          _apiService.fetchResearchFrontiers(trimmed, filters: filters),
          const <KeywordMetric>[],
        ),
      ]);

      final results = [...batch1, ...batch2, ...batch3, ...batch4];

      if (generation != _searchGeneration) {
        return;
      }

      final publicationPage = results[0] as PublicationPageResult;
      publications = publicationPage.publications;
      publicationTotalCount = publicationPage.totalCount;
      journalPublicationPage = 1;
      journalPagePublications = sortPublicationsByYearDesc(
        publicationPage.publications,
      );
      publicationTrend = results[1] as Map<String, int>;
      final citationResult = results[2] as CitationVelocityResult;
      citationVelocity = citationResult.velocity;
      searchCitationTotal = citationResult.sampleTotalCitations;
      searchAverageCitations = citationResult.averageCitations;
      topJournals = results[3] as List<JournalModel>;
      topAuthors = results[4] as List<AuthorModel>;
      topInstitutions = results[5] as List<InstitutionModel>;
      countryOutputs = results[6] as List<CountryOutput>;
      keywordFrontiers = results[7] as List<KeywordMetric>;
      searchError = null;

      await _recordRecentSearch(trimmed);
    } on ApiException catch (exception) {
      if (generation != _searchGeneration) {
        return;
      }
      _resetSearchResults();
      searchError = exception.message;
    } catch (_) {
      if (generation != _searchGeneration) {
        return;
      }
      _resetSearchResults();
      searchError = 'Không thể tải dữ liệu nghiên cứu. Vui lòng thử lại.';
    } finally {
      if (generation == _searchGeneration) {
        isSearchLoading = false;
        notifyListeners();
      }
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
    publicationTotalCount = 0;
    journalPagePublications = const [];
    journalPublicationPage = 1;
    journalPublicationsError = null;
    publicationTrend = const {};
    citationVelocity = const {};
    searchCitationTotal = 0;
    searchAverageCitations = 0;
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

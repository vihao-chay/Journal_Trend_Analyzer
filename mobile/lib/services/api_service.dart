import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/analytics_models.dart';
import '../models/author_model.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../models/publication_page_result.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({
    http.Client? client,
    this.mailto = _defaultMailto,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  static const String _host = 'api.openalex.org';
  static const String _defaultMailto = 'prm_project_app@example.com';

  final http.Client _client;
  final String mailto;
  final Duration timeout;

  static const int defaultPublicationPageSize = 20;
  static const int maxTopJournalLimit = 25;

  Future<PublicationPageResult> fetchPublicationsPage({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
    int page = 1,
    int perPage = defaultPublicationPageSize,
  }) async {
    final queryParameters = _buildWorksQuery(
      search: query,
      filters: filters,
      perPage: perPage,
      sort: _worksSort(filters) ?? 'publication_year:desc',
    );
    queryParameters['page'] = '${page.clamp(1, 9999)}';

    final payload = await _getJson(_buildUri('/works', queryParameters));
    final meta = _asMap(payload['meta']);
    final publications = _asJsonList(
      payload['results'],
    ).map(PublicationModel.fromJson).toList(growable: false);

    return PublicationPageResult(
      publications: publications,
      totalCount: _asInt(meta?['count']),
      page: page,
      perPage: perPage,
    );
  }

  Future<List<PublicationModel>> searchPublications(
    String query, {
    ResearchFilters filters = ResearchFilters.empty,
  }) async {
    final page = await fetchPublicationsPage(
      query: query,
      filters: filters,
      perPage: 50,
    );
    return page.publications;
  }

  Future<List<PublicationModel>> fetchFeaturedPublications({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
  }) async {
    final uri = _buildUri(
      '/works',
      _buildWorksQuery(
        search: query,
        filters: filters,
        perPage: 12,
        sort: _worksSort(filters) ?? 'publication_year:desc',
      ),
    );
    final payload = await _getJson(uri);
    return _asJsonList(
      payload['results'],
    ).map(PublicationModel.fromJson).toList(growable: false);
  }

  Future<PublicationModel?> fetchMostCitedWork({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
  }) async {
    final queryParameters = _buildWorksQuery(
      search: query,
      filters: filters,
      perPage: 1,
      sort: 'cited_by_count:desc',
    );
    final payload = await _getJson(_buildUri('/works', queryParameters));
    final results = _asJsonList(payload['results']);
    if (results.isEmpty) {
      return null;
    }
    return PublicationModel.fromJson(results.first);
  }

  /// Total entity count from OpenAlex `meta.count` list responses.
  Future<int> fetchEntityCount(String path) async {
    final payload = await _getJson(_buildUri(path, {'per_page': '1'}));
    final meta = _asMap(payload['meta']);
    return _asInt(meta?['count']);
  }

  Future<Map<String, int>> fetchGlobalPublicationTrend({
    ResearchFilters filters = ResearchFilters.empty,
  }) {
    return fetchPublicationTrend('', filters: filters);
  }

  Future<Map<String, int>> fetchPublicationTrend(
    String query, {
    ResearchFilters filters = ResearchFilters.empty,
  }) async {
    final payload = await _getJson(
      _buildUri(
        '/works',
        _buildWorksQuery(
          search: query,
          filters: filters,
          groupBy: 'publication_year',
          perPage: 100,
        ),
      ),
    );
    return _parsePublicationTrend(payload);
  }

  Future<CitationVelocityResult> fetchCitationVelocity(
    String query, {
    ResearchFilters filters = ResearchFilters.empty,
    int perPage = 100,
  }) async {
    final queryParameters = _buildWorksQuery(
      search: query,
      filters: filters,
      perPage: perPage,
      sort: 'cited_by_count:desc',
    );
    queryParameters['select'] =
        'id,display_name,publication_year,cited_by_count,counts_by_year';

    final payload = await _getJson(_buildUri('/works', queryParameters));
    final results = _asJsonList(payload['results']);
    final sampleTotalCitations = results.fold<int>(
      0,
      (sum, work) => sum + _asInt(work['cited_by_count']),
    );

    return CitationVelocityResult(
      velocity: _parseCitationVelocityResults(results),
      sampleTotalCitations: sampleTotalCitations,
      sampleSize: results.length,
    );
  }

  Future<List<JournalModel>> fetchTopJournals({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
    int perPage = maxTopJournalLimit,
  }) async {
    if (_isBlank(query) && filters.isEmpty) {
      final payload = await _getJson(
        _buildUri('/sources', {
          'sort': _entitySort(filters),
          'per_page': '$perPage',
        }),
      );
      return _asJsonList(
        payload['results'],
      ).map(JournalModel.fromMap).toList(growable: false);
    }

    final groups = await _fetchWorkGroups(
      groupBy: 'primary_location.source.id',
      query: query,
      filters: filters,
      perPage: perPage,
    );
    final groupedJournals = groups.map(JournalModel.fromMap).toList();
    return _hydrateJournalImpact(groupedJournals);
  }

  Future<List<JournalModel>> _hydrateJournalImpact(
    List<JournalModel> groupedJournals,
  ) async {
    final topJournals = groupedJournals
        .take(maxTopJournalLimit)
        .toList(growable: false);
    final detailedJournals = await Future.wait(
      topJournals.map((journal) async {
        final id = _normalizeOpenAlexId(journal.id);
        if (id == null) {
          return journal;
        }
        try {
          final payload = await _getJson(_buildUri('/sources/$id', const {}));
          final detailed = JournalModel.fromMap(payload);
          return JournalModel(
            id: journal.id,
            displayName: journal.displayName,
            worksCount: journal.worksCount,
            citedByCount: detailed.citedByCount,
          );
        } catch (_) {
          return journal;
        }
      }),
    );

    return [
      ...detailedJournals,
      ...groupedJournals.skip(detailedJournals.length),
    ];
  }

  Future<List<AuthorModel>> fetchTopAuthors({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
    int perPage = 10,
  }) async {
    if (_isBlank(query) && filters.isEmpty) {
      final payload = await _getJson(
        _buildUri('/authors', {
          'sort': _entitySort(filters),
          'per_page': '$perPage',
        }),
      );
      return _asJsonList(
        payload['results'],
      ).map(AuthorModel.fromMap).toList(growable: false);
    }

    final groups = await _fetchWorkGroups(
      groupBy: 'authorships.author.id',
      query: query,
      filters: filters,
      perPage: perPage,
    );
    final groupedAuthors = groups.map(AuthorModel.fromMap).toList();
    return _hydrateAuthorImpact(groupedAuthors);
  }

  Future<List<InstitutionModel>> fetchTopInstitutions({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
    int perPage = 10,
  }) async {
    if (_isBlank(query) && filters.isEmpty) {
      final payload = await _getJson(
        _buildUri('/institutions', {
          'sort': _entitySort(filters),
          'per_page': '$perPage',
        }),
      );
      return _asJsonList(
        payload['results'],
      ).map(InstitutionModel.fromMap).toList(growable: false);
    }

    final groups = await _fetchWorkGroups(
      groupBy: 'authorships.institutions.id',
      query: query,
      filters: filters,
      perPage: perPage,
    );
    return groups.map(InstitutionModel.fromMap).toList(growable: false);
  }

  Future<List<CountryOutput>> fetchCountryOutputs({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
    int perPage = 12,
  }) async {
    final groups = await _fetchWorkGroups(
      groupBy: 'authorships.countries',
      query: query,
      filters: filters,
      perPage: perPage,
    );
    return groups.map(CountryOutput.fromGroup).toList(growable: false);
  }

  Future<List<KeywordMetric>> fetchTrendingKeywords({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
    int perPage = 12,
  }) async {
    if (_isBlank(query) && filters.isEmpty) {
      final payload = await _getJson(
        _buildUri('/keywords', {
          'sort': _entitySort(filters),
          'per_page': '$perPage',
        }),
      );
      return _asJsonList(
        payload['results'],
      ).map(KeywordMetric.fromMap).toList(growable: false);
    }
    return fetchResearchFrontiers(
      query ?? '',
      filters: filters,
      perPage: perPage,
    );
  }

  Future<List<KeywordMetric>> fetchResearchFrontiers(
    String query, {
    ResearchFilters filters = ResearchFilters.empty,
    int perPage = 12,
  }) async {
    final groups = await _fetchWorkGroups(
      groupBy: 'keywords.id',
      query: query,
      filters: filters,
      perPage: perPage,
    );
    return groups.map(KeywordMetric.fromMap).toList(growable: false);
  }

  Future<List<PublicationModel>> fetchWorksBySourceId(String sourceId) async {
    final filterId = _normalizeOpenAlexId(sourceId);
    if (filterId == null) {
      return const [];
    }
    final uri = _buildUri('/works', {
      'filter': 'primary_location.source.id:$filterId',
      'per_page': '50',
      'sort': 'cited_by_count:desc',
    });
    final payload = await _getJson(uri);
    return _asJsonList(
      payload['results'],
    ).map(PublicationModel.fromJson).toList(growable: false);
  }

  Future<List<PublicationModel>> fetchWorksByAuthorId(String authorId) async {
    final filterId = _normalizeOpenAlexId(authorId);
    if (filterId == null) {
      return const [];
    }
    final uri = _buildUri('/works', {
      'filter': 'authorships.author.id:$filterId',
      'per_page': '50',
      'sort': 'cited_by_count:desc',
    });
    final payload = await _getJson(uri);
    return _asJsonList(
      payload['results'],
    ).map(PublicationModel.fromJson).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchGlobalTopElements(
    String elementType,
  ) async {
    final items = await _fetchTopElementsCompat(elementType);
    return items;
  }

  Future<List<Map<String, dynamic>>> fetchTopElements(
    String query,
    String elementType,
  ) {
    return _fetchTopElementsCompat(elementType, query: query);
  }

  void dispose() {
    _client.close();
  }

  Future<List<Map<String, dynamic>>> _fetchTopElementsCompat(
    String elementType, {
    String? query,
  }) async {
    final normalizedType = elementType.trim().toLowerCase();
    if (normalizedType == 'authors') {
      final authors = await fetchTopAuthors(query: query);
      return authors
          .map(
            (author) => {
              'id': author.id,
              'display_name': author.displayName,
              'works_count': author.worksCount,
              'cited_by_count': author.citedByCount,
            },
          )
          .toList(growable: false);
    }
    if (normalizedType == 'journals') {
      final journals = await fetchTopJournals(query: query);
      return journals
          .map(
            (journal) => {
              'id': journal.id,
              'display_name': journal.displayName,
              'works_count': journal.worksCount,
              'cited_by_count': journal.citedByCount,
            },
          )
          .toList(growable: false);
    }
    throw ArgumentError.value(
      elementType,
      'elementType',
      'Supported values are "authors" and "journals".',
    );
  }

  Future<List<Map<String, dynamic>>> _fetchWorkGroups({
    required String groupBy,
    required String? query,
    required ResearchFilters filters,
    required int perPage,
  }) async {
    final payload = await _getJson(
      _buildUri(
        '/works',
        _buildWorksQuery(
          search: query,
          filters: filters,
          groupBy: groupBy,
          perPage: perPage,
        ),
      ),
    );
    return _asJsonList(payload['group_by']);
  }

  Future<List<AuthorModel>> _hydrateAuthorImpact(
    List<AuthorModel> groupedAuthors,
  ) async {
    final topAuthors = groupedAuthors.take(8).toList(growable: false);
    final detailedAuthors = await Future.wait(
      topAuthors.map((author) async {
        final id = _normalizeOpenAlexId(author.id);
        if (id == null) {
          return author;
        }
        try {
          final payload = await _getJson(_buildUri('/authors/$id', const {}));
          final detailed = AuthorModel.fromMap(payload);
          return AuthorModel(
            id: author.id,
            displayName: author.displayName,
            worksCount: author.worksCount,
            citedByCount: detailed.citedByCount,
          );
        } catch (_) {
          return author;
        }
      }),
    );

    return [...detailedAuthors, ...groupedAuthors.skip(detailedAuthors.length)];
  }

  Map<String, int> _parsePublicationTrend(Map<String, dynamic> payload) {
    final groupedRows = _asJsonList(payload['group_by']);
    final trend = <String, int>{};

    for (final row in groupedRows) {
      final year = row['key']?.toString().trim();
      if (year == null || year.isEmpty || year == 'null') {
        continue;
      }
      trend[year] = _asInt(row['count']);
    }

    final sortedEntries = trend.entries.toList()
      ..sort((left, right) {
        final leftYear = int.tryParse(left.key);
        final rightYear = int.tryParse(right.key);
        if (leftYear != null && rightYear != null) {
          return leftYear.compareTo(rightYear);
        }
        return left.key.compareTo(right.key);
      });

    return Map<String, int>.fromEntries(sortedEntries);
  }

  Map<String, int> _parseCitationVelocityResults(
    List<Map<String, dynamic>> results,
  ) {
    final citationsByYear = <int, int>{};

    for (final work in results) {
      final countsByYear = _asJsonList(work['counts_by_year']);
      for (final row in countsByYear) {
        final year = _asInt(row['year']);
        final citationCount = _asInt(row['cited_by_count']);
        if (year <= 0 || citationCount <= 0) {
          continue;
        }
        citationsByYear[year] = (citationsByYear[year] ?? 0) + citationCount;
      }
    }

    if (citationsByYear.isEmpty) {
      for (final work in results) {
        final year = _asInt(work['publication_year']);
        final citationCount = _asInt(work['cited_by_count']);
        if (year <= 0 || citationCount <= 0) {
          continue;
        }
        citationsByYear[year] = (citationsByYear[year] ?? 0) + citationCount;
      }
    }

    final sortedEntries = citationsByYear.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    return {
      for (final entry in sortedEntries) entry.key.toString(): entry.value,
    };
  }

  Map<String, String> _buildWorksQuery({
    String? search,
    required ResearchFilters filters,
    String? groupBy,
    int perPage = 25,
    String? sort,
  }) {
    final queryParameters = <String, String>{'per_page': '$perPage'};
    final searchValue = _composeSearch(search, filters);
    if (searchValue.isNotEmpty) {
      queryParameters['search'] = searchValue;
    }

    final workFilters = _buildWorkFilters(filters);
    if (workFilters.isNotEmpty) {
      queryParameters['filter'] = workFilters.join(',');
    }

    if (groupBy != null && groupBy.isNotEmpty) {
      queryParameters['group_by'] = groupBy;
    }

    if (sort != null && sort.isNotEmpty && groupBy == null) {
      queryParameters['sort'] = sort;
    }

    return queryParameters;
  }

  String _composeSearch(String? query, ResearchFilters filters) {
    final parts = <String>[
      if (!_isBlank(query)) query!.trim(),
      if (_shouldUseAsSearchText(filters.field)) filters.field.trim(),
      if (_shouldUseAsSearchText(filters.subfield)) filters.subfield.trim(),
      if (_shouldUseAsSearchText(filters.topic)) filters.topic.trim(),
      if (_shouldUseAsSearchText(filters.journal)) filters.journal.trim(),
    ];
    return parts.join(' ').trim();
  }

  List<String> _buildWorkFilters(ResearchFilters filters) {
    final workFilters = <String>[];
    final currentYear = DateTime.now().year;
    if (filters.fromYear != null) {
      workFilters.add(
        'from_publication_date:${filters.fromYear!.clamp(1, currentYear)}-01-01',
      );
    }
    if (filters.toYear != null) {
      workFilters.add(
        'to_publication_date:${filters.toYear!.clamp(1, currentYear)}-12-31',
      );
    } else {
      workFilters.add('publication_year:1800-$currentYear');
    }
    if (filters.openAccessOnly) {
      workFilters.add('open_access.is_oa:true');
    }

    final countryCode = _normalizeCountryCode(filters.country);
    if (countryCode != null) {
      workFilters.add('authorships.countries:$countryCode');
    }

    final journalId = _normalizeTypedId(filters.journal, 'S');
    if (journalId != null) {
      workFilters.add('primary_location.source.id:$journalId');
    }

    final fieldId = _normalizeHierarchicalId(filters.field, 'fields');
    if (fieldId != null) {
      workFilters.add('primary_topic.field.id:$fieldId');
    }

    final subfieldId = _normalizeHierarchicalId(filters.subfield, 'subfields');
    if (subfieldId != null) {
      workFilters.add('primary_topic.subfield.id:$subfieldId');
    }

    final topicId = _normalizeTypedId(filters.topic, 'T');
    if (topicId != null) {
      workFilters.add('topics.id:$topicId');
    }

    return workFilters;
  }

  String? _worksSort(ResearchFilters filters) {
    return switch (filters.sortMode) {
      SortMode.relevance => null,
      SortMode.citations => 'cited_by_count:desc',
      SortMode.publicationCount => 'publication_year:desc',
    };
  }

  String _entitySort(ResearchFilters filters) {
    return switch (filters.sortMode) {
      SortMode.citations => 'cited_by_count:desc',
      SortMode.relevance || SortMode.publicationCount => 'works_count:desc',
    };
  }

  Uri _buildUri(String path, Map<String, String> queryParameters) {
    return Uri.https(_host, path, {...queryParameters, 'mailto': mailto});
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, {int maxRetries = 3}) async {
    int retries = 0;
    while (true) {
      try {
        final response = await _client.get(uri).timeout(timeout);

        if ((response.statusCode == 429 || response.statusCode >= 500) &&
            retries < maxRetries) {
          retries++;
          final baseDelay = 1000 * (1 << retries);
          final jitter = DateTime.now().millisecond % 1000;
          final delay = Duration(milliseconds: baseDelay + jitter);
          await Future.delayed(delay);
          continue; // Retry
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ApiException('OpenAlex phản hồi lỗi ${response.statusCode}.');
        }

        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }

        throw const FormatException('Expected a JSON object response.');
      } on ApiException {
        rethrow;
      } on TimeoutException {
        throw const ApiException('OpenAlex phản hồi quá lâu.');
      } on SocketException {
        throw const ApiException(
          'Không có kết nối internet. Vui lòng thử lại.',
        );
      } on http.ClientException {
        throw const ApiException('Không thể kết nối tới OpenAlex.');
      } on FormatException {
        throw const ApiException('OpenAlex trả về dữ liệu không hợp lệ.');
      } catch (_) {
        throw const ApiException('Có lỗi khi tải dữ liệu OpenAlex.');
      }
    }
  }

  static bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  static bool _shouldUseAsSearchText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (_normalizeCountryCode(trimmed) != null) {
      return false;
    }
    if (_normalizeTypedId(trimmed, 'S') != null) {
      return false;
    }
    if (_normalizeTypedId(trimmed, 'T') != null) {
      return false;
    }
    if (_normalizeHierarchicalId(trimmed, 'fields') != null) {
      return false;
    }
    if (_normalizeHierarchicalId(trimmed, 'subfields') != null) {
      return false;
    }
    return true;
  }

  static String? _normalizeOpenAlexId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return trimmed;
  }

  static String? _normalizeCountryCode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length != 2) {
      return null;
    }
    return trimmed.toUpperCase();
  }

  static String? _normalizeTypedId(String raw, String prefix) {
    final normalized = _normalizeOpenAlexId(raw);
    if (normalized == null) {
      return null;
    }
    final upper = normalized.toUpperCase();
    if (!upper.startsWith(prefix.toUpperCase())) {
      return null;
    }
    return upper;
  }

  static String? _normalizeHierarchicalId(String raw, String collection) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.pathSegments.length >= 2) {
      final segments = uri.pathSegments;
      final parent = segments[segments.length - 2];
      final child = segments.last;
      if (parent == collection && int.tryParse(child) != null) {
        return '$collection/$child';
      }
    }

    if (trimmed.startsWith('$collection/')) {
      final child = trimmed.substring(collection.length + 1);
      return int.tryParse(child) == null ? null : '$collection/$child';
    }

    return int.tryParse(trimmed) == null ? null : '$collection/$trimmed';
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

  static List<Map<String, dynamic>> _asJsonList(Object? value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          }
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
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

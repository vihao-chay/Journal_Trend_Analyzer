import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/publication_model.dart';

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
  static const String _defaultMailto = 'team_email@gmail.com';

  final http.Client _client;
  final String mailto;
  final Duration timeout;

  Future<List<PublicationModel>> searchPublications(String query) async {
    final uri = _buildUri('/works', {'search': query.trim(), 'per_page': '50'});
    final payload = await _getJson(uri);
    final results = _asJsonList(payload['results']);

    return results.map(PublicationModel.fromJson).toList(growable: false);
  }

  /// Total entity count from `meta.count` ([OpenAlex list response](https://developers.openalex.org/api-reference/introduction)).
  Future<int> fetchEntityCount(String path) async {
    final payload = await _getJson(_buildUri(path, {'per_page': '1'}));
    final meta = _asMap(payload['meta']);
    return _asInt(meta?['count']);
  }

  Future<Map<String, int>> fetchGlobalPublicationTrend() async {
    final payload = await _getJson(
      _buildUri('/works', {'group_by': 'publication_year'}),
    );
    return _parsePublicationTrend(payload);
  }

  Future<Map<String, int>> fetchPublicationTrend(String query) async {
    final payload = await _getJson(
      _buildUri('/works', {
        'search': query.trim(),
        'group_by': 'publication_year',
      }),
    );
    return _parsePublicationTrend(payload);
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

  Future<List<Map<String, dynamic>>> fetchGlobalTopElements(
    String elementType,
  ) async {
    return _fetchTopElements(elementType);
  }

  Future<List<Map<String, dynamic>>> fetchTopElements(
    String query,
    String elementType,
  ) async {
    return _fetchTopElements(elementType, search: query.trim());
  }

  Future<PublicationModel?> fetchMostCitedWork() async {
    final payload = await _getJson(
      _buildUri('/works', {
        'sort': 'cited_by_count:desc',
        'per_page': '1',
      }),
    );
    final results = _asJsonList(payload['results']);
    if (results.isEmpty) {
      return null;
    }

    return PublicationModel.fromJson(results.first);
  }

  Future<List<Map<String, dynamic>>> _fetchTopElements(
    String elementType, {
    String? search,
  }) async {
    final normalizedType = elementType.trim().toLowerCase();
    final path = switch (normalizedType) {
      'authors' => '/authors',
      'journals' => '/sources',
      _ => throw ArgumentError.value(
        elementType,
        'elementType',
        'Supported values are "authors" and "journals".',
      ),
    };

    final queryParameters = <String, String>{
      'sort': 'works_count:desc',
      'per_page': '10',
    };
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    final uri = _buildUri(path, queryParameters);
    final payload = await _getJson(uri);
    final results = _asJsonList(payload['results']);

    return results
        .map((item) {
          final displayName = _asNonEmptyString(item['display_name']);
          if (displayName == null) {
            return null;
          }

          return <String, dynamic>{
            'display_name': displayName,
            'works_count': _asInt(item['works_count']),
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  void dispose() {
    _client.close();
  }

  Uri _buildUri(String path, Map<String, String> queryParameters) {
    return Uri.https(_host, path, {...queryParameters, 'mailto': mailto});
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'OpenAlex request failed with status ${response.statusCode}.',
        );
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
      throw const ApiException('OpenAlex took too long to respond.');
    } on SocketException {
      throw const ApiException('No internet connection. Please try again.');
    } on http.ClientException {
      throw const ApiException('Could not connect to OpenAlex.');
    } on FormatException {
      throw const ApiException('OpenAlex returned an unexpected response.');
    } catch (_) {
      throw const ApiException('Something went wrong while loading data.');
    }
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

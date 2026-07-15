import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/models/analytics_models.dart';
import 'package:mobile/models/app_notification.dart';
import 'package:mobile/models/auth_user.dart';
import 'package:mobile/models/author_model.dart';
import 'package:mobile/models/global_overview.dart';
import 'package:mobile/models/journal_model.dart';
import 'package:mobile/models/publication_model.dart';
import 'package:mobile/models/publication_page_result.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/search_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/viewmodels/firebase_features_view_model.dart';

const patrolUser = AuthUser(
  uid: 'patrol-user',
  displayName: 'Patrol Tester',
  email: 'patrol@example.com',
);

const patrolPublication = PublicationModel(
  id: 'https://openalex.org/W2741809807',
  title: 'Deep learning in research analytics',
  publicationYear: 2024,
  citedByCount: 152,
  doi: 'https://doi.org/10.0000/example',
  journalName: 'Journal of Research Analytics',
  authors: ['Jane Doe', 'Nguyen Van A'],
  abstractText:
      'A deterministic Patrol fixture publication used to verify detail screens.',
  landingPageUrl: 'https://openalex.org/W2741809807',
);

const patrolJournal = JournalModel(
  id: 'https://openalex.org/S123',
  displayName: 'Journal of Research Analytics',
  worksCount: 4820,
  citedByCount: 26000,
);

const patrolAuthor = AuthorModel(
  id: 'https://openalex.org/A123',
  displayName: 'Jane Doe',
  worksCount: 120,
  citedByCount: 3500,
);

const patrolInstitution = InstitutionModel(
  id: 'https://openalex.org/I123',
  displayName: 'Open Research University',
  worksCount: 900,
  countryCode: 'US',
  countryName: 'United States',
);

const patrolCountry = CountryOutput(
  id: 'https://openalex.org/countries/US',
  name: 'United States',
  countryCode: 'US',
  worksCount: 1200,
);

const patrolKeyword = KeywordMetric(
  id: 'https://openalex.org/keywords/deep-learning',
  displayName: 'deep learning',
  worksCount: 2400,
  citedByCount: 18000,
  field: 'Computer science',
);

const patrolPublicationTrend = {'2021': 80, '2022': 120, '2023': 180};
const patrolCitationVelocity = {'2021': 200, '2022': 550, '2023': 900};

Future<void> pumpSignedOutApp(dynamic $) async {
  await pumpPatrolApp(
    $,
    MyApp(
      searchProvider: createPatrolSearchProvider(),
      themeProvider: ThemeProvider(autoLoad: false),
      authProvider: AuthProvider(
        authService: FakeAuthService(),
        autoInitialize: false,
      ),
      firebaseFeaturesProvider: PatrolFirebaseFeaturesViewModel(),
    ),
  );
}

Future<void> pumpAuthenticatedApp(dynamic $, {bool searched = true}) async {
  await pumpPatrolApp(
    $,
    MyApp(
      searchProvider: createPatrolSearchProvider(searched: searched),
      themeProvider: ThemeProvider(autoLoad: false),
      authProvider: AuthProvider(
        authService: FakeAuthService(initialUser: patrolUser),
        autoInitialize: false,
        initialUser: patrolUser,
      ),
      firebaseFeaturesProvider: PatrolFirebaseFeaturesViewModel(),
    ),
  );
}

Future<void> pumpPatrolApp(dynamic $, Widget widget) async {
  await $.pumpWidget(widget);
  await $.pump();
  await $.pump(const Duration(milliseconds: 300));
}

SearchProvider createPatrolSearchProvider({bool searched = false}) {
  final provider = SearchProvider(
    apiService: PatrolApiService(),
    autoLoadGlobalOverview: false,
  )..globalOverview = patrolGlobalOverview;

  if (searched) {
    seedSearchState(provider);
  }
  return provider;
}

void seedSearchState(SearchProvider provider) {
  provider
    ..hasSearched = true
    ..keyword = 'deep learning'
    ..publications = const [patrolPublication]
    ..publicationTotalCount = 1
    ..journalPagePublications = const [patrolPublication]
    ..publicationTrend = patrolPublicationTrend
    ..citationVelocity = patrolCitationVelocity
    ..topJournals = const [patrolJournal]
    ..topAuthors = const [patrolAuthor]
    ..topInstitutions = const [patrolInstitution]
    ..countryOutputs = const [patrolCountry]
    ..keywordFrontiers = const [patrolKeyword]
    ..mostInfluentialPublication = patrolPublication
    ..searchAverageCitations = 152
    ..searchCitationTotal = 456
    ..recentSearches = const ['deep learning'];
}

const patrolGlobalOverview = GlobalOverview(
  totalWorks: 1284000,
  totalAuthors: 214000,
  totalSources: 4200,
  publicationTrend: {'2021': 800, '2022': 1100, '2023': 1450},
  citationVelocity: {'2021': 500, '2022': 1200, '2023': 2400},
  topJournals: [patrolJournal],
  topAuthors: [patrolAuthor],
  topInstitutions: [patrolInstitution],
  countryOutputs: [patrolCountry],
  trendingKeywords: [patrolKeyword],
  featuredPublications: [patrolPublication],
  mostCitedWork: patrolPublication,
  peakYear: 2023,
  peakYearCount: 1450,
);

Future<void> searchForTopic(dynamic $, String topic) async {
  await $.scrollUntilVisible(
    finder: find.byKey(const ValueKey('research_search_input_text_field')),
  );
  await $(
    find.byKey(const ValueKey('research_search_input_text_field')),
  ).enterText(topic);
  await $(find.byKey(const ValueKey('research_search_submit_button'))).tap();
  await $.pumpAndSettle();
}

Future<void> openBottomTab(dynamic $, String label) async {
  await $(find.text(label).last).tap();
  await $.pumpAndSettle();
}

Future<void> openBottomTabIndex(dynamic $, int index) async {
  await $(find.byType(NavigationDestination).at(index)).tap();
  await $.pumpAndSettle();
}

class FakeAuthService implements AuthService {
  FakeAuthService({AuthUser? initialUser}) : _currentUser = initialUser {
    _authController.add(_currentUser);
  }

  AuthUser? _currentUser;
  final StreamController<AuthUser?> _authController =
      StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> get authStateChanges => _authController.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<AuthUser?> signInWithGoogle() async {
    _currentUser = patrolUser;
    _authController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authController.add(null);
  }
}

class PatrolApiService extends ApiService {
  @override
  Future<PublicationPageResult> fetchPublicationsPage({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
    int page = 1,
    int perPage = ApiService.defaultPublicationPageSize,
  }) async {
    return PublicationPageResult(
      publications: const [patrolPublication],
      totalCount: 1,
      page: page,
      perPage: perPage,
    );
  }

  @override
  Future<List<PublicationModel>> searchPublications(
    String query, {
    ResearchFilters filters = ResearchFilters.empty,
  }) async {
    return const [patrolPublication];
  }

  @override
  Future<List<PublicationModel>> fetchFeaturedPublications({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
  }) async {
    return const [patrolPublication];
  }

  @override
  Future<PublicationModel?> fetchMostCitedWork({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
  }) async {
    return patrolPublication;
  }

  @override
  Future<int> fetchEntityCount(String path) async {
    return switch (path) {
      '/authors' => 214000,
      '/sources' => 4200,
      _ => 1284000,
    };
  }

  @override
  Future<Map<String, int>> fetchGlobalPublicationTrend({
    ResearchFilters filters = ResearchFilters.empty,
  }) async {
    return patrolGlobalOverview.publicationTrend;
  }

  @override
  Future<Map<String, int>> fetchPublicationTrend(
    String query, {
    ResearchFilters filters = ResearchFilters.empty,
  }) async {
    return patrolPublicationTrend;
  }

  @override
  Future<CitationVelocityResult> fetchCitationVelocity(
    String query, {
    ResearchFilters filters = ResearchFilters.empty,
    int perPage = 100,
  }) async {
    return const CitationVelocityResult(
      velocity: patrolCitationVelocity,
      sampleTotalCitations: 456,
      sampleSize: 3,
    );
  }

  @override
  Future<List<JournalModel>> fetchTopJournals({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
    int perPage = ApiService.maxTopJournalLimit,
  }) async {
    return const [patrolJournal];
  }

  @override
  Future<List<AuthorModel>> fetchTopAuthors({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
    int perPage = 10,
  }) async {
    return const [patrolAuthor];
  }

  @override
  Future<List<InstitutionModel>> fetchTopInstitutions({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
    int perPage = 10,
  }) async {
    return const [patrolInstitution];
  }

  @override
  Future<List<CountryOutput>> fetchCountryOutputs({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
    int perPage = 12,
  }) async {
    return const [patrolCountry];
  }

  @override
  Future<List<KeywordMetric>> fetchTrendingKeywords({
    String? query,
    ResearchFilters filters = ResearchFilters.empty,
    int perPage = 12,
  }) async {
    return const [patrolKeyword];
  }

  @override
  Future<List<KeywordMetric>> fetchResearchFrontiers(
    String query, {
    ResearchFilters filters = ResearchFilters.empty,
    int perPage = 12,
  }) async {
    return const [patrolKeyword];
  }

  @override
  Future<List<PublicationModel>> fetchWorksBySourceId(String sourceId) async {
    return const [patrolPublication];
  }

  @override
  Future<List<PublicationModel>> fetchWorksByAuthorId(String authorId) async {
    return const [patrolPublication];
  }

  @override
  void dispose() {}
}

class PatrolFirebaseFeaturesViewModel extends FirebaseFeaturesViewModel {
  PatrolFirebaseFeaturesViewModel() : super(autoInitialize: false) {
    isFirebaseAvailable = true;
    isMessagingReady = true;
    notificationPermissionLabel = 'authorized';
    fcmToken = 'patrol-fcm-token';
    maxJournals = 10;
    maxKeywords = 12;
    notifications = [
      AppNotification(
        id: 'patrol-notification-1',
        title: 'New trending research topic',
        body: 'Deep learning is trending in the current dataset.',
        receivedAt: DateTime(2026, 7, 14, 9, 30),
        source: AppNotificationSource.foreground,
      ),
    ];
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refreshRemoteConfig() async {
    isRemoteConfigLoading = true;
    notifyListeners();
    maxJournals = 10;
    maxKeywords = 12;
    errorMessage = null;
    isRemoteConfigLoading = false;
    notifyListeners();
  }

  @override
  Future<String?> exportReportPdf(DashboardReportData data) async {
    isExporting = true;
    errorMessage = null;
    lastExportedUrl = null;
    notifyListeners();

    lastPdfPath = 'patrol/generated/journal_trend_report.pdf';
    lastExportedUrl =
        'https://firebasestorage.googleapis.com/v0/b/patrol/o/journal_trend_report.pdf';

    isExporting = false;
    notifyListeners();
    return lastExportedUrl;
  }

  @override
  Future<void> trackLogin({String method = 'google'}) async {}

  @override
  Future<void> trackLogout() async {}

  @override
  Future<void> trackSearchTopic(String topic) async {}

  @override
  Future<void> trackViewPublication({
    required String publicationId,
    required String title,
    int? publicationYear,
  }) async {}

  @override
  Future<void> trackViewJournal({
    required String journalId,
    required String name,
  }) async {}

  @override
  Future<void> trackViewKeyword({
    required String keywordId,
    required String name,
  }) async {}

  @override
  Future<void> trackExportPdf({
    required String topic,
    String? storageUrl,
  }) async {}

  @override
  Future<void> recordHandledException() async {}

  @override
  Future<void> forceTestCrash() async {}
}

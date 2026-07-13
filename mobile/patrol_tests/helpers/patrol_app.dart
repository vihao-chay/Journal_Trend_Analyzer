import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/models/analytics_models.dart';
import 'package:mobile/models/auth_user.dart';
import 'package:mobile/models/author_model.dart';
import 'package:mobile/models/global_overview.dart';
import 'package:mobile/models/journal_model.dart';
import 'package:mobile/models/publication_model.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/search_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/viewmodels/firebase_features_view_model.dart';

Future<void> pumpAuthenticatedApp(dynamic $) async {
  await $.pumpWidgetAndSettle(
    MyApp(
      searchProvider: seededSearchProvider(),
      themeProvider: ThemeProvider(autoLoad: false),
      authProvider: AuthProvider(
        autoInitialize: false,
        initialUser: const AuthUser(
          uid: 'patrol-user',
          displayName: 'Patrol Tester',
          email: 'patrol@example.com',
        ),
      ),
      firebaseFeaturesProvider: FirebaseFeaturesViewModel(
        autoInitialize: false,
      ),
    ),
  );
}

SearchProvider seededSearchProvider() {
  const publication = PublicationModel(
    id: 'https://openalex.org/W2741809807',
    title: 'Deep learning in research analytics',
    publicationYear: 2024,
    citedByCount: 152,
    doi: 'https://doi.org/10.0000/example',
    journalName: 'Journal of Research Analytics',
    authors: ['Jane Doe', 'Nguyen Van A'],
    landingPageUrl: 'https://openalex.org/W2741809807',
  );
  const journal = JournalModel(
    id: 'https://openalex.org/S123',
    displayName: 'Journal of Research Analytics',
    worksCount: 4820,
    citedByCount: 26000,
  );
  const author = AuthorModel(
    id: 'https://openalex.org/A123',
    displayName: 'Jane Doe',
    worksCount: 120,
    citedByCount: 3500,
  );
  const keyword = KeywordMetric(
    id: 'https://openalex.org/keywords/deep-learning',
    displayName: 'deep learning',
    worksCount: 2400,
    citedByCount: 18000,
    field: 'Computer science',
  );

  return SearchProvider(autoLoadGlobalOverview: false)
    ..globalOverview = const GlobalOverview(
      totalWorks: 1284000,
      totalAuthors: 214000,
      totalSources: 4200,
      publicationTrend: {'2021': 800, '2022': 1100, '2023': 1450},
      citationVelocity: {'2021': 500, '2022': 1200, '2023': 2400},
      topJournals: [journal],
      topAuthors: [author],
      topInstitutions: [
        InstitutionModel(
          id: 'https://openalex.org/I123',
          displayName: 'Open Research University',
          worksCount: 900,
          countryCode: 'US',
          countryName: 'United States',
        ),
      ],
      countryOutputs: [
        CountryOutput(
          id: 'https://openalex.org/countries/US',
          name: 'United States',
          countryCode: 'US',
          worksCount: 1200,
        ),
      ],
      trendingKeywords: [keyword],
      featuredPublications: [publication],
      mostCitedWork: publication,
      peakYear: 2023,
      peakYearCount: 1450,
    )
    ..hasSearched = true
    ..keyword = 'deep learning'
    ..publications = const [publication]
    ..publicationTotalCount = 1
    ..journalPagePublications = const [publication]
    ..publicationTrend = const {'2021': 80, '2022': 120, '2023': 180}
    ..citationVelocity = const {'2021': 200, '2022': 550, '2023': 900}
    ..topJournals = const [journal]
    ..topAuthors = const [author]
    ..keywordFrontiers = const [keyword]
    ..countryOutputs = const [
      CountryOutput(
        id: 'https://openalex.org/countries/US',
        name: 'United States',
        countryCode: 'US',
        worksCount: 1200,
      ),
    ]
    ..mostInfluentialPublication = publication
    ..searchAverageCitations = 152;
}

Future<void> openBottomTab(dynamic $, String label) async {
  await $(find.text(label).last).tap();
  await $.pumpAndSettle();
}

Future<void> openBottomTabIndex(dynamic $, int index) async {
  await $(find.byType(NavigationDestination).at(index)).tap();
  await $.pumpAndSettle();
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';
import 'package:mobile/models/analytics_models.dart';
import 'package:mobile/models/author_model.dart';
import 'package:mobile/models/global_overview.dart';
import 'package:mobile/models/journal_model.dart';
import 'package:mobile/models/publication_model.dart';
import 'package:mobile/providers/search_provider.dart';

SearchProvider _testSearchProvider() {
  return SearchProvider(autoLoadGlobalOverview: false)
    ..globalOverview = GlobalOverview(
      totalWorks: 1284,
      totalAuthors: 214,
      totalSources: 42,
      publicationTrend: const {
        '2020': 1200000,
        '2021': 1300000,
        '2022': 1400000,
      },
      citationVelocity: const {'2020': 900, '2021': 1800, '2022': 3200},
      topJournals: const [
        JournalModel(
          id: 'https://openalex.org/S1',
          displayName: 'Nature',
          worksCount: 50000,
        ),
      ],
      topAuthors: const [
        AuthorModel(
          id: 'https://openalex.org/A1',
          displayName: 'Jane Doe',
          worksCount: 400,
          citedByCount: 1200,
        ),
      ],
      topInstitutions: const [
        InstitutionModel(
          id: 'https://openalex.org/I1',
          displayName: 'Open Research University',
          worksCount: 800,
          countryCode: 'US',
          countryName: 'United States of America',
        ),
      ],
      countryOutputs: const [
        CountryOutput(
          id: 'https://openalex.org/countries/US',
          name: 'United States of America',
          countryCode: 'US',
          worksCount: 1000,
        ),
      ],
      trendingKeywords: const [
        KeywordMetric(
          id: 'https://openalex.org/keywords/artificial-intelligence',
          displayName: 'Artificial intelligence',
          worksCount: 600,
        ),
      ],
      featuredPublications: const [
        PublicationModel(
          id: 'https://openalex.org/W1',
          title: 'AI research trends',
          publicationYear: 2024,
          citedByCount: 90,
          doi: null,
          journalName: 'Nature',
          authors: ['Jane Doe'],
        ),
      ],
      peakYear: 2022,
      peakYearCount: 1400000,
    );
}

void main() {
  testWidgets('renders search and trend screens on a mobile viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MyApp(searchProvider: _testSearchProvider()));

    expect(find.text('Phân tích nghiên cứu OpenAlex'), findsOneWidget);
    expect(find.text('Trang chủ nghiên cứu'), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Tạp chí'), findsWidgets);
    expect(find.text('Từ khóa'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsWidgets);

    await tester.tap(find.text('Tạp chí').last);
    await tester.pumpAndSettle();

    expect(find.text('Danh sách bài báo'), findsOneWidget);

    await tester.tap(find.text('Từ khóa').last);
    await tester.pumpAndSettle();

    expect(find.text('Tốc độ tăng trích dẫn theo chủ đề'), findsOneWidget);
    expect(find.text('Tác giả có trích dẫn cao nhất'), findsOneWidget);

    await tester.tap(find.text('Hồ sơ').last);
    await tester.pumpAndSettle();

    expect(find.text('Cài đặt người dùng'), findsOneWidget);
  });
}

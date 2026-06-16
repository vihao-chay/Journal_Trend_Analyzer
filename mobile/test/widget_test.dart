import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';
import 'package:mobile/models/author_model.dart';
import 'package:mobile/models/global_overview.dart';
import 'package:mobile/models/journal_model.dart';
import 'package:mobile/providers/search_provider.dart';

SearchProvider _testSearchProvider() {
  return SearchProvider(autoLoadGlobalOverview: false)
    ..globalOverview = GlobalOverview(
      totalWorks: 1284,
      totalAuthors: 214,
      totalSources: 42,
      publicationTrend: const {'2020': 1200000, '2021': 1300000, '2022': 1400000},
      topJournals: const [
        JournalModel(displayName: 'Nature', worksCount: 50000),
      ],
      topAuthors: const [
        AuthorModel(displayName: 'Jane Doe', worksCount: 400),
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

    expect(find.text('Journal Trend Analyzer'), findsOneWidget);
    expect(find.text('Publication Search'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Trends'), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Research Dashboard'), findsOneWidget);
    expect(find.text('Global statistics from the full OpenAlex catalog.'), findsOneWidget);
    expect(find.text('Works'), findsOneWidget);

    await tester.tap(find.text('Trends'));
    await tester.pumpAndSettle();

    expect(find.text('Publication Trend Analysis'), findsOneWidget);
    expect(find.text('Publications per Year'), findsOneWidget);
  });
}

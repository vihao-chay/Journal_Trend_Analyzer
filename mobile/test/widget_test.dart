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
        JournalModel(id: 'https://openalex.org/S1', displayName: 'Nature', worksCount: 50000),
      ],
      topAuthors: const [
        AuthorModel(id: 'https://openalex.org/A1', displayName: 'Jane Doe', worksCount: 400),
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
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Keywords'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();

    expect(find.text('Journals'), findsOneWidget);

    await tester.tap(find.text('Keywords'));
    await tester.pumpAndSettle();

    expect(find.text('Publication Trend Analysis'), findsOneWidget);
    expect(find.text('Publications per Year'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsWidgets);
  });
}

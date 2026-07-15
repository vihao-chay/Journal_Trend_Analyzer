import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_app.dart';

void main() {
  patrolTest('TC06 - Keywords Navigation displays statistics and list', (
    $,
  ) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 2);

    expect(
      find.byKey(const ValueKey('keywords_frontier_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('keywords_citation_velocity_chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('keywords_author_scatter_chart')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('keyword_tile_1')), findsOneWidget);
    expect(find.text('deep learning'), findsWidgets);
  });

  patrolTest('TC07 - Keyword Details displays keyword analysis info', (
    $,
  ) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 2);

    await $(find.byKey(const ValueKey('keyword_tile_1'))).tap();
    await $.pumpAndSettle();

    expect(find.byKey(const Key('keyword_detail_screen')), findsOneWidget);
    expect(find.text('deep learning'), findsWidgets);
    expect(
      find.byKey(const ValueKey('keyword_publication_trend_chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('keyword_related_journals')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('keyword_top_authors')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('keyword_related_publications')),
      findsOneWidget,
    );
  });
}

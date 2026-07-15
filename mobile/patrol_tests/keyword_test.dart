import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_app.dart';

void main() {
  patrolTest('shows keyword frontier list and charts', ($) async {
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
    expect(find.text('deep learning'), findsWidgets);
  });

  patrolTest('opens keyword detail with trend and related sections', ($) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 2);

    await $(find.text('deep learning').first).tap();
    await $.pumpAndSettle();

    expect(find.byKey(const Key('keyword_detail_screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('keyword_publication_trend_chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('keyword_related_journals')),
      findsOneWidget,
    );
  });
}

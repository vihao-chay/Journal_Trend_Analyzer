import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_app.dart';

void main() {
  patrolTest('shows searched publication dashboard on Home', ($) async {
    await pumpAuthenticatedApp($);

    expect(
      find.byKey(const ValueKey('home_search_results_dashboard')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home_publication_trend_chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home_publication_results')),
      findsOneWidget,
    );
  });

  patrolTest('opens publication detail and exposes original link action', (
    $,
  ) async {
    await pumpAuthenticatedApp($);

    await $(find.text('Deep learning in research analytics').first).tap();
    await $.pumpAndSettle();

    expect(find.byKey(const Key('publication_detail_screen')), findsOneWidget);
    expect(
      find.byKey(const Key('open_original_publication_button')),
      findsOneWidget,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_app.dart';

void main() {
  patrolTest('TC02 - Topic Search displays publication results', ($) async {
    await pumpAuthenticatedApp($, searched: false);

    await searchForTopic($, 'deep learning');

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
    expect(
      find.byKey(
        const ValueKey(
          'home_publication_result_https://openalex.org/W2741809807',
        ),
      ),
      findsOneWidget,
    );
  });

  patrolTest('TC03 - Publication Details displays selected publication info', (
    $,
  ) async {
    await pumpAuthenticatedApp($);

    const publicationCardKey = ValueKey(
      'home_publication_result_https://openalex.org/W2741809807',
    );

    await $.scrollUntilVisible(finder: find.byKey(publicationCardKey));
    await $(find.byKey(publicationCardKey)).tap();
    await $.pumpAndSettle();

    expect(find.byKey(const Key('publication_detail_screen')), findsOneWidget);
    expect(find.text('Deep learning in research analytics'), findsOneWidget);
    expect(find.text('Journal of Research Analytics'), findsOneWidget);
    expect(
      find.byKey(const Key('open_original_publication_button')),
      findsOneWidget,
    );
  });
}

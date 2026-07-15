import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_app.dart';

void main() {
  patrolTest('TC04 - Journals Navigation displays statistics and list', (
    $,
  ) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 1);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Journal of Research Analytics'), findsWidgets);
    expect(find.byKey(const ValueKey('journal_card_1')), findsOneWidget);
  });

  patrolTest('TC05 - Journal Details displays selected journal info', (
    $,
  ) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 1);

    await $.scrollUntilVisible(
      finder: find.byKey(const ValueKey('journal_card_1')),
    );
    await $(find.byKey(const ValueKey('journal_card_1'))).tap();
    await $.pumpAndSettle();

    expect(find.byKey(const Key('journal_detail_screen')), findsOneWidget);
    expect(find.text('Journal of Research Analytics'), findsWidgets);
    expect(
      find.byKey(const Key('journal_related_publications')),
      findsOneWidget,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_app.dart';

void main() {
  patrolTest('shows journal ranking and publication list', ($) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 1);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Journal of Research Analytics'), findsWidgets);
    expect(find.textContaining('Danh'), findsWidgets);
  });

  patrolTest('opens journal detail with related publications', ($) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 1);

    await $(find.text('Journal of Research Analytics').first).tap();
    await $.pumpAndSettle();

    expect(find.byKey(const Key('journal_detail_screen')), findsOneWidget);
    expect(find.byKey(const Key('journal_related_publications')), findsWidgets);
  });
}

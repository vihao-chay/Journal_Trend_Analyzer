import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_app.dart';

void main() {
  patrolTest('TC10 - Remote Config displays fetched configuration values', (
    $,
  ) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 3);

    expect(
      find.byKey(const ValueKey('profile_remote_config_card')),
      findsOneWidget,
    );
    expect(find.textContaining('max_journals'), findsOneWidget);
    expect(find.textContaining('max_keywords'), findsOneWidget);
  });
}

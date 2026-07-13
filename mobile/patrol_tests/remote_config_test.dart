import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_app.dart';

void main() {
  patrolTest('shows both Remote Config values', ($) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 3);

    expect(
      find.byKey(const ValueKey('profile_remote_config_card')),
      findsOneWidget,
    );
    expect(find.textContaining('max_journals'), findsOneWidget);
    expect(find.textContaining('max_keywords'), findsOneWidget);
  });

  patrolTest('can refresh Remote Config from Profile', ($) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 3);

    await $(
      find.byKey(const ValueKey('profile_refresh_remote_config_button')),
    ).tap();
    await $.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile_remote_config_card')),
      findsOneWidget,
    );
  });
}

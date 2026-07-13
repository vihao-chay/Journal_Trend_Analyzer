import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_app.dart';

void main() {
  patrolTest('shows Firebase profile sections', ($) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 3);

    expect(find.text('patrol@example.com'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile_firebase_status_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile_remote_config_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile_notifications_section')),
      findsOneWidget,
    );
  });

  patrolTest('supports theme and sign-out controls', ($) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 3);

    expect(find.textContaining('Firebase'), findsWidgets);
    expect(find.byIcon(Icons.logout), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });
}

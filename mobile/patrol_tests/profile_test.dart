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
      find.byKey(const ValueKey('profile_copy_fcm_token_button')),
      findsOneWidget,
    );
  });

  patrolTest('opens Notification screen from app bar bell', ($) async {
    await pumpAuthenticatedApp($);

    await $(find.byKey(const ValueKey('app_notification_bell_button'))).tap();
    await $.pumpAndSettle();

    expect(find.byKey(const Key('notifications_screen')), findsOneWidget);
    expect(find.text('Trung tâm thông báo'), findsOneWidget);
  });

  patrolTest('supports theme and sign-out controls', ($) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 3);

    expect(find.textContaining('Firebase'), findsWidgets);
    expect(
      find.byKey(const ValueKey('profile_bottom_logout_button')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });

  patrolTest('performs logout and returns to Login screen', ($) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 3);

    await $.scrollUntilVisible(
      finder: find.byKey(const ValueKey('profile_bottom_logout_button')),
    );
    await $(find.byKey(const ValueKey('profile_bottom_logout_button'))).tap();
    await $.pumpAndSettle();

    expect(find.text('OpenAlex Research Analytics'), findsOneWidget);
    expect(find.textContaining('Google'), findsOneWidget);
  });
}

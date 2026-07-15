import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_app.dart';

void main() {
  patrolTest('TC08 - Profile Navigation displays user profile info', ($) async {
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

  patrolTest('TC11 - Logout redirects to Login screen', ($) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 3);

    await $.scrollUntilVisible(
      finder: find.byKey(const ValueKey('profile_bottom_logout_button')),
    );
    await $(find.byKey(const ValueKey('profile_bottom_logout_button'))).tap();
    await $.pumpAndSettle();

    expect(find.text('OpenAlex Research Analytics'), findsOneWidget);
    expect(find.byKey(const ValueKey('login_google_button')), findsOneWidget);
  });
}

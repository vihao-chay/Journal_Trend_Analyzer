import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_app.dart';

void main() {
  patrolTest('exposes PDF export action in Profile', ($) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 3);

    await $.scrollUntilVisible(
      finder: find.byKey(const ValueKey('profile_export_pdf_button')),
    );
    expect(
      find.byKey(const ValueKey('profile_export_pdf_button')),
      findsOneWidget,
    );
  });

  patrolTest('runs the guarded export flow without crashing the UI', ($) async {
    await pumpAuthenticatedApp($);
    await openBottomTabIndex($, 3);

    await $.scrollUntilVisible(
      finder: find.byKey(const ValueKey('profile_export_pdf_button')),
    );
    await $(find.byKey(const ValueKey('profile_export_pdf_button'))).tap();
    await $.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile_firebase_actions_card')),
      findsOneWidget,
    );
  });
}

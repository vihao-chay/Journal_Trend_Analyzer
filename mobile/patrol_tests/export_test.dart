import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_app.dart';

void main() {
  patrolTest('TC09 - PDF Export uploads report to Firebase Storage', ($) async {
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
    expect(
      find.byKey(const ValueKey('profile_open_exported_pdf_button')),
      findsOneWidget,
    );
    expect(find.textContaining('PDF local:'), findsOneWidget);
  });
}

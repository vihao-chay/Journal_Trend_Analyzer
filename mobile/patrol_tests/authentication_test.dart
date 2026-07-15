import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_app.dart';

void main() {
  patrolTest('TC01 - Google Sign-In navigates to Home screen', ($) async {
    await pumpSignedOutApp($);

    expect(find.text('OpenAlex Research Analytics'), findsOneWidget);
    expect(find.byKey(const ValueKey('login_google_button')), findsOneWidget);

    await $(find.byKey(const ValueKey('login_google_button'))).tap();
    await $.pumpAndSettle();

    expect(find.byKey(const ValueKey('home_screen_content')), findsOneWidget);
  });
}

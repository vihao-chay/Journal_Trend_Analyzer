import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('renders detail and trend screens on a mobile viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MyApp());

    expect(find.text('Journal Trend Analyzer'), findsOneWidget);
    expect(find.text('Open DOI Link'), findsOneWidget);
    expect(find.text('Abstract'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);

    await tester.tap(find.text('Trends'));
    await tester.pumpAndSettle();

    expect(find.text('Publication Trend Analysis'), findsOneWidget);
    expect(find.text('Publications per Year'), findsOneWidget);
  });
}

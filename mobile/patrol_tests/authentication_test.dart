import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/search_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/viewmodels/firebase_features_view_model.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('shows Google Sign-In screen for signed-out users', ($) async {
    await $.pumpWidgetAndSettle(
      MyApp(
        searchProvider: SearchProvider(autoLoadGlobalOverview: false),
        themeProvider: ThemeProvider(autoLoad: false),
        authProvider: AuthProvider(autoInitialize: false),
        firebaseFeaturesProvider: FirebaseFeaturesViewModel(
          autoInitialize: false,
        ),
      ),
    );

    expect(find.text('OpenAlex Research Analytics'), findsOneWidget);
    expect(find.textContaining('Google'), findsOneWidget);
  });

  patrolTest('can start the Google Sign-In flow when enabled', ($) async {
    await $.pumpWidgetAndSettle(
      MyApp(
        searchProvider: SearchProvider(autoLoadGlobalOverview: false),
        themeProvider: ThemeProvider(autoLoad: false),
        authProvider: AuthProvider(autoInitialize: false),
        firebaseFeaturesProvider: FirebaseFeaturesViewModel(
          autoInitialize: false,
        ),
      ),
    );

    expect(find.textContaining('Google'), findsOneWidget);

    if (const bool.fromEnvironment('PATROL_GOOGLE_LOGIN_ENABLED')) {
      await $(find.textContaining('Google')).tap();
      await $.pumpAndSettle();
    }
  });
}

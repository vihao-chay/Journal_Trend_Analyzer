# Journal Trend Analyzer - Lab 03

Flutter mobile app phan tich xu huong hoc thuat tu OpenAlex, bo sung Firebase theo yeu cau PRM393 Lab 03.

## Chuc nang da trien khai

- Firebase Authentication voi Google Sign-In.
- Firebase Analytics events: `login`, `search_topic`, `view_publication`, `view_journal`, `view_keyword`, `export_pdf`, `logout`.
- Firebase Cloud Messaging notification center, luu inbox foreground/background/opened messages bang local preferences.
- Firebase Remote Config voi 2 key:
  - `max_journals`: gioi han so tap chi hien thi trong tab Journals.
  - `max_keywords`: gioi han so keyword hien thi trong tab Keywords.
- Firebase Storage export PDF: tao bao cao dashboard va upload vao `exports/`.
- Firebase Crashlytics: global error handlers, non-fatal test, crash test button.
- MVVM + Provider: `SearchProvider`, `AuthProvider`, `FirebaseFeaturesViewModel`, `JournalDetailViewModel`, `KeywordDetailViewModel`.
- Bottom navigation: Home, Journals, Keywords, Profile.
- Detail screens: publication, journal, keyword.
- Patrol E2E source tests trong `patrol_tests/`.

## Cai dat

```powershell
flutter pub get
```

Can cau hinh Firebase cho Android truoc khi chay day du:

1. Tao Firebase project va Android app package `com.example.mobile`.
2. Dat `google-services.json` vao `android/app/google-services.json`.
3. Bat Authentication Google provider, Analytics, Crashlytics, Cloud Messaging, Remote Config, Storage.
4. Tao Remote Config keys `max_journals` va `max_keywords`.

Neu khong dung file options sinh boi FlutterFire, co the truyen dart-define:

```powershell
flutter run `
  --dart-define=FIREBASE_API_KEY=... `
  --dart-define=FIREBASE_ANDROID_APP_ID=... `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... `
  --dart-define=FIREBASE_PROJECT_ID=... `
  --dart-define=FIREBASE_STORAGE_BUCKET=... `
  --dart-define=FIREBASE_WEB_CLIENT_ID=...
```

## Chay va kiem thu

```powershell
flutter analyze --no-pub
flutter test --no-pub -r expanded
flutter build apk --debug --no-pub
```

Patrol E2E:

```powershell
dart pub global activate patrol_cli
patrol test -t patrol_tests/authentication_test.dart
patrol test
```

Google Sign-In native flow can tai khoan test tren thiet bi/emulator Google Play. Test `can start the Google Sign-In flow when enabled` chi bam nut Google khi them:

```powershell
patrol test -t patrol_tests/authentication_test.dart --dart-define=PATROL_GOOGLE_LOGIN_ENABLED=true
```

## Ghi chu demo Lab

- Nut `Test crash` trong Profile se lam app crash that de gui Crashlytics fatal event. Chi bam khi dang demo Crashlytics.
- Nut `Gui non-fatal` gui exception da handle len Crashlytics.
- Export PDF can Firebase Storage bucket hop le va Storage rules cho phep user dang nhap upload.
- FCM token hien trong Profile de gui test message tu Firebase Console.
- Video/report nen quay cac man: Google login, search topic, publication detail, journal detail, keyword detail, Remote Config thay doi limit, export PDF, FCM notification, Crashlytics non-fatal/fatal.

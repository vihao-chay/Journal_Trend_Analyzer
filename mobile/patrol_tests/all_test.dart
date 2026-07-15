import 'package:flutter_test/flutter_test.dart';

import 'authentication_test.dart' as authentication_test;
import 'export_test.dart' as export_test;
import 'journal_test.dart' as journal_test;
import 'keyword_test.dart' as keyword_test;
import 'profile_test.dart' as profile_test;
import 'publication_test.dart' as publication_test;
import 'remote_config_test.dart' as remote_config_test;

void main() {
  group('authentication_test', authentication_test.main);
  group('export_test', export_test.main);
  group('journal_test', journal_test.main);
  group('keyword_test', keyword_test.main);
  group('profile_test', profile_test.main);
  group('publication_test', publication_test.main);
  group('remote_config_test', remote_config_test.main);
}

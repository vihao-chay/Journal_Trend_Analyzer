import 'package:flutter/foundation.dart';

import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../services/api_service.dart';

class JournalDetailViewModel extends ChangeNotifier {
  JournalDetailViewModel({required this.journal, ApiService? apiService})
    : _apiService = apiService ?? ApiService(),
      _ownsApiService = apiService == null;

  final JournalModel journal;
  final ApiService _apiService;
  final bool _ownsApiService;

  bool isLoading = false;
  String? errorMessage;
  List<PublicationModel> publications = const [];

  double get averageCitations =>
      journal.worksCount <= 0 ? 0 : journal.citedByCount / journal.worksCount;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      publications = await _apiService.fetchWorksBySourceId(journal.id);
    } on ApiException catch (exception) {
      publications = const [];
      errorMessage = exception.message;
    } catch (_) {
      publications = const [];
      errorMessage = 'Không thể tải danh sách bài báo của tạp chí.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_ownsApiService) {
      _apiService.dispose();
    }
    super.dispose();
  }
}

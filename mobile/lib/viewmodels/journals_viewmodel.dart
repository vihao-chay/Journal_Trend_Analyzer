import 'package:flutter/foundation.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';

class JournalsViewModel extends ChangeNotifier {
  List<JournalModel> _topJournals = [];
  bool _isLoading = false;
  String? _error;

  List<JournalModel> get topJournals => _topJournals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void processPublications(List<PublicationModel> publications) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, int> journalCounts = {};
      final Map<String, int> journalCitations = {};

      for (var pub in publications) {
        if (pub.journalName.isNotEmpty && pub.journalName != 'Unknown Journal') {
          journalCounts[pub.journalName] = (journalCounts[pub.journalName] ?? 0) + 1;
          journalCitations[pub.journalName] = (journalCitations[pub.journalName] ?? 0) + pub.citedByCount;
        }
      }

      final List<JournalModel> journals = journalCounts.entries.map((e) {
        return JournalModel(
          id: e.key, // Using name as ID since we don't have journal IDs here
          displayName: e.key,
          worksCount: e.value,
          citedByCount: journalCitations[e.key] ?? 0,
        );
      }).toList();

      journals.sort((a, b) => b.worksCount.compareTo(a.worksCount));
      _topJournals = journals;
    } catch (e) {
      _error = 'Failed to process journals: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

import 'author_model.dart';
import 'journal_model.dart';
import 'publication_model.dart';

/// OpenAlex-wide statistics loaded from global list/aggregate endpoints.
class GlobalOverview {
  const GlobalOverview({
    required this.totalWorks,
    required this.totalAuthors,
    required this.totalSources,
    required this.publicationTrend,
    required this.topJournals,
    required this.topAuthors,
    this.mostCitedWork,
    this.peakYear,
    this.peakYearCount = 0,
  });

  final int totalWorks;
  final int totalAuthors;
  final int totalSources;
  final Map<String, int> publicationTrend;
  final List<JournalModel> topJournals;
  final List<AuthorModel> topAuthors;
  final PublicationModel? mostCitedWork;
  final int? peakYear;
  final int peakYearCount;

  static GlobalOverview? fromApiResults({
    required int totalWorks,
    required int totalAuthors,
    required int totalSources,
    required Map<String, int> publicationTrend,
    required List<JournalModel> topJournals,
    required List<AuthorModel> topAuthors,
    required PublicationModel? mostCitedWork,
  }) {
    if (totalWorks <= 0) {
      return null;
    }

    int? peakYear;
    var peakYearCount = 0;
    for (final entry in publicationTrend.entries) {
      final year = int.tryParse(entry.key);
      if (year == null) {
        continue;
      }
      if (entry.value > peakYearCount) {
        peakYear = year;
        peakYearCount = entry.value;
      }
    }

    return GlobalOverview(
      totalWorks: totalWorks,
      totalAuthors: totalAuthors,
      totalSources: totalSources,
      publicationTrend: publicationTrend,
      topJournals: topJournals,
      topAuthors: topAuthors,
      mostCitedWork: mostCitedWork,
      peakYear: peakYear,
      peakYearCount: peakYearCount,
    );
  }
}

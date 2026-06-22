import '../models/publication_model.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalPublications,
    required this.totalCitations,
    required this.averageCitations,
    required this.uniqueAuthors,
    required this.uniqueJournals,
    this.topYear,
    this.topYearCount = 0,
    this.topAuthor,
    this.topAuthorCount = 0,
    this.topJournal,
    this.topJournalCount = 0,
    this.mostCitedPublication,
  });

  final int totalPublications;
  final int totalCitations;
  final double averageCitations;
  final int uniqueAuthors;
  final int uniqueJournals;
  final int? topYear;
  final int topYearCount;
  final String? topAuthor;
  final int topAuthorCount;
  final String? topJournal;
  final int topJournalCount;
  final PublicationModel? mostCitedPublication;

  static const empty = DashboardStats(
    totalPublications: 0,
    totalCitations: 0,
    averageCitations: 0,
    uniqueAuthors: 0,
    uniqueJournals: 0,
  );

  factory DashboardStats.fromPublications(List<PublicationModel> publications) {
    if (publications.isEmpty) {
      return empty;
    }

    final totalCitations = publications.fold<int>(
      0,
      (sum, publication) => sum + publication.citedByCount,
    );
    final authorCounts = <String, int>{};
    final journalCounts = <String, int>{};
    final yearCounts = <int, int>{};

    for (final publication in publications) {
      final year = publication.publicationYear;
      if (year > 0) {
        yearCounts[year] = (yearCounts[year] ?? 0) + 1;
      }

      final journal = publication.journalName.trim();
      if (journal.isNotEmpty && journal != 'Unknown Journal') {
        journalCounts[journal] = (journalCounts[journal] ?? 0) + 1;
      }

      for (final author in publication.authors) {
        final name = author.trim();
        if (name.isNotEmpty) {
          authorCounts[name] = (authorCounts[name] ?? 0) + 1;
        }
      }
    }

    final topYearEntry = _topEntry(yearCounts);
    final topAuthorEntry = _topEntry(authorCounts);
    final topJournalEntry = _topEntry(journalCounts);
    final mostCited = publications.reduce(
      (current, next) =>
          next.citedByCount > current.citedByCount ? next : current,
    );

    return DashboardStats(
      totalPublications: publications.length,
      totalCitations: totalCitations,
      averageCitations: totalCitations / publications.length,
      uniqueAuthors: authorCounts.length,
      uniqueJournals: journalCounts.length,
      topYear: topYearEntry?.key,
      topYearCount: topYearEntry?.value ?? 0,
      topAuthor: topAuthorEntry?.key,
      topAuthorCount: topAuthorEntry?.value ?? 0,
      topJournal: topJournalEntry?.key,
      topJournalCount: topJournalEntry?.value ?? 0,
      mostCitedPublication: mostCited.citedByCount > 0 ? mostCited : null,
    );
  }
}

class _CountEntry<T> {
  const _CountEntry(this.key, this.value);

  final T key;
  final int value;
}

_CountEntry<T>? _topEntry<T>(Map<T, int> counts) {
  if (counts.isEmpty) {
    return null;
  }

  final entry = counts.entries.reduce(
    (current, next) => next.value > current.value ? next : current,
  );
  return _CountEntry(entry.key, entry.value);
}

List<PublicationModel> sortPublicationsByYearDesc(
  List<PublicationModel> publications,
) {
  final sorted = List<PublicationModel>.from(publications);
  sorted.sort((a, b) {
    final aYear = a.publicationYear > 0 ? a.publicationYear : 0;
    final bYear = b.publicationYear > 0 ? b.publicationYear : 0;
    return bYear.compareTo(aYear);
  });
  return sorted;
}

String formatCompactNumber(num value) {
  final rounded = value.round();
  if (rounded >= 1000000) {
    return '${(rounded / 1000000).toStringAsFixed(1)}M';
  }
  if (rounded >= 1000) {
    return '${(rounded / 1000).toStringAsFixed(1)}K';
  }
  return _formatWithCommas(rounded);
}

String _formatWithCommas(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < raw.length; index++) {
    if (index > 0 && (raw.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(raw[index]);
  }
  return buffer.toString();
}

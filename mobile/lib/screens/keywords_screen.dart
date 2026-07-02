import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_models.dart';
import '../models/author_model.dart';
import '../models/journal_model.dart';
import '../providers/search_provider.dart';
import '../widgets/app_widgets.dart';
import 'detail_screens.dart';

class KeywordsScreen extends StatelessWidget {
  const KeywordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSearched = context.select<SearchProvider, bool>(
      (provider) => provider.hasSearched,
    );
    final keyword = context.select<SearchProvider, String?>(
      (provider) => provider.keyword,
    );
    final isSearchLoading = context.select<SearchProvider, bool>(
      (provider) => provider.isSearchLoading,
    );
    final overview = context.select<SearchProvider, dynamic>(
      (provider) => provider.globalOverview,
    );
    final searchAuthors = context.select<SearchProvider, List<AuthorModel>>(
      (provider) => provider.topAuthors,
    );
    final searchJournals = context.select<SearchProvider, List<JournalModel>>(
      (provider) => provider.topJournals,
    );
    final searchCitationVelocity =
        context.select<SearchProvider, Map<String, int>>(
      (provider) => provider.citationVelocity,
    );

    final authors = hasSearched
        ? searchAuthors
        : overview?.topAuthors ?? const <AuthorModel>[];
    final journals = hasSearched
        ? searchJournals
        : overview?.topJournals ?? const <JournalModel>[];
    final citationVelocity = hasSearched
        ? searchCitationVelocity
        : overview?.citationVelocity ?? const <String, int>{};

    return ScreenScroll(
      onRefresh: () => context.read<SearchProvider>().loadGlobalOverview(),
      children: [
        ScreenHeader(
          title: 'Từ khóa',
          subtitle: hasSearched && keyword != null
              ? 'Phân tích từ khóa cho "$keyword".'
              : 'Theo dõi xu hướng từ khóa từ OpenAlex.',
          badge: hasSearched ? 'Đã lọc' : 'Xu hướng',
        ),
        const SizedBox(height: AppSpacing.medium),
        const SearchContextBanner(),
        if (isSearchLoading && hasSearched) ...[
          const SizedBox(height: AppSpacing.medium),
          const LinearProgressIndicator(minHeight: 5),
        ],
        const SizedBox(height: AppSpacing.medium),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.show_chart,
                title: 'Tốc độ tăng trích dẫn theo chủ đề',
              ),
              const SizedBox(height: 14),
              SizedBox(height: 260, child: LineChart(series: citationVelocity)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.scatter_plot,
                title: 'Tác giả có trích dẫn cao nhất',
              ),
              const SizedBox(height: 14),
              ScatterPlot(points: _authorScatterPoints(authors)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        _AuthorsAndJournals(authors: authors, journals: journals),
      ],
    );
  }

  List<ScatterPointData> _authorScatterPoints(List<AuthorModel> authors) {
    return authors
        .take(10)
        .map(
          (author) => ScatterPointData(
            label: author.displayName,
            x: author.worksCount.toDouble(),
            y: (author.citedByCount > 0
                    ? author.citedByCount
                    : author.worksCount * 12)
                .toDouble(),
            size: author.worksCount.toDouble(),
          ),
        )
        .toList(growable: false);
  }
}

class _AuthorsAndJournals extends StatelessWidget {
  const _AuthorsAndJournals({required this.authors, required this.journals});

  final List<AuthorModel> authors;
  final List<JournalModel> journals;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 780;
        final authorCard = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              icon: Icons.person_outline,
              title: 'Tác giả hàng đầu',
            ),
            const SizedBox(height: 14),
            if (authors.isEmpty)
              const AppEmptyState(
                icon: Icons.person_search,
                title: 'Chưa có tác giả',
                message:
                    'Dữ liệu tác giả sẽ xuất hiện sau khi tìm kiếm ở Trang chủ.',
              )
            else
              for (var index = 0; index < authors.take(5).length; index++) ...[
                AuthorCard(
                  author: authors[index],
                  rank: index + 1,
                  onTap: () {
                    final url = Uri.parse('https://openalex.org/${authors[index].id}');
                    launchUrl(url);
                  },
                ),
                const SizedBox(height: 12),
              ],
          ],
        );

        final journalCard = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              icon: Icons.library_books_outlined,
              title: 'Tạp chí hàng đầu',
            ),
            const SizedBox(height: 14),
            if (journals.isEmpty)
              const AppEmptyState(
                icon: Icons.library_books_outlined,
                title: 'Chưa có tạp chí',
                message:
                    'Dữ liệu tạp chí sẽ xuất hiện sau khi tìm kiếm ở Trang chủ.',
              )
            else
              for (var index = 0; index < journals.take(5).length; index++) ...[
                JournalCard(
                  journal: journals[index],
                  rank: index + 1,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            JournalDetailScreen(journal: journals[index]),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
          ],
        );

        if (!wide) {
          return Column(
            children: [
              authorCard,
              const SizedBox(height: AppSpacing.medium),
              journalCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: authorCard),
            const SizedBox(width: AppSpacing.medium),
            Expanded(child: journalCard),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_models.dart';
import '../models/author_model.dart';
import '../models/journal_model.dart';
import '../providers/search_provider.dart';
import '../widgets/app_widgets.dart';
import 'detail_screens.dart';

class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key});

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  final TextEditingController _keywordController = TextEditingController();

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  void _search([String? value]) {
    final keyword = (value ?? _keywordController.text).trim();
    if (keyword.isEmpty) return;
    _keywordController.text = keyword;
    FocusScope.of(context).unfocus();
    context.read<SearchProvider>().search(keyword);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final overview = provider.globalOverview;
    final usingSearch = provider.hasSearched;
    final authors = usingSearch
        ? provider.topAuthors
        : overview?.topAuthors ?? const <AuthorModel>[];
    final journals = usingSearch
        ? provider.topJournals
        : overview?.topJournals ?? const <JournalModel>[];
    final citationVelocity = usingSearch
        ? provider.citationVelocity
        : overview?.citationVelocity ?? const <String, int>{};
    final suggestedKeywords =
        overview?.trendingKeywords
            .map((keyword) => keyword.displayName)
            .where((name) => name.trim().isNotEmpty)
            .take(12)
            .toList(growable: false) ??
        const <String>[];

    return ScreenScroll(
      onRefresh: () => context.read<SearchProvider>().loadGlobalOverview(),
      children: [
        ScreenHeader(
          title: 'Keywords',
          subtitle: usingSearch && provider.keyword != null
              ? 'Phân tích keyword cho "${provider.keyword}".'
              : 'Theo dõi xu hướng keyword từ OpenAlex.',
          badge: usingSearch ? 'Đã lọc' : 'Trending',
        ),
        const SizedBox(height: AppSpacing.medium),
        ResearchSearchBar(
          controller: _keywordController,
          hintText: 'Tìm keyword hoặc research topic...',
          onSubmitted: _search,
          onSearchPressed: () => _search(),
        ),
        const SizedBox(height: 12),
        TopicDropdownCard(
          title: 'Keyword gợi ý',
          icon: Icons.local_fire_department_outlined,
          topics: suggestedKeywords,
          onSelected: _search,
          emptyText: 'Đang chờ keyword từ OpenAlex',
        ),
        if (provider.isSearchLoading && usingSearch) ...[
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
                title: 'Tốc độ tăng citation của chủ đề',
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
                title: 'Tác giả có citation cao nhất',
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
            y:
                (author.citedByCount > 0
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
                message: 'Dữ liệu tác giả sẽ xuất hiện sau khi tìm kiếm.',
              )
            else
              for (var index = 0; index < authors.take(5).length; index++) ...[
                AuthorCard(author: authors[index], rank: index + 1),
                const SizedBox(height: 12),
              ],
          ],
        );

        final journalCard = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              icon: Icons.library_books_outlined,
              title: 'Journal hàng đầu',
            ),
            const SizedBox(height: 14),
            if (journals.isEmpty)
              const AppEmptyState(
                icon: Icons.library_books_outlined,
                title: 'Chưa có journal',
                message: 'Dữ liệu journal sẽ xuất hiện sau khi tìm kiếm.',
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

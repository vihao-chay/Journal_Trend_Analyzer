import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_models.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../providers/search_provider.dart';
import '../widgets/app_widgets.dart';
import 'detail_screens.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final overview = provider.globalOverview;
    final journals = provider.hasSearched
        ? provider.topJournals
        : overview?.topJournals ?? const <JournalModel>[];
    final publications = provider.hasSearched
        ? provider.publications
        : overview?.featuredPublications ?? const <PublicationModel>[];
    final title = provider.hasSearched && provider.keyword != null
        ? 'Journal cho "${provider.keyword}"'
        : 'Journal nổi bật trên OpenAlex';

    return ScreenScroll(
      onRefresh: () => context.read<SearchProvider>().loadGlobalOverview(),
      children: [
        ScreenHeader(
          title: 'Journal',
          subtitle: title,
          badge: provider.hasSearched ? 'Đã lọc' : 'Toàn cục',
        ),
        const SizedBox(height: AppSpacing.medium),
        if (provider.isSearchLoading && provider.hasSearched)
          const SectionCard(
            child: SizedBox(
              height: 120,
              child: AppLoadingState(message: 'Đang tải journal...'),
            ),
          )
        else if (provider.searchError != null && provider.hasSearched)
          SectionCard(child: AppErrorState(message: provider.searchError!))
        else ...[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  icon: Icons.bar_chart,
                  title: 'Journal Ranking theo số bài',
                ),
                const SizedBox(height: 14),
                HorizontalBarChart(
                  data: journals
                      .take(8)
                      .map(
                        (journal) => ChartBarData(
                          label: journal.displayName,
                          value: journal.worksCount,
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          _PublicationList(publications: publications),
          const SizedBox(height: AppSpacing.medium),
          _JournalList(journals: journals),
        ],
      ],
    );
  }
}

class _PublicationList extends StatelessWidget {
  const _PublicationList({required this.publications});

  final List<PublicationModel> publications;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: SectionTitle(
                icon: Icons.article_outlined,
                title: 'Danh sách publication',
              ),
            ),
            if (publications.isNotEmpty)
              MetricPill(
                label: '${publications.length} bài đã tải',
                icon: Icons.cloud_done_outlined,
                accentColor: AppColors.secondary,
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (publications.isEmpty)
          const AppEmptyState(
            icon: Icons.article_outlined,
            title: 'Chưa có publication',
            message: 'Hãy tìm một chủ đề ở Home để xem danh sách bài báo.',
          )
        else
          for (final publication in publications) ...[
            PaperCard(
              publication: publication,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PublicationDetailScreen(publication: publication),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _JournalList extends StatelessWidget {
  const _JournalList({required this.journals});

  final List<JournalModel> journals;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          icon: Icons.library_books_outlined,
          title: 'Hồ sơ journal',
        ),
        const SizedBox(height: 14),
        if (journals.isEmpty)
          const AppEmptyState(
            icon: Icons.library_books_outlined,
            title: 'Chưa có journal',
            message: 'Dữ liệu journal sẽ xuất hiện sau khi tải OpenAlex.',
          )
        else
          for (var index = 0; index < journals.take(10).length; index++) ...[
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
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_models.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../providers/search_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_widgets.dart';
import 'detail_screens.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final provider = context.read<SearchProvider>();
      if (provider.journalPagePublications.isEmpty &&
          !provider.isJournalPublicationsLoading) {
        provider.loadJournalPublications(page: 1);
      }
    });
  }

  Future<void> _refreshJournalData() async {
    final provider = context.read<SearchProvider>();
    await Future.wait<void>([
      provider.loadGlobalOverview(),
      provider.loadJournalPublications(page: provider.journalPublicationPage),
    ]);
  }

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
    final isJournalPublicationsLoading =
        context.select<SearchProvider, bool>(
      (provider) => provider.isJournalPublicationsLoading,
    );
    final searchError = context.select<SearchProvider, String?>(
      (provider) => provider.searchError,
    );
    final journalPublicationsError =
        context.select<SearchProvider, String?>(
      (provider) => provider.journalPublicationsError,
    );
    final overview = context.select<SearchProvider, dynamic>(
      (provider) => provider.globalOverview,
    );
    final searchJournals = context.select<SearchProvider, List<JournalModel>>(
      (provider) => provider.topJournals,
    );
    final publications =
        context.select<SearchProvider, List<PublicationModel>>(
      (provider) => provider.journalPagePublications,
    );
    final publicationTotalCount = context.select<SearchProvider, int>(
      (provider) => provider.publicationTotalCount,
    );
    final journalPublicationPage = context.select<SearchProvider, int>(
      (provider) => provider.journalPublicationPage,
    );
    final journalPublicationTotalPages =
        context.select<SearchProvider, int>(
      (provider) => provider.journalPublicationTotalPages,
    );

    final journals = hasSearched
        ? searchJournals
        : overview?.topJournals ?? const <JournalModel>[];
    final subtitle = hasSearched && keyword != null
        ? 'Tạp chí cho "$keyword"'
        : 'Tạp chí nổi bật trên OpenAlex';
    final isPublicationListLoading =
        isJournalPublicationsLoading || (isSearchLoading && hasSearched);
    final publicationListError = hasSearched ? searchError : journalPublicationsError;

    return ScreenScroll(
      onRefresh: _refreshJournalData,
      children: [
        ScreenHeader(
          title: 'Tạp chí',
          subtitle: subtitle,
          badge: hasSearched ? 'Đã lọc' : 'Toàn cục',
        ),
        const SizedBox(height: AppSpacing.medium),
        const SearchContextBanner(),
        const SizedBox(height: AppSpacing.medium),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.bar_chart,
                title: 'Xếp hạng tạp chí theo số bài',
              ),
              const SizedBox(height: 14),
              if (isSearchLoading && hasSearched)
                const SizedBox(
                  height: 120,
                  child: AppLoadingState(message: 'Đang tải tạp chí...'),
                )
              else if (searchError != null && hasSearched)
                AppErrorState(message: searchError)
              else
                HorizontalBarChart(
                  data: journals
                      .take(8)
                      .map<ChartBarData>(
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
        _PublicationList(
          publications: publications,
          totalCount: publicationTotalCount,
          currentPage: journalPublicationPage,
          totalPages: journalPublicationTotalPages,
          isLoading: isPublicationListLoading,
          error: publicationListError,
          onPageSelected: (page) {
            context.read<SearchProvider>().loadJournalPublications(page: page);
          },
        ),
        const SizedBox(height: AppSpacing.medium),
        _JournalList(journals: journals),
      ],
    );
  }
}

class _PublicationList extends StatelessWidget {
  const _PublicationList({
    required this.publications,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    required this.error,
    required this.onPageSelected,
  });

  final List<PublicationModel> publications;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          icon: Icons.article_outlined,
          title: 'Danh sách bài báo',
        ),
        if (totalCount > 0) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const MetricPill(
                label: 'Mới → cũ',
                icon: Icons.sort,
                accentColor: AppColors.chartLine,
              ),
              MetricPill(
                label: 'Tổng $totalCount bài',
                icon: Icons.library_books_outlined,
                accentColor: AppColors.secondary,
              ),
              if (totalPages > 0)
                MetricPill(
                  label:
                      'Trang $currentPage / $totalPages (${ApiService.defaultPublicationPageSize}/trang)',
                  icon: Icons.layers_outlined,
                  accentColor: AppColors.primary,
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        if (isLoading)
          const SizedBox(
            height: 160,
            child: AppLoadingState(message: 'Đang tải bài báo...'),
          )
        else if (error != null)
          AppErrorState(message: error!)
        else if (publications.isEmpty)
          const AppEmptyState(
            icon: Icons.article_outlined,
            title: 'Chưa có bài báo',
            message: 'Hãy tìm một chủ đề ở Trang chủ để xem danh sách bài báo.',
          )
        else ...[
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
          if (totalPages > 1) ...[
            const SizedBox(height: 4),
            _PublicationPaginationBar(
              currentPage: currentPage,
              totalPages: totalPages,
              onPrevious: currentPage > 1
                  ? () => onPageSelected(currentPage - 1)
                  : null,
              onNext: currentPage < totalPages
                  ? () => onPageSelected(currentPage + 1)
                  : null,
            ),
          ],
        ],
      ],
    );
  }
}

class _PublicationPaginationBar extends StatelessWidget {
  const _PublicationPaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left, size: 20),
            label: const Text('Trước'),
          ),
          Expanded(
            child: Text(
              'Trang $currentPage / $totalPages',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          OutlinedButton(
            onPressed: onNext,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sau'),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ],
      ),
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
          title: 'Hồ sơ tạp chí',
        ),
        const SizedBox(height: 14),
        if (journals.isEmpty)
          const AppEmptyState(
            icon: Icons.library_books_outlined,
            title: 'Chưa có tạp chí',
            message: 'Dữ liệu tạp chí sẽ xuất hiện sau khi tải OpenAlex.',
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

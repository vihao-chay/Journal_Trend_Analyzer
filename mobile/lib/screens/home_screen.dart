import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_models.dart';
import '../models/global_overview.dart';
import '../models/publication_model.dart';
import '../providers/search_provider.dart';
import '../services/publication_analytics.dart';
import '../widgets/app_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _fallbackTopics = [
    'artificial intelligence',
    'climate change',
    'public health',
    'machine learning',
    'renewable energy',
    'education technology',
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch([String? value]) {
    final keyword = (value ?? _searchController.text).trim();
    if (keyword.isEmpty) return;
    _searchController.text = keyword;
    FocusScope.of(context).unfocus();
    context.read<SearchProvider>().search(keyword);
  }

  @override
  Widget build(BuildContext context) {
    final overview = context.select<SearchProvider, GlobalOverview?>(
      (provider) => provider.globalOverview,
    );
    final recentSearches = context.select<SearchProvider, List<String>>(
      (provider) => provider.recentSearches,
    );
    final filters = context.select<SearchProvider, ResearchFilters>(
      (provider) => provider.filters,
    );
    final hasSearched = context.select<SearchProvider, bool>(
      (provider) => provider.hasSearched,
    );
    final isGlobalLoading = context.select<SearchProvider, bool>(
      (provider) => provider.isGlobalLoading,
    );
    final globalError = context.select<SearchProvider, String?>(
      (provider) => provider.globalError,
    );
    final isSearchLoading = context.select<SearchProvider, bool>(
      (provider) => provider.isSearchLoading,
    );
    final searchError = context.select<SearchProvider, String?>(
      (provider) => provider.searchError,
    );
    final keyword = context.select<SearchProvider, String?>(
      (provider) => provider.keyword,
    );
    final publications = context.select<SearchProvider, List<PublicationModel>>(
      (provider) => provider.publications,
    );
    final countryOutputs = context.select<SearchProvider, List<CountryOutput>>(
      (provider) => provider.countryOutputs,
    );
    final searchStats = context.select<SearchProvider, DashboardStats>(
      (provider) => provider.searchDashboardStats,
    );

    final apiTopics =
        overview?.trendingKeywords
            .map((keyword) => keyword.displayName)
            .where((name) => name.trim().isNotEmpty)
            .take(12)
            .toList(growable: false) ??
        const <String>[];
    final suggestedTopics = apiTopics.isEmpty ? _fallbackTopics : apiTopics;

    return ScreenScroll(
      onRefresh: () => context.read<SearchProvider>().loadGlobalOverview(),
      children: [
        const ScreenHeader(
          title: 'Trang chủ nghiên cứu',
          subtitle: 'Tìm kiếm chủ đề và xem nhanh các chỉ số học thuật.',
          badge: 'OpenAlex',
        ),
        const SizedBox(height: AppSpacing.medium),
        ResearchSearchBar(
          controller: _searchController,
          onSubmitted: _submitSearch,
          onSearchPressed: () => _submitSearch(),
        ),
        const SizedBox(height: 12),
        _TopicChips(
          title: 'Tìm kiếm gần đây',
          icon: Icons.history,
          topics: recentSearches,
          onSelected: _submitSearch,
          emptyText: 'Chưa có lịch sử tìm kiếm',
        ),
        const SizedBox(height: 12),
        TopicDropdownCard(
          title: 'Chủ đề gợi ý',
          icon: Icons.local_fire_department_outlined,
          topics: suggestedTopics,
          onSelected: _submitSearch,
        ),
        const SizedBox(height: AppSpacing.medium),
        _YearFilterCard(
          filters: filters,
          onApply: (fromYear, toYear) =>
              context.read<SearchProvider>().updateFilters(
                ResearchFilters(fromYear: fromYear, toYear: toYear),
                rerunSearch: hasSearched,
              ),
          onReset: () => context.read<SearchProvider>().resetFilters(
            rerunSearch: hasSearched,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        _OverviewMetrics(
          overview: overview,
          isLoading: isGlobalLoading,
          error: globalError,
          searchStats: searchStats,
          hasSearched: hasSearched,
        ),
        if (hasSearched) ...[
          const SizedBox(height: AppSpacing.medium),
          _SearchStateCard(
            keyword: keyword,
            isLoading: isSearchLoading,
            error: searchError,
            stats: searchStats,
            loadedPublicationCount: context.select<SearchProvider, int>(
              (provider) => provider.publicationTotalCount > 0
                  ? provider.publicationTotalCount
                  : publications.length,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.medium),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.public,
                title: 'Số lượng bài báo theo quốc gia',
              ),
              const SizedBox(height: 14),
              MapChart(
                countries: hasSearched
                    ? countryOutputs
                    : overview?.countryOutputs ?? const [],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopicChips extends StatelessWidget {
  const _TopicChips({
    required this.title,
    required this.icon,
    required this.topics,
    required this.onSelected,
    this.emptyText,
  });

  final String title;
  final IconData icon;
  final List<String> topics;
  final ValueChanged<String> onSelected;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 10),
          if (topics.isEmpty)
            Text(
              emptyText ?? 'Chưa có dữ liệu',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final topic in topics.take(10))
                  ActionChip(
                    label: Text(topic),
                    onPressed: () => onSelected(topic),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _YearFilterCard extends StatefulWidget {
  const _YearFilterCard({
    required this.filters,
    required this.onApply,
    required this.onReset,
  });

  final ResearchFilters filters;
  final void Function(int? fromYear, int? toYear) onApply;
  final VoidCallback onReset;

  @override
  State<_YearFilterCard> createState() => _YearFilterCardState();
}

class _YearFilterCardState extends State<_YearFilterCard> {
  late final TextEditingController _fromYearController;
  late final TextEditingController _toYearController;

  @override
  void initState() {
    super.initState();
    _fromYearController = TextEditingController();
    _toYearController = TextEditingController();
    _syncFromFilters();
  }

  @override
  void didUpdateWidget(covariant _YearFilterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters != widget.filters) {
      _syncFromFilters();
    }
  }

  @override
  void dispose() {
    _fromYearController.dispose();
    _toYearController.dispose();
    super.dispose();
  }

  void _syncFromFilters() {
    _fromYearController.text = widget.filters.fromYear?.toString() ?? '';
    _toYearController.text = widget.filters.toYear?.toString() ?? '';
  }

  void _apply() {
    widget.onApply(
      int.tryParse(_fromYearController.text.trim()),
      int.tryParse(_toYearController.text.trim()),
    );
  }

  void _reset() {
    _fromYearController.clear();
    _toYearController.clear();
    widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      accentColor: AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: Icons.date_range, title: 'Lọc theo năm'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromYearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Từ năm'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _toYearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Đến năm'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Đặt lại'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _apply,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetrics extends StatelessWidget {
  const _OverviewMetrics({
    required this.overview,
    required this.isLoading,
    required this.error,
    required this.searchStats,
    required this.hasSearched,
  });

  final GlobalOverview? overview;
  final bool isLoading;
  final String? error;
  final DashboardStats searchStats;
  final bool hasSearched;

  @override
  Widget build(BuildContext context) {
    if (isLoading && overview == null) {
      return const SectionCard(
        child: SizedBox(
          height: 160,
          child: AppLoadingState(message: 'Đang tải tổng quan OpenAlex...'),
        ),
      );
    }

    if (overview == null) {
      return SectionCard(
        child: AppErrorState(
          message: error ?? 'Không thể tải tổng quan OpenAlex.',
          onRetry: () => context.read<SearchProvider>().loadGlobalOverview(),
        ),
      );
    }

    final loadedOverview = overview!;
    final cards = [
      _MetricCardData(
        formatCompactNumber(loadedOverview.totalWorks),
        'Công trình',
        Icons.article_outlined,
        AppColors.secondary,
      ),
      _MetricCardData(
        formatCompactNumber(loadedOverview.totalAuthors),
        'Tác giả',
        Icons.groups_outlined,
        AppColors.chartLine,
      ),
      _MetricCardData(
        formatCompactNumber(loadedOverview.totalSources),
        'Tạp chí',
        Icons.library_books_outlined,
        AppColors.accent,
      ),
      _MetricCardData(
        loadedOverview.peakYear == null ? 'N/A' : '${loadedOverview.peakYear}',
        'Năm cao điểm',
        Icons.calendar_month,
        AppColors.primaryLight,
      ),
    ];

    if (hasSearched) {
      cards.addAll([
        _MetricCardData(
          formatCompactNumber(searchStats.totalPublications),
          'Bài đã tải',
          Icons.manage_search,
          AppColors.secondary,
        ),
        _MetricCardData(
          formatCompactNumber(searchStats.totalCitations),
          'Trích dẫn',
          Icons.format_quote,
          AppColors.accent,
        ),
      ]);
    }

    return _MetricGrid(cards: cards);
  }
}

class _MetricCardData {
  const _MetricCardData(this.value, this.label, this.icon, this.color);

  final String value;
  final String label;
  final IconData icon;
  final Color color;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.cards});

  final List<_MetricCardData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 620
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return MetricCard(
              value: card.value,
              label: card.label,
              icon: card.icon,
              accentColor: card.color,
            );
          },
        );
      },
    );
  }
}

class _SearchStateCard extends StatelessWidget {
  const _SearchStateCard({
    required this.keyword,
    required this.isLoading,
    required this.error,
    required this.stats,
    required this.loadedPublicationCount,
  });

  final String? keyword;
  final bool isLoading;
  final String? error;
  final DashboardStats stats;
  final int loadedPublicationCount;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      accentColor: AppColors.chartLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            icon: Icons.analytics_outlined,
            title: keyword == null ? 'Kết quả tìm kiếm' : 'Kết quả: "$keyword"',
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const LinearProgressIndicator(minHeight: 5)
          else if (error != null)
            Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MetricPill(
                  label:
                      '${formatCompactNumber(loadedPublicationCount)} bài đã tải',
                  icon: Icons.cloud_done_outlined,
                  accentColor: AppColors.secondary,
                ),
                MetricPill(
                  label:
                      '${formatCompactNumber(stats.totalCitations)} trích dẫn',
                  icon: Icons.format_quote,
                  accentColor: AppColors.accent,
                ),
                MetricPill(
                  label: 'TB ${stats.averageCitations.toStringAsFixed(1)}',
                  icon: Icons.trending_up,
                  accentColor: AppColors.chartLine,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

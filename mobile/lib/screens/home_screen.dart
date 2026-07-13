import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_models.dart';
import '../models/global_overview.dart';
import '../models/publication_model.dart';
import '../providers/search_provider.dart';
import '../services/publication_analytics.dart';
import '../viewmodels/firebase_features_view_model.dart';
import '../widgets/app_widgets.dart';
import 'detail_screens.dart';

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
    unawaited(
      context.read<FirebaseFeaturesViewModel>().trackSearchTopic(keyword),
    );
    unawaited(context.read<SearchProvider>().search(keyword));
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
    final publicationTotalCount = context.select<SearchProvider, int>(
      (provider) => provider.publicationTotalCount,
    );
    final searchAverageCitations = context.select<SearchProvider, double>(
      (provider) => provider.searchAverageCitations,
    );
    final publicationTrend = context.select<SearchProvider, Map<String, int>>(
      (provider) => provider.publicationTrend,
    );
    final publications = context.select<SearchProvider, List<PublicationModel>>(
      (provider) => provider.publications,
    );
    final dashboardStats = context.select<SearchProvider, DashboardStats>(
      (provider) => provider.searchDashboardStats,
    );
    final mostInfluentialPublication = context
        .select<SearchProvider, PublicationModel?>(
          (provider) => provider.mostInfluentialPublication,
        );
    final countryOutputs = context.select<SearchProvider, List<CountryOutput>>(
      (provider) => provider.countryOutputs,
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
      key: const ValueKey('home_screen_content'),
      onRefresh: () {
        final provider = context.read<SearchProvider>();
        final currentKeyword = provider.keyword?.trim();
        if (provider.hasSearched &&
            currentKeyword != null &&
            currentKeyword.isNotEmpty) {
          return provider.search(currentKeyword);
        }
        return provider.loadGlobalOverview();
      },
      children: [
        const ScreenHeader(
          key: ValueKey('home_screen_header'),
          title: 'Trang chủ nghiên cứu',
          subtitle: 'Tìm kiếm chủ đề và xem nhanh các chỉ số học thuật.',
          badge: 'OpenAlex',
        ),
        const SizedBox(height: AppSpacing.medium),

        _CompactSearchAndFilterCard(
          key: const ValueKey('home_search_and_filter'),
          searchController: _searchController,
          onSubmitSearch: _submitSearch,
          filters: filters,
          hasSearched: hasSearched,
          recentSearches: recentSearches,
          suggestedTopics: suggestedTopics,
        ),

        const SizedBox(height: AppSpacing.small),

        _CompactOverviewMetrics(
          overview: overview,
          isLoading: isGlobalLoading,
          error: globalError,
        ),

        if (hasSearched) ...[
          const SizedBox(height: AppSpacing.medium),
          _SearchResultsDashboard(
            keyword: keyword,
            isLoading: isSearchLoading,
            error: searchError,
            publicationTotalCount: publicationTotalCount,
            searchAverageCitations: searchAverageCitations,
            publicationTrend: publicationTrend,
            dashboardStats: dashboardStats,
            mostInfluentialPublication: mostInfluentialPublication,
            publications: publications,
            onRetry: keyword == null || keyword.trim().isEmpty
                ? null
                : () => context.read<SearchProvider>().search(keyword),
            onOpenPublication: (publication) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      PublicationDetailScreen(publication: publication),
                ),
              );
            },
          ),
        ],

        const SizedBox(height: AppSpacing.medium),
        SectionCard(
          key: const ValueKey('home_country_output_section'),
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

class _CompactSearchAndFilterCard extends StatefulWidget {
  const _CompactSearchAndFilterCard({
    super.key,
    required this.searchController,
    required this.onSubmitSearch,
    required this.filters,
    required this.hasSearched,
    required this.recentSearches,
    required this.suggestedTopics,
  });

  final TextEditingController searchController;
  final void Function([String?]) onSubmitSearch;
  final ResearchFilters filters;
  final bool hasSearched;
  final List<String> recentSearches;
  final List<String> suggestedTopics;

  @override
  State<_CompactSearchAndFilterCard> createState() =>
      _CompactSearchAndFilterCardState();
}

class _CompactSearchAndFilterCardState
    extends State<_CompactSearchAndFilterCard> {
  late final TextEditingController _fromYearController;
  late final TextEditingController _toYearController;
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _fromYearController = TextEditingController();
    _toYearController = TextEditingController();
    _syncFromFilters();
  }

  @override
  void didUpdateWidget(covariant _CompactSearchAndFilterCard oldWidget) {
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

  Future<void> _applyFilter() async {
    FocusScope.of(context).unfocus();
    await context.read<SearchProvider>().updateFilters(
      ResearchFilters(
        fromYear: int.tryParse(_fromYearController.text.trim()),
        toYear: int.tryParse(_toYearController.text.trim()),
      ),
      rerunSearch: widget.hasSearched,
    );

    if (!widget.hasSearched &&
        mounted &&
        widget.searchController.text.trim().isNotEmpty) {
      widget.onSubmitSearch();
    }
  }

  void _resetFilter() {
    _fromYearController.clear();
    _toYearController.clear();
    FocusScope.of(context).unfocus();
    context.read<SearchProvider>().resetFilters(
      rerunSearch: widget.hasSearched,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(8),
      accentColor: AppColors.primary,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ResearchSearchBar(
                  key: const ValueKey('home_topic_search_field'),
                  controller: widget.searchController,
                  onSubmitted: widget.onSubmitSearch,
                  onSearchPressed: () => widget.onSubmitSearch(),
                  suggestions: widget.recentSearches,
                ),
              ),
              if (widget.suggestedTopics.isNotEmpty)
                PopupMenuButton<String>(
                  key: const ValueKey('home_suggested_topics_button'),
                  icon: const Icon(
                    Icons.local_fire_department_outlined,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Chủ đề gợi ý',
                  onSelected: (topic) {
                    widget.searchController.text = topic;
                    widget.onSubmitSearch(topic);
                  },
                  itemBuilder: (context) {
                    return widget.suggestedTopics.map((topic) {
                      return PopupMenuItem(value: topic, child: Text(topic));
                    }).toList();
                  },
                ),
              IconButton(
                key: const ValueKey('home_filter_toggle_button'),
                icon: Icon(
                  _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    _isFilterExpanded = !_isFilterExpanded;
                  });
                },
                tooltip: 'Bộ lọc',
              ),
            ],
          ),
          if (_isFilterExpanded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.date_range,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fromYearController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Từ năm',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _toYearController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Đến năm',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const ValueKey('home_filter_reset_button'),
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _resetFilter,
                  color: AppColors.error,
                  tooltip: 'Đặt lại',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const ValueKey('home_filter_apply_button'),
                  icon: const Icon(Icons.check, size: 20),
                  onPressed: _applyFilter,
                  color: AppColors.secondary,
                  tooltip: 'Áp dụng',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactOverviewMetrics extends StatelessWidget {
  const _CompactOverviewMetrics({
    required this.overview,
    required this.isLoading,
    required this.error,
  });

  final GlobalOverview? overview;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (isLoading && overview == null) {
      return const SectionCard(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          height: 40,
          child: AppLoadingState(message: 'Đang tải thống kê...'),
        ),
      );
    }

    if (overview == null) {
      return SectionCard(
        padding: const EdgeInsets.all(12),
        child: AppErrorState(
          message: error ?? 'Không thể tải thống kê.',
          onRetry: () => context.read<SearchProvider>().loadGlobalOverview(),
        ),
      );
    }

    final loadedOverview = overview!;

    return SectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.query_stats,
            title: 'Thống kê tổng quan OpenAlex',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MetricPill(
                label:
                    '${formatCompactNumber(loadedOverview.totalWorks)} Bài báo',
                icon: Icons.article_outlined,
                accentColor: AppColors.secondary,
              ),
              MetricPill(
                label:
                    '${formatCompactNumber(loadedOverview.totalAuthors)} Tác giả',
                icon: Icons.groups_outlined,
                accentColor: AppColors.chartLine,
              ),
              MetricPill(
                label:
                    '${formatCompactNumber(loadedOverview.totalSources)} Tạp chí',
                icon: Icons.library_books_outlined,
                accentColor: AppColors.accent,
              ),
              if (loadedOverview.peakYear != null)
                MetricPill(
                  label: 'Đỉnh: ${loadedOverview.peakYear}',
                  icon: Icons.calendar_month,
                  accentColor: AppColors.primaryLight,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchStateCard extends StatelessWidget {
  const _SearchStateCard({
    required this.keyword,
    required this.isLoading,
    required this.error,
    required this.publicationTotalCount,
    required this.searchCitationTotal,
  });

  final String? keyword;
  final bool isLoading;
  final String? error;
  final int publicationTotalCount;
  final int searchCitationTotal;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(12),
      accentColor: AppColors.chartLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            icon: Icons.analytics_outlined,
            title: keyword == null ? 'Kết quả tìm kiếm' : 'Kết quả: "$keyword"',
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const LinearProgressIndicator(minHeight: 3)
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
                      '${formatCompactNumber(publicationTotalCount)} kết quả',
                  icon: Icons.cloud_done_outlined,
                  accentColor: AppColors.secondary,
                ),
                MetricPill(
                  label:
                      '${formatCompactNumber(searchCitationTotal)} trích dẫn',
                  icon: Icons.format_quote,
                  accentColor: AppColors.accent,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SearchResultsDashboard extends StatelessWidget {
  const _SearchResultsDashboard({
    required this.keyword,
    required this.isLoading,
    required this.error,
    required this.publicationTotalCount,
    required this.searchAverageCitations,
    required this.publicationTrend,
    required this.dashboardStats,
    required this.mostInfluentialPublication,
    required this.publications,
    required this.onRetry,
    required this.onOpenPublication,
  });

  final String? keyword;
  final bool isLoading;
  final String? error;
  final int publicationTotalCount;
  final double searchAverageCitations;
  final Map<String, int> publicationTrend;
  final DashboardStats dashboardStats;
  final PublicationModel? mostInfluentialPublication;
  final List<PublicationModel> publications;
  final VoidCallback? onRetry;
  final ValueChanged<PublicationModel> onOpenPublication;

  @override
  Widget build(BuildContext context) {
    final influential =
        mostInfluentialPublication ?? dashboardStats.mostCitedPublication;

    if (isLoading && publications.isEmpty) {
      return const SectionCard(
        key: ValueKey('home_search_loading_card'),
        child: SizedBox(
          height: 180,
          child: AppLoadingState(message: 'Đang phân tích chủ đề...'),
        ),
      );
    }

    if (error != null && publications.isEmpty) {
      return SectionCard(
        key: const ValueKey('home_search_error_card'),
        child: AppErrorState(message: error!, onRetry: onRetry),
      );
    }

    return Column(
      key: const ValueKey('home_search_results_dashboard'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchStateCard(
          keyword: keyword,
          isLoading: isLoading,
          error: error,
          publicationTotalCount: publicationTotalCount,
          searchCitationTotal: dashboardStats.totalCitations,
        ),
        const SizedBox(height: AppSpacing.medium),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final metrics = _DashboardMetricsCard(
              dashboardStats: dashboardStats,
              publicationTotalCount: publicationTotalCount,
              averageCitations: searchAverageCitations,
            );
            final trend = _TrendCard(publicationTrend: publicationTrend);
            if (!wide) {
              return Column(
                children: [
                  metrics,
                  const SizedBox(height: AppSpacing.medium),
                  trend,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: metrics),
                const SizedBox(width: AppSpacing.medium),
                Expanded(child: trend),
              ],
            );
          },
        ),
        if (influential != null) ...[
          const SizedBox(height: AppSpacing.medium),
          SectionCard(
            key: const ValueKey('home_most_influential_publication'),
            accentColor: AppColors.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Bài báo ảnh hưởng nhất',
                ),
                const SizedBox(height: 14),
                PaperCard(
                  publication: influential,
                  onTap: () => onOpenPublication(influential),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.medium),
        SectionCard(
          key: const ValueKey('home_publication_results'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.article_outlined,
                title: 'Bài báo phù hợp',
              ),
              const SizedBox(height: 14),
              if (publications.isEmpty)
                const AppEmptyState(
                  icon: Icons.article_outlined,
                  title: 'Chưa có bài báo',
                  message: 'Thử một chủ đề khác hoặc nới khoảng năm lọc.',
                )
              else
                for (final publication in publications.take(8)) ...[
                  PaperCard(
                    publication: publication,
                    onTap: () => onOpenPublication(publication),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardMetricsCard extends StatelessWidget {
  const _DashboardMetricsCard({
    required this.dashboardStats,
    required this.publicationTotalCount,
    required this.averageCitations,
  });

  final DashboardStats dashboardStats;
  final int publicationTotalCount;
  final double averageCitations;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('home_dashboard_metrics'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.speed_outlined,
            title: 'Chỉ số dashboard',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MetricPill(
                label: '${formatCompactNumber(publicationTotalCount)} kết quả',
                icon: Icons.cloud_done_outlined,
                accentColor: AppColors.secondary,
              ),
              MetricPill(
                label: '${averageCitations.toStringAsFixed(1)} trích dẫn/bài',
                icon: Icons.calculate_outlined,
                accentColor: AppColors.chartLine,
              ),
              MetricPill(
                label: '${dashboardStats.uniqueAuthors} tác giả',
                icon: Icons.groups_outlined,
                accentColor: AppColors.accent,
              ),
              MetricPill(
                label: '${dashboardStats.uniqueJournals} tạp chí',
                icon: Icons.library_books_outlined,
                accentColor: AppColors.primaryLight,
              ),
              if (dashboardStats.topYear != null)
                MetricPill(
                  label:
                      'Năm nổi bật: ${dashboardStats.topYear} (${dashboardStats.topYearCount})',
                  icon: Icons.calendar_month,
                ),
            ],
          ),
          if (dashboardStats.topAuthor != null) ...[
            const SizedBox(height: 12),
            HighlightTile(
              icon: Icons.person_outline,
              text:
                  'Tác giả xuất hiện nhiều nhất: ${dashboardStats.topAuthor} (${dashboardStats.topAuthorCount} bài).',
            ),
          ],
          if (dashboardStats.topJournal != null)
            HighlightTile(
              icon: Icons.menu_book_outlined,
              text:
                  'Tạp chí xuất hiện nhiều nhất: ${dashboardStats.topJournal} (${dashboardStats.topJournalCount} bài).',
            ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.publicationTrend});

  final Map<String, int> publicationTrend;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('home_publication_trend_chart'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.show_chart,
            title: 'Xu hướng công bố theo năm',
          ),
          const SizedBox(height: 14),
          SizedBox(height: 220, child: LineChart(series: publicationTrend)),
        ],
      ),
    );
  }
}

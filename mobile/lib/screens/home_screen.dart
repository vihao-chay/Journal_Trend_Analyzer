import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_models.dart';
import '../models/author_model.dart';
import '../models/global_overview.dart';
import '../models/journal_model.dart';
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
    final topAuthors = context.select<SearchProvider, List<AuthorModel>>(
      (provider) => provider.topAuthors,
    );
    final topJournals = context.select<SearchProvider, List<JournalModel>>(
      (provider) => provider.topJournals,
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
            topAuthors: topAuthors,
            topJournals: topJournals,
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

class _SearchStateCard extends StatelessWidget {
  const _SearchStateCard({
    required this.keyword,
    required this.isLoading,
    required this.error,
    required this.publicationTotalCount,
    required this.searchAverageCitations,
    required this.searchCitationTotal,
    required this.publicationTrend,
    required this.dashboardStats,
    required this.topAuthors,
    required this.topJournals,
  });

  final String? keyword;
  final bool isLoading;
  final String? error;
  final int publicationTotalCount;
  final double searchAverageCitations;
  final int searchCitationTotal;
  final Map<String, int> publicationTrend;
  final DashboardStats dashboardStats;
  final List<AuthorModel> topAuthors;
  final List<JournalModel> topJournals;

  @override
  Widget build(BuildContext context) {
    final averageCitations = searchAverageCitations > 0
        ? searchAverageCitations
        : dashboardStats.averageCitations;
    final peakYear =
        _peakYearFromTrend(publicationTrend) ??
        (dashboardStats.topYear == null
            ? null
            : _YearMetric(
                dashboardStats.topYear!,
                dashboardStats.topYearCount,
              ));
    final topAuthor = topAuthors.isNotEmpty ? topAuthors.first : null;
    final topJournal = topJournals.isNotEmpty ? topJournals.first : null;
    final topAuthorName = topAuthor?.displayName ?? dashboardStats.topAuthor;
    final topAuthorCount =
        topAuthor?.worksCount ?? dashboardStats.topAuthorCount;
    final topJournalName = topJournal?.displayName ?? dashboardStats.topJournal;
    final topJournalCount =
        topJournal?.worksCount ?? dashboardStats.topJournalCount;

    return SectionCard(
      key: const ValueKey('home_topic_overview_dashboard'),
      padding: const EdgeInsets.all(12),
      accentColor: AppColors.chartLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            icon: Icons.analytics_outlined,
            title: keyword == null
                ? 'Tổng quan chủ đề'
                : 'Tổng quan chủ đề: "$keyword"',
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
                      '${formatCompactNumber(publicationTotalCount)} bài báo',
                  icon: Icons.cloud_done_outlined,
                  accentColor: AppColors.secondary,
                ),
                MetricPill(
                  label:
                      '${formatCompactNumber(searchCitationTotal)} trích dẫn',
                  icon: Icons.format_quote,
                  accentColor: AppColors.accent,
                ),
                MetricPill(
                  label: '${averageCitations.toStringAsFixed(1)} trích dẫn/bài',
                  icon: Icons.calculate_outlined,
                  accentColor: AppColors.chartLine,
                ),
              ],
            ),
          if (!isLoading && error == null) ...[
            if (peakYear != null) ...[
              const SizedBox(height: 12),
              HighlightTile(
                icon: Icons.calendar_month_outlined,
                text:
                    'Năm hoạt động mạnh nhất: ${peakYear.year} (${formatCompactNumber(peakYear.count)} bài).',
              ),
            ],
            if (topAuthorName != null && topAuthorName.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              HighlightTile(
                icon: Icons.person_outline,
                text:
                    'Tác giả đóng góp nhiều nhất: $topAuthorName (${formatCompactNumber(topAuthorCount)} bài).',
              ),
            ],
            if (topJournalName != null && topJournalName.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              HighlightTile(
                icon: Icons.menu_book_outlined,
                text:
                    'Tạp chí nổi bật nhất: $topJournalName (${formatCompactNumber(topJournalCount)} bài).',
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _YearMetric {
  const _YearMetric(this.year, this.count);

  final int year;
  final int count;
}

_YearMetric? _peakYearFromTrend(Map<String, int> publicationTrend) {
  _YearMetric? peak;
  for (final entry in publicationTrend.entries) {
    final year = int.tryParse(entry.key);
    if (year == null) {
      continue;
    }
    if (peak == null || entry.value > peak.count) {
      peak = _YearMetric(year, entry.value);
    }
  }
  return peak;
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
    required this.topAuthors,
    required this.topJournals,
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
  final List<AuthorModel> topAuthors;
  final List<JournalModel> topJournals;
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
          searchAverageCitations: searchAverageCitations,
          searchCitationTotal: dashboardStats.totalCitations,
          publicationTrend: publicationTrend,
          dashboardStats: dashboardStats,
          topAuthors: topAuthors,
          topJournals: topJournals,
        ),
        const SizedBox(height: AppSpacing.medium),
        _TrendCard(publicationTrend: publicationTrend),
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

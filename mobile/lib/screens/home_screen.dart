import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_models.dart';
import '../models/global_overview.dart';
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
    final publicationTotalCount = context.select<SearchProvider, int>(
      (provider) => provider.publicationTotalCount,
    );
    final searchCitationTotal = context.select<SearchProvider, int>(
      (provider) => provider.searchCitationTotal,
    );
    final searchAverageCitations = context.select<SearchProvider, double>(
      (provider) => provider.searchAverageCitations,
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
      onRefresh: () => context.read<SearchProvider>().loadGlobalOverview(),
      children: [
        const ScreenHeader(
          title: 'Trang chủ nghiên cứu',
          subtitle: 'Tìm kiếm chủ đề và xem nhanh các chỉ số học thuật.',
          badge: 'OpenAlex',
        ),
        const SizedBox(height: AppSpacing.medium),
        
        // Cùng một ô cho Search và Filter
        _CompactSearchAndFilterCard(
          searchController: _searchController,
          onSubmitSearch: _submitSearch,
          filters: filters,
          hasSearched: hasSearched,
          recentSearches: recentSearches,
          suggestedTopics: suggestedTopics,
        ),
        
        const SizedBox(height: AppSpacing.small),
        
        // Phần thống kê thu nhỏ
        _CompactOverviewMetrics(
          overview: overview,
          isLoading: isGlobalLoading,
          error: globalError,
          hasSearched: hasSearched,
          publicationTotalCount: publicationTotalCount,
          searchCitationTotal: searchCitationTotal,
        ),
        
        if (hasSearched) ...[
          const SizedBox(height: AppSpacing.small),
          _SearchStateCard(
            keyword: keyword,
            isLoading: isSearchLoading,
            error: searchError,
            publicationTotalCount: publicationTotalCount,
            searchCitationTotal: searchCitationTotal,
            searchAverageCitations: searchAverageCitations,
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

class _CompactSearchAndFilterCard extends StatefulWidget {
  const _CompactSearchAndFilterCard({
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
  State<_CompactSearchAndFilterCard> createState() => _CompactSearchAndFilterCardState();
}

class _CompactSearchAndFilterCardState extends State<_CompactSearchAndFilterCard> {
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

  void _applyFilter() {
    FocusScope.of(context).unfocus();
    context.read<SearchProvider>().updateFilters(
      ResearchFilters(
        fromYear: int.tryParse(_fromYearController.text.trim()),
        toYear: int.tryParse(_toYearController.text.trim()),
      ),
      rerunSearch: widget.hasSearched,
    );
    if (widget.searchController.text.trim().isNotEmpty) {
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
                  controller: widget.searchController,
                  onSubmitted: widget.onSubmitSearch,
                  onSearchPressed: () => widget.onSubmitSearch(),
                  suggestions: widget.recentSearches,
                ),
              ),
              if (widget.suggestedTopics.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.local_fire_department_outlined, color: AppColors.primary),
                  tooltip: 'Chủ đề gợi ý',
                  onSelected: (topic) {
                    widget.searchController.text = topic;
                    widget.onSubmitSearch(topic);
                  },
                  itemBuilder: (context) {
                    return widget.suggestedTopics.map((topic) {
                      return PopupMenuItem(
                        value: topic,
                        child: Text(topic),
                      );
                    }).toList();
                  },
                ),
              IconButton(
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
                const Icon(Icons.date_range, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fromYearController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Từ năm',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _resetFilter,
                  color: AppColors.error,
                  tooltip: 'Đặt lại',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check, size: 20),
                  onPressed: _applyFilter,
                  color: AppColors.secondary,
                  tooltip: 'Áp dụng',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ]
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
    required this.hasSearched,
    required this.publicationTotalCount,
    required this.searchCitationTotal,
  });

  final GlobalOverview? overview;
  final bool isLoading;
  final String? error;
  final bool hasSearched;
  final int publicationTotalCount;
  final int searchCitationTotal;

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
                label: '${formatCompactNumber(loadedOverview.totalWorks)} Bài báo',
                icon: Icons.article_outlined,
                accentColor: AppColors.secondary,
              ),
              MetricPill(
                label: '${formatCompactNumber(loadedOverview.totalAuthors)} Tác giả',
                icon: Icons.groups_outlined,
                accentColor: AppColors.chartLine,
              ),
              MetricPill(
                label: '${formatCompactNumber(loadedOverview.totalSources)} Tạp chí',
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
    required this.searchAverageCitations,
  });

  final String? keyword;
  final bool isLoading;
  final String? error;
  final int publicationTotalCount;
  final int searchCitationTotal;
  final double searchAverageCitations;

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

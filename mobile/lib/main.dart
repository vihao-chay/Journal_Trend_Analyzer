import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'models/author_model.dart';
import 'models/journal_model.dart';
import 'providers/search_provider.dart';
import 'screens/search_screen.dart';
import 'services/publication_analytics.dart';
import 'widgets/app_widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.searchProvider});

  final SearchProvider? searchProvider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => searchProvider ?? SearchProvider(),
      child: MaterialApp(
        title: 'Journal Trend Analyzer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const JournalShell(),
      ),
    );
  }
}

class JournalStat {
  const JournalStat(this.name, this.value, this.score);

  final String name;
  final int value;
  final double score;
}

class TrendPoint {
  const TrendPoint(this.year, this.publications);

  final int year;
  final int publications;
}

List<TrendPoint> trendPointsFromMap(Map<String, int> trend) {
  return trend.entries
      .map((entry) {
        final year = int.tryParse(entry.key);
        if (year == null) {
          return null;
        }
        return TrendPoint(year, entry.value);
      })
      .whereType<TrendPoint>()
      .toList(growable: false);
}

List<JournalStat> journalStatsFromModels(List<JournalModel> journals) {
  if (journals.isEmpty) {
    return const [];
  }

  final maxValue = journals
      .map((journal) => journal.worksCount)
      .reduce(math.max);

  return journals
      .map(
        (journal) => JournalStat(
          journal.displayName,
          journal.worksCount,
          maxValue == 0 ? 0 : journal.worksCount / maxValue,
        ),
      )
      .toList(growable: false);
}

List<JournalStat> journalStatsFromAuthors(List<AuthorModel> authors) {
  if (authors.isEmpty) {
    return const [];
  }

  final maxValue = authors.map((author) => author.worksCount).reduce(math.max);

  return authors
      .map(
        (author) => JournalStat(
          author.displayName,
          author.worksCount,
          maxValue == 0 ? 0 : author.worksCount / maxValue,
        ),
      )
      .toList(growable: false);
}

class JournalShell extends StatefulWidget {
  const JournalShell({super.key});

  @override
  State<JournalShell> createState() => _JournalShellState();
}

class _JournalShellState extends State<JournalShell> {
  int _selectedIndex = 0;

  static const _pages = [SearchScreen(), DashboardScreen(), TrendsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.show_chart_outlined),
                selectedIcon: Icon(Icons.show_chart),
                label: 'Trends',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _statColors = [
    AppColors.secondary,
    AppColors.chartLine,
    AppColors.accent,
    AppColors.primary,
  ];

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<SearchProvider, bool>(
      (provider) => provider.isGlobalLoading,
    );
    final overview = context.select<SearchProvider, dynamic>(
      (provider) => provider.globalOverview,
    );
    final error = context.select<SearchProvider, String?>(
      (provider) => provider.globalError,
    );
    final hasSearched = context.select<SearchProvider, bool>(
      (provider) => provider.hasSearched,
    );
    final keyword = context.select<SearchProvider, String?>(
      (provider) => provider.keyword,
    );
    final searchSnapshot = context.select<SearchProvider, DashboardStats>(
      (provider) => provider.searchDashboardStats,
    );

    if (isLoading && overview == null) {
      return const AppLoadingState(message: 'Loading OpenAlex statistics...');
    }

    if (overview == null) {
      return AppErrorState(
        message: error ?? 'Unable to load OpenAlex statistics.',
        onRetry: () =>
            context.read<SearchProvider>().loadGlobalOverview(),
      );
    }

    final gridStats = [
      (formatCompactNumber(overview.totalWorks), 'Works', Icons.article_outlined),
      (
        formatCompactNumber(overview.totalAuthors),
        'Authors',
        Icons.groups_outlined,
      ),
      (
        formatCompactNumber(overview.totalSources),
        'Journals',
        Icons.library_books_outlined,
      ),
      (
        overview.mostCitedWork == null
            ? '—'
            : formatCompactNumber(overview.mostCitedWork!.citedByCount),
        'Top Citations',
        Icons.format_quote,
      ),
    ];

    final highlights = <(IconData, String)>[
      if (overview.peakYear != null)
        (
          Icons.calendar_month,
          'Peak publication year: ${overview.peakYear} (${formatCompactNumber(overview.peakYearCount)} works)',
        ),
      if (overview.mostCitedWork != null)
        (Icons.star, 'Most cited: ${overview.mostCitedWork!.title}'),
      if (overview.topJournals.isNotEmpty)
        (
          Icons.library_books,
          'Leading journal: ${overview.topJournals.first.displayName}',
        ),
      if (overview.topAuthors.isNotEmpty)
        (
          Icons.person,
          'Leading author: ${overview.topAuthors.first.displayName}',
        ),
    ];

    final journalMomentum = journalStatsFromModels(
      overview.topJournals.take(5).toList(growable: false),
    );

    return ScreenScroll(
      onRefresh: () => context.read<SearchProvider>().loadGlobalOverview(),
      children: [
        const ScreenHeader(
          title: 'Research Dashboard',
          subtitle: 'Global statistics from the full OpenAlex catalog.',
          badge: 'OpenAlex',
        ),
        const SizedBox(height: AppSpacing.medium),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: gridStats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final stat = gridStats[index];
            return StatCard(
              value: stat.$1,
              label: stat.$2,
              icon: stat.$3,
              accentColor: _statColors[index % _statColors.length],
            );
          },
        ),
        const SizedBox(height: AppSpacing.medium),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.insights,
                title: 'Global Highlights',
              ),
              const SizedBox(height: 14),
              for (final highlight in highlights)
                HighlightTile(icon: highlight.$1, text: highlight.$2),
            ],
          ),
        ),
        if (journalMomentum.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.medium),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  icon: Icons.bar_chart,
                  title: 'Top Journal Contributions',
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < journalMomentum.length; i++)
                  RankedBarRow(
                    rank: i + 1,
                    name: journalMomentum[i].name,
                    value: journalMomentum[i].value,
                    score: journalMomentum[i].score,
                    valueLabel: '${formatCompactNumber(journalMomentum[i].value)} works',
                  ),
              ],
            ),
          ),
        ],
        if (hasSearched) ...[
          const SizedBox(height: AppSpacing.medium),
          _SearchSnapshotCard(keyword: keyword, stats: searchSnapshot),
        ],
      ],
    );
  }
}

class _SearchSnapshotCard extends StatelessWidget {
  const _SearchSnapshotCard({required this.keyword, required this.stats});

  final String? keyword;
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      accentColor: AppColors.chartLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            icon: Icons.search,
            title: keyword == null ? 'Latest Search' : 'Search: "$keyword"',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MetricPill(
                label: '${formatCompactNumber(stats.totalPublications)} papers',
                icon: Icons.article_outlined,
              ),
              MetricPill(
                label: '${formatCompactNumber(stats.totalCitations)} citations',
                icon: Icons.format_quote,
                accentColor: AppColors.accent,
              ),
              MetricPill(
                label: 'avg ${stats.averageCitations.toStringAsFixed(1)}',
                icon: Icons.analytics_outlined,
                accentColor: AppColors.chartLine,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  static const int _maxYearsDisplayed = 40;

  @override
  Widget build(BuildContext context) {
    final hasSearched = context.select<SearchProvider, bool>(
      (provider) => provider.hasSearched,
    );
    final isSearchLoading = context.select<SearchProvider, bool>(
      (provider) => provider.isSearchLoading,
    );
    final isGlobalLoading = context.select<SearchProvider, bool>(
      (provider) => provider.isGlobalLoading,
    );
    final searchTrend = context.select<SearchProvider, Map<String, int>>(
      (provider) => provider.publicationTrend,
    );
    final searchJournals = context.select<SearchProvider, List<JournalModel>>(
      (provider) => provider.topJournals,
    );
    final searchAuthors = context.select<SearchProvider, List<AuthorModel>>(
      (provider) => provider.topAuthors,
    );
    final globalOverview = context.select<SearchProvider, dynamic>(
      (provider) => provider.globalOverview,
    );
    final keyword = context.select<SearchProvider, String?>(
      (provider) => provider.keyword,
    );
    final searchError = context.select<SearchProvider, String?>(
      (provider) => provider.searchError,
    );
    final globalError = context.select<SearchProvider, String?>(
      (provider) => provider.globalError,
    );

    final usingSearchData = hasSearched && !isSearchLoading;
    final trendSource = usingSearchData
        ? searchTrend
        : (globalOverview?.publicationTrend ?? const {});
    final journalSource = usingSearchData
        ? searchJournals
        : (globalOverview?.topJournals ?? const []);
    final authorSource = usingSearchData
        ? searchAuthors
        : (globalOverview?.topAuthors ?? const []);

    final trendPoints = trendPointsFromMap(trendSource);
    // The OpenAlex global trend spans centuries (e.g. 1400–2028), which makes
    // recent years unreadable on mobile. Default to a recent sliding window.
    final displayedPoints = trendPoints.length > _maxYearsDisplayed
        ? trendPoints.sublist(trendPoints.length - _maxYearsDisplayed)
        : trendPoints;
    final topJournals = journalStatsFromModels(journalSource);
    final topAuthors = journalStatsFromAuthors(authorSource);
    final yearRange = _yearRangeLabel(displayedPoints);
    final isLoading = usingSearchData
        ? isSearchLoading
        : isGlobalLoading;
    final error = usingSearchData
        ? searchError
        : globalError;

    if (isLoading && displayedPoints.isEmpty) {
      return const AppLoadingState(message: 'Loading trend data...');
    }

    if (error != null && displayedPoints.isEmpty) {
      return AppErrorState(
        message: error,
        onRetry: usingSearchData
            ? null
            : () => context.read<SearchProvider>().loadGlobalOverview(),
      );
    }

    return ScreenScroll(
      onRefresh: () => context.read<SearchProvider>().loadGlobalOverview(),
      children: [
        ScreenHeader(
          title: 'Publication Trend Analysis',
          subtitle: usingSearchData && keyword != null
              ? 'Trends for "$keyword" from OpenAlex.'
              : 'Global publication trends from the full OpenAlex catalog.',
          badge: usingSearchData ? 'Filtered' : 'Global',
        ),
        const SizedBox(height: AppSpacing.medium),
        SectionCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          accentColor: AppColors.chartLine,
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Publications per Year',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  MetricPill(label: yearRange, accentColor: AppColors.chartLine),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                width: double.infinity,
                child: displayedPoints.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.show_chart,
                        title: 'No trend data',
                        message: 'Yearly publication data is not available.',
                      )
                    : PublicationLineChart(points: displayedPoints),
              ),
            ],
          ),
        ),
        if (topJournals.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.medium),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  icon: Icons.library_books,
                  title: 'Top Research Journals',
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < topJournals.take(5).length; i++)
                  RankedBarRow(
                    rank: i + 1,
                    name: topJournals[i].name,
                    value: topJournals[i].value,
                    score: topJournals[i].score,
                    valueLabel: '${formatCompactNumber(topJournals[i].value)} works',
                  ),
              ],
            ),
          ),
        ],
        if (topAuthors.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.medium),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  icon: Icons.person_outline,
                  title: 'Top Authors',
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < topAuthors.take(5).length; i++)
                  RankedBarRow(
                    rank: i + 1,
                    name: topAuthors[i].name,
                    value: topAuthors[i].value,
                    score: topAuthors[i].score,
                    valueLabel: '${formatCompactNumber(topAuthors[i].value)} works',
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

String _yearRangeLabel(List<TrendPoint> points) {
  if (points.isEmpty) {
    return 'No data';
  }
  return '${points.first.year}–${points.last.year}';
}

class PublicationLineChart extends StatelessWidget {
  const PublicationLineChart({super.key, required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PublicationLinePainter(points),
      child: const SizedBox.expand(),
    );
  }
}

class PublicationLinePainter extends CustomPainter {
  PublicationLinePainter(this.points);

  final List<TrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    const left = 8.0;
    const right = 8.0;
    const top = 10.0;
    const bottom = 28.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final maxValue = points.map((point) => point.publications).reduce(math.max);
    final minValue = points.map((point) => point.publications).reduce(math.min);
    final valueRange = math.max(1, maxValue - minValue);

    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.55)
      ..strokeWidth = 1;

    for (var index = 0; index < 4; index++) {
      final y = top + chartHeight * index / 3;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    final offsets = <Offset>[];
    final pointCount = points.length;
    final xDivisor = pointCount > 1 ? pointCount - 1 : 1;
    for (var index = 0; index < pointCount; index++) {
      final x = left + chartWidth * index / xDivisor;
      final normalized = (points[index].publications - minValue) / valueRange;
      final y = top + chartHeight - (normalized * chartHeight * 0.86 + 8);
      offsets.add(Offset(x, y));
    }

    final areaPath = Path()
      ..moveTo(offsets.first.dx, size.height - bottom)
      ..lineTo(offsets.first.dx, offsets.first.dy);

    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var index = 1; index < offsets.length; index++) {
      final previous = offsets[index - 1];
      final current = offsets[index];
      final controlX = previous.dx + (current.dx - previous.dx) / 2;
      linePath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
      areaPath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }
    areaPath
      ..lineTo(offsets.last.dx, size.height - bottom)
      ..close();

    final areaPaint = Paint()
      ..shader = AppColors.chartGradient.createShader(
        Rect.fromLTWH(left, top, chartWidth, chartHeight),
      );
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = AppColors.chartLine
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final pointPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    final pointBorderPaint = Paint()
      ..color = AppColors.chartLine
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final offset in offsets) {
      canvas
        ..drawCircle(offset, 4.2, pointPaint)
        ..drawCircle(offset, 4.2, pointBorderPaint);
    }

    if (pointCount == 1) {
      _drawLabel(
        canvas,
        points.first.year.toString(),
        Offset(offsets.first.dx, size.height - 17),
        maxWidth: size.width,
        alignCenter: true,
      );
      return;
    }

    final labelStep = math.max(1, pointCount ~/ 4);
    for (var index = 0; index < pointCount; index += labelStep) {
      final point = points[index];
      final x = left + chartWidth * index / xDivisor;
      _drawLabel(
        canvas,
        point.year.toString(),
        Offset(x, size.height - 17),
        maxWidth: size.width,
        alignCenter: true,
      );
    }
    if ((pointCount - 1) % labelStep != 0) {
      final lastPoint = points.last;
      final x = left + chartWidth;
      _drawLabel(
        canvas,
        lastPoint.year.toString(),
        Offset(x, size.height - 17),
        maxWidth: size.width,
        alignCenter: true,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset origin, {
    required double maxWidth,
    bool alignCenter = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rawDx = alignCenter ? origin.dx - painter.width / 2 : origin.dx;
    const padding = 2.0;
    final minDx = padding;
    final maxDx = (maxWidth - painter.width - padding).clamp(minDx, maxWidth);
    final dx = rawDx.clamp(minDx, maxDx);
    painter.paint(canvas, Offset(dx, origin.dy));
  }

  @override
  bool shouldRepaint(covariant PublicationLinePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

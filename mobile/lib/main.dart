import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journal Trend Analyzer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const JournalShell(),
    );
  }
}

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1A365D);
  static const secondary = Color(0xFF2B6CB0);
  static const accent = Color(0xFFDD6B20);
  static const chartLine = Color(0xFF319795);
  static const background = Color(0xFFF7FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
  static const border = Color(0xFFE2E8F0);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: Color(0xFFE53E3E),
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        titleSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        labelLarge: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: AppColors.surface,
        elevation: 0,
        indicatorColor: AppColors.secondary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.secondary : AppColors.textPrimary,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.secondary : AppColors.textPrimary,
            size: 21,
          );
        }),
      ),
    );
  }
}

class Article {
  const Article({
    required this.type,
    required this.topic,
    required this.year,
    required this.title,
    required this.authors,
    required this.citations,
    required this.abstractText,
    required this.keywords,
    required this.doi,
  });

  final String type;
  final String topic;
  final String year;
  final String title;
  final String authors;
  final int citations;
  final String abstractText;
  final List<String> keywords;
  final String doi;
}

class JournalStat {
  const JournalStat(this.name, this.citations, this.score);

  final String name;
  final int citations;
  final double score;
}

class TrendPoint {
  const TrendPoint(this.year, this.publications);

  final int year;
  final int publications;
}

const featuredArticle = Article(
  type: 'ARTICLE',
  topic: 'Human-Interaction',
  year: '2022',
  title:
      'Neural Substrates of Cognitive Flexibility in Complex Decision-Making Environments',
  authors: 'Dr. Lily Chen, Dr. Robert Johnson, +9 authors',
  citations: 342,
  doi: 'https://doi.org/10.1016/j.neuro.2022.08.014',
  keywords: [
    'Cognitive Flexibility',
    'fMRI',
    'Executive Function',
    'Decision-Making',
    'Computational Modeling',
  ],
  abstractText:
      'Cognitive flexibility, the ability to adaptively switch thinking or behavior in response to changing environmental demands, is a hallmark of higher-order executive function. This study investigates the underlying neural substrates supporting cognitive flexibility within complex multi-dimensional decision-making tasks. Utilizing functional magnetic resonance imaging (fMRI) combined with computational modeling, we analyzed the blood-oxygen-level-dependent (BOLD) signals of 68 healthy adult participants as they navigated a novel dynamically shifting problem-solving paradigm.\n\n'
      'Our findings reveal a distributed network involving the lateral dorsolateral prefrontal cortex (dlPFC), and the anterior insula, which dynamically coordinate to resolve conflicts and update action-value representations. Furthermore, effective connectivity analyses suggest a hierarchical flow of information where the ACC signals the need for behavioral adjustment, while the dlPFC implements adaptive control. In line with reinforcement learning models, the resultant network demonstrates nuanced neural underpinnings for the human brain\'s capacity to maintain adaptive and goal-directed performance in complex environments.',
);

const trendPoints = [
  TrendPoint(2016, 38),
  TrendPoint(2017, 55),
  TrendPoint(2018, 76),
  TrendPoint(2019, 90),
  TrendPoint(2020, 104),
  TrendPoint(2021, 131),
  TrendPoint(2022, 156),
  TrendPoint(2023, 184),
  TrendPoint(2024, 196),
];

const topJournals = [
  JournalStat('Journal of Artificial Intelligence Research', 12450, 1.00),
  JournalStat('IEEE Transactions on Pattern Analysis', 9800, 0.79),
  JournalStat('Conference on Neural Information Processing', 8750, 0.70),
  JournalStat('International Conference on Machine Learning', 6540, 0.53),
  JournalStat('Human Machine Intelligence', 4900, 0.39),
];

const searchResults = [
  Article(
    type: 'ARTICLE',
    topic: 'Human-Interaction',
    year: '2022',
    title:
        'Neural Substrates of Cognitive Flexibility in Complex Decision-Making Environments',
    authors: 'Dr. Lily Chen, Dr. Robert Johnson',
    citations: 342,
    doi: 'https://doi.org/10.1016/j.neuro.2022.08.014',
    keywords: ['Cognitive Flexibility', 'fMRI'],
    abstractText: '',
  ),
  Article(
    type: 'REVIEW',
    topic: 'Artificial Intelligence',
    year: '2024',
    title: 'Publication Trend Analysis for Generative AI Research',
    authors: 'Prof. Anika Patel, Dr. Marco Silva',
    citations: 288,
    doi: 'https://doi.org/10.1145/ai-trends.2024',
    keywords: ['Generative AI', 'Bibliometrics'],
    abstractText: '',
  ),
  Article(
    type: 'ARTICLE',
    topic: 'Data Mining',
    year: '2023',
    title: 'Topic Evolution in Machine Learning Journals from 2016 to 2024',
    authors: 'Dr. Samuel Park, Dr. Grace Rivera',
    citations: 219,
    doi: 'https://doi.org/10.1109/mltopics.2023',
    keywords: ['Topic Modeling', 'Machine Learning'],
    abstractText: '',
  ),
];

class JournalShell extends StatefulWidget {
  const JournalShell({super.key});

  @override
  State<JournalShell> createState() => _JournalShellState();
}

class _JournalShellState extends State<JournalShell> {
  int _selectedIndex = 3;

  static const _pages = [
    SearchScreen(),
    DashboardScreen(),
    TrendsScreen(),
    DetailScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDetail = _selectedIndex == 3;

    return Scaffold(
      appBar: JournalAppBar(
        showBack: isDetail,
        onBack: isDetail ? () => setState(() => _selectedIndex = 2) : null,
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
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
              icon: Icon(Icons.trending_up),
              label: 'Trends',
            ),
            NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article),
              label: 'Details',
            ),
          ],
        ),
      ),
    );
  }
}

class JournalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const JournalAppBar({super.key, required this.showBack, this.onBack});

  final bool showBack;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: showBack ? 42 : 14,
      leading: showBack
          ? IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back, size: 22),
              onPressed: onBack,
            )
          : null,
      titleSpacing: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!showBack)
            const Icon(Icons.auto_stories, size: 18, color: AppColors.primary),
          if (!showBack) const SizedBox(width: 6),
          const Flexible(
            child: Text(
              'Journal Trend Analyzer',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: ProfileAvatar(showPhotoAccent: !showBack),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.showPhotoAccent = true});

  final bool showPhotoAccent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: showPhotoAccent
              ? const LinearGradient(
                  colors: [Color(0xFFEDF2F7), Color(0xFFFFE1C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: showPhotoAccent ? null : Colors.transparent,
        ),
        child: Icon(
          showPhotoAccent ? Icons.person : Icons.more_vert,
          color: showPhotoAccent ? AppColors.primary : AppColors.primary,
          size: showPhotoAccent ? 19 : 22,
        ),
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScroll(
      children: [
        const Text(
          'Publication Search',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Explore AI and cognitive science publications.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: cardShadow,
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppColors.secondary, size: 21),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search by title, author, keyword',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              Icon(Icons.tune, color: AppColors.primary, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final article in searchResults) ...[
          PublicationCard(article: article),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('1,284', 'Publications', Icons.article_outlined),
      ('68.4K', 'Citations', Icons.format_quote),
      ('214', 'Authors', Icons.groups_outlined),
      ('42', 'Journals', Icons.library_books_outlined),
    ];

    return ScreenScroll(
      children: [
        const Text(
          'Research Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'High-level view of the analyzed publication corpus.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final stat = stats[index];
            return StatCard(value: stat.$1, label: stat.$2, icon: stat.$3);
          },
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.insights,
                title: 'Dominant Topics',
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  TagChip(label: 'Machine Learning'),
                  TagChip(label: 'Decision-Making'),
                  TagChip(label: 'Neural Networks'),
                  TagChip(label: 'Human-AI Interaction'),
                  TagChip(label: 'Computer Vision'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.bar_chart,
                title: 'Citation Momentum',
              ),
              const SizedBox(height: 12),
              for (final journal in topJournals.take(3)) ...[
                JournalBarRow(journal: journal),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScroll(
      children: [
        const Text(
          'Publication Trend Analysis',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Analyzing AI research corpus from 2016 to 2024.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        SectionCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
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
                  MetricPill(label: '2016-2024'),
                ],
              ),
              const SizedBox(height: 8),
              const SizedBox(
                height: 218,
                width: double.infinity,
                child: PublicationLineChart(points: trendPoints),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Top 5 Research Journals',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'More',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.more_horiz,
                      color: AppColors.primary,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final journal in topJournals) ...[
                JournalBarRow(journal: journal),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScroll(
      children: [
        ArticleHeaderCard(article: featuredArticle),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(icon: Icons.subject, title: 'Abstract'),
              const SizedBox(height: 12),
              Text(
                featuredArticle.abstractText,
                textAlign: TextAlign.justify,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Keywords',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final keyword in featuredArticle.keywords)
                    TagChip(label: keyword),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ScreenScroll extends StatelessWidget {
  const ScreenScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: cardShadow,
      ),
      child: child,
    );
  }
}

class ArticleHeaderCard extends StatelessWidget {
  const ArticleHeaderCard({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryChip(label: article.type),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${article.topic} - ${article.year}',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(article.title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  article.authors,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.secondary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          MetricPill(
            label: '${article.citations} Citations',
            icon: Icons.format_quote,
            fillWidth: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('DOI: ${article.doi}')));
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open DOI Link'),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class PublicationCard extends StatelessWidget {
  const PublicationCard({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryChip(label: article.type),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${article.topic} - ${article.year}',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            article.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            article.authors,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: MetricPill(
              label: '${article.citations} citations',
              icon: Icons.local_fire_department,
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary, size: 22),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.secondary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class MetricPill extends StatelessWidget {
  const MetricPill({
    super.key,
    required this.label,
    this.icon,
    this.fillWidth = false,
  });

  final String label;
  final IconData? icon;
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: fillWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: fillWidth
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.secondary, size: 15),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (fillWidth) {
      return SizedBox(width: double.infinity, child: pill);
    }

    return pill;
  }
}

class JournalBarRow extends StatelessWidget {
  const JournalBarRow({super.key, required this.journal});

  final JournalStat journal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                journal.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatNumber(journal.citations),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: journal.score,
            minHeight: 6,
            backgroundColor: AppColors.border,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class PublicationLineChart extends StatelessWidget {
  const PublicationLineChart({super.key, required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: PublicationLinePainter(points));
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
    for (var index = 0; index < points.length; index++) {
      final x = left + chartWidth * index / (points.length - 1);
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
      ..shader = const LinearGradient(
        colors: [Color(0x554C78A8), Color(0x004C78A8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(left, top, chartWidth, chartHeight));
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final pointPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    final pointBorderPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final offset in offsets) {
      canvas
        ..drawCircle(offset, 4.2, pointPaint)
        ..drawCircle(offset, 4.2, pointBorderPaint);
    }

    final labels = <int>[2016, 2018, 2020, 2022, 2024];
    for (final year in labels) {
      final index = points.indexWhere((point) => point.year == year);
      if (index == -1) {
        continue;
      }
      final x = left + chartWidth * index / (points.length - 1);
      _drawLabel(
        canvas,
        "'${year.toString().substring(2)}",
        Offset(x, size.height - 17),
        alignCenter: true,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset origin, {
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
    final dx = alignCenter ? origin.dx - painter.width / 2 : origin.dx;
    painter.paint(canvas, Offset(dx, origin.dy));
  }

  @override
  bool shouldRepaint(covariant PublicationLinePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

List<BoxShadow> get cardShadow {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}

String _formatNumber(int value) {
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

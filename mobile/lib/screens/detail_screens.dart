import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_models.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../services/publication_analytics.dart';
import '../viewmodels/firebase_features_view_model.dart';
import '../viewmodels/journal_detail_view_model.dart';
import '../viewmodels/keyword_detail_view_model.dart';
import '../widgets/app_widgets.dart';

class PublicationDetailScreen extends StatefulWidget {
  const PublicationDetailScreen({super.key, required this.publication});

  final PublicationModel publication;

  @override
  State<PublicationDetailScreen> createState() =>
      _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  PublicationModel get publication => widget.publication;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<FirebaseFeaturesViewModel>().trackViewPublication(
        publicationId: publication.id,
        title: publication.title,
        publicationYear: publication.publicationYear,
      );
    });
  }

  Future<void> _openDoi(BuildContext context) async {
    final target =
        publication.landingPageUrl ?? publication.doi ?? publication.id;
    final messenger = ScaffoldMessenger.of(context);

    if (target.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Bài báo này chưa có DOI.')),
      );
      return;
    }

    final uri = Uri.tryParse(target.trim());
    if (uri == null || !uri.hasScheme) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Liên kết DOI không hợp lệ.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không mở được liên kết DOI.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authors = publication.authors.isEmpty
        ? 'Tác giả không xác định'
        : publication.authors.join(', ');

    return Scaffold(
      key: const Key('publication_detail_screen'),
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(showBack: true, title: 'Chi tiết bài báo'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.medium,
          AppSpacing.medium,
          AppSpacing.medium,
          AppSpacing.large,
        ),
        children: [
          SectionCard(
            padding: const EdgeInsets.all(16),
            accentColor: AppColors.secondary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CategoryChip(label: publication.displayYear),
                    MetricPill(
                      label:
                          '${formatDisplayNumber(publication.citedByCount)} trích dẫn',
                      icon: Icons.format_quote,
                      accentColor: AppColors.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(publication.title, style: theme.textTheme.headlineLarge),
                const SizedBox(height: 10),
                Text(
                  authors,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  publication.journalName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (publication.abstractText != null &&
              publication.abstractText!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(icon: Icons.subject, title: 'Tóm tắt'),
                  const SizedBox(height: 12),
                  Text(
                    publication.abstractText!,
                    textAlign: TextAlign.justify,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(icon: Icons.link, title: 'Liên kết DOI'),
                const SizedBox(height: 12),
                SelectableText(
                  publication.doi ?? 'Không có DOI',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('open_original_publication_button'),
                    onPressed:
                        (publication.landingPageUrl ??
                                publication.doi ??
                                publication.id)
                            .trim()
                            .isEmpty
                        ? null
                        : () => _openDoi(context),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Mở bài báo gốc'),
                  ),
                ),
                if (publication.doi == null) ...[
                  const SizedBox(height: 8),
                  Text('Không có DOI', style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class JournalDetailScreen extends StatefulWidget {
  const JournalDetailScreen({super.key, required this.journal});

  final JournalModel journal;

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  late final JournalDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = JournalDetailViewModel(journal: widget.journal)..load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<FirebaseFeaturesViewModel>().trackViewJournal(
        journalId: widget.journal.id,
        name: widget.journal.displayName,
      );
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _reload() {
    _viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('journal_detail_screen'),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const GradientAppBar(showBack: true, title: 'Chi tiết tạp chí'),
      body: ScreenScroll(
        children: [
          SectionCard(
            accentColor: AppColors.secondary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  icon: Icons.menu_book_outlined,
                  title: 'Hồ sơ tạp chí',
                ),
                const SizedBox(height: 14),
                Text(
                  widget.journal.displayName,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MetricPill(
                      label:
                          '${formatCompactNumber(widget.journal.worksCount)} bài',
                      icon: Icons.article_outlined,
                    ),
                    if (widget.journal.citedByCount > 0)
                      MetricPill(
                        label:
                            '${formatCompactNumber(widget.journal.citedByCount)} trích dẫn',
                        icon: Icons.format_quote,
                        accentColor: AppColors.accent,
                      ),
                    MetricPill(
                      label:
                          '${_viewModel.averageCitations.toStringAsFixed(1)} trích dẫn/bài',
                      icon: Icons.calculate_outlined,
                      accentColor: AppColors.chartLine,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              if (_viewModel.isLoading) {
                return const AppLoadingState(message: 'Đang tải bài báo...');
              }
              if (_viewModel.errorMessage != null) {
                return AppErrorState(
                  message: _viewModel.errorMessage!,
                  onRetry: _reload,
                );
              }
              final works = _viewModel.publications;
              if (works.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.article_outlined,
                  title: 'Chưa có bài báo',
                  message: 'OpenAlex chưa trả về công trình cho journal này.',
                );
              }

              return Column(
                key: const Key('journal_related_publications'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenHeader(
                    title: 'Bài báo nổi bật',
                    subtitle: 'Sắp xếp theo số trích dẫn từ OpenAlex.',
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  for (final work in works.take(20)) ...[
                    PaperCard(
                      publication: work,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PublicationDetailScreen(publication: work),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class KeywordDetailScreen extends StatefulWidget {
  const KeywordDetailScreen({super.key, required this.keyword});

  final KeywordMetric keyword;

  @override
  State<KeywordDetailScreen> createState() => _KeywordDetailScreenState();
}

class _KeywordDetailScreenState extends State<KeywordDetailScreen> {
  late final KeywordDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = KeywordDetailViewModel(keyword: widget.keyword)..load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<FirebaseFeaturesViewModel>().trackViewKeyword(
        keywordId: widget.keyword.id,
        name: widget.keyword.displayName,
      );
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyword = widget.keyword;
    return Scaffold(
      key: const Key('keyword_detail_screen'),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const GradientAppBar(showBack: true, title: 'Chi tiết từ khóa'),
      body: ScreenScroll(
        children: [
          SectionCard(
            accentColor: AppColors.chartLine,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  icon: Icons.tag_outlined,
                  title: 'Hồ sơ từ khóa',
                ),
                const SizedBox(height: 14),
                Text(
                  keyword.displayName,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MetricPill(
                      label: '${formatCompactNumber(keyword.worksCount)} bài',
                      icon: Icons.article_outlined,
                    ),
                    if (keyword.citedByCount > 0)
                      MetricPill(
                        label:
                            '${formatCompactNumber(keyword.citedByCount)} trích dẫn',
                        icon: Icons.format_quote,
                        accentColor: AppColors.accent,
                      ),
                    if (keyword.field != null)
                      MetricPill(
                        label: keyword.field!,
                        icon: Icons.account_tree_outlined,
                        accentColor: AppColors.primaryLight,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              if (_viewModel.isLoading) {
                return const SizedBox(
                  height: 220,
                  child: AppLoadingState(
                    message: 'Đang tải phân tích từ khóa...',
                  ),
                );
              }
              if (_viewModel.errorMessage != null) {
                return AppErrorState(
                  message: _viewModel.errorMessage!,
                  onRetry: _viewModel.load,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionCard(
                    key: const ValueKey('keyword_publication_trend_chart'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          icon: Icons.show_chart,
                          title: 'Xu hướng công bố',
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 220,
                          child: LineChart(series: _viewModel.publicationTrend),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _KeywordJournalsSection(viewModel: _viewModel),
                  const SizedBox(height: AppSpacing.medium),
                  _KeywordAuthorsSection(viewModel: _viewModel),
                  const SizedBox(height: AppSpacing.medium),
                  _KeywordPublicationsSection(viewModel: _viewModel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _KeywordJournalsSection extends StatelessWidget {
  const _KeywordJournalsSection({required this.viewModel});

  final KeywordDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final journals = viewModel.relatedJournals;
    return SectionCard(
      key: const ValueKey('keyword_related_journals'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.library_books_outlined,
            title: 'Tạp chí liên quan',
          ),
          const SizedBox(height: 14),
          if (journals.isEmpty)
            const AppEmptyState(
              icon: Icons.library_books_outlined,
              title: 'Chưa có tạp chí',
              message: 'OpenAlex chưa trả về tạp chí cho từ khóa này.',
            )
          else ...[
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
              valueSuffix: 'bài',
              onTap: (index) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        JournalDetailScreen(journal: journals[index]),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _KeywordAuthorsSection extends StatelessWidget {
  const _KeywordAuthorsSection({required this.viewModel});

  final KeywordDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final authors = viewModel.topAuthors;
    return SectionCard(
      key: const ValueKey('keyword_top_authors'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.groups_outlined,
            title: 'Tác giả nổi bật',
          ),
          const SizedBox(height: 14),
          if (authors.isEmpty)
            const AppEmptyState(
              icon: Icons.person_search,
              title: 'Chưa có tác giả',
              message: 'Dữ liệu tác giả sẽ xuất hiện khi OpenAlex trả về.',
            )
          else
            for (var index = 0; index < authors.take(5).length; index++) ...[
              AuthorCard(
                author: authors[index],
                rank: index + 1,
                onTap: () {
                  final uri = Uri.tryParse(authors[index].id);
                  if (uri != null && uri.hasScheme) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _KeywordPublicationsSection extends StatelessWidget {
  const _KeywordPublicationsSection({required this.viewModel});

  final KeywordDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final publications = viewModel.relatedPublications;
    return SectionCard(
      key: const ValueKey('keyword_related_publications'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.article_outlined,
            title: 'Bài báo liên quan',
          ),
          const SizedBox(height: 14),
          if (publications.isEmpty)
            const AppEmptyState(
              icon: Icons.article_outlined,
              title: 'Chưa có bài báo',
              message: 'Thử từ khóa khác để mở rộng kết quả.',
            )
          else
            for (final publication in publications.take(10)) ...[
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
      ),
    );
  }
}

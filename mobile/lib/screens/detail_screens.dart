import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../services/api_service.dart';
import '../services/publication_analytics.dart';
import '../widgets/app_widgets.dart';

class PublicationDetailScreen extends StatelessWidget {
  const PublicationDetailScreen({super.key, required this.publication});

  final PublicationModel publication;

  Future<void> _openDoi(BuildContext context) async {
    final doi = publication.doi;
    final messenger = ScaffoldMessenger.of(context);

    if (doi == null || doi.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Bài báo này chưa có DOI.')),
      );
      return;
    }

    final uri = Uri.tryParse(doi.trim());
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
        ? 'Unknown authors'
        : publication.authors.join(', ');

    return Scaffold(
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
                    CategoryChip(label: publication.publicationYear.toString()),
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: publication.doi == null
                        ? null
                        : () => _openDoi(context),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Mở DOI'),
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
  late final ApiService _api = ApiService();
  late Future<List<PublicationModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchWorksBySourceId(widget.journal.id);
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _api.fetchWorksBySourceId(widget.journal.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(showBack: true, title: 'Chi tiết journal'),
      body: ScreenScroll(
        children: [
          SectionCard(
            accentColor: AppColors.secondary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  icon: Icons.menu_book_outlined,
                  title: 'Hồ sơ journal',
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
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          FutureBuilder<List<PublicationModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingState(message: 'Đang tải bài báo...');
              }
              if (snapshot.hasError) {
                return AppErrorState(
                  message: 'Không thể tải danh sách bài báo.',
                  onRetry: _reload,
                );
              }
              final works = snapshot.data ?? const [];
              if (works.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.article_outlined,
                  title: 'Chưa có bài báo',
                  message: 'OpenAlex chưa trả về công trình cho journal này.',
                );
              }

              return Column(
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

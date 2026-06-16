import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../providers/search_provider.dart';
import '../services/api_service.dart';
import '../services/publication_analytics.dart';
import '../widgets/app_widgets.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSearched = context.select<SearchProvider, bool>(
      (provider) => provider.hasSearched,
    );
    final keyword = context.select<SearchProvider, String?>(
      (provider) => provider.keyword,
    );
    final global = context.select<SearchProvider, dynamic>(
      (provider) => provider.globalOverview,
    );
    final searchTop = context.select<SearchProvider, List<JournalModel>>(
      (provider) => provider.topJournals,
    );

    final journals = hasSearched ? searchTop : (global?.topJournals ?? const []);
    final title = hasSearched && keyword != null && keyword.isNotEmpty
        ? 'Top journals for "$keyword"'
        : 'Top journals (OpenAlex)';

    return ScreenScroll(
      children: [
        ScreenHeader(
          title: 'Journals',
          subtitle: 'Browse journals and open publication details.',
        ),
        const SizedBox(height: AppSpacing.medium),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.library_books_outlined,
                title: 'Journal rankings',
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              if (journals.isEmpty)
                const AppEmptyState(
                  icon: Icons.search,
                  title: 'No journals yet',
                  message: 'Try searching on Home to see journal rankings.',
                )
              else
                ...journals.map(
                  (journal) => _JournalRow(
                    journal: journal,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => JournalPublicationsScreen(
                            journal: journal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JournalRow extends StatelessWidget {
  const _JournalRow({required this.journal, required this.onTap});

  final JournalModel journal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                journal.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatCompactNumber(journal.worksCount),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class JournalPublicationsScreen extends StatefulWidget {
  const JournalPublicationsScreen({super.key, required this.journal});

  final JournalModel journal;

  @override
  State<JournalPublicationsScreen> createState() =>
      _JournalPublicationsScreenState();
}

class _JournalPublicationsScreenState extends State<JournalPublicationsScreen> {
  late final ApiService _api = ApiService();

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(),
      body: ScreenScroll(
        children: [
          ScreenHeader(
            title: widget.journal.displayName,
            subtitle: 'Recent publications from this journal.',
          ),
          const SizedBox(height: AppSpacing.medium),
          FutureBuilder<List<PublicationModel>>(
            future: _api.fetchWorksBySourceId(widget.journal.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingState(message: 'Loading publications...');
              }
              if (snapshot.hasError) {
                return AppErrorState(
                  message: 'Unable to load publications.',
                  onRetry: () => setState(() {}),
                );
              }
              final works = snapshot.data ?? const [];
              if (works.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.article_outlined,
                  title: 'No publications found',
                  message: 'Try a different journal or search keyword.',
                );
              }

              return Column(
                children: [
                  for (final work in works) ...[
                    _PublicationTile(publication: work),
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

class _PublicationTile extends StatelessWidget {
  const _PublicationTile({required this.publication});

  final PublicationModel publication;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            publication.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MetricPill(
                icon: Icons.calendar_today_outlined,
                label: publication.publicationYear.toString(),
              ),
              MetricPill(
                icon: Icons.format_quote,
                label: formatCompactNumber(publication.citedByCount),
              ),
            ],
          ),
          if (publication.journalName.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              publication.journalName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}


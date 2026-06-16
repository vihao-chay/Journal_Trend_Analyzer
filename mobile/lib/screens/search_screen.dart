import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../models/publication_model.dart';
import '../providers/search_provider.dart';
import '../widgets/app_widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch([String? submittedValue]) {
    final keyword = (submittedValue ?? _searchController.text).trim();
    if (keyword.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();
    context.read<SearchProvider>().search(keyword);
  }

  void _scheduleDebouncedSearch(String value) {
    final keyword = value.trim();
    _debounce?.cancel();
    if (keyword.length < 3) {
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      context.read<SearchProvider>().search(keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<SearchProvider, bool>(
      (provider) => provider.isSearchLoading,
    );
    final error = context.select<SearchProvider, String?>(
      (provider) => provider.searchError,
    );
    final hasSearched = context.select<SearchProvider, bool>(
      (provider) => provider.hasSearched,
    );
    final publications = context.select<SearchProvider, List<PublicationModel>>(
      (provider) => provider.publications,
    );
    final recents = context.select<SearchProvider, List<String>>(
      (provider) => provider.recentSearches,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(
            title: 'Publication Search',
            subtitle: 'Explore scholarly works from the OpenAlex catalog.',
          ),
          const SizedBox(height: AppSpacing.medium),
          _SearchField(
            controller: _searchController,
            onSubmitted: _submitSearch,
            onChanged: _scheduleDebouncedSearch,
            onSearchPressed: () => _submitSearch(),
          ),
          if (recents.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in recents.take(8))
                  ActionChip(
                    label: Text(item),
                    onPressed: () {
                      _searchController.text = item;
                      _submitSearch(item);
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.medium),
          Expanded(
            child: _SearchResultsView(
              isLoading: isLoading,
              error: error,
              hasSearched: hasSearched,
              publications: publications,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onChanged,
    required this.onSearchPressed,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final VoidCallback onSearchPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: appCardShadow,
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search by title, author, keyword...',
          prefixIcon: const Icon(Icons.search, color: AppColors.secondary),
          suffixIcon: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              onPressed: onSearchPressed,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({
    required this.isLoading,
    required this.error,
    required this.hasSearched,
    required this.publications,
  });

  final bool isLoading;
  final String? error;
  final bool hasSearched;
  final List<PublicationModel> publications;

  @override
  Widget build(BuildContext context) {
    if (!hasSearched) {
      return const AppEmptyState(
        icon: Icons.manage_search,
        title: 'Start your research',
        message:
            'Enter a keyword to discover publications, authors, and journals from OpenAlex.',
      );
    }

    if (isLoading) {
      return ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.large),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => const AppShimmer(
          child: _SkeletonPublicationCard(),
        ),
      );
    }

    if (error != null) {
      return AppErrorState(message: error!);
    }

    if (publications.isEmpty) {
      return const AppEmptyState(
        icon: Icons.search_off,
        title: 'No results found',
        message: 'Try a different keyword or check your spelling.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.large),
      itemCount: publications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final publication = publications[index];
        return PublicationCard(
          publication: publication,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    PublicationDetailScreen(publication: publication),
              ),
            );
          },
        );
      },
    );
  }
}

class PublicationCard extends StatelessWidget {
  const PublicationCard({
    super.key,
    required this.publication,
    required this.onTap,
  });

  final PublicationModel publication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authors = publication.authors.isEmpty
        ? 'Unknown authors'
        : publication.authors.take(3).join(', ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: AppColors.border),
            boxShadow: appCardShadow,
          ),
          child: Row(
            // Avoid stretching in unconstrained layouts (e.g. inside slivers),
            // which can trigger layout assertions and semantics parentData errors.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.medium),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CategoryChip(
                            label: publication.publicationYear.toString(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              publication.journalName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        publication.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authors,
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
                          label:
                              '${formatDisplayNumber(publication.citedByCount)} citations',
                          icon: Icons.local_fire_department,
                          accentColor: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonPublicationCard extends StatelessWidget {
  const _SkeletonPublicationCard();

  @override
  Widget build(BuildContext context) {
    final base = AppColors.border.withValues(alpha: 0.55);
    final highlight = AppColors.border.withValues(alpha: 0.25);

    Widget bar({double? width, double height = 10}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
        boxShadow: appCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: highlight,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppRadius.medium),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 22,
                        decoration: BoxDecoration(
                          color: highlight,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: bar()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  bar(width: double.infinity, height: 12),
                  const SizedBox(height: 8),
                  bar(width: 220, height: 12),
                  const SizedBox(height: 12),
                  bar(width: 180),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 120,
                      height: 32,
                      decoration: BoxDecoration(
                        color: highlight,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                        border: Border.all(
                          color: highlight.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PublicationDetailScreen extends StatelessWidget {
  const PublicationDetailScreen({super.key, required this.publication});

  final PublicationModel publication;

  Future<void> _openDoi(BuildContext context) async {
    final doi = publication.doi;
    final messenger = ScaffoldMessenger.of(context);

    if (doi == null || doi.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No DOI link available.')),
      );
      return;
    }

    final uri = Uri.tryParse(doi.trim());
    if (uri == null || !uri.hasScheme) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Invalid DOI link.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open DOI link.')),
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
      appBar: const GradientAppBar(
        showBack: true,
        title: 'Publication Details',
      ),
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
                Row(
                  children: [
                    CategoryChip(label: publication.publicationYear.toString()),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        publication.journalName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                const SizedBox(height: 16),
                MetricPill(
                  label:
                      '${formatDisplayNumber(publication.citedByCount)} Citations',
                  icon: Icons.format_quote,
                  fillWidth: true,
                  accentColor: AppColors.accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (publication.abstractText != null &&
              publication.abstractText!.trim().isNotEmpty) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(icon: Icons.subject, title: 'Abstract'),
                  const SizedBox(height: 12),
                  Text(
                    publication.abstractText!,
                    textAlign: TextAlign.justify,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(icon: Icons.link, title: 'DOI Link'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: publication.doi == null
                        ? null
                        : () => _openDoi(context),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open DOI Link'),
                  ),
                ),
                if (publication.doi == null) ...[
                  const SizedBox(height: 8),
                  Text('No DOI available', style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

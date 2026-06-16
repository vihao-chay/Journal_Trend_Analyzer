import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/publication_model.dart';
import '../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Future<List<PublicationModel>>? _searchResults;

  late final ApiService _apiService;
  late final bool _ownsApiService;

  @override
  void initState() {
    super.initState();
    _ownsApiService = widget.apiService == null;
    _apiService = widget.apiService ?? ApiService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsApiService) {
      _apiService.dispose();
    }
    super.dispose();
  }

  void _submitSearch([String? submittedValue]) {
    final keyword = (submittedValue ?? _searchController.text).trim();
    if (keyword.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _searchResults = _apiService.searchPublications(keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Publication Search',
            style: TextStyle(
              color: _SearchColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Explore AI and cognitive science publications.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _SearchField(
            controller: _searchController,
            onSubmitted: _submitSearch,
            onSearchPressed: _submitSearch,
          ),
          const SizedBox(height: 16),
          Expanded(child: _SearchResultsView(resultsFuture: _searchResults)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onSearchPressed,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearchPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _SearchColors.border),
        boxShadow: _cardShadow,
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by title, author, keyword',
          hintStyle: const TextStyle(color: _SearchColors.textSecondary),
          border: InputBorder.none,
          prefixIcon: const Icon(
            Icons.search,
            color: _SearchColors.secondary,
            size: 21,
          ),
          suffixIcon: IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.arrow_forward, color: _SearchColors.primary),
            onPressed: onSearchPressed,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({required this.resultsFuture});

  final Future<List<PublicationModel>>? resultsFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (resultsFuture == null) {
      return const _EmptySearchState();
    }

    return FutureBuilder<List<PublicationModel>>(
      future: resultsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              _friendlyErrorMessage(snapshot.error),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        final publications = snapshot.data ?? const <PublicationModel>[];
        if (publications.isEmpty) {
          return const _NoResultsState();
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 18),
          itemCount: publications.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final publication = publications[index];
            return _PublicationCard(
              publication: publication,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    settings: RouteSettings(arguments: publication),
                    builder: (_) =>
                        PublicationDetailScreen(publication: publication),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static String _friendlyErrorMessage(Object? error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Unable to load publications. Please try again.';
  }
}

class _PublicationCard extends StatelessWidget {
  const _PublicationCard({required this.publication, required this.onTap});

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
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: _SearchSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategoryChip(label: publication.publicationYear.toString()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      publication.journalName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _SearchColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
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
                  color: _SearchColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _MetricPill(
                  label: '${_formatNumber(publication.citedByCount)} citations',
                  icon: Icons.format_quote,
                ),
              ),
            ],
          ),
        ),
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
    if (!launched) {
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
      appBar: AppBar(title: const Text('Publication Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        children: [
          _SearchSectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CategoryChip(
                      label: publication.publicationYear.toString(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        publication.journalName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _SearchColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(publication.title, style: theme.textTheme.headlineLarge),
                const SizedBox(height: 10),
                Text(
                  authors,
                  style: const TextStyle(
                    color: _SearchColors.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                _MetricPill(
                  label: '${_formatNumber(publication.citedByCount)} Citations',
                  icon: Icons.format_quote,
                  fillWidth: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SearchSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(
                  icon: Icons.library_books,
                  title: 'Journal',
                ),
                const SizedBox(height: 10),
                Text(
                  publication.journalName,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SearchSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(icon: Icons.link, title: 'DOI'),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: publication.doi == null
                        ? null
                        : () => _openDoi(context),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open Link'),
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Enter a keyword to search OpenAlex publications.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: _SearchColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No publications found for this keyword.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: _SearchColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SearchSectionCard extends StatelessWidget {
  const _SearchSectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _SearchColors.border),
        boxShadow: _cardShadow,
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _SearchColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _SearchColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _SearchColors.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _SearchColors.secondary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, this.icon, this.fillWidth = false});

  final String label;
  final IconData? icon;
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _SearchColors.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: fillWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: fillWidth
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: _SearchColors.secondary, size: 15),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _SearchColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
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

class _SearchColors {
  const _SearchColors._();

  static const primary = Color(0xFF1A365D);
  static const secondary = Color(0xFF2B6CB0);
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
  static const border = Color(0xFFE2E8F0);
}

List<BoxShadow> get _cardShadow {
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

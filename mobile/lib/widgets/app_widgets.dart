import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../models/analytics_models.dart';
import '../models/author_model.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../providers/search_provider.dart';
import '../services/publication_analytics.dart';

class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? AppColors.border.withValues(alpha: 0.55);
    final highlight =
        widget.highlightColor ?? AppColors.border.withValues(alpha: 0.20);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Sweep a narrow highlight band across the widget.
        final progress = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (progress * 2 - 1);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlidingGradientTransform(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}

class ScreenScroll extends StatelessWidget {
  const ScreenScroll({super.key, required this.children, this.onRefresh});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final scrollView = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );

    if (onRefresh == null) {
      return scrollView;
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: onRefresh!,
      child: scrollView,
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            if (badge != null) ...[
              const SizedBox(width: AppSpacing.small),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.medium),
    this.accentColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: theme.brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : appCardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (accentColor != null) Container(height: 3, color: accentColor),
            Padding(padding: padding, child: child),
          ],
        ),
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
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Icon(icon, color: colors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
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
    this.accentColor = AppColors.secondary,
  });

  final String label;
  final IconData? icon;
  final bool fillWidth;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: fillWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: fillWidth
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: accentColor, size: 15),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accentColor,
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

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class HighlightTile extends StatelessWidget {
  const HighlightTile({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class RankedBarRow extends StatelessWidget {
  const RankedBarRow({
    super.key,
    required this.rank,
    required this.name,
    required this.value,
    required this.score,
    this.valueLabel,
  });

  final int rank;
  final String name;
  final int value;
  final double score;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (rank) {
      1 => AppColors.accent,
      2 => AppColors.secondary,
      3 => AppColors.chartLine,
      _ => AppColors.textSecondary,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color: rankColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      valueLabel ?? formatCompactNumber(value),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: score,
                    minHeight: 8,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.85),
                    color: rankColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.message = 'Đang tải dữ liệu...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppColors.secondary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off,
                color: AppColors.error,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({
    super.key,
    this.showBack = false,
    this.onBack,
    this.title = 'Phân tích nghiên cứu OpenAlex',
  });

  final bool showBack;
  final VoidCallback? onBack;
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final darkPrimary = Color.lerp(colors.primary, Colors.black, 0.32)!;
    return AppBar(
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [darkPrimary, colors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: showBack
          ? IconButton(
              tooltip: 'Quay lại',
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack ?? () => Navigator.maybePop(context),
            )
          : null,
      title: Row(
        children: [
          if (!showBack) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_stories,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchContextBanner extends StatelessWidget {
  const SearchContextBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSearched = context.select<SearchProvider, bool>(
      (provider) => provider.hasSearched,
    );
    final keyword = context.select<SearchProvider, String?>(
      (provider) => provider.keyword,
    );
    final isLoading = context.select<SearchProvider, bool>(
      (provider) => provider.isSearchLoading,
    );

    return SectionCard(
      padding: const EdgeInsets.all(12),
      accentColor: hasSearched ? AppColors.chartLine : AppColors.secondary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasSearched ? Icons.filter_alt_outlined : Icons.public,
            color: AppColors.secondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasSearched && keyword != null
                  ? 'Đang xem kết quả cho: "$keyword"'
                  : 'Đang xem dữ liệu toàn cục OpenAlex. Tìm chủ đề ở Trang chủ để lọc kết quả.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (isLoading && hasSearched) ...[
            const SizedBox(width: 10),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}

class ResearchSearchBar extends StatelessWidget {
  const ResearchSearchBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onSearchPressed,
    this.onChanged,
    this.hintText = 'Tìm chủ đề, bài báo, tác giả...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearchPressed;
  final ValueChanged<String>? onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: theme.brightness == Brightness.dark ? null : appCardShadow,
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
          suffixIcon: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: IconButton(
              tooltip: 'Tìm kiếm',
              icon: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
              onPressed: onSearchPressed,
            ),
          ),
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.accentColor = AppColors.secondary,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return StatCard(
      value: value,
      label: label,
      icon: icon,
      accentColor: accentColor,
    );
  }
}

class PaperCard extends StatelessWidget {
  const PaperCard({super.key, required this.publication, required this.onTap});

  final PublicationModel publication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authors = publication.authors.isEmpty
        ? 'Tác giả không xác định'
        : publication.authors.take(3).join(', ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: theme.brightness == Brightness.dark
                ? null
                : appCardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 144,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          CategoryChip(label: publication.displayYear),
                          MetricPill(
                            label:
                                '${formatCompactNumber(publication.citedByCount)} trích dẫn',
                            icon: Icons.format_quote,
                            accentColor: AppColors.accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        publication.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authors,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        publication.journalName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
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

class JournalCard extends StatelessWidget {
  const JournalCard({
    super.key,
    required this.journal,
    required this.rank,
    required this.onTap,
  });

  final JournalModel journal;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: SectionCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _RankBadge(rank: rank),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journal.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        MetricPill(
                          label:
                              '${formatCompactNumber(journal.worksCount)} bài',
                          icon: Icons.article_outlined,
                        ),
                        if (journal.citedByCount > 0)
                          MetricPill(
                            label:
                                '${formatCompactNumber(journal.citedByCount)} trích dẫn',
                            icon: Icons.format_quote,
                            accentColor: AppColors.accent,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthorCard extends StatelessWidget {
  const AuthorCard({super.key, required this.author, required this.rank});

  final AuthorModel author;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MetricPill(
                      label: '${formatCompactNumber(author.worksCount)} bài',
                      icon: Icons.article_outlined,
                    ),
                    if (author.citedByCount > 0)
                      MetricPill(
                        label:
                            '${formatCompactNumber(author.citedByCount)} trích dẫn',
                        icon: Icons.format_quote,
                        accentColor: AppColors.accent,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final color = switch (rank) {
      1 => AppColors.accent,
      2 => AppColors.secondary,
      3 => AppColors.chartLine,
      _ => AppColors.primary,
    };

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class FilterPanel extends StatefulWidget {
  const FilterPanel({
    super.key,
    required this.filters,
    required this.onApply,
    required this.onReset,
  });

  final ResearchFilters filters;
  final ValueChanged<ResearchFilters> onApply;
  final VoidCallback onReset;

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late final TextEditingController _fromYearController;
  late final TextEditingController _toYearController;
  late final TextEditingController _fieldController;
  late final TextEditingController _subfieldController;
  late final TextEditingController _topicController;
  late final TextEditingController _countryController;
  late final TextEditingController _journalController;
  late bool _openAccessOnly;
  late SortMode _sortMode;

  @override
  void initState() {
    super.initState();
    _fromYearController = TextEditingController();
    _toYearController = TextEditingController();
    _fieldController = TextEditingController();
    _subfieldController = TextEditingController();
    _topicController = TextEditingController();
    _countryController = TextEditingController();
    _journalController = TextEditingController();
    _syncFromFilters(widget.filters);
  }

  @override
  void didUpdateWidget(covariant FilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters != widget.filters) {
      _syncFromFilters(widget.filters);
    }
  }

  @override
  void dispose() {
    _fromYearController.dispose();
    _toYearController.dispose();
    _fieldController.dispose();
    _subfieldController.dispose();
    _topicController.dispose();
    _countryController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  void _syncFromFilters(ResearchFilters filters) {
    _fromYearController.text = filters.fromYear?.toString() ?? '';
    _toYearController.text = filters.toYear?.toString() ?? '';
    _fieldController.text = filters.field;
    _subfieldController.text = filters.subfield;
    _topicController.text = filters.topic;
    _countryController.text = filters.country;
    _journalController.text = filters.journal;
    _openAccessOnly = filters.openAccessOnly;
    _sortMode = filters.sortMode;
  }

  void _apply() {
    widget.onApply(
      ResearchFilters(
        fromYear: int.tryParse(_fromYearController.text.trim()),
        toYear: int.tryParse(_toYearController.text.trim()),
        field: _fieldController.text.trim(),
        subfield: _subfieldController.text.trim(),
        topic: _topicController.text.trim(),
        country: _countryController.text.trim(),
        journal: _journalController.text.trim(),
        openAccessOnly: _openAccessOnly,
        sortMode: _sortMode,
      ),
    );
  }

  void _reset() {
    setState(() => _syncFromFilters(ResearchFilters.empty));
    widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      accentColor: AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionTitle(icon: Icons.tune, title: 'Bộ lọc'),
              ),
              MetricPill(
                label: '${widget.filters.activeCount} đang bật',
                icon: Icons.filter_alt_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 620;
              final children = [
                _FilterTextField(
                  controller: _fromYearController,
                  label: 'Từ năm',
                  keyboardType: TextInputType.number,
                ),
                _FilterTextField(
                  controller: _toYearController,
                  label: 'Đến năm',
                  keyboardType: TextInputType.number,
                ),
                _FilterTextField(
                  controller: _fieldController,
                  label: 'Lĩnh vực',
                  hint: 'Computer Science hoặc fields/17',
                ),
                _FilterTextField(
                  controller: _subfieldController,
                  label: 'Tiểu lĩnh vực',
                  hint: 'Artificial Intelligence hoặc subfields/1702',
                ),
                _FilterTextField(
                  controller: _topicController,
                  label: 'Chủ đề',
                  hint: 'Graphene hoặc T10083',
                ),
                _FilterTextField(
                  controller: _journalController,
                  label: 'Tạp chí',
                  hint: 'Nature hoặc S137773608',
                ),
                _FilterTextField(
                  controller: _countryController,
                  label: 'Quốc gia',
                  hint: 'US, CN, GB, JP, VN...',
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      for (final code in const ['US', 'CN', 'GB', 'JP', 'VN'])
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(code),
                          onPressed: () {
                            setState(() => _countryController.text = code);
                          },
                        ),
                    ],
                  ),
                ),
              ];

              if (!isWide) {
                return Column(
                  children: [
                    for (final child in children) ...[
                      child,
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final child in children)
                    SizedBox(
                      width: (constraints.maxWidth - 12) / 2,
                      child: child,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _openAccessOnly,
              onChanged: (value) => setState(() => _openAccessOnly = value),
              title: const Text('Chỉ Open Access'),
              subtitle: const Text('Lọc các công trình có truy cập mở'),
            ),
          ),
          DropdownButtonFormField<SortMode>(
            initialValue: _sortMode,
            decoration: const InputDecoration(labelText: 'Sắp xếp'),
            items: const [
              DropdownMenuItem(
                value: SortMode.relevance,
                child: Text('Liên quan nhất'),
              ),
              DropdownMenuItem(
                value: SortMode.citations,
                child: Text('Trích dẫn cao'),
              ),
              DropdownMenuItem(
                value: SortMode.publicationCount,
                child: Text('Số công bố'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _sortMode = value);
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Đặt lại'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _apply,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TopicDropdownCard extends StatelessWidget {
  const TopicDropdownCard({
    super.key,
    required this.title,
    required this.icon,
    required this.topics,
    required this.onSelected,
    this.emptyText = 'Chưa có dữ liệu',
  });

  final String title;
  final IconData icon;
  final List<String> topics;
  final ValueChanged<String> onSelected;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final uniqueTopics = <String>{
      for (final topic in topics)
        if (topic.trim().isNotEmpty) topic.trim(),
    }.toList(growable: false);

    return SectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 10),
          if (uniqueTopics.isEmpty)
            Text(emptyText, style: Theme.of(context).textTheme.bodySmall)
          else
            DropdownButtonFormField<String>(
              initialValue: null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Chọn chủ đề',
                prefixIcon: Icon(Icons.topic_outlined),
              ),
              items: [
                for (final topic in uniqueTopics.take(12))
                  DropdownMenuItem(value: topic, child: Text(topic)),
              ],
              onChanged: (value) {
                if (value == null || value.trim().isEmpty) return;
                onSelected(value);
              },
            ),
        ],
      ),
    );
  }
}

class _FilterTextField extends StatelessWidget {
  const _FilterTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.trailing,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
        if (trailing != null) ...[const SizedBox(height: 8), trailing!],
      ],
    );
  }
}

class HorizontalBarChart extends StatelessWidget {
  const HorizontalBarChart({
    super.key,
    required this.data,
    this.valueSuffix = 'bài',
  });

  final List<ChartBarData> data;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const AppEmptyState(
        icon: Icons.bar_chart,
        title: 'Chưa có dữ liệu',
        message: 'Dữ liệu xếp hạng sẽ xuất hiện sau khi tải từ OpenAlex.',
      );
    }

    final visibleData = data.take(8).toList(growable: false);
    final chartHeight = (70.0 + visibleData.length * 58.0)
        .clamp(260.0, 560.0)
        .toDouble();

    return SizedBox(
      height: chartHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: _HorizontalBarChartPainter(
          data: visibleData,
          valueSuffix: valueSuffix,
          textStyle: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _HorizontalBarChartPainter extends CustomPainter {
  const _HorizontalBarChartPainter({
    required this.data,
    required this.valueSuffix,
    required this.textStyle,
  });

  final List<ChartBarData> data;
  final String valueSuffix;
  final TextStyle? textStyle;

  static const _barColors = [
    AppColors.accent,
    AppColors.secondary,
    AppColors.chartLine,
    Color(0xFF64748B),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const plotLeft = 34.0;
    final plotRight = size.width - 12;
    const plotTop = 12.0;
    final plotBottom = size.height - 44;
    final plotWidth = math.max(1.0, plotRight - plotLeft);
    final plotHeight = math.max(1.0, plotBottom - plotTop);
    final maxValue = math.max(
      1,
      data.map((item) => item.value).reduce(math.max),
    );
    final rowHeight = plotHeight / data.length;

    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.78)
      ..strokeWidth = 1;
    final trackPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.58);

    for (var tick = 0; tick <= 4; tick++) {
      final x = plotLeft + plotWidth * tick / 4;
      canvas.drawLine(Offset(x, plotTop), Offset(x, plotBottom), gridPaint);
      _drawText(
        canvas,
        tick == 0 ? '0' : formatCompactNumber(maxValue * tick / 4),
        Offset(x, plotBottom + 8),
        maxWidth: 54,
        color: AppColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        alignCenter: true,
      );
    }

    _drawVerticalText(canvas, 'Số bài', Offset(10, plotTop + plotHeight / 2));
    _drawText(
      canvas,
      _capitalizeAxisLabel(valueSuffix),
      Offset(plotLeft + plotWidth / 2, size.height - 14),
      maxWidth: 48,
      color: AppColors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      alignCenter: true,
    );

    for (var index = 0; index < data.length; index++) {
      final item = data[index];
      final rowTop = plotTop + rowHeight * index;
      final labelY = rowTop + 4;
      final barHeight = math.min(14.0, rowHeight * 0.24);
      final barTop = rowTop + math.min(34.0, rowHeight * 0.52);
      final ratio = (item.value / maxValue).clamp(0.0, 1.0).toDouble();
      final barWidth = math.max(2.0, plotWidth * ratio);
      final color = index < _barColors.length
          ? _barColors[index]
          : AppColors.primary.withValues(alpha: 0.72);

      final valueText = formatCompactNumber(item.value);
      final valuePainter = _textPainter(
        valueText,
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      )..layout(maxWidth: 72);
      valuePainter.paint(
        canvas,
        Offset(plotRight - valuePainter.width, labelY),
      );

      _drawText(
        canvas,
        '${index + 1}. ${item.label}',
        Offset(plotLeft, labelY),
        maxWidth: math.max(72, plotWidth - valuePainter.width - 16),
        color: AppColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        maxLines: 1,
      );

      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(plotLeft, barTop, plotWidth, barHeight),
        const Radius.circular(999),
      );
      canvas.drawRRect(trackRect, trackPaint);

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(plotLeft, barTop, barWidth, barHeight),
        const Radius.circular(999),
      );
      canvas.drawRRect(barRect, Paint()..color = color);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double maxWidth,
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    int maxLines = 1,
    bool alignCenter = false,
    bool alignRight = false,
  }) {
    final painter = _textPainter(
      text,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);
    final dx = alignRight
        ? offset.dx - painter.width
        : alignCenter
        ? offset.dx - painter.width / 2
        : offset.dx;
    painter.paint(canvas, Offset(dx, offset.dy));
  }

  void _drawVerticalText(Canvas canvas, String text, Offset center) {
    final painter = _textPainter(
      text,
      color: AppColors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w800,
    )..layout(maxWidth: 80);

    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(-math.pi / 2);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  TextPainter _textPainter(
    String text, {
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    int maxLines = 1,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: (textStyle ?? const TextStyle()).copyWith(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.18,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '...',
    );
  }

  @override
  bool shouldRepaint(covariant _HorizontalBarChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.valueSuffix != valueSuffix ||
        oldDelegate.textStyle != textStyle;
  }
}

String _capitalizeAxisLabel(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }
  return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
}

class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.trend, this.maxPoints = 40});

  final Map<String, int> trend;
  final int maxPoints;

  @override
  Widget build(BuildContext context) {
    final points = _trendPointsFromMap(trend);
    final displayed = points.length > maxPoints
        ? points.sublist(points.length - maxPoints)
        : points;

    if (displayed.isEmpty) {
      return const AppEmptyState(
        icon: Icons.show_chart,
        title: 'Chưa có xu hướng',
        message: 'OpenAlex chưa trả về dữ liệu theo năm cho truy vấn này.',
      );
    }

    return CustomPaint(
      painter: _TrendChartPainter(displayed),
      child: const SizedBox.expand(),
    );
  }
}

class _TrendPoint {
  const _TrendPoint(this.year, this.value);

  final int year;
  final int value;
}

List<_TrendPoint> _trendPointsFromMap(Map<String, int> trend) {
  return trend.entries
      .map((entry) {
        final year = int.tryParse(entry.key);
        if (year == null) {
          return null;
        }
        return _TrendPoint(year, entry.value);
      })
      .whereType<_TrendPoint>()
      .toList(growable: false);
}

class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.series,
    this.xAxisLabel = 'Năm',
    this.yAxisLabel = 'Trích dẫn',
    this.maxPoints = 18,
  });

  final Map<String, int> series;
  final String xAxisLabel;
  final String yAxisLabel;
  final int maxPoints;

  @override
  Widget build(BuildContext context) {
    final points = _trendPointsFromMap(series);
    final displayed = points.length > maxPoints
        ? points.sublist(points.length - maxPoints)
        : points;

    if (displayed.isEmpty) {
      return const AppEmptyState(
        icon: Icons.show_chart,
        title: 'Chưa có tốc độ trích dẫn',
        message:
            'OpenAlex chưa trả về dữ liệu trích dẫn theo năm cho chủ đề này.',
      );
    }

    return CustomPaint(
      painter: _LineChartPainter(
        points: displayed,
        xAxisLabel: xAxisLabel,
        yAxisLabel: yAxisLabel,
        textStyle: Theme.of(context).textTheme.bodySmall,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.points,
    required this.xAxisLabel,
    required this.yAxisLabel,
    required this.textStyle,
  });

  final List<_TrendPoint> points;
  final String xAxisLabel;
  final String yAxisLabel;
  final TextStyle? textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const left = 78.0;
    const right = 18.0;
    const top = 16.0;
    const bottom = 48.0;
    final plotWidth = math.max(1.0, size.width - left - right);
    final plotHeight = math.max(1.0, size.height - top - bottom);
    final plotRect = Rect.fromLTWH(left, top, plotWidth, plotHeight);
    final maxValue = math.max(
      1,
      points.map((point) => point.value).reduce(math.max),
    );

    final backgroundPaint = Paint()
      ..color = AppColors.background.withValues(alpha: 0.42);
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.72)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(plotRect, const Radius.circular(8)),
      backgroundPaint,
    );

    const yTickCount = 5;
    for (var tick = 0; tick < yTickCount; tick++) {
      final ratio = tick / (yTickCount - 1);
      final y = plotRect.bottom - plotRect.height * ratio;
      canvas.drawLine(
        Offset(plotRect.left, y),
        Offset(plotRect.right, y),
        gridPaint,
      );
      _drawText(
        canvas,
        formatCompactNumber(maxValue * ratio),
        Offset(plotRect.left - 10, y),
        maxWidth: 50,
        color: AppColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        anchor: _LineTextAnchor.rightCenter,
      );
    }

    final xDivisor = points.length > 1 ? points.length - 1 : 1;
    final labelStep = math.max(1, points.length ~/ 4);
    for (var index = 0; index < points.length; index++) {
      final x = plotRect.left + plotRect.width * index / xDivisor;
      if (index % labelStep == 0 || index == points.length - 1) {
        canvas.drawLine(
          Offset(x, plotRect.top),
          Offset(x, plotRect.bottom),
          gridPaint,
        );
        _drawText(
          canvas,
          points[index].year.toString(),
          Offset(x, plotRect.bottom + 18),
          maxWidth: 52,
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          anchor: _LineTextAnchor.center,
        );
      }
    }

    canvas
      ..drawLine(plotRect.bottomLeft, plotRect.bottomRight, axisPaint)
      ..drawLine(plotRect.bottomLeft, plotRect.topLeft, axisPaint);

    _drawText(
      canvas,
      xAxisLabel,
      Offset(plotRect.center.dx, size.height - 12),
      maxWidth: 100,
      color: AppColors.textPrimary,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      anchor: _LineTextAnchor.center,
    );
    _drawVerticalText(canvas, yAxisLabel, Offset(10, plotRect.center.dy));

    final offsets = <Offset>[
      for (var index = 0; index < points.length; index++)
        Offset(
          plotRect.left + plotRect.width * index / xDivisor,
          plotRect.bottom - plotRect.height * (points[index].value / maxValue),
        ),
    ];
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
    }

    final linePaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final fillPaint = Paint()..color = AppColors.surface;
    final pointPaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final offset in offsets) {
      canvas
        ..drawCircle(offset, 4, fillPaint)
        ..drawCircle(offset, 4, pointPaint);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double maxWidth,
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    _LineTextAnchor anchor = _LineTextAnchor.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: (textStyle ?? const TextStyle()).copyWith(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth);

    final dx = switch (anchor) {
      _LineTextAnchor.left => offset.dx,
      _LineTextAnchor.center => offset.dx - painter.width / 2,
      _LineTextAnchor.rightCenter => offset.dx - painter.width,
    };
    final dy = anchor == _LineTextAnchor.rightCenter
        ? offset.dy - painter.height / 2
        : offset.dy;
    painter.paint(canvas, Offset(dx, dy));
  }

  void _drawVerticalText(Canvas canvas, String text, Offset center) {
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(-math.pi / 2);
    _drawText(
      canvas,
      text,
      Offset.zero,
      maxWidth: 120,
      color: AppColors.textPrimary,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      anchor: _LineTextAnchor.center,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.xAxisLabel != xAxisLabel ||
        oldDelegate.yAxisLabel != yAxisLabel ||
        oldDelegate.textStyle != textStyle;
  }
}

enum _LineTextAnchor { left, center, rightCenter }

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter(this.points);

  final List<_TrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const left = 8.0;
    const right = 8.0;
    const top = 10.0;
    const bottom = 30.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final maxValue = points.map((point) => point.value).reduce(math.max);
    final minValue = points.map((point) => point.value).reduce(math.min);
    final valueRange = math.max(1, maxValue - minValue);

    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.65)
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
    final xDivisor = points.length > 1 ? points.length - 1 : 1;
    for (var index = 0; index < points.length; index++) {
      final x = left + chartWidth * index / xDivisor;
      final normalized = (points[index].value - minValue) / valueRange;
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

    final pointPaint = Paint()..color = AppColors.surface;
    final pointBorderPaint = Paint()
      ..color = AppColors.chartLine
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final offset in offsets) {
      canvas
        ..drawCircle(offset, 4.2, pointPaint)
        ..drawCircle(offset, 4.2, pointBorderPaint);
    }

    final labelStep = math.max(1, points.length ~/ 4);
    for (var index = 0; index < points.length; index += labelStep) {
      final x = left + chartWidth * index / xDivisor;
      _drawLabel(
        canvas,
        points[index].year.toString(),
        Offset(x, size.height - 18),
        size.width,
      );
    }
    if ((points.length - 1) % labelStep != 0) {
      _drawLabel(
        canvas,
        points.last.year.toString(),
        Offset(left + chartWidth, size.height - 18),
        size.width,
      );
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset origin, double maxWidth) {
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
    final rawDx = origin.dx - painter.width / 2;
    final dx = rawDx
        .clamp(2.0, math.max(2.0, maxWidth - painter.width - 2))
        .toDouble();
    painter.paint(canvas, Offset(dx, origin.dy));
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class ScatterPlot extends StatefulWidget {
  const ScatterPlot({
    super.key,
    required this.points,
    this.xLabel = 'Số bài',
    this.yLabel = 'Trích dẫn',
  });

  final List<ScatterPointData> points;
  final String xLabel;
  final String yLabel;

  @override
  State<ScatterPlot> createState() => _ScatterPlotState();
}

class _ScatterPlotState extends State<ScatterPlot> {
  int? _hoveredIndex;
  int? _selectedIndex;

  int? get _activeIndex => _hoveredIndex ?? _selectedIndex;

  @override
  void didUpdateWidget(covariant ScatterPlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((_hoveredIndex ?? -1) >= widget.points.length) {
      _hoveredIndex = null;
    }
    if ((_selectedIndex ?? -1) >= widget.points.length) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return const AppEmptyState(
        icon: Icons.scatter_plot,
        title: 'Chưa có dữ liệu tác giả',
        message: 'Biểu đồ sẽ cập nhật sau khi có dữ liệu từ OpenAlex.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
          300,
        );

        return SizedBox(
          height: chartSize.height,
          width: double.infinity,
          child: MouseRegion(
            cursor: _activeIndex == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            onHover: (event) {
              final index = _hitTestScatterPoint(
                widget.points,
                chartSize,
                event.localPosition,
              );
              if (index != _hoveredIndex) {
                setState(() => _hoveredIndex = index);
              }
            },
            onExit: (_) {
              if (_hoveredIndex != null) {
                setState(() => _hoveredIndex = null);
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final index = _hitTestScatterPoint(
                  widget.points,
                  chartSize,
                  details.localPosition,
                );
                setState(() {
                  _selectedIndex = _selectedIndex == index ? null : index;
                });
              },
              child: CustomPaint(
                painter: _ScatterPlotPainter(
                  points: widget.points,
                  xLabel: widget.xLabel,
                  yLabel: widget.yLabel,
                  activeIndex: _activeIndex,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScatterPlotPainter extends CustomPainter {
  const _ScatterPlotPainter({
    required this.points,
    required this.xLabel,
    required this.yLabel,
    required this.activeIndex,
  });

  final List<ScatterPointData> points;
  final String xLabel;
  final String yLabel;
  final int? activeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final metrics = _scatterPlotMetrics(size);
    final plotRect = metrics.plotRect;
    final xDomain = _ScatterLogDomain.fromValues(
      points.map((point) => point.x),
    );
    final yDomain = _ScatterLogDomain.fromValues(
      points.map((point) => point.y),
    );

    final axisPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    final backgroundPaint = Paint()
      ..color = AppColors.background.withValues(alpha: 0.45);

    canvas.drawRRect(
      RRect.fromRectAndRadius(plotRect, const Radius.circular(8)),
      backgroundPaint,
    );

    const tickCount = 5;
    for (var index = 0; index < tickCount; index++) {
      final ratio = index / (tickCount - 1);
      final x = plotRect.left + ratio * plotRect.width;
      final y = plotRect.bottom - ratio * plotRect.height;

      canvas
        ..drawLine(
          Offset(x, plotRect.top),
          Offset(x, plotRect.bottom),
          gridPaint,
        )
        ..drawLine(
          Offset(plotRect.left, y),
          Offset(plotRect.right, y),
          gridPaint,
        );

      _drawText(
        canvas,
        formatCompactNumber(xDomain.valueAt(ratio)),
        Offset(x, plotRect.bottom + 18),
        anchor: _ScatterTextAnchor.center,
        maxWidth: 56,
      );
      _drawText(
        canvas,
        formatCompactNumber(yDomain.valueAt(ratio)),
        Offset(plotRect.left - 10, y),
        anchor: _ScatterTextAnchor.right,
        maxWidth: 50,
      );
    }

    canvas
      ..drawLine(plotRect.bottomLeft, plotRect.bottomRight, axisPaint)
      ..drawLine(plotRect.bottomLeft, plotRect.topLeft, axisPaint);

    _drawText(
      canvas,
      '$xLabel (log)',
      Offset(plotRect.center.dx, size.height - 16),
      color: AppColors.textPrimary,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      anchor: _ScatterTextAnchor.center,
      maxWidth: 140,
    );
    _drawRotatedText(canvas, '$yLabel (log)', Offset(18, plotRect.center.dy));

    final plotted = _buildPlottedScatterPoints(points, size);

    final shadowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final pointsToPaint = [...plotted]
      ..sort((a, b) => b.radius.compareTo(a.radius));

    for (final item in pointsToPaint) {
      final fillPaint = Paint()..color = item.color.withValues(alpha: 0.66);
      final borderPaint = Paint()
        ..color = item.color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas
        ..drawCircle(
          item.center.translate(0, 1.5),
          item.radius + 1,
          shadowPaint,
        )
        ..drawCircle(item.center, item.radius, fillPaint)
        ..drawCircle(item.center, item.radius, borderPaint);
    }

    final topCitationPoint = plotted.reduce(
      (current, next) => next.point.y > current.point.y ? next : current,
    );
    _drawTopCitationMarker(canvas, topCitationPoint);

    final currentIndex = activeIndex;
    if (currentIndex != null &&
        currentIndex >= 0 &&
        currentIndex < plotted.length) {
      _drawActivePoint(canvas, plotted[currentIndex], plotRect, size);
    }
  }

  void _drawRotatedText(Canvas canvas, String text, Offset center) {
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(-math.pi / 2);
    _drawText(
      canvas,
      text,
      Offset.zero,
      color: AppColors.textPrimary,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      anchor: _ScatterTextAnchor.center,
      maxWidth: 140,
    );
    canvas.restore();
  }

  void _drawTopCitationMarker(Canvas canvas, _PlottedScatterPoint item) {
    final haloPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final ringPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas
      ..drawCircle(item.center, item.radius + 6, haloPaint)
      ..drawCircle(item.center, item.radius + 3, ringPaint);
  }

  void _drawActivePoint(
    Canvas canvas,
    _PlottedScatterPoint item,
    Rect plotRect,
    Size size,
  ) {
    final activePaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(item.center, item.radius + 6, activePaint);

    final painter = TextPainter(
      text: TextSpan(
        text: item.point.label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
      maxLines: 2,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.min(180, math.max(96, plotRect.width * 0.34)));

    final preferRight = item.center.dx < plotRect.center.dx;
    final rawDx = preferRight
        ? item.center.dx + item.radius + 10
        : item.center.dx - item.radius - painter.width - 10;
    final dx = rawDx
        .clamp(plotRect.left + 6, size.width - painter.width - 6)
        .toDouble();
    final rawDy = item.center.dy - painter.height - item.radius - 10;
    final dy = rawDy
        .clamp(plotRect.top + 6, plotRect.bottom - painter.height - 6)
        .toDouble();
    final tooltipRect = Rect.fromLTWH(
      dx - 8,
      dy - 6,
      painter.width + 16,
      painter.height + 12,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(tooltipRect, const Radius.circular(8)),
      Paint()..color = Colors.white.withValues(alpha: 0.96),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tooltipRect, const Radius.circular(8)),
      Paint()
        ..color = AppColors.secondary.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    painter.paint(canvas, Offset(dx, dy));
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    Color color = AppColors.textSecondary,
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.w700,
    _ScatterTextAnchor anchor = _ScatterTextAnchor.left,
    double maxWidth = 80,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1,
        ),
      ),
      maxLines: 1,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    final dx = switch (anchor) {
      _ScatterTextAnchor.left => offset.dx,
      _ScatterTextAnchor.center => offset.dx - painter.width / 2,
      _ScatterTextAnchor.right => offset.dx - painter.width,
    };
    painter.paint(canvas, Offset(dx, offset.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ScatterPlotPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.xLabel != xLabel ||
        oldDelegate.yLabel != yLabel ||
        oldDelegate.activeIndex != activeIndex;
  }
}

int? _hitTestScatterPoint(
  List<ScatterPointData> points,
  Size size,
  Offset position,
) {
  final plotted = _buildPlottedScatterPoints(points, size);
  var nearestDistance = double.infinity;
  int? nearestIndex;

  for (final item in plotted) {
    final distance = (item.center - position).distance;
    final threshold = math.max(16.0, item.radius + 9);
    if (distance <= threshold && distance < nearestDistance) {
      nearestDistance = distance;
      nearestIndex = item.index;
    }
  }

  return nearestIndex;
}

_ScatterPlotMetrics _scatterPlotMetrics(Size size) {
  const left = 66.0;
  const right = 24.0;
  const top = 20.0;
  const bottom = 58.0;
  final plotWidth = math.max(1.0, size.width - left - right);
  final plotHeight = math.max(1.0, size.height - top - bottom);
  final plotRect = Rect.fromLTWH(left, top, plotWidth, plotHeight);
  final pointRect = plotRect.deflate(
    plotWidth > 60 && plotHeight > 60 ? 14 : 4,
  );
  return _ScatterPlotMetrics(plotRect: plotRect, pointRect: pointRect);
}

List<_PlottedScatterPoint> _buildPlottedScatterPoints(
  List<ScatterPointData> points,
  Size size,
) {
  if (points.isEmpty) {
    return const [];
  }

  final metrics = _scatterPlotMetrics(size);
  final xDomain = _ScatterLogDomain.fromValues(points.map((point) => point.x));
  final yDomain = _ScatterLogDomain.fromValues(points.map((point) => point.y));
  final maxSize = math.max(
    1.0,
    points.map((point) => point.size).reduce(math.max),
  );

  return [
    for (var index = 0; index < points.length; index++)
      _PlottedScatterPoint(
        index: index,
        point: points[index],
        center: Offset(
          metrics.pointRect.left +
              xDomain.normalize(points[index].x) * metrics.pointRect.width,
          metrics.pointRect.bottom -
              yDomain.normalize(points[index].y) * metrics.pointRect.height,
        ),
        radius: 3.0 + math.sqrt(points[index].size / maxSize) * 1.9,
        color: AppColors.secondary,
      ),
  ];
}

class _ScatterPlotMetrics {
  const _ScatterPlotMetrics({required this.plotRect, required this.pointRect});

  final Rect plotRect;
  final Rect pointRect;
}

class _ScatterLogDomain {
  const _ScatterLogDomain(this.minLog, this.maxLog);

  final double minLog;
  final double maxLog;

  factory _ScatterLogDomain.fromValues(Iterable<double> rawValues) {
    final values = rawValues
        .where((value) => value.isFinite)
        .map((value) => math.max(0.0, value))
        .toList(growable: false);

    if (values.isEmpty) {
      return const _ScatterLogDomain(0, 1);
    }

    var minLog = values.map((value) => math.log(value + 1)).reduce(math.min);
    var maxLog = values.map((value) => math.log(value + 1)).reduce(math.max);
    final range = maxLog - minLog;

    if (range.abs() < 0.001) {
      minLog = math.max(0, minLog - 0.5);
      maxLog = maxLog + 0.5;
    } else {
      minLog = math.max(0, minLog - range * 0.08);
      maxLog = maxLog + range * 0.08;
    }

    return _ScatterLogDomain(minLog, maxLog);
  }

  double normalize(double value) {
    final range = maxLog - minLog;
    if (range.abs() < 0.001) {
      return 0.5;
    }
    final logValue = math.log(math.max(0, value) + 1);
    return ((logValue - minLog) / range).clamp(0.0, 1.0).toDouble();
  }

  double valueAt(double ratio) {
    final clampedRatio = ratio.clamp(0.0, 1.0).toDouble();
    return math.max(0, math.exp(minLog + (maxLog - minLog) * clampedRatio) - 1);
  }
}

class _PlottedScatterPoint {
  const _PlottedScatterPoint({
    required this.index,
    required this.point,
    required this.center,
    required this.radius,
    required this.color,
  });

  final int index;
  final ScatterPointData point;
  final Offset center;
  final double radius;
  final Color color;
}

enum _ScatterTextAnchor { left, center, right }

class BubbleChart extends StatelessWidget {
  const BubbleChart({super.key, required this.bubbles});

  final List<BubblePointData> bubbles;

  @override
  Widget build(BuildContext context) {
    if (bubbles.isEmpty) {
      return const AppEmptyState(
        icon: Icons.bubble_chart,
        title: 'Chưa có biên giới nghiên cứu',
        message: 'Các cụm keyword nổi bật sẽ xuất hiện tại đây.',
      );
    }

    final maxValue = bubbles.map((bubble) => bubble.value).reduce(math.max);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (var index = 0; index < bubbles.length; index++)
          _BubbleNode(
            bubble: bubbles[index],
            ratio: maxValue == 0 ? 0 : bubbles[index].value / maxValue,
            color: [
              AppColors.secondary,
              AppColors.chartLine,
              AppColors.accent,
              AppColors.primaryLight,
            ][index % 4],
          ),
      ],
    );
  }
}

class _BubbleNode extends StatelessWidget {
  const _BubbleNode({
    required this.bubble,
    required this.ratio,
    required this.color,
  });

  final BubblePointData bubble;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = 92.0 + ratio * 42.0;
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.42)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bubble.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCompactNumber(bubble.value),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapChart extends StatelessWidget {
  const MapChart({super.key, required this.countries});

  final List<CountryOutput> countries;

  static const _coordinates = <String, LatLng>{
    'US': LatLng(39.8, -98.6),
    'CA': LatLng(56.1, -106.3),
    'MX': LatLng(23.6, -102.5),
    'BR': LatLng(-14.2, -51.9),
    'AR': LatLng(-38.4, -63.6),
    'CL': LatLng(-35.7, -71.5),
    'CO': LatLng(4.6, -74.1),
    'GB': LatLng(55.4, -3.4),
    'FR': LatLng(46.2, 2.2),
    'DE': LatLng(51.2, 10.4),
    'IT': LatLng(41.9, 12.6),
    'ES': LatLng(40.5, -3.7),
    'NL': LatLng(52.1, 5.3),
    'SE': LatLng(60.1, 18.6),
    'NO': LatLng(60.5, 8.5),
    'FI': LatLng(61.9, 25.7),
    'RU': LatLng(61.5, 105.3),
    'TR': LatLng(39.0, 35.2),
    'IR': LatLng(32.4, 53.7),
    'SA': LatLng(23.9, 45.1),
    'EG': LatLng(26.8, 30.8),
    'CN': LatLng(35.9, 104.2),
    'JP': LatLng(36.2, 138.3),
    'KR': LatLng(36.5, 127.8),
    'IN': LatLng(20.6, 78.9),
    'ID': LatLng(-2.5, 118.0),
    'AU': LatLng(-25.3, 133.8),
    'ZA': LatLng(-30.6, 22.9),
    'VN': LatLng(14.1, 108.3),
    'SG': LatLng(1.35, 103.8),
  };

  @override
  Widget build(BuildContext context) {
    if (countries.isEmpty) {
      return const AppEmptyState(
        icon: Icons.public,
        title: 'Chưa có dữ liệu quốc gia',
        message: 'OpenAlex chưa trả về phân bố quốc gia cho bộ lọc này.',
      );
    }

    final topCountries = countries.take(8).toList(growable: false);
    final maxValue = topCountries
        .map((item) => item.worksCount)
        .reduce(math.max);
    final circles = <CircleMarker>[];
    final markers = <Marker>[];

    for (var index = 0; index < topCountries.length; index++) {
      final country = topCountries[index];
      final point = _coordinates[country.countryCode];
      if (point == null) {
        continue;
      }

      final ratio = maxValue == 0 ? 0 : country.worksCount / maxValue;
      final radius = 10.0 + ratio * 20.0;
      final color = [
        AppColors.accent,
        AppColors.secondary,
        AppColors.chartLine,
        AppColors.primaryLight,
      ][index % 4];

      circles.add(
        CircleMarker(
          point: point,
          radius: radius,
          color: color.withValues(alpha: 0.38),
          borderColor: Colors.white.withValues(alpha: 0.85),
          borderStrokeWidth: 2,
        ),
      );
      markers.add(
        Marker(
          point: point,
          width: 48,
          height: 28,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                country.countryCode.isEmpty
                    ? '${index + 1}'
                    : country.countryCode,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: SizedBox(
              height: 280,
              width: double.infinity,
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(18, 12),
                  initialZoom: 1.35,
                  minZoom: 1,
                  maxZoom: 5,
                  interactionOptions: InteractionOptions(
                    flags:
                        InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.journal_trend_analyzer',
                  ),
                  CircleLayer(circles: circles),
                  MarkerLayer(markers: markers),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () async => launchUrl(
                            Uri.parse('https://openstreetmap.org/copyright'),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.7),
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                '© OpenStreetMap contributors',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < math.min(5, topCountries.length); index++)
          RankedBarRow(
            rank: index + 1,
            name: topCountries[index].name,
            value: topCountries[index].worksCount,
            score: maxValue == 0
                ? 0
                : topCountries[index].worksCount / maxValue,
            valueLabel:
                '${formatCompactNumber(topCountries[index].worksCount)} bài',
          ),
      ],
    );
  }
}

String formatDisplayNumber(int value) {
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

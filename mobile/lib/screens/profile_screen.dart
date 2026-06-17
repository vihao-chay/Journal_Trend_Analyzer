import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/search_provider.dart';
import '../widgets/app_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recentCount = context.select<SearchProvider, int>(
      (provider) => provider.recentSearches.length,
    );
    final hasGlobal = context.select<SearchProvider, bool>(
      (provider) => provider.globalOverview != null,
    );

    return ScreenScroll(
      children: [
        const ScreenHeader(
          title: 'Profile',
          subtitle: 'Settings and app information.',
        ),
        const SizedBox(height: AppSpacing.medium),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(icon: Icons.settings, title: 'Settings'),
              const SizedBox(height: 14),
              _SettingRow(
                title: 'Clear recent searches',
                subtitle: '$recentCount saved',
                icon: Icons.history,
                onTap: () => context.read<SearchProvider>().clearRecentSearches(),
              ),
              const Divider(height: 22),
              _SettingRow(
                title: 'Reload OpenAlex overview',
                subtitle: hasGlobal ? 'Tap to refresh' : 'Not loaded yet',
                icon: Icons.refresh,
                onTap: () => context.read<SearchProvider>().loadGlobalOverview(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        const SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(icon: Icons.info_outline, title: 'About'),
              SizedBox(height: 10),
              Text(
                'Journal Trend Analyzer\n'
                'Mobile-first app for exploring OpenAlex works, journals, and trends.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}


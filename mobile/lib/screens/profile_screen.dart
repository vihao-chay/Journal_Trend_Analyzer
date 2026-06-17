import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/search_provider.dart';
import '../widgets/app_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final recentCount = provider.recentSearches.length;
    final hasGlobal = provider.globalOverview != null;

    return ScreenScroll(
      children: [
        const ScreenHeader(
          title: 'Hồ sơ',
          subtitle: 'Thiết lập trải nghiệm phân tích nghiên cứu.',
          badge: 'Settings',
        ),
        const SizedBox(height: AppSpacing.medium),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.person_outline,
                title: 'User settings',
              ),
              const SizedBox(height: 14),
              _SettingRow(
                title: 'Xóa tìm kiếm gần đây',
                subtitle: '$recentCount mục đã lưu',
                icon: Icons.history,
                onTap: () =>
                    context.read<SearchProvider>().clearRecentSearches(),
              ),
              const Divider(height: 22),
              _SettingRow(
                title: 'Tải lại tổng quan OpenAlex',
                subtitle: hasGlobal
                    ? 'Dữ liệu đã sẵn sàng'
                    : 'Chưa tải dữ liệu',
                icon: Icons.refresh,
                onTap: () =>
                    context.read<SearchProvider>().loadGlobalOverview(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        const SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                icon: Icons.palette_outlined,
                title: 'Theme settings',
              ),
              SizedBox(height: 14),
              _ThemeOption(
                title: 'Light academic',
                subtitle: 'Nền trắng, accent xanh mềm, typography rõ ràng',
                icon: Icons.light_mode_outlined,
                selected: true,
              ),
              Divider(height: 22),
              _ThemeOption(
                title: 'Dashboard cards',
                subtitle: 'Card bo góc, biểu đồ gọn, ưu tiên khả năng đọc',
                icon: Icons.dashboard_customize_outlined,
                selected: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        FilterPanel(
          filters: provider.filters,
          onApply: (filters) => context.read<SearchProvider>().updateFilters(
            filters,
            rerunSearch: provider.hasSearched,
          ),
          onReset: () => context.read<SearchProvider>().resetFilters(
            rerunSearch: provider.hasSearched,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        const SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(icon: Icons.info_outline, title: 'Về website'),
              SizedBox(height: 12),
              Text(
                'OpenAlex Research Analytics giúp sinh viên và nhà nghiên cứu tìm chủ đề, đọc publication, phân tích journal, tác giả, quốc gia và keyword frontier.',
              ),
              SizedBox(height: 12),
              MetricPill(
                label: 'Data source: OpenAlex',
                icon: Icons.dataset_outlined,
                accentColor: AppColors.chartLine,
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
            _SettingIcon(icon: icon),
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

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SettingIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Icon(
          selected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: selected ? AppColors.success : AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

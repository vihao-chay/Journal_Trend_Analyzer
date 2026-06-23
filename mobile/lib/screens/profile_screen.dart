import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/search_provider.dart';
import '../providers/theme_provider.dart';
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
    final isGlobalLoading = context.select<SearchProvider, bool>(
      (provider) => provider.isGlobalLoading,
    );
    final globalError = context.select<SearchProvider, String?>(
      (provider) => provider.globalError,
    );
    final themeProvider = context.watch<ThemeProvider>();

    return ScreenScroll(
      children: [
        const ScreenHeader(
          title: 'Hồ sơ',
          subtitle: 'Thiết lập trải nghiệm phân tích nghiên cứu.',
          badge: 'Cài đặt',
        ),
        const SizedBox(height: AppSpacing.medium),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.person_outline,
                title: 'Cài đặt người dùng',
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
                subtitle: isGlobalLoading
                    ? 'Đang tải dữ liệu mới từ OpenAlex...'
                    : globalError != null
                    ? 'Lần tải gần nhất thất bại'
                    : hasGlobal
                    ? 'Dữ liệu đã sẵn sàng - nhấn để tải lại'
                    : 'Chưa tải dữ liệu',
                icon: Icons.refresh,
                isLoading: isGlobalLoading,
                onTap: isGlobalLoading
                    ? null
                    : () => _reloadGlobalOverview(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.palette_outlined,
                title: 'Giao diện',
              ),
              const SizedBox(height: 16),
              Text(
                'Chế độ hiển thị',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Sáng'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Tối'),
                    ),
                  ],
                  selected: {themeProvider.themeMode},
                  onSelectionChanged: (selection) {
                    themeProvider.setThemeMode(selection.first);
                  },
                ),
              ),
              const Divider(height: 28),
              Text(
                'Màu chủ đạo',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  for (final accent in AppAccent.values)
                    _AccentSwatch(
                      accent: accent,
                      selected: themeProvider.accent == accent,
                      onTap: () => themeProvider.setAccent(accent),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        const SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(icon: Icons.info_outline, title: 'Giới thiệu'),
              SizedBox(height: 12),
              Text(
                'Ứng dụng phân tích nghiên cứu OpenAlex giúp sinh viên và nhà nghiên cứu tìm chủ đề, đọc bài báo, phân tích tạp chí, tác giả, quốc gia và xu hướng từ khóa.',
              ),
              SizedBox(height: 12),
              MetricPill(
                label: 'Nguồn dữ liệu: OpenAlex',
                icon: Icons.dataset_outlined,
                accentColor: AppColors.chartLine,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _reloadGlobalOverview(BuildContext context) async {
    final provider = context.read<SearchProvider>();
    await provider.loadGlobalOverview();
    if (!context.mounted) {
      return;
    }

    final error = provider.globalError;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error ?? 'Đã tải lại dữ liệu tổng quan OpenAlex.'),
        ),
      );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final AppAccent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: accent.label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Semantics(
          button: true,
          selected: selected,
          label: accent.label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white.withValues(alpha: 0.75),
                width: selected ? 3 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.color.withValues(alpha: 0.26),
                  blurRadius: selected ? 10 : 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 22)
                : null,
          ),
        ),
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: colors.primary, size: 20),
    );
  }
}

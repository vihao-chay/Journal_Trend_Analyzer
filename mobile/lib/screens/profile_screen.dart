import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../models/auth_user.dart';
import '../providers/auth_provider.dart';
import '../providers/search_provider.dart';
import '../providers/theme_provider.dart';
import '../viewmodels/firebase_features_view_model.dart';
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
    final authProvider = context.watch<AuthProvider>();
    final firebaseFeatures = context.watch<FirebaseFeaturesViewModel>();

    return ScreenScroll(
      children: [
        const ScreenHeader(
          title: 'Hồ sơ',
          subtitle: 'Thiết lập trải nghiệm phân tích nghiên cứu.',
          badge: 'Cài đặt',
        ),
        const SizedBox(height: AppSpacing.medium),
        SectionCard(child: _UserAccountCard(user: authProvider.user)),
        const SizedBox(height: AppSpacing.medium),
        _FirebaseStatusCard(firebaseFeatures: firebaseFeatures),
        const SizedBox(height: AppSpacing.medium),
        _RemoteConfigCard(firebaseFeatures: firebaseFeatures),
        const SizedBox(height: AppSpacing.medium),
        _FirebaseActionsCard(
          firebaseFeatures: firebaseFeatures,
          onExportPdf: () => _exportPdf(context),
          onRecordHandledException: () => _recordHandledException(context),
          onForceCrash: firebaseFeatures.forceTestCrash,
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
        const SizedBox(height: AppSpacing.medium),
        SectionCard(
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('profile_bottom_logout_button'),
              onPressed: authProvider.isSigningOut
                  ? null
                  : () => _signOut(context),
              icon: authProvider.isSigningOut
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.logout),
              label: Text(
                authProvider.isSigningOut ? 'Đang đăng xuất...' : 'Đăng xuất',
              ),
            ),
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

  Future<void> _signOut(BuildContext context) async {
    final provider = context.read<AuthProvider>();
    final firebaseFeatures = context.read<FirebaseFeaturesViewModel>();
    await firebaseFeatures.trackLogout();
    await provider.signOut();
    if (!context.mounted) {
      return;
    }

    final error = provider.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final searchProvider = context.read<SearchProvider>();
    final firebaseFeatures = context.read<FirebaseFeaturesViewModel>();
    final data = DashboardReportData(
      topic: searchProvider.keyword ?? 'OpenAlex overview',
      totalPublications: searchProvider.hasSearched
          ? searchProvider.publicationTotalCount
          : searchProvider.globalOverview?.totalWorks ?? 0,
      averageCitations: searchProvider.searchAverageCitations,
      topJournals:
          (searchProvider.hasSearched
                  ? searchProvider.topJournals
                  : searchProvider.globalOverview?.topJournals ?? const [])
              .map((journal) => journal.displayName)
              .toList(growable: false),
      topKeywords:
          (searchProvider.hasSearched
                  ? searchProvider.keywordFrontiers
                  : searchProvider.globalOverview?.trendingKeywords ?? const [])
              .map((keyword) => keyword.displayName)
              .toList(growable: false),
      recentSearches: searchProvider.recentSearches,
    );

    final url = await firebaseFeatures.exportReportPdf(data);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            url == null
                ? firebaseFeatures.errorMessage ?? 'Xuất PDF thất bại.'
                : 'Đã xuất PDF và upload lên Firebase Storage.',
          ),
        ),
      );
  }

  Future<void> _recordHandledException(BuildContext context) async {
    await context.read<FirebaseFeaturesViewModel>().recordHandledException();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Đã gửi non-fatal exception lên Crashlytics.'),
        ),
      );
  }
}

class _FirebaseStatusCard extends StatelessWidget {
  const _FirebaseStatusCard({required this.firebaseFeatures});

  final FirebaseFeaturesViewModel firebaseFeatures;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final token = firebaseFeatures.fcmToken;
    return SectionCard(
      key: const ValueKey('profile_firebase_status_card'),
      accentColor: firebaseFeatures.isFirebaseAvailable
          ? AppColors.secondary
          : AppColors.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.cloud_done_outlined,
            title: 'Firebase Lab 03',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MetricPill(
                label: firebaseFeatures.isFirebaseAvailable
                    ? 'Firebase sẵn sàng'
                    : 'Firebase chưa sẵn sàng',
                icon: firebaseFeatures.isFirebaseAvailable
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
                accentColor: firebaseFeatures.isFirebaseAvailable
                    ? AppColors.secondary
                    : AppColors.error,
              ),
              MetricPill(
                label: firebaseFeatures.notificationPermissionLabel == null
                    ? 'FCM đang khởi tạo'
                    : 'FCM: ${firebaseFeatures.notificationPermissionLabel}',
                icon: Icons.mark_email_read_outlined,
                accentColor: AppColors.accent,
              ),
            ],
          ),
          if (firebaseFeatures.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              firebaseFeatures.errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (token != null && token.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('profile_copy_fcm_token_button'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: token));
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Đã copy FCM token.')),
                    );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy FCM token'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RemoteConfigCard extends StatelessWidget {
  const _RemoteConfigCard({required this.firebaseFeatures});

  final FirebaseFeaturesViewModel firebaseFeatures;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const ValueKey('profile_remote_config_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(icon: Icons.tune, title: 'Remote Config'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MetricPill(
                label:
                    'max_journals/max_journal = ${firebaseFeatures.maxJournals}',
                icon: Icons.library_books_outlined,
              ),
              MetricPill(
                label:
                    'max_keywords/max_keyword = ${firebaseFeatures.maxKeywords}',
                icon: Icons.tag_outlined,
                accentColor: AppColors.chartLine,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('profile_refresh_remote_config_button'),
              onPressed: firebaseFeatures.isRemoteConfigLoading
                  ? null
                  : () async {
                      await firebaseFeatures.refreshRemoteConfig();
                      if (!context.mounted) {
                        return;
                      }
                      await context.read<SearchProvider>().loadGlobalOverview();
                    },
              icon: firebaseFeatures.isRemoteConfigLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Tải lại Remote Config'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FirebaseActionsCard extends StatelessWidget {
  const _FirebaseActionsCard({
    required this.firebaseFeatures,
    required this.onExportPdf,
    required this.onRecordHandledException,
    required this.onForceCrash,
  });

  final FirebaseFeaturesViewModel firebaseFeatures;
  final VoidCallback onExportPdf;
  final VoidCallback onRecordHandledException;
  final Future<void> Function() onForceCrash;

  @override
  Widget build(BuildContext context) {
    final exportUrl = firebaseFeatures.lastExportedUrl;
    return SectionCard(
      key: const ValueKey('profile_firebase_actions_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Storage PDF & Crashlytics',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('profile_export_pdf_button'),
              onPressed: firebaseFeatures.isExporting ? null : onExportPdf,
              icon: firebaseFeatures.isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                firebaseFeatures.isExporting
                    ? 'Đang xuất PDF...'
                    : 'Xuất PDF và upload Storage',
              ),
            ),
          ),
          if (exportUrl != null && exportUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('profile_open_exported_pdf_button'),
              onPressed: () {
                final uri = Uri.tryParse(exportUrl);
                if (uri != null && uri.hasScheme) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Mở PDF đã upload'),
            ),
          ],
          const Divider(height: 26),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('profile_test_crashlytics_button'),
                  onPressed: onRecordHandledException,
                  icon: const Icon(Icons.bug_report_outlined),
                  label: const Text('Gửi non-fatal'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('profile_force_crash_button'),
                  onPressed: () {
                    onForceCrash();
                  },
                  icon: const Icon(Icons.warning_amber_outlined),
                  label: const Text('Test crash'),
                ),
              ),
            ],
          ),
          if (firebaseFeatures.lastPdfPath != null) ...[
            const SizedBox(height: 12),
            Text(
              'PDF local: ${firebaseFeatures.lastPdfPath}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
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

class _UserAccountCard extends StatelessWidget {
  const _UserAccountCard({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentUser = user;

    return Row(
      children: [
        _UserAvatar(user: currentUser),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentUser?.nameOrEmail ?? 'Chưa đăng nhập',
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                currentUser?.email ?? 'Chưa có email',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final photoUrl = user?.photoUrl;
    return CircleAvatar(
      radius: 32,
      backgroundColor: colors.primary.withValues(alpha: 0.12),
      backgroundImage: photoUrl == null || photoUrl.trim().isEmpty
          ? null
          : NetworkImage(photoUrl),
      child: photoUrl == null || photoUrl.trim().isEmpty
          ? Text(
              user?.initials ?? 'U',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
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

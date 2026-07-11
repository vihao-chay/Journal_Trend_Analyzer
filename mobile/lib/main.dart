import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/search_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_gate.dart';
import 'screens/home_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/keywords_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/app_widgets.dart';
import 'services/remote_config_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/dashboard_provider.dart';
import 'providers/detail_provider.dart';
import 'firebase/firebase_options.dart';
import 'viewmodels/journals_viewmodel.dart';
import 'viewmodels/keywords_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 1. Khởi tạo Firebase nền tảng (Của Dev 1 cấu hình)
  await Firebase.initializeApp(
    options: AppFirebaseOptions.currentPlatform,
  );
  
  // 2. Khởi tạo Remote Config của bạn (Dev 2)
  final remoteConfigService = RemoteConfigService();
  await remoteConfigService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.searchProvider,
    this.themeProvider,
    this.authProvider,
    
  });

  final SearchProvider? searchProvider;
  final ThemeProvider? themeProvider;
  final AuthProvider? authProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => searchProvider ?? SearchProvider(),
        ),
        ChangeNotifierProvider(create: (_) => themeProvider ?? ThemeProvider()),
        ChangeNotifierProvider(create: (_) => authProvider ?? AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()), // Bộ não thống kê
        ChangeNotifierProvider(create: (_) => DetailProvider()),    // Bộ xử lý chi tiết & DOI
        ChangeNotifierProvider(create: (_) => JournalsViewModel()),
        ChangeNotifierProvider(create: (_) => KeywordsViewModel()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Phân tích xu hướng học thuật',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightThemeFor(themeProvider.seedColor),
          darkTheme: AppTheme.darkThemeFor(themeProvider.seedColor),
          themeMode: themeProvider.themeMode,
          home: const AuthGate(child: ResearchAnalyticsShell()),
        ),
      ),
    );
  }
}

class ResearchAnalyticsShell extends StatefulWidget {
  const ResearchAnalyticsShell({super.key});

  @override
  State<ResearchAnalyticsShell> createState() => _ResearchAnalyticsShellState();
}

class _ResearchAnalyticsShellState extends State<ResearchAnalyticsShell> {
  int _selectedIndex = 0;

  static const _pages = [
    HomeScreen(),
    JournalScreen(),
    KeywordsScreen(),
    ProfileScreen(),
  ];

  static const _items = [
    _NavigationItem(
      label: 'Trang chủ',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _NavigationItem(
      label: 'Tạp chí',
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books,
    ),
    _NavigationItem(
      label: 'Từ khóa',
      icon: Icons.tag_outlined,
      selectedIcon: Icons.tag,
    ),
    _NavigationItem(
      label: 'Hồ sơ',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 900;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: const GradientAppBar(),
          body: useRail
              ? _DesktopBody(
                  selectedIndex: _selectedIndex,
                  onSelected: _selectTab,
                  pages: _pages,
                  items: _items,
                  extended: constraints.maxWidth >= 1120,
                )
              : IndexedStack(index: _selectedIndex, children: _pages),
          bottomNavigationBar: useRail
              ? null
              : _MobileNavigation(
                  selectedIndex: _selectedIndex,
                  onSelected: _selectTab,
                  items: _items,
                ),
        );
      },
    );
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _DesktopBody extends StatelessWidget {
  const _DesktopBody({
    required this.selectedIndex,
    required this.onSelected,
    required this.pages,
    required this.items,
    required this.extended,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<Widget> pages;
  final List<_NavigationItem> items;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(3, 0),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              extended: extended,
              backgroundColor: Theme.of(context).colorScheme.surface,
              indicatorColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.14),
              selectedIconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.primary,
              ),
              unselectedIconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              selectedLabelTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              destinations: [
                for (final item in items)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(index: selectedIndex, children: pages),
        ),
      ],
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<_NavigationItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/search_provider.dart';
import 'screens/home_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/keywords_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/app_widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.searchProvider});

  final SearchProvider? searchProvider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => searchProvider ?? SearchProvider(),
      child: MaterialApp(
        title: 'OpenAlex Research Analytics',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const ResearchAnalyticsShell(),
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
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _NavigationItem(
      label: 'Journal',
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books,
    ),
    _NavigationItem(
      label: 'Keywords',
      icon: Icons.tag_outlined,
      selectedIcon: Icons.tag,
    ),
    _NavigationItem(
      label: 'Profile',
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
          backgroundColor: AppColors.background,
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
            color: AppColors.surface,
            border: const Border(right: BorderSide(color: AppColors.border)),
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
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.secondary.withValues(alpha: 0.12),
              selectedIconTheme: const IconThemeData(
                color: AppColors.secondary,
              ),
              unselectedIconTheme: const IconThemeData(
                color: AppColors.textSecondary,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: AppColors.textSecondary,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
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

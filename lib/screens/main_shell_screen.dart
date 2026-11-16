import 'dart:ui';

import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/ios_pressable.dart';
import 'cart_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';

/// Root navigation shell hosting the frosted iOS bottom navigation bar.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  final PageStorageBucket _bucket = PageStorageBucket();
  final ValueNotifier<LibraryFilter> _libraryFilter =
      ValueNotifier<LibraryFilter>(LibraryFilter.all);

  int _currentIndex = 0;

  @override
  void dispose() {
    _libraryFilter.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  void _openCategoryInCatalog(String category) {
    AppScope.read(context).catalog.setCategory(category);
    _selectTab(0);
  }

  void _openLibraryWithFilter(LibraryFilter filter) {
    _libraryFilter.value = filter;
    _selectTab(2);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    const barContentHeight = 62.0;
    final totalBarHeight = barContentHeight + bottomSafe;

    final activePage = switch (_currentIndex) {
      0 => HomeScreen(
        key: const ValueKey<int>(0),
        bottomPadding: totalBarHeight + 20,
      ),
      1 => ExploreScreen(
        key: const ValueKey<int>(1),
        bottomPadding: totalBarHeight + 20,
        onSelectCategoryInCatalog: _openCategoryInCatalog,
      ),
      2 => LibraryScreen(
        key: const ValueKey<int>(2),
        filterNotifier: _libraryFilter,
        bottomPadding: totalBarHeight + 20,
        onBrowseCatalog: () => _selectTab(0),
      ),
      3 => CartScreen(
        key: const ValueKey<int>(3),
        embeddedBottomPadding: barContentHeight,
        onReturnHome: () => _selectTab(0),
      ),
      _ => ProfileScreen(
        key: const ValueKey<int>(4),
        bottomPadding: totalBarHeight + 20,
        onOpenLibraryFilter: _openLibraryWithFilter,
        onOpenBasketTab: () => _selectTab(3),
      ),
    };

    return Scaffold(
      extendBody: true,
      body: PageStorage(
        bucket: _bucket,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: activePage,
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: scope.cart,
        builder: (context, _) {
          return _FrostedIOSTabBar(
            currentIndex: _currentIndex,
            basketCount: scope.cart.count,
            onSelect: _selectTab,
          );
        },
      ),
    );
  }
}

class _FrostedIOSTabBar extends StatelessWidget {
  const _FrostedIOSTabBar({
    required this.currentIndex,
    required this.basketCount,
    required this.onSelect,
  });

  final int currentIndex;
  final int basketCount;
  final ValueChanged<int> onSelect;

  static const _items = <({String label, IconData icon, IconData activeIcon})>[
    (label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
    (
      label: 'Explore',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
    ),
    (
      label: 'Library',
      icon: Icons.bookmarks_outlined,
      activeIcon: Icons.bookmarks_rounded,
    ),
    (
      label: 'Basket',
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag_rounded,
    ),
    (
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(color: colors.hairlineBorder, width: 0.7),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: _TabBarItem(
                        label: _items[i].label,
                        icon: _items[i].icon,
                        activeIcon: _items[i].activeIcon,
                        selected: currentIndex == i,
                        badgeCount: i == 3 ? basketCount : 0,
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBarItem extends StatelessWidget {
  const _TabBarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;
    final fg = selected ? colors.ink : colors.mutedText;

    return Semantics(
      selected: selected,
      child: IOSPressable(
        onTap: onTap,
        pressedScale: 0.90,
        pressedOpacity: 0.7,
        semanticLabel: '$label tab',
        child: SizedBox(
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(selected ? activeIcon : icon, size: 24, color: fg),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 17,
                          minHeight: 17,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

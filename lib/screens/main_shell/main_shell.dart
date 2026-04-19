import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../navigation/app_router.dart';

class _NavItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const _navItems = [
  _NavItem(
    route: AppRoutes.dashboard,
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
  ),
  _NavItem(
    route: AppRoutes.tasks,
    icon: Icons.check_box_outlined,
    activeIcon: Icons.check_box_rounded,
    label: 'Tasks',
  ),
  _NavItem(
    route: AppRoutes.habits,
    icon: Icons.loop_outlined,
    activeIcon: Icons.loop_rounded,
    label: 'Habits',
  ),
  _NavItem(
    route: AppRoutes.focus,
    icon: Icons.timer_outlined,
    activeIcon: Icons.timer_rounded,
    label: 'Focus',
  ),
  _NavItem(
    route: AppRoutes.analytics,
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
    label: 'Stats',
  ),
];

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: _navItems.map((item) {
                final isActive = location == item.route ||
                    (item.route != AppRoutes.dashboard &&
                        location.startsWith(item.route));
                return Expanded(
                  child: _NavBarItem(
                    item: item,
                    isActive: isActive,
                    onTap: () => context.go(item.route),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primarySurface
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              isActive ? item.activeIcon : item.icon,
              size: 22,
              color: isActive
                  ? AppColors.primary
                  : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textTertiary,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ],
      ),
    );
  }
}

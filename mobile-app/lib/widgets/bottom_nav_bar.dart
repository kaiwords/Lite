import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LiteratureBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  const LiteratureBottomNavBar({super.key, required this.currentIndex});

  static const _tabs = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', path: '/'),
    _NavItem(icon: Icons.headphones_outlined, activeIcon: Icons.headphones_rounded, label: 'Audio', path: '/audio'),
    _NavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Market', path: '/marketplace'),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: 'Alerts', path: '/alerts'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', path: '/profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => context.go(tab.path),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? tab.activeIcon : tab.icon,
                        color: isActive ? activeColor : inactiveColor,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive ? activeColor : inactiveColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}

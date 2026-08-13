import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

const _tabs = [
  _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', path: '/'),
  _NavItem(icon: Icons.headphones_outlined, activeIcon: Icons.headphones_rounded, label: 'Audio', path: '/audio'),
  _NavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Market', path: '/marketplace'),
  _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: 'Alerts', path: '/alerts'),
  _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', path: '/profile'),
];

class LiteratureBottomNavBar extends ConsumerStatefulWidget {
  final int currentIndex;
  // Called instead of navigating when the already-active tab is tapped
  // again — e.g. Home/Audio use this to scroll to top and refresh, the way
  // most feed apps treat a second tap on the current tab.
  final VoidCallback? onSameTabTap;
  const LiteratureBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onSameTabTap,
  });

  @override
  ConsumerState<LiteratureBottomNavBar> createState() =>
      _LiteratureBottomNavBarState();
}

class _LiteratureBottomNavBarState extends ConsumerState<LiteratureBottomNavBar>
    with SingleTickerProviderStateMixin {
  // Each screen builds its own fresh nav bar instance (there's no persistent
  // shell keeping one alive across navigations), so this can't slide between
  // tabs — instead the active tab plays a little "pop" the moment the bar
  // mounts, giving every screen landing a small sense of motion rather than
  // a static, inert bar.
  late final AnimationController _popCtrl;

  // Which tab is currently being pressed, for the tactile scale-down effect.
  int? _pressedIndex;

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final activeBg = activeColor.withValues(alpha: isDark ? 0.18 : 0.10);

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
              final isActive = i == widget.currentIndex;
              final isPressed = _pressedIndex == i;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => setState(() => _pressedIndex = i),
                  onTapCancel: () => setState(() => _pressedIndex = null),
                  onTapUp: (_) => setState(() => _pressedIndex = null),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (isActive && widget.onSameTabTap != null) {
                      widget.onSameTabTap!();
                    } else {
                      context.go(tab.path);
                    }
                  },
                  child: AnimatedScale(
                    scale: isPressed ? 0.88 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: AnimatedBuilder(
                      animation: _popCtrl,
                      builder: (context, _) {
                        // Monotonic 0→1 fade/grow for the pill background;
                        // a springy overshoot-then-settle for the icon so
                        // landing on a tab feels like it "arrives" rather
                        // than just appearing.
                        final entrance = Curves.easeOut.transform(_popCtrl.value);
                        final bounce = Curves.easeOutBack.transform(_popCtrl.value);
                        final iconScale = isActive ? (0.6 + 0.4 * bounce) : 1.0;
                        final pillOpacity = isActive ? entrance : 0.0;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: activeBg.withValues(
                                  alpha: activeBg.a * pillOpacity,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Transform.scale(
                                scale: iconScale,
                                child: Icon(
                                  isActive ? tab.activeIcon : tab.icon,
                                  color: isActive ? activeColor : inactiveColor,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: GoogleFonts.lato(
                                fontSize: 10,
                                fontWeight:
                                    isActive ? FontWeight.w700 : FontWeight.w400,
                                color: isActive ? activeColor : inactiveColor,
                              ),
                              child: Text(tab.label),
                            ),
                          ],
                        );
                      },
                    ),
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

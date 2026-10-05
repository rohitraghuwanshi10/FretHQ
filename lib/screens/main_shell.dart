import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_layout.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';
import 'tuner_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  final int initialTabIndex;

  const MainShell({super.key, this.initialTabIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const HomeScreen(isEmbedded: true),
    const TunerScreen(isEmbedded: true),
    const AnalyticsScreen(isEmbedded: true),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Row(
          children: [
            _buildDesktopSidebar(),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.borderSubtle
                  : AppColors.lightBorderSubtle,
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  // ==========================================
  // --- DESKTOP SIDEBAR NAVIGATION ---
  // ==========================================
  Widget _buildDesktopSidebar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final sidebarBg = isDark ? AppColors.surface : AppColors.lightSurface;

    return Container(
      width: 240,
      color: sidebarBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                  ),
                  child: const Icon(Icons.music_note_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FRET HQ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Mastery & Practice',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Navigation Links
          _buildSidebarNavItem(0, Icons.fitness_center_rounded, 'Train & Practice', AppColors.primary),
          const SizedBox(height: 6),
          _buildSidebarNavItem(1, Icons.tune_rounded, 'Tools & Tuner', AppColors.cyan),
          const SizedBox(height: 6),
          _buildSidebarNavItem(2, Icons.insights_rounded, 'Analytics', AppColors.purple),
          const SizedBox(height: 6),
          _buildSidebarNavItem(3, Icons.settings_rounded, 'Settings', AppColors.emerald),

          const Spacer(),

          // Theme Toggle & App Info at Bottom
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService.themeModeNotifier,
            builder: (context, mode, _) {
              final isCurrentDark = Theme.of(context).brightness == Brightness.dark;
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ThemeService.setThemeMode(isCurrentDark ? ThemeMode.light : ThemeMode.dark);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCurrentDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        size: 18,
                        color: isCurrentDark ? AppColors.gold : AppColors.purple,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isCurrentDark ? 'Light Theme' : 'Dark Theme',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'v1.0.0 • Desktop Edition',
              style: TextStyle(fontSize: 10, color: textSecondary.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(int index, IconData icon, String label, Color activeColor) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextSecondary;

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.35) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? textPrimary : textMuted,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // --- MOBILE FLOATING BOTTOM BAR ---
  // ==========================================
  Widget _buildFloatingNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.surfaceGlass : AppColors.lightSurfaceGlass;
    final navBorder = isDark ? AppColors.borderMedium : AppColors.lightBorderMedium;
    final navShadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0x1F0F172A),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ];

    return SafeArea(
      child: SizedBox(
        height: 76,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              height: 56,
              decoration: BoxDecoration(
                color: navBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: navBorder, width: 1.0),
                boxShadow: navShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.fitness_center_rounded, 'Train', AppColors.primary),
                      _buildNavItem(1, Icons.tune_rounded, 'Tools', AppColors.cyan),
                      _buildNavItem(2, Icons.insights_rounded, 'Analytics', AppColors.purple),
                      _buildNavItem(3, Icons.settings_rounded, 'Settings', AppColors.emerald),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color activeColor) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : (isDark ? AppColors.textMuted : AppColors.lightTextSecondary),
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

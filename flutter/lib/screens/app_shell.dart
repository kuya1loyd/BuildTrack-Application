import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/motion.dart';
import 'home_screen.dart';
import 'materials_screen.dart';
import 'more_screen.dart';
import 'project_detail_screen.dart';
import 'projects_screen.dart';
import 'tasks_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _reloadToken = 0;

  static const _tabs = <({String label, IconData icon, IconData activeIcon})>[
    (label: 'Home', icon: Ionicons.home_outline, activeIcon: Ionicons.home),
    (
      label: 'Projects',
      icon: Ionicons.business_outline,
      activeIcon: Ionicons.business,
    ),
    (
      label: 'Tasks',
      icon: Ionicons.checkbox_outline,
      activeIcon: Ionicons.checkbox,
    ),
    (
      label: 'Materials',
      icon: Ionicons.cube_outline,
      activeIcon: Ionicons.cube,
    ),
    (label: 'More', icon: Ionicons.grid_outline, activeIcon: Ionicons.grid),
  ];

  void _openProject(Project project) {
    Navigator.of(context).push(
      FadeThroughPageRoute(page: ProjectDetailScreen(projectId: project.id)),
    );
  }

  void _selectTab(int index) {
    context.read<AppState>().noteActivity();
    if (index == _index) return;
    // Bumping the token makes the newly visible tab reload its rows from the
    // database instead of showing stale state.
    setState(() {
      _index = index;
      _reloadToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final screens = [
      HomeScreen(
        onOpenTab: _selectTab,
        onOpenProject: _openProject,
        reloadToken: _reloadToken,
        active: _index == 0,
      ),
      ProjectsScreen(reloadToken: _reloadToken, active: _index == 1),
      TasksScreen(reloadToken: _reloadToken, active: _index == 2),
      MaterialsScreen(reloadToken: _reloadToken, active: _index == 3),
      MoreScreen(
        onSignOut: widget.onSignOut,
        onOpenTab: _selectTab,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: _BottomBar(
        tabs: _tabs,
        activeIndex: _index,
        taskBadge: state.tasks
            .where(
              (t) => t.bucket == 'today' && t.status != TaskStatus.completed,
            )
            .length,
        onTap: _selectTab,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.tabs,
    required this.activeIndex,
    required this.onTap,
    required this.taskBadge,
  });

  final List<({String label, IconData icon, IconData activeIcon})> tabs;
  final int activeIndex;
  final ValueChanged<int> onTap;
  final int taskBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    label: tabs[i].label,
                    icon: tabs[i].icon,
                    activeIcon: tabs[i].activeIcon,
                    active: activeIndex == i,
                    badge: i == 2 && taskBadge > 0 ? taskBadge : null,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final int? badge;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final CurvedAnimation _popCurve = CurvedAnimation(
    parent: _pop,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _popCurve.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pop.forward(from: 0);
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: widget.active ? AppColors.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: _popCurve,
                  builder: (context, child) => Transform.scale(
                    scale: 1 + 0.2 * (1 - _popCurve.value),
                    child: child,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.active ? widget.activeIcon : widget.icon,
                      key: ValueKey(widget.active),
                      size: 22,
                      color: widget.active
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                if (widget.badge != null)
                  Positioned(
                    top: -5,
                    right: -8,
                    child: _Badge(count: widget.badge!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: widget.active ? FontWeight.w800 : FontWeight.w600,
              color: widget.active ? AppColors.primary : AppColors.textMuted,
            ),
            child: Text(widget.label),
          ),
        ],
      ),
    ),
  );
}
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

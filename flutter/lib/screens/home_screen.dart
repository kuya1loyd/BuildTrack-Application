import 'package:flutter/material.dart' hide Material;
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../data/repositories.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/domain.dart';
import '../widgets/motion.dart';
import '../widgets/sheets.dart';
import '../widgets/ui.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'project_detail_screen.dart';
import 'reports_screen.dart';

/// Home dashboard — executive command center.
/// Renders live metrics, the active project hero card, fast shortcuts,
/// today's priorities, and weekly velocity charts straight from the database.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenTab,
    required this.onOpenProject,
    this.reloadToken = 0,
    this.active = true,
  });

  final ValueChanged<int> onOpenTab;
  final ValueChanged<Project> onOpenProject;
  final int reloadToken;
  final bool active;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Project> _projects = [];
  final List<Task> _tasks = [];
  final List<Material> _materials = [];
  final List<TeamMember> _team = [];
  Map<String, int> _weeklyCompletions = const {};
  String? _selectedProjectId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && oldWidget.reloadToken != widget.reloadToken) {
      _load();
    }
  }

  Future<void> _load() async {
    final user = context.read<AppState>().user;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    // Sequential fetches to protect pool budget on remote db.
    final projects = await ProjectsRepository.instance.fetchForUser(user.id);
    final tasks = await TasksRepository.instance.fetchForUser(user.id);
    final materials = await MaterialsRepository.instance.fetchForUser(user.id);
    final team = await TeamRepository.instance.fetchForUser(user.id);
    final weekly = await StatsRepository.instance.weeklyCompletions(user.id);
    if (!mounted) return;
    setState(() {
      _projects
        ..clear()
        ..addAll(projects);
      _tasks
        ..clear()
        ..addAll(tasks);
      _materials
        ..clear()
        ..addAll(materials);
      _team
        ..clear()
        ..addAll(team);
      _weeklyCompletions = weekly;
      _loading = false;
    });
  }

  Project? get _selectedProject {
    if (_projects.isEmpty) return null;
    final id = _selectedProjectId;
    if (id != null) {
      for (final project in _projects) {
        if (project.id == id) return project;
      }
    }
    return _projects.first;
  }

  int get _overallProgress {
    if (_projects.isEmpty) return 0;
    final sum = _projects.fold<int>(0, (sum, p) => sum + p.progress);
    return (sum / _projects.length).round();
  }

  int get _totalWorkers =>
      _team.length + _projects.fold<int>(0, (sum, p) => sum + p.members);

  int get _openIssues =>
      _tasks.where((t) => t.status == TaskStatus.delayed).length +
      _materials
          .where(
            (m) =>
                m.status == StockStatus.critical ||
                m.status == StockStatus.lowStock,
          )
          .length;

  List<Task> get _todayTasks => _tasks
      .where((t) => t.bucket == 'today' && t.status != TaskStatus.completed)
      .toList();

  Future<void> _toggleDone(Task task) async {
    final next = task.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) _tasks[index] = _tasks[index].copyWith(status: next);
    });
    await context.read<AppState>().setTaskStatus(task.id, next);
  }

  void _showProjectPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(Spacing.xl),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Row(
                  children: [
                    const Text(
                      'Select Project',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onOpenTab(1);
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                    itemBuilder: (context, index) {
                      final p = _projects[index];
                      final isSelected = p.id ==
                          (_selectedProjectId ??
                              (_projects.isNotEmpty
                                  ? _projects.first.id
                                  : ''));
                      return PressableScale(
                        onPressed: () {
                          setState(() => _selectedProjectId = p.id);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(Spacing.md),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primarySoft : AppColors.background,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Ionicons.business,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: Spacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? AppColors.primary : AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p.location.isEmpty ? 'Site' : p.location} · ${p.progress}% completed',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Ionicons.checkmark_circle,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    final project = _selectedProject;
    final hasProjects = _projects.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: hasProjects
          ? FloatingActionButton(
              heroTag: 'home_add_task',
              backgroundColor: AppColors.primary,
              elevation: 4,
              onPressed: () => showAddTaskSheet(
                context,
                state,
                onChanged: _load,
              ),
              child: const Icon(Ionicons.add, color: Colors.white, size: 26),
            )
          : null,
      body: SafeArea(
        top: true,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              Spacing.md,
              Spacing.xl,
              Spacing.xxxl + 56,
            ),
            children: [
              // 1. Header with live status badge & profile
              Entrance(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const StatusGlowDot(color: AppColors.success, size: 6),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('EEEE, MMM d').format(DateTime.now()),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Spacing.sm),
                          Text(
                            '${greetingForHour(DateTime.now())} ${user?.firstName ?? 'there'} 👋',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconBadge(
                      icon: Ionicons.notifications_outline,
                      badge: _openIssues,
                      onPressed: () => showNotificationsModal(
                        context,
                        state,
                        onOpenTab: widget.onOpenTab,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Avatar(
                      initials: user?.initials ?? '?',
                      avatarUrl: user?.avatarUrl,
                      size: 44,
                      onTap: () {
                        Navigator.of(context).push(
                          FadeThroughPageRoute<void>(
                            page: const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),

              if (_loading)
                const Column(
                  children: [
                    Skeleton(height: 180, radius: 22),
                    SizedBox(height: Spacing.lg),
                    Skeleton(height: 72, radius: 18),
                    SizedBox(height: Spacing.lg),
                    SkeletonList(count: 3, itemHeight: 84),
                  ],
                )
              else ...[
                // 2. Executive Hero Project Command Deck
                if (hasProjects && project != null)
                  Entrance(
                    delay: const Duration(milliseconds: 70),
                    child: _HeroProjectCard(
                      project: project,
                      onSwitchProject: () => _showProjectPicker(context),
                      onOpenProject: () => widget.onOpenProject(project),
                    ),
                  )
                else
                  Entrance(
                    delay: const Duration(milliseconds: 70),
                    child: AppCard(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Ionicons.business_outline,
                              size: 24,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: Spacing.lg),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No active projects',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Launch your first site to track budget & tasks.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: GradientButton(
                              title: 'Create',
                              height: 38,
                              onPressed: () => showAddProjectSheet(
                                context,
                                state,
                                onChanged: _load,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: Spacing.xl),

                // 3. Quick Action Shortcuts Bar
                Entrance(
                  delay: const Duration(milliseconds: 140),
                  child: Row(
                    children: [
                      _QuickActionTile(
                        label: 'New Task',
                        icon: Ionicons.checkbox_outline,
                        color: AppColors.primary,
                        onTap: () => showAddTaskSheet(context, state, onChanged: _load),
                      ),
                      const SizedBox(width: Spacing.sm),
                      _QuickActionTile(
                        label: 'Add Stock',
                        icon: Ionicons.cube_outline,
                        color: const Color(0xFF0EA5E9),
                        onTap: () => showAddMaterialSheet(context, state, onChanged: _load),
                      ),
                      const SizedBox(width: Spacing.sm),
                      _QuickActionTile(
                        label: 'Projects',
                        icon: Ionicons.business_outline,
                        color: const Color(0xFF8B5CF6),
                        onTap: () => widget.onOpenTab(1),
                      ),
                      const SizedBox(width: Spacing.sm),
                      _QuickActionTile(
                        label: 'Reports',
                        icon: Ionicons.bar_chart_outline,
                        color: AppColors.success,
                        onTap: () => Navigator.of(context).push(
                          FadeThroughPageRoute<void>(page: const ReportsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.xl),

                // 4. Performance Stat Cards (2x2 Grid)
                Entrance(
                  delay: const Duration(milliseconds: 200),
                  child: GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: Spacing.md,
                      crossAxisSpacing: Spacing.md,
                      childAspectRatio: 1.18,
                    ),
                    children: [
                      ProgressStatCard(
                        label: 'Overall Progress',
                        value: _overallProgress,
                      ),
                      BudgetStatCard(
                        spent: project?.spent ?? 0,
                        total: project?.budget ?? 0,
                        delay: const Duration(milliseconds: 60),
                      ),
                      CountStatCard(
                        label: 'Workforce',
                        value: _totalWorkers,
                        icon: Ionicons.people_outline,
                        tone: AppColors.info,
                        caption: 'Active crew members',
                        delay: const Duration(milliseconds: 120),
                      ),
                      CountStatCard(
                        label: 'Attention',
                        value: _openIssues,
                        icon: Ionicons.warning_outline,
                        tone: _openIssues > 0 ? AppColors.warning : AppColors.success,
                        caption: _openIssues > 0 ? 'Requires action' : 'All clear',
                        delay: const Duration(milliseconds: 180),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.xxl),

                // 5. Today's Tasks
                Entrance(
                  delay: const Duration(milliseconds: 260),
                  child: SectionHeader(
                    title: "Today's Priorities",
                    actionLabel: 'View all (${_todayTasks.length})',
                    onAction: () => widget.onOpenTab(2),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                if (_todayTasks.isEmpty)
                  Entrance(
                    delay: const Duration(milliseconds: 300),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.xl,
                        vertical: Spacing.xl,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Ionicons.checkmark_done_outline,
                              size: 20,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'All caught up for today!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'No urgent tasks pending right now.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => showAddTaskSheet(
                              context,
                              state,
                              onChanged: _load,
                            ),
                            child: const Text(
                              '+ Add',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < _todayTasks.length && i < 3; i++)
                    Entrance(
                      delay: Duration(milliseconds: 300 + i * 70),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.sm),
                        child: TaskRow(
                          task: _todayTasks[i],
                          onToggleDone: () => _toggleDone(_todayTasks[i]),
                          onTap: () {
                            final task = _todayTasks[i];
                            final proj = _projects
                                .where((p) => p.id == task.projectId)
                                .firstOrNull;
                            if (proj != null) widget.onOpenProject(proj);
                          },
                        ),
                      ),
                    ),
                const SizedBox(height: Spacing.xxl),

                // 6. Weekly Velocity Insights
                Entrance(
                  delay: const Duration(milliseconds: 380),
                  child: SectionHeader(
                    title: 'Weekly Velocity',
                    actionLabel: 'Details',
                    onAction: () => Navigator.of(context).push(
                      FadeThroughPageRoute<void>(page: const ReportsScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Entrance(
                  delay: const Duration(milliseconds: 440),
                  child: Builder(
                    builder: (context) {
                      final totalDone = _weeklyCompletions.values.fold<int>(
                        0,
                        (sum, value) => sum + value,
                      );
                      return AppCard(
                        padding: const EdgeInsets.all(Spacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Ionicons.trending_up_outline,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: Spacing.sm),
                                    const Text(
                                      'Tasks Completed',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    '$totalDone done this week',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Spacing.lg),
                            MiniBarChart(
                              data: _weeklySeries(),
                              height: 120,
                              emptyLabel: 'Complete tasks to see daily velocity',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<({String label, int value})> _weeklySeries() {
    final weekly = _weeklyCompletions;
    if (weekly.isEmpty) return const [];
    final entries = weekly.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      for (final entry in entries)
        (label: _shortLabel(entry.key), value: entry.value),
    ];
  }
}

String _shortLabel(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return isoDate;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

/// Executive dark command hero card for the primary active project.
class _HeroProjectCard extends StatelessWidget {
  const _HeroProjectCard({
    required this.project,
    required this.onSwitchProject,
    required this.onOpenProject,
  });

  final Project project;
  final VoidCallback onSwitchProject;
  final VoidCallback onOpenProject;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E293B), // Slate 800
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: const Color(0x33F97316),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x1AF97316),
            blurRadius: 28,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ambient warm background glow
          Positioned(
            top: -40,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x33F97316),
                      Color(0x00F97316),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Row + Switch Project Pill
                Row(
                  children: [
                    StatusPill(
                      label: project.phase.isEmpty ? 'Active Site' : project.phase,
                      color: AppColors.primary,
                      pulse: true,
                      compact: true,
                    ),
                    const Spacer(),
                    PressableScale(
                      scaleTo: 0.94,
                      onPressed: onSwitchProject,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1FFFFFFF),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Switch',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Ionicons.chevron_down,
                              size: 13,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.lg),

                // Project Title & Location
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onOpenProject,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Ionicons.location_sharp,
                            size: 13,
                            color: Color(0xFFFDBA74),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              project.location.isEmpty
                                  ? 'Active Construction Site'
                                  : project.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.xl),

                // Progress Bar with animated numbers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'COMPLETION RATE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    CountUpNumber(
                      project.progress,
                      suffix: '%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedProgressBar(
                  value: project.progress,
                  height: 8,
                  color: AppColors.primary,
                ),
                const SizedBox(height: Spacing.lg),

                // Divider line
                const Divider(color: Color(0x26FFFFFF), height: 1),
                const SizedBox(height: Spacing.md),

                // Bottom Meta Row + Direct Arrow CTA
                Row(
                  children: [
                    // Budget
                    Row(
                      children: [
                        const Icon(
                          Ionicons.wallet_outline,
                          size: 15,
                          color: Color(0xFF34D399),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${compactCurrency(project.spent)} / ${compactCurrency(project.budget)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: Spacing.lg),

                    // Workers
                    Row(
                      children: [
                        const Icon(
                          Ionicons.people_outline,
                          size: 15,
                          color: Color(0xFF38BDF8),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${project.members} crew',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // View details button
                    PressableScale(
                      scaleTo: 0.94,
                      onPressed: onOpenProject,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4DF97316),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Ionicons.arrow_forward,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact square shortcut button for high-frequency actions.
class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressableScale(
        scaleTo: 0.94,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: Spacing.md,
            horizontal: Spacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: const [Shadows.card],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

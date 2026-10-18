import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart' as m;
import '../state/app_state.dart';
import '../widgets/domain.dart';
import '../widgets/motion.dart';
import '../widgets/sheets.dart';
import '../widgets/ui.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) _searchController.clear();
    });
  }

  void _onQueryChanged(String value) => setState(() {});

  void _showOverflowMenu(
    BuildContext context,
    AppState state,
    m.Project project,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.overlay,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          Spacing.xl,
          Spacing.lg,
          Spacing.xl,
          Spacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              project.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            _OverflowAction(
              icon: Ionicons.trending_up_outline,
              label: 'Update progress',
              onTap: () {
                Navigator.of(sheetContext).pop();
                showUpdateProgressSheet(context, state, project);
              },
            ),
            _OverflowAction(
              icon: Ionicons.add_circle_outline,
              label: 'Add task to this project',
              onTap: () {
                Navigator.of(sheetContext).pop();
                showAddTaskSheet(context, state);
              },
            ),
            _OverflowAction(
              icon: Ionicons.copy_outline,
              label: 'Copy project summary',
              onTap: () {
                Navigator.of(sheetContext).pop();
                _copySummary(context, project, state);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copySummary(
    BuildContext context,
    m.Project project,
    AppState state,
  ) async {
    final tasks = state.tasks.where((t) => t.projectId == project.id).toList();
    final done = tasks.where((t) => t.status == m.TaskStatus.completed).length;
    final buffer = StringBuffer('BuildTrack — ${project.name}\n')
      ..writeln('Status: ${m.projectStatusLabel(project.status)}')
      ..writeln('Progress: ${project.progress}%')
      ..writeln('Phase: ${project.phase}')
      ..writeln(
        'Budget: ${compactCurrency(project.spent)} of ${compactCurrency(project.budget)}',
      )
      ..writeln('Tasks: $done of ${tasks.length} completed');

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!context.mounted) return;
    showAppSnack(context, 'Project summary copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final project = state.projects
        .where((p) => p.id == widget.projectId)
        .firstOrNull;

    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: const EmptyState(
          icon: Ionicons.alert_circle_outline,
          title: 'Project unavailable',
          message: 'This project is no longer in your workspace.',
        ),
      );
    }

    final projectTasks = state.tasks
        .where((t) => t.projectId == project.id)
        .toList();
    final timeline = state.timelineFor(project.id);
    final team = state.projectTeamFor(project.id);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _ProjectHero(
              project: project,
              searching: _searching,
              searchController: _searchController,
              onToggleSearch: _toggleSearch,
              onQueryChanged: _onQueryChanged,
              onOverflow: () => _showOverflowMenu(context, state, project),
            ),
            Expanded(
              child: _ProjectSheet(
                project: project,
                tasks: projectTasks,
                timeline: timeline,
                team: team,
                state: state,
                query: _searchController.text,
              ),
            ),

            Entrance(
              delay: const Duration(milliseconds: 420),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.xl,
                    0,
                    Spacing.xl,
                    Spacing.md,
                  ),
                  child: GradientButton(
                    title: 'Update Progress',
                    icon: Ionicons.trending_up_outline,
                    onPressed: () =>
                        showUpdateProgressSheet(context, state, project),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverflowAction extends StatelessWidget {
  const _OverflowAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: PressableScale(
        scaleTo: 0.98,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        highlightColor: AppColors.primary.withValues(alpha: 0.07),
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              const Icon(
                Ionicons.chevron_forward,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectHero extends StatelessWidget {
  const _ProjectHero({
    required this.project,
    required this.searching,
    required this.searchController,
    required this.onToggleSearch,
    required this.onQueryChanged,
    required this.onOverflow,
  });

  final m.Project project;
  final bool searching;
  final TextEditingController searchController;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onOverflow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: searching ? 268 : 208,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.dark, AppColors.primary],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.sm,
                    Spacing.lg,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Entrance(
                        style: EntranceStyle.slideInRight,
                        child: IconBadge(
                          icon: Icons.arrow_back,
                          background: const Color(0x3DFFFFFF),
                          tone: Colors.white,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      Row(
                        children: [
                          Entrance(
                            delay: const Duration(milliseconds: 60),
                            style: EntranceStyle.slideInRight,
                            child: IconBadge(
                              icon: searching
                                  ? Ionicons.close
                                  : Ionicons.search_outline,
                              background: const Color(0x3DFFFFFF),
                              tone: Colors.white,
                              onPressed: onToggleSearch,
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Entrance(
                            delay: const Duration(milliseconds: 120),
                            style: EntranceStyle.slideInRight,
                            child: IconBadge(
                              icon: Ionicons.ellipsis_horizontal,
                              background: const Color(0x3DFFFFFF),
                              tone: Colors.white,
                              onPressed: onOverflow,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (searching)
                  Entrance(
                    delay: const Duration(milliseconds: 60),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Spacing.xl,
                        0,
                        Spacing.xl,
                        Spacing.md,
                      ),
                      child: AppField(
                        label: '',
                        hint: 'Search this project',
                        prefixIcon: Ionicons.search,
                        glass: true,
                        controller: searchController,
                        onChanged: onQueryChanged,
                      ),
                    ),
                  ),
                Entrance(
                  delay: const Duration(milliseconds: 100),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.xl,
                      0,
                      Spacing.xl,
                      Spacing.xl,
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  project.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: Spacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Spacing.md,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  m.projectStatusLabel(project.status),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            project.phase.isEmpty
                                ? project.location
                                : project.phase,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xE6FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectSheet extends StatefulWidget {
  const _ProjectSheet({
    required this.project,
    required this.tasks,
    required this.timeline,
    required this.team,
    required this.state,
    this.query = '',
  });

  final m.Project project;
  final List<m.Task> tasks;
  final List<m.TimelineStep> timeline;
  final List<m.TeamMember> team;
  final AppState state;
  final String query;

  @override
  State<_ProjectSheet> createState() => _ProjectSheetState();
}

class _ProjectSheetState extends State<_ProjectSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 4,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      transform: Matrix4.translationValues(0, -Spacing.xl, 0),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              Spacing.lg,
              Spacing.xl,
              0,
            ),
            child: Entrance(
              delay: const Duration(milliseconds: 120),
              child: UnderlineTabs(
                items: const ['Overview', 'Tasks', 'Materials', 'Team'],
                activeIndex: _tabController.index,
                onChanged: (index) =>
                    setState(() => _tabController.animateTo(index)),
              ),
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                return IndexedStack(
                  index: _tabController.index,
                  children: [
                    _overview(context),
                    _tasks(context),
                    _materials(context),
                    _team(context),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _overview(BuildContext context) {
    final project = widget.project;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.xl,
        Spacing.xl,
        Spacing.xxl,
      ),
      children: [
        Entrance(
          delay: const Duration(milliseconds: 160),
          child: AppCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall progress',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    CountUpNumber(
                      project.progress,
                      suffix: '%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                AnimatedProgressBar(
                  value: project.progress,
                  height: 10,
                  color: toneForProgress(project.progress),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Entrance(
          delay: const Duration(milliseconds: 220),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Column(
              children: [
                _InfoRow(
                  icon: Ionicons.calendar_outline,
                  label: 'Timeline',
                  value: _timelineValue(project),
                ),
                _InfoRow(
                  icon: Ionicons.wallet_outline,
                  label: 'Budget',
                  value:
                      '${compactCurrency(project.spent)} / ${compactCurrency(project.budget)}',
                ),
                _InfoRow(
                  icon: Ionicons.location_outline,
                  label: 'Location',
                  value: project.location.isEmpty ? '—' : project.location,
                ),
                _InfoRow(
                  icon: Ionicons.person_outline,
                  label: 'Client',
                  value: project.client.isEmpty ? '—' : project.client,
                ),
                _InfoRow(
                  icon: Ionicons.people_outline,
                  label: 'Workers',
                  value: '${project.members}',
                ),
                _InfoRow(
                  icon: Ionicons.layers_outline,
                  label: 'Current Stage',
                  value: project.currentStage.isEmpty
                      ? '—'
                      : project.currentStage,
                  last: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.xl),
        const Entrance(
          delay: Duration(milliseconds: 280),
          child: Text(
            'Project Timeline',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        TimelineList(steps: widget.timeline),
      ],
    );
  }

  String _timelineValue(m.Project project) {
    final start = parseDate(project.startDate);
    final end = parseDate(project.endDate);
    if (start == null && end == null) return '—';
    if (start == null) return formatDate(end);
    if (end == null) return formatDate(start);
    return '${formatDate(start)} – ${formatDate(end)}';
  }

  Widget _tasks(BuildContext context) {
    final query = widget.query.trim().toLowerCase();
    final tasks = query.isEmpty
        ? widget.tasks
        : widget.tasks
              .where(
                (t) =>
                    t.title.toLowerCase().contains(query) ||
                    t.projectName.toLowerCase().contains(query),
              )
              .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.xl,
        Spacing.xl,
        Spacing.xxl,
      ),
      children: [
        if (tasks.isEmpty)
          EmptyState(
            icon: Ionicons.checkbox_outline,
            title: widget.tasks.isEmpty ? 'No tasks yet' : 'No matches',
            message: widget.tasks.isEmpty
                ? 'Add tasks to this project to track day-to-day execution.'
                : 'No task matches "$query". Try a different word.',
            actionLabel: 'Add Task',
            onAction: () => showAddTaskSheet(context, widget.state),
          )
        else
          for (var i = 0; i < tasks.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Entrance(
                delay: Duration(milliseconds: 120 + i * 70),
                child: TaskRow(
                  task: tasks[i],
                  onToggleDone: () => widget.state.setTaskStatus(
                    tasks[i].id,
                    tasks[i].status == m.TaskStatus.pending
                        ? m.TaskStatus.completed
                        : m.TaskStatus.pending,
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _materials(BuildContext context) {
    final materials = widget.state.materials;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.xl,
        Spacing.xl,
        Spacing.xxl,
      ),
      children: [
        if (materials.isEmpty)
          EmptyState(
            icon: Ionicons.cube_outline,
            title: 'No materials yet',
            message: 'Add materials to keep the site inventory up to date.',
            actionLabel: 'Add Material',
            onAction: () => showAddMaterialSheet(context, widget.state),
          )
        else
          for (var i = 0; i < materials.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Entrance(
                delay: Duration(milliseconds: 120 + i * 60),
                child: MaterialRow(material: materials[i]),
              ),
            ),
      ],
    );
  }

  Widget _team(BuildContext context) {
    final team = widget.team;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.xl,
        Spacing.xl,
        Spacing.xxl,
      ),
      children: [
        if (team.isEmpty)
          EmptyState(
            icon: Ionicons.people_outline,
            title: 'No team members yet',
            message: 'Add the people working on this project.',
            actionLabel: 'Add Member',
            onAction: () => showAddMemberSheet(
              context,
              widget.state,
              projectId: widget.project.id,
            ),
          )
        else
          for (var i = 0; i < team.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Entrance(
                delay: Duration(milliseconds: 120 + i * 70),
                child: AppCard(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Row(
                    children: [
                      Avatar(
                        initials: _initials(team[i].name),
                        size: 40,
                        tone: AppColors.info,
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              team[i].role,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconBadge(
                        icon: Ionicons.call_outline,
                        tone: AppColors.primary,
                        background: AppColors.primarySoft,
                        onPressed: () async {
                          showAppSnack(
                            context,
                            'Calling is not set up — contact ${team[i].name} through your usual channels.',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        const SizedBox(height: Spacing.md),
        AppButton(
          title: 'Add Team Member',
          icon: Ionicons.person_add_outline,
          variant: AppButtonVariant.outline,
          onPressed: () => showAddMemberSheet(
            context,
            widget.state,
            projectId: widget.project.id,
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0].toUpperCase()}${parts.last[0].toUpperCase()}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: Spacing.md),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

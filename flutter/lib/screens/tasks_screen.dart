import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/repositories.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/domain.dart';
import '../widgets/motion.dart';
import '../widgets/sheets.dart';
import '../widgets/ui.dart';
import 'project_detail_screen.dart';

/// Tasks tab. The screen owns its own state (the Flutter equivalent of
/// useState) and renders rows loaded straight from the database, so what you
/// see always comes from the database rather than stale in-memory data.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, this.reloadToken = 0, this.active = true});

  /// Bumped by the shell whenever a tab becomes visible, which triggers a
  /// fresh database load.
  final int reloadToken;
  final bool active;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<Task> _tasks = [];
  bool _loading = true;
  int _bucketIndex = 0;
  bool _searching = false;
  String _query = '';

  static const _buckets = ['Today', 'This Week', 'All'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && oldWidget.reloadToken != widget.reloadToken) {
      _load();
    }
  }

  Future<void> _load() async {
    final user = context.read<AppState>().user;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    final tasks = await TasksRepository.instance.fetchForUser(user.id);
    if (!mounted) return;
    setState(() {
      _tasks
        ..clear()
        ..addAll(tasks);
      _loading = false;
    });
  }

  bool _inBucket(Task task) {
    return switch (_bucketIndex) {
      0 => task.bucket == 'today',
      1 => task.bucket == 'today' || task.bucket == 'week',
      _ => true,
    };
  }

  bool _matchesQuery(Task task) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return task.title.toLowerCase().contains(query) ||
        task.projectName.toLowerCase().contains(query);
  }

  bool _isVisible(Task task) => _inBucket(task) && _matchesQuery(task);

  List<Task> _visible() => _tasks.where(_isVisible).toList();

  List<Task> _others() => _tasks.where((task) => !_isVisible(task)).toList();

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

  void _openProject(Task task) {
    if (task.projectId.isEmpty) return;
    Navigator.of(context).push(
      FadeThroughPageRoute(
        page: ProjectDetailScreen(projectId: task.projectId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final visible = _visible();
    final others = _others();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        heroTag: 'tasks_add_task',
        backgroundColor: AppColors.primary,
        onPressed: () => showAddTaskSheet(context, state, onChanged: _load),
        child: const Icon(Ionicons.add, color: Colors.white, size: 26),
      ),
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Tasks',
              subtitle: _tasks.isEmpty
                  ? 'No tasks yet'
                  : '${_tasks.length} total · ${visible.length} in view',
              trailing: IconBadge(
                icon: _searching ? Ionicons.close : Ionicons.search_outline,
                onPressed: () => setState(() {
                  _searching = !_searching;
                  if (!_searching) _query = '';
                }),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _searching
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Spacing.xl,
                        Spacing.md,
                        Spacing.xl,
                        0,
                      ),
                      child: AppField(
                        label: '',
                        hint: 'Search tasks or projects...',
                        prefixIcon: Ionicons.search,
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Entrance(
              delay: const Duration(milliseconds: 120),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.xl,
                  0,
                  Spacing.xl,
                  0,
                ),
                child: SegmentedControl(
                  items: _buckets,
                  activeIndex: _bucketIndex,
                  onChanged: (index) => setState(() => _bucketIndex = index),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.xl,
                    Spacing.lg,
                    Spacing.xl,
                    Spacing.xxxl + 56,
                  ),
                  children: [
                    Entrance(
                      delay: const Duration(milliseconds: 120),
                      child: Text(
                        "${_buckets[_bucketIndex]}'s Tasks (${visible.length})",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    if (_loading)
                      const SkeletonList()
                    else if (visible.isEmpty && others.isEmpty)
                      EmptyState(
                        icon: Ionicons.checkbox_outline,
                        title: 'No tasks here',
                        message: _tasks.isEmpty
                            ? 'Add tasks to keep your projects on track. They will show up here by due date.'
                            : 'Nothing due in this window.',
                        actionLabel: 'Add Task',
                        onAction: () =>
                            showAddTaskSheet(context, state, onChanged: _load),
                      )
                    else if (visible.isEmpty)
                      EmptyState(
                        icon: Ionicons.calendar_outline,
                        title:
                            'No tasks ${_buckets[_bucketIndex].toLowerCase()}',
                        message:
                            '${others.length} task${others.length == 1 ? '' : 's'} '
                            'are due on other days — they are listed below.',
                      )
                    else
                      for (var i = 0; i < visible.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: Entrance(
                            delay: Duration(milliseconds: 140 + i * 70),
                            child: TaskRow(
                              task: visible[i],
                              onToggleDone: () => _toggleDone(visible[i]),
                              onTap: () => _openProject(visible[i]),
                            ),
                          ),
                        ),
                    if (!_loading && visible.isNotEmpty && others.isNotEmpty) ...[
                      const SizedBox(height: Spacing.lg),
                      Entrance(
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          'Other tasks (${others.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      for (var i = 0; i < others.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: Entrance(
                            delay: Duration(milliseconds: 240 + i * 60),
                            child: TaskRow(
                              task: others[i],
                              onToggleDone: () => _toggleDone(others[i]),
                              onTap: () => _openProject(others[i]),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

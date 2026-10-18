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

/// Projects tab. Owns its own state and renders rows loaded from the database.
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key, this.reloadToken = 0, this.active = true});

  final int reloadToken;
  final bool active;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final List<Project> _projects = [];
  bool _loading = true;
  String _query = '';
  int _filterIndex = 0;

  static const _filters = ['All', 'Active', 'Completed', 'Delayed'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProjectsScreen oldWidget) {
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
    final projects = await ProjectsRepository.instance.fetchForUser(user.id);
    if (!mounted) return;
    setState(() {
      _projects
        ..clear()
        ..addAll(projects);
      _loading = false;
    });
  }

  List<Project> get _filtered {
    final filter = _filters[_filterIndex];
    final query = _query.trim().toLowerCase();
    return _projects.where((project) {
      final matchesFilter =
          filter == 'All' || projectStatusLabel(project.status) == filter;
      final matchesQuery = project.name.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final projects = _filtered;
    final activeCount = _projects
        .where((p) => p.status == ProjectStatus.active)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _AddProjectButton(
        onPressed: () =>
            showAddProjectSheet(context, state, onChanged: _load),
      ),
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Projects',
              subtitle: _projects.isEmpty
                  ? 'No projects yet'
                  : '${_projects.length} total · $activeCount active',
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
                child: Column(
                  children: [
                    AppField(
                      label: '',
                      hint: 'Search projects...',
                      prefixIcon: Ionicons.search,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: Spacing.md),
                    UnderlineTabs(
                      items: _filters,
                      activeIndex: _filterIndex,
                      onChanged: (index) =>
                          setState(() => _filterIndex = index),
                    ),
                  ],
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
                    if (_loading)
                      const SkeletonList()
                    else if (projects.isEmpty && _projects.isEmpty)
                      EmptyState(
                        icon: Ionicons.business_outline,
                        title: 'No projects yet',
                        message:
                            'Create your first project to track progress, budget, tasks and materials.',
                        actionLabel: 'New Project',
                        onAction: () => showAddProjectSheet(
                          context,
                          state,
                          onChanged: _load,
                        ),
                      )
                    else if (projects.isEmpty)
                      const EmptyState(
                        icon: Ionicons.search_outline,
                        title: 'Nothing found',
                        message: 'No projects match your search or filter.',
                      )
                    else
                      for (var i = 0; i < projects.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.md),
                          child: ProjectCard(
                            project: projects[i],
                            index: i,
                            onTap: () => Navigator.of(context).push(
                              FadeThroughPageRoute(
                                page: ProjectDetailScreen(
                                  projectId: projects[i].id,
                                ),
                              ),
                            ),
                          ),
                        ),
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

class _AddProjectButton extends StatelessWidget {
  const _AddProjectButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Entrance(
      style: EntranceStyle.popIn,
      delay: const Duration(milliseconds: 300),
      child: PressableScale(
        scaleTo: 0.88,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onPressed: onPressed,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4DF97316),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: 'projects_add_project',
            backgroundColor: Colors.transparent,
            elevation: 0,
            highlightElevation: 0,
            onPressed: onPressed,
            child: const Icon(Ionicons.add, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

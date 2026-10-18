import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/domain.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final completedTasks = state.tasks
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final taskRate = state.tasks.isEmpty
        ? 0
        : (completedTasks / state.tasks.length * 100).round();
    final budgetUsed = (state.totalBudgetUsed * 100).round();
    final spent = state.projects.fold<double>(0, (sum, p) => sum + p.spent);
    final budget = state.projects.fold<double>(0, (sum, p) => sum + p.budget);

    final weekly = state.weeklyCompletions.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final weeklySeries = [
      for (final entry in weekly)
        (label: _shortLabel(entry.key), value: entry.value),
    ];

    final budgetSeries = state.projects
        .map(
          (p) => (
            label: p.name.split(' ').first,
            budget: p.budget,
            actual: p.spent,
          ),
        )
        .take(4)
        .toList();

    final hasData = state.projects.isNotEmpty || state.tasks.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            Entrance(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.xl,
                  Spacing.md,
                  Spacing.xl,
                  0,
                ),
                child: Row(
                  children: [
                    IconBadge(
                      icon: Icons.chevron_left,
                      background: Colors.white,
                      tone: AppColors.text,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: Spacing.md),
                    const Expanded(
                      child: Text(
                        'Reports',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    AppButton(
                      title: 'Share',
                      icon: Ionicons.share_outline,
                      height: 40,
                      expand: false,
                      onPressed: () => _shareReport(context, state),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.xl,
                  Spacing.lg,
                  Spacing.xl,
                  Spacing.xxxl,
                ),
                children: [
                  if (!hasData)
                    EmptyState(
                      icon: Ionicons.bar_chart_outline,
                      title: 'No reports yet',
                      message:
                          'Once you add projects and complete tasks, your performance analytics will appear here.',
                    )
                  else ...[
                    for (var i = 0; i < 4; i++)
                      Entrance(
                        delay: Duration(milliseconds: 80 + i * 80),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.md),
                          child: _MetricCard(
                            label: const [
                              'Overall Progress',
                              'Budget Used',
                              'Tasks Completed',
                              'Open Issues',
                            ][i],
                            value: [
                              state.overallProgress,
                              budgetUsed,
                              taskRate,
                              state.openIssues,
                            ][i],
                            hint: [
                              '${state.projects.length} projects',
                              '${compactCurrency(spent)} / ${compactCurrency(budget)}',
                              '$completedTasks of ${state.tasks.length} tasks',
                              'Delayed tasks & low stock',
                            ][i],
                            color: const [
                              AppColors.primary,
                              AppColors.success,
                              AppColors.info,
                              AppColors.warning,
                            ][i],
                          ),
                        ),
                      ),
                    const SizedBox(height: Spacing.sm),

                    Entrance(
                      delay: const Duration(milliseconds: 420),
                      child: SectionHeader(title: 'Task Completions'),
                    ),
                    const SizedBox(height: Spacing.md),
                    Entrance(
                      delay: const Duration(milliseconds: 480),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Completed tasks per week',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: Spacing.lg),
                            MiniBarChart(
                              data: weeklySeries,
                              height: 130,
                              emptyLabel:
                                  'Complete a task to populate this chart',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),

                    Entrance(
                      delay: const Duration(milliseconds: 540),
                      child: SectionHeader(title: 'Budget by Project'),
                    ),
                    const SizedBox(height: Spacing.md),
                    Entrance(
                      delay: const Duration(milliseconds: 600),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _legendDot(AppColors.info, 'Budget'),
                                const SizedBox(width: Spacing.lg),
                                _legendDot(AppColors.primary, 'Actual'),
                              ],
                            ),
                            const SizedBox(height: Spacing.lg),
                            GroupedBarChart(data: budgetSeries, height: 150),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),

                    Entrance(
                      delay: const Duration(milliseconds: 660),
                      child: SectionHeader(title: 'Project Progress'),
                    ),
                    const SizedBox(height: Spacing.md),
                    for (var i = 0; i < state.projects.length; i++)
                      Entrance(
                        delay: Duration(milliseconds: 700 + i * 70),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.md),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        state.projects[i].name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.text,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${state.projects[i].progress}%',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: Spacing.sm),
                                AnimatedProgressBar(
                                  value: state.projects[i].progress,
                                  height: 8,
                                  color: toneForProgress(
                                    state.projects[i].progress,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: Spacing.xs + 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _shareReport(BuildContext context, AppState state) async {
    if (state.projects.isEmpty && state.tasks.isEmpty) {
      showAppSnack(context, 'Nothing to share yet — add a project first.');
      return;
    }

    final completedTasks = state.tasks
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final taskRate = state.tasks.isEmpty
        ? 0
        : (completedTasks / state.tasks.length * 100).round();
    final budgetUsed = (state.totalBudgetUsed * 100).round();
    final spent = state.projects.fold<double>(0, (sum, p) => sum + p.spent);
    final budget = state.projects.fold<double>(0, (sum, p) => sum + p.budget);

    final buffer = StringBuffer('BuildTrack report\n')
      ..writeln('Overall progress: ${state.overallProgress}%')
      ..writeln(
        'Tasks completed: $completedTasks of ${state.tasks.length} ($taskRate%)',
      )
      ..writeln(
        'Budget used: ${compactCurrency(spent)} of ${compactCurrency(budget)} ($budgetUsed%)',
      )
      ..writeln('Workers: ${state.totalWorkers}')
      ..writeln('Open issues: ${state.openIssues}');

    if (state.projects.isNotEmpty) {
      buffer.writeln('\nProjects:');
      for (final project in state.projects) {
        buffer.writeln(
          '• ${project.name} — ${project.progress}% · ${projectStatusLabel(project.status)}',
        );
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!context.mounted) return;
    showAppSnack(context, 'Report summary copied to clipboard.');
  }
}

String _shortLabel(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return isoDate;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.hint,
    required this.color,
  });

  final String label;
  final int value;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(Ionicons.analytics_outline, size: 20, color: color),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$value%',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

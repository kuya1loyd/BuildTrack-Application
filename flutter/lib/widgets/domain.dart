import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart' as m;
import 'motion.dart';
import 'ui.dart';

const TextStyle _kStatValueStyle = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w800,
  color: AppColors.text,
  letterSpacing: -0.5,
);

const TextStyle _kStatLabelStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

const TextStyle _kStatCaptionStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: AppColors.textMuted,
);

class _StatCardIcon extends StatelessWidget {
  const _StatCardIcon({required this.icon, required this.tone});

  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 19, color: tone),
    );
  }
}

class ProgressStatCard extends StatelessWidget {
  const ProgressStatCard({
    super.key,
    required this.label,
    required this.value,
    this.delay = Duration.zero,
  });

  final String label;
  final int value;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Entrance(
      delay: delay,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _StatCardIcon(
                  icon: Ionicons.trending_up_outline,
                  tone: AppColors.primary,
                ),
                const Spacer(),
                CountUpNumber(
                  value,
                  suffix: '%',
                  style: _kStatValueStyle,
                  duration: const Duration(milliseconds: 1000),
                ),
              ],
            ),
            const Spacer(),
            Text(label, style: _kStatLabelStyle),
            const SizedBox(height: Spacing.sm),
            AnimatedProgressBar(
              value: value,
              color: AppColors.primary,
              delay: delay + const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetStatCard extends StatelessWidget {
  const BudgetStatCard({
    super.key,
    required this.spent,
    required this.total,
    this.delay = Duration.zero,
  });

  final double spent;
  final double total;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final hasBudget = total > 0;
    final used = hasBudget ? (spent / total * 100).round().clamp(0, 100) : 0;

    return Entrance(
      delay: delay,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _StatCardIcon(
                  icon: Ionicons.wallet_outline,
                  tone: AppColors.success,
                ),
                const Spacer(),
                CountUpNumber(
                  used,
                  suffix: '%',
                  style: _kStatValueStyle.copyWith(
                    color: hasBudget ? AppColors.text : AppColors.textMuted,
                  ),
                  duration: const Duration(milliseconds: 1000),
                ),
              ],
            ),
            const Spacer(),
            const Text('Budget', style: _kStatLabelStyle),
            const SizedBox(height: Spacing.sm),
            AnimatedProgressBar(
              value: used,
              color: AppColors.success,
              delay: delay + const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class CountStatCard extends StatelessWidget {
  const CountStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone = AppColors.info,
    this.caption = '',
    this.delay = Duration.zero,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color tone;
  final String caption;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Entrance(
      delay: delay,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatCardIcon(icon: icon, tone: tone),
                const Spacer(),
                CountUpNumber(
                  value,
                  style: _kStatValueStyle,
                  duration: const Duration(milliseconds: 1000),
                ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _kStatLabelStyle,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _kStatCaptionStyle,
            ),
          ],
        ),
      ),
    );
  }
}

Color _taskStatusColor(m.TaskStatus status) => switch (status) {
  m.TaskStatus.pending => AppColors.textMuted,
  m.TaskStatus.inProgress => AppColors.info,
  m.TaskStatus.completed => AppColors.success,
  m.TaskStatus.delayed => AppColors.danger,
};

class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleDone,
    this.trailing,
  });

  final m.Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleDone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final done = task.status == m.TaskStatus.completed;
    return AppCard(
      padding: const EdgeInsets.all(Spacing.md),
      onTap: onTap,
      child: Row(
        children: [
          BouncingCheckmark(
            checked: done,
            onTap: onToggleDone,
            activeColor: AppColors.success,
            size: 26,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: done ? AppColors.textMuted : AppColors.text,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textMuted,
                  ),
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${task.due} · ${task.team}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          trailing ??
              StatusPill(
                label: m.taskStatusLabel(task.status),
                color: _taskStatusColor(task.status),
                compact: true,
              ),
        ],
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.index = 0,
  });

  final m.Project project;
  final VoidCallback? onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tone = m.projectStatusColor(project.status);
    final used = project.budget <= 0
        ? 0
        : (project.spent / project.budget * 100).round().clamp(0, 100);

    return Entrance(
      delay: Duration(milliseconds: 60 + index * 70),
      child: AppCard(
        onTap: onTap,

        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.card, tone.withValues(alpha: 0.07)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tone.withValues(alpha: 0.92),
                        tone.withValues(alpha: 0.55),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Ionicons.business_outline,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        project.phase.isEmpty
                            ? project.location
                            : '${project.phase} · ${project.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                StatusPill(
                  label: m.projectStatusLabel(project.status),
                  color: tone,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            _CardMetric(
              label: 'Budget',
              value:
                  '${compactCurrency(project.spent)} / ${compactCurrency(project.budget)}',
              barValue: used,
              barColor: tone,
            ),
            const SizedBox(height: Spacing.md),
            _CardMetric(
              label: 'Progress',
              value: '${project.progress}%',
              barValue: project.progress,
              barColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardMetric extends StatelessWidget {
  const _CardMetric({
    required this.label,
    required this.value,
    required this.barValue,
    required this.barColor,
  });

  final String label;
  final String value;
  final int barValue;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedProgressBar(value: barValue, height: 6, color: barColor),
      ],
    );
  }
}

Color _stockColor(m.StockStatus status) => switch (status) {
  m.StockStatus.available => AppColors.success,
  m.StockStatus.lowStock => AppColors.warning,
  m.StockStatus.critical => AppColors.danger,
  m.StockStatus.outOfStock => AppColors.danger,
};

IconData _materialIcon(String icon) => switch (icon) {
  'steel' => Ionicons.construct_outline,
  'bricks' => Ionicons.grid_outline,
  'paint' => Ionicons.color_fill_outline,
  'wood' => Ionicons.layers_outline,
  'sand' => Ionicons.water_outline,
  'cement' => Ionicons.server_outline,
  _ => Ionicons.cube_outline,
};

class MaterialRow extends StatelessWidget {
  const MaterialRow({
    super.key,
    required this.material,
    this.onTap,
    this.trailing,
  });

  final m.Material material;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tone = _stockColor(material.status);
    return AppCard(
      padding: const EdgeInsets.all(Spacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(_materialIcon(material.icon), size: 20, color: tone),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatQuantity(material.quantity)} ${material.unit} · ${material.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          trailing ??
              StatusPill(
                label: m.stockStatusLabel(material.status),
                color: tone,
                compact: true,
              ),
        ],
      ),
    );
  }
}

class TimelineList extends StatelessWidget {
  const TimelineList({super.key, required this.steps});

  final List<m.TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.lg),
        child: Text(
          'No stages yet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(step: steps[i], isLast: i == steps.length - 1, index: i),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isLast,
    required this.index,
  });

  final m.TimelineStep step;
  final bool isLast;
  final int index;

  @override
  Widget build(BuildContext context) {
    final done = step.status == m.TimelineStatus.done;
    final active = step.status == m.TimelineStatus.inProgress;
    final color = done
        ? AppColors.success
        : active
        ? AppColors.primary
        : AppColors.border;

    return Entrance(
      delay: Duration(milliseconds: 80 + index * 90),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: done
                        ? AppColors.success
                        : active
                        ? AppColors.primarySoft
                        : AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.6),
                  ),
                  alignment: Alignment.center,
                  child: done
                      ? const Icon(
                          Ionicons.checkmark,
                          size: 14,
                          color: Colors.white,
                        )
                      : active
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: done ? AppColors.success : AppColors.border,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: done || active
                            ? AppColors.text
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.timelineStatusLabel(step.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: done
                            ? AppColors.success
                            : active
                            ? AppColors.primary
                            : AppColors.textMuted,
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

class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.data,
    this.height = 110,
    this.barColor = AppColors.primary,
    this.emptyLabel = 'No data yet',
  });

  final List<({String label, int value})> data;
  final double height;
  final Color barColor;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            emptyLabel,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      );
    }

    final maxValue = data.map((e) => e.value).reduce(math.max).toDouble();
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final item in data)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: math.max(
                          4.0,
                          (height - 28) *
                              (item.value / math.max(maxValue, 1)) *
                              t,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              barColor,
                              Color.lerp(barColor, Colors.white, 0.15) ?? barColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: item.value > 0
                              ? [
                                  BoxShadow(
                                    color: barColor.withValues(alpha: 0.28 * t),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
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

class GroupedBarChart extends StatelessWidget {
  const GroupedBarChart({super.key, required this.data, this.height = 150});

  final List<({String label, double budget, double actual})> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'No projects yet',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      );
    }
    final maxValue = data
        .map((e) => math.max(e.budget, e.actual))
        .reduce(math.max);
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final item in data)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _bar(
                              item.budget / maxValue * (height - 30) * t,
                              Colors.blue,
                            ),
                            const SizedBox(width: 3),
                            _bar(
                              item.actual / maxValue * (height - 30) * t,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
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

  Widget _bar(double barHeight, Color color) {
    return Expanded(
      child: Container(
        height: math.max(barHeight, 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}

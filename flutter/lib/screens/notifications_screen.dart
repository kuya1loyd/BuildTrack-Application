import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../core/theme.dart';
import '../models/models.dart' as m;
import '../state/app_state.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';

class NotificationItem {
  const NotificationItem({
    required this.severity,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.targetTab,
  });

  final NotificationSeverity severity;
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final int targetTab;
}

enum NotificationSeverity { critical, warning, info }

extension on NotificationSeverity {
  Color get color => switch (this) {
    NotificationSeverity.critical => AppColors.danger,
    NotificationSeverity.warning => AppColors.warning,
    NotificationSeverity.info => AppColors.info,
  };

  Color get soft => switch (this) {
    NotificationSeverity.critical => AppColors.dangerSoft,
    NotificationSeverity.warning => AppColors.warningSoft,
    NotificationSeverity.info => AppColors.infoSoft,
  };

  String get label => switch (this) {
    NotificationSeverity.critical => 'Critical',
    NotificationSeverity.warning => 'Attention',
    NotificationSeverity.info => 'Today',
  };
}

Future<void> showNotificationsModal(
  BuildContext context,
  AppState state, {
  required ValueChanged<int> onOpenTab,
}) {
  final items = buildNotifications(state);
  final criticalCount = items
      .where((i) => i.severity == NotificationSeverity.critical)
      .length;

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Notifications',
    barrierColor: AppColors.overlay,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, _, _) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.72,
        ),
        child: Dialog(
          backgroundColor: AppColors.card,
          insetPadding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
          ),
          child: Padding(
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
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    IconBadge(
                      icon: Ionicons.close,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                StatusPill(
                  label: '$criticalCount critical',
                  color: criticalCount > 0
                      ? AppColors.danger
                      : AppColors.success,
                ),
                const SizedBox(height: Spacing.md),
                Flexible(
                  child: NotificationsList(
                    items: items,
                    onOpenTab: (tab) {
                      Navigator.of(dialogContext).pop();
                      onOpenTab(tab);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

List<NotificationItem> buildNotifications(AppState state) {
  final items = <NotificationItem>[];

  for (final task in state.tasks.where(
    (t) => t.status == m.TaskStatus.delayed,
  )) {
    items.add(
      NotificationItem(
        severity: NotificationSeverity.critical,
        icon: Ionicons.alert_circle_outline,
        title: 'Task delayed: ${task.title}',
        subtitle: task.projectName.isEmpty
            ? 'was due ${task.dueAt.isEmpty ? task.due : task.dueAt}'
            : '${task.projectName} · was due ${task.dueAt.isEmpty ? task.due : task.dueAt}',
        tag: 'task',
        targetTab: 2,
      ),
    );
  }

  for (final project in state.projects.where(
    (p) => p.status == m.ProjectStatus.delayed,
  )) {
    items.add(
      NotificationItem(
        severity: NotificationSeverity.warning,
        icon: Ionicons.time_outline,
        title: 'Project behind schedule',
        subtitle: project.name,
        tag: 'project',
        targetTab: 1,
      ),
    );
  }

  for (final material in state.materials.where(
    (mat) =>
        mat.status == m.StockStatus.critical ||
        mat.status == m.StockStatus.lowStock ||
        mat.status == m.StockStatus.outOfStock,
  )) {
    final critical = material.status != m.StockStatus.lowStock;
    items.add(
      NotificationItem(
        severity: critical
            ? NotificationSeverity.critical
            : NotificationSeverity.warning,
        icon: critical ? Ionicons.warning_outline : Ionicons.cube_outline,
        title: critical ? 'Critical stock' : 'Low stock',
        subtitle:
            '${material.name} · ${formatMaterialQuantity(material)} ${material.unit} left',
        tag: 'material',
        targetTab: 3,
      ),
    );
  }

  for (final task in state.todayTasks) {
    items.add(
      NotificationItem(
        severity: NotificationSeverity.info,
        icon: Ionicons.today_outline,
        title: 'Due today: ${task.title}',
        subtitle: task.projectName.isEmpty
            ? task.dueAt.isEmpty
                  ? task.due
                  : task.dueAt
            : '${task.projectName} · ${task.dueAt.isEmpty ? task.due : task.dueAt}',
        tag: 'today',
        targetTab: 2,
      ),
    );
  }

  return items;
}

String formatMaterialQuantity(m.Material material) {
  final value = material.quantity;
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

class NotificationsList extends StatelessWidget {
  const NotificationsList({
    super.key,
    required this.items,
    required this.onOpenTab,
  });

  final List<NotificationItem> items;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Ionicons.notifications_off_outline,
        title: 'All clear',
        message:
            'No delayed tasks, behind-schedule projects or low stock right now.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
      itemBuilder: (context, index) {
        final item = items[index];
        return Entrance(
          delay: Duration(milliseconds: 90 + index * 60),
          child: AppCard(
            padding: const EdgeInsets.all(Spacing.md),
            onTap: () => onOpenTab(item.targetTab),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.severity.soft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Icon(item.icon, size: 20, color: item.severity.color),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
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
                  label: item.severity.label,
                  color: item.severity.color,
                  compact: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

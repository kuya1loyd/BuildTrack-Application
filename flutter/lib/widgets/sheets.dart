import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'ui.dart';

Future<void> showAddTaskSheet(
  BuildContext context,
  AppState state, {
  Future<void> Function()? onChanged,
}) async {
  final outerContext = context;
  final titleController = TextEditingController();
  final teamController = TextEditingController();
  final timeController = TextEditingController();
  DateTime? dueDate;
  var saving = false;

  await showAppSheet(
    context: context,
    title: 'Add Task',
    child: StatefulBuilder(
      builder: (context, setSheetState) => Column(
        children: [
          AppField(
            label: 'Task title',
            hint: 'e.g. Electrical installation',
            controller: titleController,
            prefixIcon: Ionicons.create_outline,
          ),
          const SizedBox(height: Spacing.lg),
          AppField(
            label: 'Team',
            hint: 'e.g. Engineering Team',
            controller: teamController,
            prefixIcon: Ionicons.people_outline,
          ),
          const SizedBox(height: Spacing.lg),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(
                      context,
                    ).colorScheme.copyWith(primary: AppColors.primary),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setSheetState(() => dueDate = picked);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Ionicons.calendar_outline,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: Spacing.md),
                  Text(
                    dueDate == null
                        ? 'Due date (optional)'
                        : formatDate(dueDate),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: dueDate == null
                          ? AppColors.textMuted
                          : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          AppField(
            label: 'Due time',
            hint: 'e.g. 3:00 PM',
            controller: timeController,
            prefixIcon: Ionicons.time_outline,
          ),
          const SizedBox(height: Spacing.xl),
          GradientButton(
            title: 'Add Task',
            loading: saving,
            onPressed: () async {
              if (saving) return;
              if (titleController.text.trim().isEmpty) {
                showAppSnack(context, 'Enter a task title', error: true);
                return;
              }
              final navigator = Navigator.of(context);
              setSheetState(() => saving = true);
              navigator.pop();
              try {
                await state.addTask(
                  title: titleController.text.trim(),
                  team: teamController.text.trim(),
                  dueDate: dueDate,
                  dueTime: timeController.text.trim(),
                );
                if (outerContext.mounted) {
                  showAppSnack(outerContext, 'Task added');
                }
                await onChanged?.call();
              } catch (e) {
                if (outerContext.mounted) {
                  showAppSnack(outerContext, 'Could not add task', error: true);
                }
              }
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> showAddProjectSheet(
  BuildContext context,
  AppState state, {
  Future<void> Function()? onChanged,
}) async {
  final outerContext = context;
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final clientController = TextEditingController();
  final budgetController = TextEditingController();
  final phaseController = TextEditingController();
  final membersController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  var saving = false;

  await showAppSheet(
    context: context,
    title: 'New Project',
    child: StatefulBuilder(
      builder: (context, setSheetState) => Column(
        children: [
          AppField(
            label: 'Project name',
            hint: 'e.g. Cairo Office Building',
            controller: nameController,
            prefixIcon: Ionicons.business_outline,
          ),
          const SizedBox(height: Spacing.lg),
          AppField(
            label: 'Location',
            hint: 'e.g. Cairo, Egypt',
            controller: locationController,
            prefixIcon: Ionicons.location_outline,
          ),
          const SizedBox(height: Spacing.lg),
          AppField(
            label: 'Client (optional)',
            hint: 'Client name',
            controller: clientController,
            prefixIcon: Ionicons.person_outline,
          ),
          const SizedBox(height: Spacing.lg),
          AppField(
            label: 'Phase (optional)',
            hint: 'e.g. Construction Phase',
            controller: phaseController,
            prefixIcon: Ionicons.layers_outline,
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: AppField(
                  label: 'Budget',
                  hint: '0',
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Ionicons.wallet_outline,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: AppField(
                  label: 'Workers',
                  hint: '0',
                  controller: membersController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Ionicons.people_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: _DatePickerTile(
                  label: 'Start',
                  value: startDate,
                  onPicked: (value) => setSheetState(() => startDate = value),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _DatePickerTile(
                  label: 'End',
                  value: endDate,
                  onPicked: (value) => setSheetState(() => endDate = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          GradientButton(
            title: 'Create Project',
            loading: saving,
            onPressed: () async {
              if (saving) return;
              if (nameController.text.trim().isEmpty) {
                showAppSnack(context, 'Enter a project name', error: true);
                return;
              }
              final navigator = Navigator.of(context);
              setSheetState(() => saving = true);
              navigator.pop();
              try {
                await state.addProject(
                  name: nameController.text.trim(),
                  location: locationController.text.trim(),
                  client: clientController.text.trim(),
                  budget: double.tryParse(budgetController.text.trim()) ?? 0,
                  phase: phaseController.text.trim(),
                  members: int.tryParse(membersController.text.trim()) ?? 0,
                  startDate: startDate,
                  endDate: endDate,
                );
                if (outerContext.mounted) {
                  showAppSnack(outerContext, 'Project created');
                }
                await onChanged?.call();
              } catch (e) {
                if (outerContext.mounted) {
                  showAppSnack(
                    outerContext,
                    'Could not create project',
                    error: true,
                  );
                }
              }
            },
          ),
        ],
      ),
    ),
  );
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Ionicons.calendar_outline,
              size: 18,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                value == null ? label : formatDate(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: value == null ? AppColors.textMuted : AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showAddMaterialSheet(
  BuildContext context,
  AppState state, {
  Future<void> Function()? onChanged,
}) async {
  final outerContext = context;
  final nameController = TextEditingController();
  final categoryController = TextEditingController();
  final quantityController = TextEditingController();
  final unitController = TextEditingController();
  var status = StockStatus.available;
  var icon = 'cube';
  var saving = false;

  await showAppSheet(
    context: context,
    title: 'Add Material',
    child: StatefulBuilder(
      builder: (context, setSheetState) => Column(
        children: [
          AppField(
            label: 'Material name',
            hint: 'e.g. Cement',
            controller: nameController,
            prefixIcon: Ionicons.cube_outline,
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: AppField(
                  label: 'Quantity',
                  hint: '0',
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Ionicons.server_outline,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: AppField(
                  label: 'Unit',
                  hint: 'bags, tons, pcs',
                  controller: unitController,
                  prefixIcon: Ionicons.pricetag_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          AppField(
            label: 'Category (optional)',
            hint: 'Cement, Steel, Paint...',
            controller: categoryController,
            prefixIcon: Ionicons.grid_outline,
          ),
          const SizedBox(height: Spacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: Spacing.sm,
              children: [
                for (final option in const [
                  ('cube', 'Materials'),
                  ('cement', 'Cement'),
                  ('steel', 'Steel'),
                  ('bricks', 'Bricks'),
                  ('paint', 'Paint'),
                  ('wood', 'Wood'),
                  ('sand', 'Sand'),
                ])
                  AppChip(
                    label: option.$2,
                    active: icon == option.$1,
                    onTap: () => setSheetState(() {
                      icon = option.$1;
                      if (categoryController.text.isEmpty) {
                        categoryController.text = option.$2 == 'Materials'
                            ? ''
                            : option.$2;
                      }
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: Spacing.sm,
              children: [
                for (final option in StockStatus.values)
                  AppChip(
                    label: stockStatusLabel(option),
                    active: status == option,
                    onTap: () => setSheetState(() => status = option),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),
          GradientButton(
            title: 'Add Material',
            loading: saving,
            onPressed: () async {
              if (saving) return;
              if (nameController.text.trim().isEmpty) {
                showAppSnack(context, 'Enter a material name', error: true);
                return;
              }
              final navigator = Navigator.of(context);
              setSheetState(() => saving = true);
              navigator.pop();
              try {
                await state.addMaterial(
                  name: nameController.text.trim(),
                  category: categoryController.text.trim(),
                  quantity:
                      double.tryParse(quantityController.text.trim()) ?? 0,
                  unit: unitController.text.trim(),
                  status: status,
                  icon: icon,
                );
                if (outerContext.mounted) {
                  showAppSnack(outerContext, 'Material added');
                }
                await onChanged?.call();
              } catch (e) {
                if (outerContext.mounted) {
                  showAppSnack(
                    outerContext,
                    'Could not add material',
                    error: true,
                  );
                }
              }
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> showAddMemberSheet(
  BuildContext context,
  AppState state, {
  String? projectId,
  Future<void> Function()? onChanged,
}) async {
  final outerContext = context;
  final nameController = TextEditingController();
  final roleController = TextEditingController();
  var saving = false;

  await showAppSheet(
    context: context,
    title: 'Add Team Member',
    child: StatefulBuilder(
      builder: (context, setSheetState) => Column(
        children: [
          AppField(
            label: 'Full name',
            hint: 'e.g. Sara Mahmoud',
            controller: nameController,
            prefixIcon: Ionicons.person_outline,
          ),
          const SizedBox(height: Spacing.lg),
          AppField(
            label: 'Role',
            hint: 'e.g. Site Engineer',
            controller: roleController,
            prefixIcon: Ionicons.briefcase_outline,
          ),
          const SizedBox(height: Spacing.xl),
          GradientButton(
            title: 'Add Member',
            loading: saving,
            onPressed: () async {
              if (saving) return;
              if (nameController.text.trim().isEmpty) {
                showAppSnack(context, 'Enter a name', error: true);
                return;
              }
              final navigator = Navigator.of(context);
              setSheetState(() => saving = true);
              navigator.pop();
              try {
                await state.addTeamMember(
                  name: nameController.text.trim(),
                  role: roleController.text.trim(),
                  projectId: projectId,
                );
                if (outerContext.mounted) {
                  showAppSnack(outerContext, 'Team member added');
                }
                await onChanged?.call();
              } catch (e) {
                if (outerContext.mounted) {
                  showAppSnack(
                    outerContext,
                    'Could not add member',
                    error: true,
                  );
                }
              }
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> showUpdateProgressSheet(
  BuildContext context,
  AppState state,
  Project project, {
  Future<void> Function()? onChanged,
}) async {
  final outerContext = context;
  final spentController = TextEditingController(
    text: project.spent.toStringAsFixed(0),
  );
  var progress = project.progress;
  var saving = false;

  await showAppSheet(
    context: context,
    title: 'Update Progress',
    child: StatefulBuilder(
      builder: (context, setSheetState) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completion',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$progress%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              thumbColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
            ),
            child: Slider(
              value: progress.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (value) =>
                  setSheetState(() => progress = value.round()),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          AppField(
            label: 'Spent so far',
            hint: '0',
            controller: spentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Ionicons.wallet_outline,
          ),
          const SizedBox(height: Spacing.xl),
          GradientButton(
            title: 'Save Update',
            loading: saving,
            onPressed: () async {
              if (saving) return;
              final navigator = Navigator.of(context);
              setSheetState(() => saving = true);
              navigator.pop();
              await state.updateProjectProgress(
                project.id,
                progress,
                double.tryParse(spentController.text.trim()) ?? project.spent,
              );
              if (outerContext.mounted) {
                showAppSnack(outerContext, 'Progress updated');
              }
              await onChanged?.call();
            },
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/repositories.dart';
import '../models/models.dart' as m;
import '../state/app_state.dart';
import '../widgets/domain.dart';
import '../widgets/motion.dart';
import '../widgets/sheets.dart';
import '../widgets/ui.dart';

/// Materials tab. Owns its own state and renders rows loaded from the database.
class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key, this.reloadToken = 0, this.active = true});

  final int reloadToken;
  final bool active;

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final List<m.Material> _materials = [];
  bool _loading = true;
  String _query = '';
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MaterialsScreen oldWidget) {
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
    final materials = await MaterialsRepository.instance.fetchForUser(user.id);
    if (!mounted) return;
    setState(() {
      _materials
        ..clear()
        ..addAll(materials);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final categories = {
      'All',
      ..._materials.map((mat) => mat.category).where((c) => c.isNotEmpty),
    };

    final filtered = _materials.where((material) {
      final matchesCategory =
          _category == 'All' || material.category == _category;
      final matchesQuery = material.name.toLowerCase().contains(
        _query.trim().toLowerCase(),
      );
      return matchesCategory && matchesQuery;
    }).toList();

    final total = _materials.length;
    final inStock = _materials
        .where((mat) => mat.status == m.StockStatus.available)
        .length;
    final lowStock = _materials
        .where((mat) => mat.status == m.StockStatus.lowStock)
        .length;
    final critical = _materials
        .where((mat) => mat.status == m.StockStatus.critical)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        heroTag: 'materials_add_material',
        backgroundColor: AppColors.primary,
        onPressed: () =>
            showAddMaterialSheet(context, state, onChanged: _load),
        child: const Icon(Ionicons.add, color: Colors.white, size: 26),
      ),
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Materials',
              subtitle: _materials.isEmpty
                  ? 'No materials yet'
                  : '${_materials.length} in stock',
              trailing: Entrance(
                delay: const Duration(milliseconds: 80),
                child: IconBadge(
                  icon: Ionicons.share_outline,
                  onPressed: () => _shareInventory(context),
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
                    0,
                    Spacing.xl,
                    Spacing.xxxl + 56,
                  ),
                  children: [
                    Entrance(
                      delay: const Duration(milliseconds: 100),
                      child: AppField(
                        label: '',
                        hint: 'Search materials...',
                        prefixIcon: Ionicons.search,
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    SizedBox(
                      height: 40,
                      child: Entrance(
                        delay: const Duration(milliseconds: 140),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (var i = 0; i < categories.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: Spacing.sm,
                                ),
                                child: Entrance(
                                  delay: Duration(milliseconds: 160 + i * 50),
                                  child: AppChip(
                                    label: categories.elementAt(i),
                                    active:
                                        _category == categories.elementAt(i),
                                    onTap: () => setState(
                                      () => _category = categories.elementAt(i),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),
                    Entrance(
                      delay: const Duration(milliseconds: 200),
                      child: const Text(
                        'Inventory Overview',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    Entrance(
                      delay: const Duration(milliseconds: 240),
                      child: Row(
                        children: [
                          _InventoryStat(
                            label: 'Total Items',
                            value: total,
                            tone: AppColors.text,
                            bg: AppColors.background,
                            delay: 240,
                          ),
                          const SizedBox(width: Spacing.sm),
                          _InventoryStat(
                            label: 'In Stock',
                            value: inStock,
                            tone: AppColors.success,
                            bg: AppColors.successSoft,
                            delay: 300,
                          ),
                          const SizedBox(width: Spacing.sm),
                          _InventoryStat(
                            label: 'Low Stock',
                            value: lowStock,
                            tone: AppColors.warning,
                            bg: AppColors.warningSoft,
                            delay: 360,
                          ),
                          const SizedBox(width: Spacing.sm),
                          _InventoryStat(
                            label: 'Critical',
                            value: critical,
                            tone: AppColors.danger,
                            bg: AppColors.dangerSoft,
                            delay: 420,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),
                    Entrance(
                      delay: const Duration(milliseconds: 300),
                      child: const Text(
                        'Material List',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    if (_loading)
                      const SkeletonList()
                    else if (filtered.isEmpty)
                      EmptyState(
                        icon: Ionicons.cube_outline,
                        title: 'No materials yet',
                        message: _materials.isEmpty
                            ? 'Track your stock here once you add materials.'
                            : 'No materials match your search.',
                        actionLabel: 'Add Material',
                        onAction: () => showAddMaterialSheet(
                          context,
                          state,
                          onChanged: _load,
                        ),
                      )
                    else
                      for (var i = 0; i < filtered.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: Entrance(
                            delay: Duration(milliseconds: 320 + i * 60),
                            child: MaterialRow(
                              material: filtered[i],
                              onTap: () =>
                                  _editQuantity(context, state, filtered[i]),
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

  void _editQuantity(
    BuildContext context,
    AppState state,
    m.Material material,
  ) {
    final outerContext = context;
    final controller = TextEditingController(
      text: material.quantity.toStringAsFixed(0),
    );
    var status = material.status;
    var saving = false;

    showAppSheet(
      context: context,
      title: material.name,
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          children: [
            AppField(
              label: 'Quantity',
              hint: '0',
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: Ionicons.server_outline,
            ),
            const SizedBox(height: Spacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: Spacing.sm,
                children: [
                  for (final option in m.StockStatus.values)
                    AppChip(
                      label: m.stockStatusLabel(option),
                      active: status == option,
                      onTap: () => setSheetState(() => status = option),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xl),
            GradientButton(
              title: 'Save',
              loading: saving,
              onPressed: () async {
                if (saving) return;
                final navigator = Navigator.of(context);
                setSheetState(() => saving = true);
                navigator.pop();
                await state.updateMaterialQuantity(
                  material.id,
                  double.tryParse(controller.text.trim()) ?? material.quantity,
                  status,
                );
                await _load();
                if (outerContext.mounted) {
                  showAppSnack(outerContext, 'Material updated');
                }
              },
            ),
            const SizedBox(height: Spacing.sm),
            AppButton(
              title: 'Delete Material',
              variant: AppButtonVariant.danger,
              icon: Ionicons.trash_outline,
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await state.deleteMaterial(material.id);
                await _load();
                if (outerContext.mounted) {
                  showAppSnack(outerContext, 'Material deleted');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareInventory(BuildContext context) async {
    if (_materials.isEmpty) {
      showAppSnack(context, 'No materials to share yet.');
      return;
    }
    final buffer = StringBuffer(
      'BuildTrack inventory — ${_materials.length} items\n',
    );
    for (final mat in _materials) {
      buffer.writeln(
        '• ${mat.name} — ${mat.quantity.toStringAsFixed(mat.quantity % 1 == 0 ? 0 : 1)} ${mat.unit} (${m.stockStatusLabel(mat.status)})',
      );
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!context.mounted) return;
    showAppSnack(context, 'Inventory summary copied to clipboard.');
  }
}

class _InventoryStat extends StatelessWidget {
  const _InventoryStat({
    required this.label,
    required this.value,
    required this.tone,
    required this.bg,
    required this.delay,
  });

  final String label;
  final int value;
  final Color tone;
  final Color bg;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Entrance(
        delay: Duration(milliseconds: delay),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: Spacing.md,
            horizontal: Spacing.xs,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              CountUpNumber(
                value,
                duration: const Duration(milliseconds: 750),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: tone,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

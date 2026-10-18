import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';
import 'help_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.onSignOut,
    required this.onOpenTab,
  });

  final Future<void> Function() onSignOut;

  final ValueChanged<int> onOpenTab;

  void _open(BuildContext context, String id) {
    switch (id) {
      case 'reports':
        Navigator.of(
          context,
        ).push(FadeThroughPageRoute(page: const ReportsScreen()));
      case 'projects':
        onOpenTab(1);
      case 'tasks':
        onOpenTab(2);
      case 'materials':
        onOpenTab(3);
      case 'profile':
        Navigator.of(
          context,
        ).push(FadeThroughPageRoute(page: const ProfileScreen()));
      case 'help':
        Navigator.of(
          context,
        ).push(FadeThroughPageRoute(page: const HelpScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    final menuItems = <({String id, String label, IconData icon})>[
      (
        id: 'reports',
        label: 'Reports & Analytics',
        icon: Ionicons.bar_chart_outline,
      ),
      (id: 'projects', label: 'Projects', icon: Ionicons.business_outline),
      (id: 'tasks', label: 'Tasks', icon: Ionicons.checkbox_outline),
      (id: 'materials', label: 'Materials', icon: Ionicons.cube_outline),
      (id: 'profile', label: 'My Profile', icon: Ionicons.person_outline),
      (id: 'help', label: 'Help & Support', icon: Ionicons.help_circle_outline),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            ScreenHeader(
              title: 'More',
              subtitle: (user?.company ?? '').isEmpty
                  ? 'Workspace'
                  : user!.company,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.xl,
                  0,
                  Spacing.xl,
                  Spacing.xxxl,
                ),
                children: [
                  const SizedBox(height: Spacing.lg),

                  Entrance(
                    delay: const Duration(milliseconds: 80),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _open(context, 'profile'),
                      child: AppCard(
                        child: Row(
                          children: [
                            Avatar(
                              initials: user?.initials ?? '?',
                              avatarUrl: user?.avatarUrl,
                              size: 56,
                            ),
                            const SizedBox(width: Spacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Signed in',
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
                                    user?.role ?? 'Project Manager',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  if ((user?.company ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      user!.company,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(
                              Ionicons.chevron_forward,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  Entrance(
                    delay: const Duration(milliseconds: 140),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                      child: Row(
                        children: [
                          _Counter(
                            value: state.overallProgress,
                            label: 'Progress',
                            suffix: '%',
                          ),
                          _divider(),
                          _Counter(value: state.totalWorkers, label: 'Workers'),
                          _divider(),
                          _Counter(
                            value: state.openIssues,
                            label: 'Open issues',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),

                  Entrance(
                    delay: const Duration(milliseconds: 200),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.lg,
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < menuItems.length; i++)
                            Entrance(
                              delay: Duration(milliseconds: 240 + i * 60),
                              child: Column(
                                children: [
                                  PressableScale(
                                    scaleTo: 0.97,
                                    highlightColor: AppColors.primary
                                        .withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                    onPressed: () =>
                                        _open(context, menuItems[i].id),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: Spacing.lg,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: AppColors.background,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.md,
                                                  ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              menuItems[i].icon,
                                              size: 18,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: Spacing.md),
                                          Expanded(
                                            child: Text(
                                              menuItems[i].label,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
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
                                  if (i != menuItems.length - 1)
                                    const Divider(
                                      height: 1,
                                      color: AppColors.border,
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),

                  Entrance(
                    delay: const Duration(milliseconds: 560),
                    child: AppButton(
                      title: 'Sign Out',
                      variant: AppButtonVariant.danger,
                      icon: Ionicons.log_out_outline,
                      onPressed: () => _confirmSignOut(context, onSignOut),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    Future<void> Function() onSignOut,
  ) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Sign out',
      barrierColor: AppColors.overlay,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, _, _) =>
          _SignOutDialog(onSignOut: onSignOut),
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

  Widget _divider() => Container(width: 1, height: 24, color: AppColors.border);
}

class _SignOutDialog extends StatefulWidget {
  const _SignOutDialog({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  State<_SignOutDialog> createState() => _SignOutDialogState();
}

class _SignOutDialogState extends State<_SignOutDialog> {
  bool _loading = false;
  bool _done = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await widget.onSignOut();
      if (!mounted) return;
      // The root router swaps to the landing screen as soon as the session
      // is cleared, but this dialog is a separate route that would otherwise
      // stay on top of the landing screen showing a spinner forever.
      // Show a confirmation, then close it so the landing page is revealed.
      setState(() {
        _loading = false;
        _done = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 560));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(
            'Could not sign out. Please try again.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading,
      child: Center(
        child: Dialog(
          backgroundColor: AppColors.card,
          insetPadding: const EdgeInsets.symmetric(horizontal: Spacing.xxxl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              Spacing.xxl,
              Spacing.xl,
              Spacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_done)
                  const _SignOutSuccess()
                else
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.dangerSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Ionicons.log_out_outline,
                      size: 26,
                      color: AppColors.danger,
                    ),
                  ),
                const SizedBox(height: Spacing.lg),
                if (_done)
                  const Text(
                    'Signed out',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  )
                else
                  const Text(
                    'Sign out?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                const SizedBox(height: Spacing.sm),
                Text(
                  _done
                      ? 'See you soon! You can sign back in any time.'
                      : 'You will need to sign in again to open your projects, '
                          'tasks and materials.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: Spacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: Spacing.md),
                        Text(
                          'Signing out...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_done)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: Spacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Ionicons.checkmark_circle,
                          size: 18,
                          color: AppColors.success,
                        ),
                        SizedBox(width: Spacing.sm),
                        Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          title: 'Cancel',
                          height: 48,
                          expand: false,
                          variant: AppButtonVariant.outline,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: AppButton(
                          title: 'Sign Out',
                          height: 48,
                          expand: false,
                          variant: AppButtonVariant.danger,
                          icon: Ionicons.log_out_outline,
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignOutSuccess extends StatelessWidget {
  const _SignOutSuccess();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.successSoft,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Ionicons.checkmark,
          size: 30,
          color: AppColors.success,
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.value, required this.label, this.suffix = ''});

  final int value;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CountUpNumber(value, suffix: suffix),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

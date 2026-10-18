import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';

import '../core/image_picker.dart';
import '../core/theme.dart';
import '../models/models.dart' hide Material;
import '../state/app_state.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _company;
  late final TextEditingController _phone;
  bool _saving = false;
  bool _updatingAvatar = false;

  static const List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200&auto=format&fit=crop&q=80',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().user;
    _name = TextEditingController(text: user?.name ?? '');
    _company = TextEditingController(text: user?.company ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final state = context.read<AppState>();
    final user = state.user;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await state.updateProfile(
        user.copyWith(
          name: _name.text.trim(),
          company: _company.text.trim(),
          phone: _phone.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.text,
          content: const Text(
            'Profile updated',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(
            'Could not save your profile. Please try again.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final state = context.read<AppState>();
    final user = state.user;
    if (user == null) return;

    try {
      final dataUrl = await pickImageAsDataUrl();
      if (dataUrl == null || dataUrl.isEmpty) return;

      if (!mounted) return;
      setState(() => _updatingAvatar = true);

      await state.updateProfile(user.copyWith(avatarUrl: dataUrl));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.text,
          content: const Text(
            'Profile picture updated!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(
            'Failed to upload image. Please try a smaller file.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingAvatar = false);
    }
  }

  Future<void> _selectPreset(String url) async {
    final state = context.read<AppState>();
    final user = state.user;
    if (user == null) return;

    Navigator.of(context).pop();
    setState(() => _updatingAvatar = true);
    try {
      await state.updateProfile(user.copyWith(avatarUrl: url));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.text,
          content: const Text(
            'Profile picture updated!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(
            'Failed to update profile picture.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    final state = context.read<AppState>();
    final user = state.user;
    if (user == null) return;

    Navigator.of(context).pop();
    setState(() => _updatingAvatar = true);
    try {
      await state.updateProfile(user.copyWith(clearAvatar: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.text,
          content: const Text(
            'Profile picture removed',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          content: Text(
            'Failed to remove photo.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingAvatar = false);
    }
  }

  void _showAvatarOptions() {
    final user = context.read<AppState>().user;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(
            Spacing.xl,
            Spacing.lg,
            Spacing.xl,
            Spacing.xxl,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                const Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Upload a photo from your computer or choose a preset avatar',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                Material(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _pickAndUploadAvatar();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            Ionicons.cloud_upload_outline,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload from computer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.text,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'PNG, JPG, WebP image',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                const Text(
                  'Choose a preset avatar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetAvatars.length,
                    separatorBuilder: (_, __) => const SizedBox(width: Spacing.md),
                    itemBuilder: (context, i) {
                      final url = _presetAvatars[i];
                      final isSelected = user?.avatarUrl == url;
                      return GestureDetector(
                        onTap: () => _selectPreset(url),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: Avatar(
                            initials: '${i + 1}',
                            avatarUrl: url,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) ...[
                  const SizedBox(height: Spacing.xl),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Ionicons.trash_outline, size: 18),
                    label: const Text(
                      'Remove photo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: _removeAvatar,
                  ),
                ],
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              Spacing.md,
              Spacing.xl,
              Spacing.xxxl,
            ),
            children: [
              Row(
                children: [
                  IconBadge(
                    icon: Icons.chevron_left,
                    background: Colors.white,
                    tone: AppColors.text,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: Spacing.md),
                  const Entrance(
                    child: Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xl),

              Entrance(
                delay: const Duration(milliseconds: 80),
                child: AppCard(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _updatingAvatar ? null : _showAvatarOptions,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: _updatingAvatar
                                  ? const SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : Avatar(
                                      initials: user?.initials ?? '?',
                                      avatarUrl: user?.avatarUrl,
                                      size: 80,
                                    ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Ionicons.camera,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      TextButton(
                        onPressed: _updatingAvatar ? null : _showAvatarOptions,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Change Photo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Entrance(
                        delay: const Duration(milliseconds: 140),
                        child: Text(
                          user?.name ?? 'Signed in',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Entrance(
                        delay: const Duration(milliseconds: 180),
                        child: Text(
                          user?.email ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Entrance(
                        delay: const Duration(milliseconds: 220),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StatusPill(
                              label: user?.role ?? 'Project Manager',
                              color: AppColors.info,
                            ),
                            const SizedBox(width: Spacing.sm),
                            StatusPill(
                              label: (user?.company ?? '').isEmpty
                                  ? 'No company'
                                  : user!.company,
                              color: AppColors.textMuted,
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
                delay: const Duration(milliseconds: 260),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      AppField(
                        label: 'Full name',
                        hint: 'Your name',
                        controller: _name,
                        prefixIcon: Ionicons.person_outline,
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: Spacing.lg),
                      AppField(
                        label: 'Company',
                        hint: 'Company name (optional)',
                        controller: _company,
                        prefixIcon: Ionicons.business_outline,
                      ),
                      const SizedBox(height: Spacing.lg),
                      AppField(
                        label: 'Phone',
                        hint: 'Phone number (optional)',
                        controller: _phone,
                        prefixIcon: Ionicons.call_outline,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xl),

              Entrance(
                delay: const Duration(milliseconds: 320),
                child: AppButton(
                  title: _saving ? 'Saving...' : 'Save Changes',
                  variant: AppButtonVariant.light,
                  icon: _saving ? null : Ionicons.checkmark,
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
